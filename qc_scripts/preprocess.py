import pathlib
import os, csv
import nibabel as nib
import numpy as np
import pandas as pd
import fsl.wrappers as fsl
from pathlib import Path
import warnings
warnings.filterwarnings("ignore")

def preprocess(wsp, pvc, rois_dir = None, reg = False, verbose = False):
    #work_spce = pathlib.Path(wsp)

    try:
        os.mkdir(os.path.join(wsp, 'qc'))
        print(f"Directory qc created successfully.")
    except FileExistsError:
        print(f"Directory qc already exists.")
    except PermissionError:
        print(f"Permission denied: Unable to create qc directory.")
    except Exception as e:
        print(f"An error occurred: {e}")

    IQMs = {}
    signal_IQMs = signal_qc(wsp, verbose = verbose)

    if rois_dir is not None:
        perf_IQMs = perfusion_qc(wsp, is_pvc = pvc, rois_dir = rois_dir,verbose = verbose)
    else:
        perf_IQMs = perfusion_qc(wsp, is_pvc=pvc, verbose=verbose)

    if reg:
        reg_IQMs = reg_qc(wsp, verbose = verbose)
        total_IQM_sets = [signal_IQMs, perf_IQMs, reg_IQMs]
    else:
        total_IQM_sets = [signal_IQMs, perf_IQMs]

    try:
        for IQM_sets in total_IQM_sets:
            if IQM_sets is None: continue
            for IQM in IQM_sets.keys():
                IQMs[IQM] = IQM_sets[IQM]
    except Exception as e:
        print(f"An exception occurred: {e}")

    IQMs_df = pd.DataFrame.from_dict(IQMs, orient='index', columns = ['Value'])
    if verbose:
        print(IQMs_df.head(10))
    IQMs_df.index.name = 'IQM'
    IQMs_df.to_csv(os.path.join(wsp, 'qc', 'IQMs.csv'))

    return IQMs


def signal_qc(wsp, verbose=False, erosion=0, gm_thres = 0.8, wm_thres = 0.9):

    assert os.path.exists(os.path.join(wsp, 'structural', 'gm_pv_asl.nii.gz'))
    assert os.path.exists(os.path.join(wsp, 'structural', 'wm_pv_asl.nii.gz'))

    gm_pv_path = os.path.join(wsp, 'structural', 'gm_pv_asl.nii.gz')
    wm_pv_path = os.path.join(wsp, 'structural', 'wm_pv_asl.nii.gz')

    gm_pv = nib.load(gm_pv_path)
    wm_pv = nib.load(wm_pv_path)

    #fsl.fslmaths(gm_pv).ero(erosion).run('eroded_gm.nii.gz')
    #fsl.fslmaths(wm_pv).ero(erosion).run('eroded_wm.nii.gz')

    eroded_gm = fsl.fslmaths(gm_pv).ero(erosion).run()
    eroded_wm = fsl.fslmaths(wm_pv).ero(erosion).run()


    assert os.path.exists(os.path.join(wsp, 'output', 'native', 'asldata_diff.nii.gz'))
    assert os.path.exists(os.path.join(wsp, 'output', 'native', 'diffdata_mean.nii.gz'))

    asl_diff_path = os.path.join(wsp, 'output', 'native', 'asldata_diff.nii.gz')
    pwi_path = os.path.join(wsp, 'output', 'native', 'diffdata_mean.nii.gz')

    eroded_gm_img = eroded_gm.get_fdata()
    eroded_wm_img = eroded_wm.get_fdata()

    #gm_img = nib.load(eroded_gm).get_fdata()
    #wm_img = nib.load(eroded_wm).get_fdata()
    pwi_img = nib.load(pwi_path).get_fdata()
    asl_diff_img = nib.load(asl_diff_path).get_fdata()
    gm_region = np.where(eroded_gm_img >= gm_thres)
    wm_region = np.where(eroded_wm_img >= wm_thres)
    gm_signal_mean = np.mean(pwi_img[gm_region])
    wm_signal_mean = np.mean(pwi_img[wm_region])


    gm_signal_ts = []
    wm_signal_ts = []

    for slice_idx in range(asl_diff_img.shape[-1]):
        t_image = asl_diff_img[:,:,:,slice_idx]
        t_gm = np.mean(t_image[gm_region])
        t_wm = np.mean(t_image[wm_region])
        gm_signal_ts.append(t_gm)
        wm_signal_ts.append(t_wm)

    gm_signal_ts = np.array(gm_signal_ts)
    wm_signal_ts = np.array(wm_signal_ts)

    SNR = gm_signal_mean/wm_signal_mean
    tSNR = np.mean(gm_signal_ts)/np.std(gm_signal_ts)
    CNR = (gm_signal_mean - wm_signal_mean)/wm_signal_mean
    tCNR = np.mean(gm_signal_ts - wm_signal_ts)/np.std(gm_signal_ts - wm_signal_ts)

    f = lambda x: round(x, 2)
    signal_dict = {}
    signal_dict['snr'] = f(SNR)
    signal_dict['tsnr'] = f(tSNR)
    signal_dict['cnr'] = f(CNR)
    signal_dict['tcnr'] = f(tCNR)

    if verbose:
        print(signal_dict)
    return signal_dict


def perfusion_qc(wsp, is_pvc=False, rois_dir=None, verbose=False):

    assert os.path.exists(os.path.join(wsp, 'output', 'native', 'calib_voxelwise', 'roi_stats.csv'))
    roi_path = os.path.join(wsp, 'output', 'native', 'calib_voxelwise', 'roi_stats.csv')
    perfusion_df = pd.read_csv(roi_path)

    roi_names = ['80%+GM', '90%+WM']
    if rois_dir is not None:
        assert os.path.exists(rois_dir)
        with open(rois_dir) as roi_file:
            roi_file_names = [l.strip() for l in roi_file.readlines()]
        for name in roi_file_names:
            roi_names.append(name)

    #roi_names = ['80%+GM', '90%+WM', 'Right_Cerebral_White_Matter_80%+',
    #             'Left_Cerebral_White_Matter_80%+', 'VBA', 'RICA', 'LICA']
    roi_indices = perfusion_df.index[perfusion_df['name'].isin(roi_names)].tolist()
    roi_stats_df = perfusion_df.iloc[roi_indices].reset_index(drop=True)
    roi_stats_df['Spcov'] = roi_stats_df[['Std', 'Mean']].apply(lambda x: x['Std'] * 100 / x['Mean'], axis=1).round(2)

    perfusion_qc = {}
    for roi in roi_names:
        perfusion_qc['cbf_' + roi] = roi_stats_df[roi_stats_df['name'] == roi]['Mean'].round(2).to_numpy()[0]
        perfusion_qc['spcov_' + roi] = roi_stats_df[roi_stats_df['name'] == roi]['Spcov'].round(2).to_numpy()[0]


    perfusion_qc['cbf_gm_wm_rate'] = round(perfusion_qc['cbf_80%+GM']/perfusion_qc['cbf_90%+WM'], 2)
    if 'Right_Cerebral_White_Matter_80%+' in roi_names and 'Left_Cerebral_White_Matter_80%+' in roi_names:
        perfusion_qc['cbf_rcwm_lcwm_rate'] = round(perfusion_qc['cbf_Right_Cerebral_White_Matter_80%+'] / perfusion_qc['cbf_Left_Cerebral_White_Matter_80%+'], 2)
    if 'LICA' in roi_names and 'RICA' in roi_names:
        perfusion_qc['cbf_rica_lica_rate'] = round(perfusion_qc['cbf_RICA'] / perfusion_qc['cbf_LICA'], 2)

    if is_pvc == True:

        assert os.path.exists(os.path.join(wsp, 'output_pvcorr', 'native', 'calib_voxelwise', 'roi_stats_gm.csv'))
        assert os.path.exists(os.path.join(wsp, 'output_pvcorr', 'native', 'calib_voxelwise', 'roi_stats_wm.csv'))

        roi_gm_path = os.path.join(wsp, 'output_pvcorr', 'native', 'calib_voxelwise', 'roi_stats_gm.csv')
        roi_wm_path = os.path.join(wsp, 'output_pvcorr', 'native', 'calib_voxelwise', 'roi_stats_wm.csv')
        perfusion_gm_df = pd.read_csv(roi_gm_path)
        perfusion_wm_df = pd.read_csv(roi_wm_path)



        if 'VBA' in roi_names and 'RICA' in roi_names and 'LICA' in roi_names:
            roi_gm_names = ['80%+GM', 'VBA', 'RICA', 'LICA']
        else:
            roi_gm_names = ['80%+GM']

        if 'Right_Cerebral_White_Matter_80%+' in roi_names and  'Left_Cerebral_White_Matter_80%+' in roi_names:
            roi_wm_names = ['90%+WM', 'Right_Cerebral_White_Matter_80%+', 'Left_Cerebral_White_Matter_80%+']
        else:
            roi_wm_names = ['90%+WM']

        roi_gm_indices = perfusion_gm_df.index[perfusion_gm_df['name'].isin(roi_gm_names)].tolist()
        roi_wm_indices = perfusion_wm_df.index[perfusion_wm_df['name'].isin(roi_wm_names)].tolist()
        roi_gm_stats_df = perfusion_gm_df.iloc[roi_gm_indices]
        roi_wm_stats_df = perfusion_wm_df.iloc[roi_wm_indices]
        roi_gm_stats_df['Spcov'] = roi_gm_stats_df[['Std', 'Mean']].apply(lambda x: x['Std'] * 100 / x['Mean'], axis=1).round(2)
        roi_wm_stats_df['Spcov'] = roi_wm_stats_df[['Std', 'Mean']].apply(lambda x: x['Std'] * 100 / x['Mean'], axis=1).round(2)

        roi_pvc_stats_df = pd.concat([roi_gm_stats_df, roi_wm_stats_df], axis=0).reset_index(drop=True)


        for roi in roi_names:
            perfusion_qc['pvc_cbf_' + roi] = roi_pvc_stats_df[roi_stats_df['name'] == roi]['Mean'].round(2).to_numpy()[0]
            perfusion_qc['pvc_spcov_' + roi] = roi_pvc_stats_df[roi_stats_df['name'] == roi]['Spcov'].round(2).to_numpy()[0]

        perfusion_qc['pvc_cbf_gm_wm_rate'] = round(perfusion_qc['pvc_cbf_80%+GM'] / perfusion_qc['pvc_cbf_90%+WM'], 2)
        if 'Right_Cerebral_White_Matter_80%+' in roi_wm_names and 'Left_Cerebral_White_Matter_80%+' in roi_wm_names:
            perfusion_qc['pvc_cbf_rcwm_lcwm_rate'] = round(perfusion_qc['pvc_cbf_Right_Cerebral_White_Matter_80%+'] / perfusion_qc['pvc_cbf_Left_Cerebral_White_Matter_80%+'], 2)
        if 'LICA' in roi_gm_names and 'RICA' in roi_gm_names:
            perfusion_qc['pvc_cbf_rica_lica_rate'] = round(perfusion_qc['pvc_cbf_RICA'] / perfusion_qc['pvc_cbf_LICA'], 2)

    if verbose:
        print("pvc = {}".format(is_pvc))
        print(perfusion_qc)

    return perfusion_qc


def reg_qc(wsp, verbose=False):

    cost_functions = ["mutualinfo", "corratio", "normcorr", "normmi", "leastsq"]
    diff_list = {}

    fsldir = os.environ["FSLDIR"]

    assert os.path.exists(os.path.join(wsp, 'output', 'native', 'asldata_diff.nii.gz'))
    assert os.path.exists(os.path.join(fsldir,"etc", "flirtsch", "ident.mat"))
    #assert os.path.exists("$FSLDIR", "data", "standard", "MNI152_T1_2mm_brain.nii.gz")
    assert os.path.exists(os.path.join(wsp, "reg", "stdref.nii.gz"))
    assert os.path.exists(os.path.join(wsp, 'output', 'std', 'calib_voxelwise', 'perfusion.nii.gz'))

    asl_std_path = os.path.join(wsp, 'output', 'std', 'calib_voxelwise', 'perfusion.nii.gz')
    asl_std_img = nib.load(asl_std_path).get_fdata()
    ref_path = os.path.join(wsp, "reg", "stdref.nii.gz")
    ref_image = nib.load(ref_path).get_fdata()
    id_matrix_path = os.path.join("$FSLDIR","etc", "flirtsch", "ident.mat")

    if asl_std_img.shape != ref_image.shape:
        raise ValueError("Images must have the same dimensions.")

    reg_qc = {}

    f = lambda x: round(x, 3)

    for costfunc in cost_functions:
        cmd = "flirt -in " + asl_std_path + ' -schedule $FSLDIR/etc/flirtsch/measurecost1.sch  -ref ' + ref_path + ' -init ' + id_matrix_path + ' -cost ' + costfunc
        output = os.popen(cmd).read()
        result = float(output.split()[0])
        reg_qc[costfunc] = f(result)


    if verbose:
        print(reg_qc)

    return reg_qc