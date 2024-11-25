"Coritical region analysis for metric file using destrieux_atlas on fsaverage5"

from tools import setup_logger
import argparse
import logging
from pathlib import Path
import regtricks as rt
import numpy as np
import nibabel as nib
import os, ntpath
import nilearn
from nilearn import datasets, surface
import pandas as pd


def surface_summary_stats(hemi):
    """
    Args: a python list
    returns: mean, std, SpCoV
    """
    if np.sum(hemi) != 0:
        mean = np.mean(hemi)
        std = np.std(hemi)
        SpCoV = std*100 / mean
        return mean, std, SpCoV
    else:
        return 0, 0, 0

def region_analysis(out, image_type, left_hemi, right_hemi):
    """
    Statistics for each hemisphere
    Args:
        out: csv file output path
        image_type: output name prefix
        left_hemi: path to left hemisphere metric file
        right_hemi: path to right hemisphere metric file
    returns: ouutput a 
    """
    
    surfs = [left_hemi, right_hemi]
    l_hemi, r_hemi = [nilearn.surface.load_surf_data(str(name)) for name in surfs]
    
    destrieux_atlas = datasets.fetch_atlas_surf_destrieux()
    left_surf_stats = {}
    left_surf_stats['Left_hemi'] = surface_summary_stats(l_hemi)
    right_surf_stats = {}
    right_surf_stats['Right_hemi'] = surface_summary_stats(r_hemi)

    labels = destrieux_atlas['labels']  

    np_left_surf = nib.load(left_hemi).agg_data()
    np_right_surf = nib.load(right_hemi).agg_data()

    for region in labels:
        left_pos = np.where(destrieux_atlas['map_left'] == labels.index(region))[0]
        right_pos = np.where(destrieux_atlas['map_right'] == labels.index(region))[0]
        left_surf_stats[region] =  surface_summary_stats(np_left_surf[left_pos])
        right_surf_stats[region] =  surface_summary_stats(np_right_surf[right_pos])

    left_surf_stats.pop(b'Unknown')
    right_surf_stats.pop(b'Unknown')


    df_left_stats = pd.DataFrame.from_dict(left_surf_stats, orient='index')
    df_left_stats.columns=['Mean_'+image_type, 'Std_'+image_type, 'SpCoV_'+image_type]
    df_left_stats.to_csv(os.path.join(out, image_type+'_left_surf_stats.csv'))

    df_right_stats = pd.DataFrame.from_dict(right_surf_stats, orient='index')
    df_right_stats.columns=['Mean_'+image_type, 'Std_'+image_type, 'SpCoV_'+image_type]
    df_right_stats.to_csv(os.path.join(out, image_type+'_right_surf_stats.csv'))

    #display(df)
    


def main(): 
    parser = argparse.ArgumentParser(
        description="This script performs toblerone to obtain PEVs from T1.")

    parser.add_argument(
        "--type",
        help="perfusion or arrival image",
        required=True
    )

    parser.add_argument(
        "-o",
        "--output",
        help="Path to output.",
        required=True
    )

    parser.add_argument(
        "-l",
        "--left",
        help="Left Hemisphere",
        required=True
    )

    parser.add_argument(
        "-r",
        "--right",
        help="Right Hemisphere",
        required=True
    )

    parser.add_argument(
        "-v", "--verbose",
        help="If this option is provided, stdout will go to the terminal "
            +"as well as to a logfile. Default is False.",
        action="store_true"
    )

    args = parser.parse_args()
    type=args.type
    left=args.left
    right=args.right
    output = args.output
    Path(output).mkdir(exist_ok=True)
    #prefix = ntpath.basename(src).split('.')[0]
    logger = setup_logger("ROI_analysis", os.path.join(output, type+'_region_analysis.log'), "INFO", args.verbose)
    region_analysis(output, type, left, right)
    logger.info(args)



if __name__ == '__main__':
    main()