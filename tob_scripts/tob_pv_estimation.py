#! /usr/bin/env python3
"""Partial volume processing using FS volumetric segmentation"""

import argparse
import glob
import os
import os.path as op
import pathlib

import nibabel as nib
import numpy as np
import regtricks as rt
import scipy
from toblerone.pvestimation import cortex as estimate_cortex

# Map from FS aparc+aseg labels to tissue types
# NB cortex is ignored
FS_LUT = {
    # Left hemisphere
    2: "WM",  # Cerebral WM
    7: "WM",  # Cerebellum
    8: "GM",  # Cerebellum
    10: "GM",  # L_Thal
    11: "GM",  # L_Caud
    12: "GM",  # L_Puta
    13: "GM",  # L_Pall
    17: "GM",  # L_Hipp
    18: "GM",  # L_Amyg
    26: "GM",  # L_Accu
    28: "WM",  # Left ventral DC
    30: "WM",  # Left vessel
    31: "GM",  # Left choroid plexus
    # Right hemisphere
    41: "WM",  # Cerebral WM
    46: "WM",  # Cerebellum
    47: "GM",  # Cerebellum
    49: "GM",  # R_Thal
    50: "GM",  # R_Caud
    51: "GM",  # R_Puta
    52: "GM",  # R_Pall
    53: "GM",  # R_Hipp
    54: "GM",  # R_Amyg
    58: "GM",  # R_Accu
    60: "WM",  # Right ventral DC
    62: "WM",  # Right vessel
    63: "GM",  # Right choroid plexus
    # Shared both sides
    16: "WM",  # Brainstem
    85: "WM",  # Optic chiasm
    77: "WM",  # Hyperintensity
    251: "WM",  # CC
    252: "WM",  # CC
    253: "WM",  # CC
    254: "WM",  # CC
    255: "WM",  # CC
}


def pvs_from_freesurfer(t1_dir, ref_spc, ref2struct=None, cores=1):
    """
    Extract and layer PVs according to tissue type, taken from a FS aparc+aseg.
    Results are stored in ASL-gridded T1 space.
    Args:
        aparcseg: path to aparc+aseg file
        surf_dict: dict with LWS/LPS/RWS/RPS keys, paths to those surfaces
        ref_spc: space in which to estimate (ie, ASL-gridded T1)
        ref2struct: FLIRT registration between reference and T1w image
        cores: number CPU cores to use, default is 1
    Returns:
        nibabel Nifti object
    """

    # Load the t1 image, aparc+aseg and surfaces from their expected
    # names and locations within t1w_dir
    surf_dict = {}
    for k, n in zip(
        ["LWS", "LPS", "RPS", "RWS"],
        [
            "L.white.32k_fs_LR.surf.gii",
            "L.pial.32k_fs_LR.surf.gii",
            "R.pial.32k_fs_LR.surf.gii",
            "R.white.32k_fs_LR.surf.gii",
        ],
    ):
        paths = glob.glob(op.join(t1_dir, f"fsaverage_LR32k/*{n}"))
        if len(paths) > 1:
            raise RuntimeError(f"Found multiple surfaces for {k}")
        surf_dict[k] = paths[0]

    ref_spc = rt.ImageSpace(ref_spc)
    aseg_spc = nib.load(op.join(t1_dir, "aparc+aseg.nii.gz"))
    aseg = aseg_spc.get_fdata().astype(int)
    aseg_spc = rt.ImageSpace(aseg_spc)

    # If not provided, an identity transform is used
    if ref2struct:
        struct2ref_reg = rt.Registration.from_flirt(
            ref2struct, ref_spc, aseg_spc
        ).inverse()
    else:
        struct2ref_reg = rt.Registration.identity()

    # Extract PVs from aparcseg segmentation, ignoring cortex.
    non_cortex_pvs = np.zeros((*aseg_spc.size, 2), dtype=np.float32)
    for k, t in FS_LUT.items():
        m = aseg == k
        idx = ["GM", "WM"].index(t)
        non_cortex_pvs[m, idx] = 1

    # Super-resolution resampling for the vol_pvs, a la applywarp.
    # 0: GM, 1: WM, always in the LAST dimension of an array
    non_cortex_pvs = struct2ref_reg.apply_to_array(
        non_cortex_pvs, aseg_spc, ref_spc, order=1, cores=cores
    )

    #ref_spc.save_image(non_cortex_pvs, "non_cortex.nii.gz")

    # Estimate cortical PVs
    cortex = estimate_cortex(
        ref=ref_spc,
        struct2ref=struct2ref_reg.src2ref,
        cores=cores,
        **surf_dict,
    )

    out = non_cortex_pvs[..., :2].copy()

    # Voxels where toblerone has identified the cortex
    ctx = cortex[..., 0] > 0.01

    # total brain PV in these voxels (GM or WM)
    ctx_brain_pv = np.maximum(cortex[ctx, :2].sum(-1), non_cortex_pvs[ctx, :2].sum(-1))

    # Layer in cortical GM (sum on top of existing GM)
    out[ctx, 0] = np.minimum(cortex[ctx, 0] + out[ctx, 0], 1)

    # In those voxels, the total brain PV be as predicted by Toblerone,
    # so update the WM value based on this
    out[ctx, 1] = np.maximum(ctx_brain_pv - out[ctx, 0], 0)

    # Sanity checks
    assert (out >= 0).all(), "Negative PV"
    assert (out <= 1).all(), "PV > 1"
    assert out.sum(-1).max() <= 1.001, "PV sum > 1"

    #ref_spc.save_image(out, "asl_pvs.nii.gz")
    #ref_spc.save_image(out.sum(-1), "gmwm.nii.gz")

    return ref_spc.make_nifti(out)


def generate_ventricle_mask(aparc_aseg, t1_asl):
    ref_spc = rt.ImageSpace(t1_asl)

    # get ventricles mask from aparc+aseg image
    aseg = nib.load(aparc_aseg).get_fdata()
    vent_mask = np.logical_or(
        aseg == 43, aseg == 4  # left ventricle  # right ventricle
    )

    # erosion in t1 space for safety
    vent_mask = scipy.ndimage.morphology.binary_erosion(vent_mask)

    # Resample to target space, re-threshold
    output = rt.Registration.identity().apply_to_array(
        vent_mask, src=aparc_aseg, ref=ref_spc, order=1
    )
    output = output > 0.8
    return output


def run_pv_estimation(study_dir, sub_id, cores, outdir, interpolation):

    sub_base = op.abspath(op.join(study_dir, sub_id))
    t1_dir = op.join(sub_base, "T1w")
    t1_asl_dir = op.join(sub_base, outdir, "T1w", "ASL")

    asl = op.join(sub_base, 'oxasl_surf', "output", "native", 'calib_voxelwise', "perfusion.nii.gz")
    struct = op.join(t1_dir, "T1w_acpc_dc_restore.nii.gz")


    # Create PVEs directory
    pve_dir = outdir#op.join(sub_base, outdir, "T1w", "ASL", "PVEs")
    os.makedirs(pve_dir, exist_ok=True)

    # Create a ventricle CSF mask in T1 ASL space
    ventricle_mask = op.join(pve_dir, "CSF_mask.nii.gz")
    aparc_aseg = op.join(t1_dir, "aparc+aseg.nii.gz")
    vmask = generate_ventricle_mask(aparc_aseg, struct)
    rt.ImageSpace.save_like(struct, vmask, ventricle_mask)

    # Estimate PVs in ASL0 space then register them to ASLT1w space
    # Yes this seems stupid but theres a good reason for it
    # aka double-resampling (ask TK)
    asl2struct = op.join(t1_asl_dir, "TIs", "reg", "asl2struct.mat")
    pvs_stacked = pvs_from_freesurfer(t1_dir, struct,  cores=cores)
    #pvs_stacked = pvs_from_freesurfer(t1_dir, asl, ref2struct=asl2struct, cores=cores)

    # register the PVEs from ASL0 space to ASLT1w space with the
    # same order of interpolation used to register the ASL series
    #asl2struct = rt.Registration.from_flirt(asl2struct, asl, struct)
    #pvs_stacked = asl2struct.apply_to_image(
    #    src=pvs_stacked, ref=t1_asl_grid, order=interpolation, cores=cores
    #)

    # Save output with tissue suffix
    fileroot = op.join(pve_dir, "pve")
    for idx, suffix in enumerate(["GM", "WM"]):
        p = "{}_{}.nii.gz".format(fileroot, suffix)
        rt.ImageSpace.save_like(struct, pvs_stacked.dataobj[..., idx], p)




def main():
    desc = """
    Generate PV estimates for a reference voxel grid. FS' volumetric 
    segmentation is used for the subcortex and a surface-based method
    is used for the cortex (toblerone). 
    """

    parser = argparse.ArgumentParser(description=desc)
    parser.add_argument(
        "--t1_dir",
        required=True,
        help="HCP pre-processed T1w dir containing aparc+aseg and fsaverage_LR32k",
    )
    parser.add_argument(
        "--ref", required=True, help="path to image defining reference grid for PVs"
    )
    parser.add_argument("--out", required=True, help="path to save output")
    parser.add_argument(
        "--stack", action="store_true", help="stack output into single 4D volume"
    )
    parser.add_argument("--cores", default=1, type=int, help="CPU cores to use")

    args = parser.parse_args()
    pvs = pvs_from_freesurfer(
        t1_dir=args.t1_dir, ref_spc=args.ref, cores=args.cores
    )
    '''
    if args.stack:
        nib.save(pvs, args.out)

    else:
        opath = pathlib.Path(args.out)
        spc = rt.ImageSpace(pvs)
        pvs = pvs.dataobj
        for idx, tiss in enumerate(["GM", "WM", "CSF"]):
            n = opath.parent.joinpath(
                opath.stem.rsplit(".", 1)[0] + f"_{tiss}" + "".join(opath.suffixes)
            )
            spc.save_image(pvs[..., idx], n.as_posix())
    '''

def main2():
    desc = """
    Generate PV estimates for a reference voxel grid. FS' volumetric 
    segmentation is used for the subcortex and a surface-based method
    is used for the cortex (toblerone). 
    """
    parser = argparse.ArgumentParser(description=desc)
    parser.add_argument(
        "--studydir",
        required=True,
        help="HCP pre-processed T1w dir containing aparc+aseg and fsaverage_LR32k",
    )
    parser.add_argument(
        "--subid", required=True, help="path to image defining reference grid for PVs"
    )
    #parser.add_argument("--out", required=True, help="path to save output")
    parser.add_argument(
        "--stack", action="store_true", help="stack output into single 4D volume"
    )
    parser.add_argument("--cores", default=1, type=int, help="CPU cores to use")

    args = parser.parse_args()

    #studydir=r'/gpfs01/share/TILDA/test_pipeline/DATA'
    #subid=r'sub-1267031'
    cores=1
    sub_base = op.abspath(op.join(args.studydir, args.subid))
    outdir=op.join(sub_base, "processed", "hcpasl_PVE")
    interpolation=3


    run_pv_estimation(args.studydir, args.subid, cores, outdir, interpolation)
    

if __name__ == '__main__': 
    main2()