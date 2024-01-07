#"Cortical ROI analysis using smetric file with FS label/annot file"


from tools import setup_logger
import argparse
import logging
from pathlib import Path
import toblerone as tob
import regtricks as rt
import numpy as np
import nibabel as nib
import os, ntpath
from nilearn import datasets
import pandas as pd
import roi_analysis
pd.set_option('display.precision', 2)

RUN_MODE = 'no_test'



def surf_roi_analysis(metric, atlas, output_path, image_type, hemi, surface=None):
    """
    Calculate the statistics for metric file in ROIs according to the region information from FS atlas(label/annot) file.
    Args:
        metric: path to the metric file
        atals: path to the label/annot file
        output_path: path to save csv result
        image_type: prefix name of output
        hemi: left/Left/L or right/Right/R hemisphere 
        surface: surface(surf.nii) file(not used in this function)
    return: a csv file of input hemisphere metric file containing 'Mean', 'Std', 'SpCoV' for each cortical ROI.

    e.g.: 
    python surf_roi_analysis.py --metric  ${input_path}/processed/struc/native/weighted/surf_pvc/"$sub_id".L.midthickness.native.func.gii --atlas ${input_path}/T1w/${sub_id}/label/lh.aparc.a2009s.annot --output ${SUBJDIR}/processed/struc/native/region_analysis/weighted/DK/pvc/left --type ${sub_id}_pvc_perfusion_dk --hemi left
    python surf_roi_analysis.py --metric  ${input_path}/processed/struc/native/weighted/surf_nonpvc/"$sub_id".L.midthickness.native.func.gii --atlas ${input_path}/T1w/${sub_id}/label/lh.aparc.a2009s.annot --output ${SUBJDIR}/processed/struc/native/region_analysis/weighted/DK/nonpvc/left --type ${sub_id}_nonpvc_perfusion_dk --hemi left

    """

    #load metric file and 
    if os.path.exists(metric) and os.path.exists(atlas):
        logger = logging.getLogger()
        logger.info("All files loaded")
    else:
        logger = logging.getLogger()
        logger.info("Input(metric/atlas) not found.")
        logger.info("End.")
        return


    labels = []
    keys = []

    if atlas.split('.')[-2] == 'label' and atlas.split('.')[-1] == 'gii':
        logger.info('Using .label.gii file for analysis.')
        PARCELLATION_ATLAS = nib.load(atlas)
        surf_label = PARCELLATION_ATLAS.darrays[0].data

        for roi in PARCELLATION_ATLAS._labeltable.labels:
            labels.append(roi.label)
            keys.append(roi.key)

    elif atlas.split('.')[-1] == 'annot':
        logger.info('Using .annot file type for analysis.')
        surf_label, _, labels  = nib.freesurfer.io.read_annot(atlas)
        keys = [i for i in range(len(labels))]#PARCELLATION_ATLAS.darrays[0].data
    
    logger.info("Atlas loaded.")

    perf_metric = nib.load(metric)
    perf_values = perf_metric.darrays[0].data

    rois = np.zeros_like(labels)
    roi_dict = {}
    perf_values = np.nan_to_num(perf_values, nan=0)

    for idx in list(set(keys)):
        pos = np.where(surf_label == idx)[0]
        roi_dict[labels[idx]] = roi_analysis.surface_summary_stats(perf_values[pos])
    

    
    if hemi == 'left' or hemi == 'L' or hemi == 'Left':
        roi_dict['Left_Hemi'] = roi_analysis.surface_summary_stats(perf_values)
    if hemi == 'right' or hemi == 'R' or hemi == 'Right':
        roi_dict['Right_Hemi'] = roi_analysis.surface_summary_stats(perf_values)
    #roi_dict.pop('???')
    df_left_stats = pd.DataFrame.from_dict(roi_dict, orient='index')
    df_left_stats.columns=['Mean', 'Std', 'SpCoV']
    df_left_stats.to_csv(os.path.join(output_path, image_type+'_'+hemi+'_stats.csv'))
    logger.info("Done.")



def main(): 

    if RUN_MODE == 'test':

        data_path = r'D:\onedrive\OneDrive - The University of Nottingham\TILDA\analysis\surface_roi'
        #label_DK = os.path.join(data_path, 'fsaverage_LR32k', 'sub-1267031.aparc.32k_fs_LR.dlabel.nii')
        #label_Dex = os.path.join(data_path, 'fsaverage_LR32k',  'sub-1267031.aparc.a2009s.32k_fs_LR.dlabel.nii')

        label_L_DK = os.path.join(data_path, 'fsaverage_LR32k', 'sub-1267031.L.aparc.32k_fs_LR.label.gii')
        label_L_Dex = os.path.join(data_path, 'fsaverage_LR32k', 'sub-1267031.L.aparc.a2009s.32k_fs_LR.label.gii')

        L_metric = os.path.join(data_path,'weighted','surf_nonpvc', 'sub-1267031.L.midthickness.native.func.gii')
        #L_metric = os.path.join(data_path,'weighted','surf_nonpvc', 'sub-1267031.L.midthickness.32k_fs_LR.func.gii')
        #R_metric = os.path.join(data_path,'weighted','surf_nonpvc', 'sub-1267031.R.midthickness.32k_fs_LR.func.gii')
        output = os.path.join(data_path,'weighted','test')
        Path(output).mkdir(exist_ok=True)
        prefix = 'perfusion'
        logger = setup_logger("Surface_ROI_analysis", os.path.join(output, prefix+'_surf_roi.log'), "INFO", False)
        surf_roi_analysis(metric=L_metric, atlas=label_L_DK, output_path=output, image_type='perfusion', hemi='left')
        #surf_roi_analysis(metric=R_metric, atlas=label_L_DK, output_path=output, image_type='perfusion', hemi='left')

    else:

        parser = argparse.ArgumentParser(
            description="This script do projection in the native space which requires ASL and T1w")

        parser.add_argument(
            "--metric",
            "-m",
            help="Metric file (i.e. func.gii)",
            required=True
        )

        parser.add_argument(
            "--atlas",
            "-a",
            help="Cortical atlas parcellation (DK/Dex)",
            required=True
        )

        parser.add_argument(
            "-s",
            "--surface",
            help="Surface for the metric file, i.e., a surf.gii file.",
            required=False
        )

        parser.add_argument(
            "--output",
            "-o",
            help="Output",
            required=True
        )


        parser.add_argument(
            "--type",
            help="Prefix for output",
            required=True
        )

        parser.add_argument(
            "--hemi",
            help="Left or Right",
            required=True
        )

        parser.add_argument(
            "-v", "--verbose",
            help="If this option is provided, stdout will go to the terminal "
                +"as well as to a logfile. Default is False.",
            action="store_true"
        )

        args = parser.parse_args()
        surf=args.surface
        atlas=args.atlas
        metric=args.metric
        output = args.output
        image_type = args.type
        hemi = args.hemi
        Path(output).mkdir(exist_ok=True)

        prefix = ntpath.basename(image_type).split('.')[0]
        logger = setup_logger("Surface_ROI_analysis", os.path.join(output, prefix+'_surf_roi.log'), "INFO", args.verbose)
        logger.info(args)

        surf_roi_analysis(metric=metric, atlas=atlas, output_path=output, image_type=image_type, hemi=hemi)


if __name__ =='__main__':
    main()