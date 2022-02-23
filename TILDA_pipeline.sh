#!/bin/bash

#SBATCH --partition=defq

#SBATCH --nodes=8

#SBATCH --ntasks-per-node=1

#SBATCH --mem=4g

#SBATCH --time=10:00:00

#SBATCH --array=1-1

module load fsl-img/6.0.4

Usage()
{
  echo "Usage: `basename $0` [OPTIONS]"
  echo " "
  echo " "
  echo "OPTIONS:"
  echo " "
  echo " "
  echo " --reference-file <Path>       (Mandatory) path to the reference image file"
  echo " --mask-file <Path>            (Mandatory) path to the mask image file"
  echo " --output-file <Path>          (Mandatory) path to the output file where the correlation values are written"
  echo " --bids-dir <Path>             (Mandatory) path to BIDS directory"
  echo " --subject-list-file <Path>    (Mandatory) path to a text file specifing the subject ids to process (one per line, without 'sub-' prefix)"
  echo " -h | --help                   help"
  echo " "
  echo " "
}

if [ $# -eq 0 ] ; then Usage; exit 0; fi

module load fsl-img/6.0.4
subject_path=
subject="sub-${SLURM_ARRAY_TASK_ID}"
subject_folder="BRC_result"


while [ "$1" != "" ]
do
    case $1 in
        --path )        shift
                                subject_path=$1/${subject}
                                ;;
                                                        
        -h | --help )           Usage
                                exit
                                ;;
        * )                     Usage
                                exit 1
    esac
    shift
done


echo "Processing ${subject}"
echo "Step 1 processing fieldmaps..."

fslmaths "${subject_path}"/fieldmap_mag1.nii -add 3.14 "${subject_path}"/fieldmap_magshift1.nii.gz
fslmaths "${subject_path}"/fieldmap_mag2.nii -add 3.14 "${subject_path}"/fieldmap_magshift2.nii.gz

fslroi "${subject_path}"/fieldmap_magshift2.nii.gz "${subject_path}"/fieldmap_magshift2_expand.nii.gz 0 80 0 80 -1 15

bet "${subject_path}"/fieldmap_magshift2_expand.nii.gz "${subject_path}"/fieldmap_mag_brain.nii.gz -f 0.6

fslmaths "${subject_path}"/fieldmap_mag_brain.nii.gz -bin "${subject_path}"/fieldmap_mag_brain_mask.nii.gz
fslmaths "${subject_path}"/fieldmap_mag_brain_mask.nii.gz -ero "${subject_path}"/fieldmap_mask_ero.nii.gz

fslroi "${subject_path}"/fieldmap_mask_ero.nii.gz "${subject_path}"/fieldmap_mask_final.nii.gz 0 80 0 80 1 13


prelude -a "${subject_path}"/fieldmap_magshift1.nii.gz -p "${subject_path}"/fieldmap_ph1.nii -o "${subject_path}"/fieldmap_ph1_unwrapped.nii.gz -m "${subject_path}"/fieldmap_mask_final.nii.gz
prelude -a "${subject_path}"/fieldmap_magshift2.nii.gz -p "${subject_path}"/fieldmap_ph2.nii -o "${subject_path}"/fieldmap_ph2_unwrapped.nii.gz -m "${subject_path}"/fieldmap_mask_final.nii.gz


fslmaths "${subject_path}"/fieldmap_ph1_unwrapped.nii.gz -sub "${subject_path}"/fieldmap_ph2_unwrapped.nii.gz -mul 1000 -div 5.32 "${subject_path}"/fieldmap_rads.nii.gz -odt float

fugue --loadfmap="${subject_path}"/fieldmap_rads.nii.gz -s 1 --savefmap="${subject_path}"/fieldmap_rads.nii.gz
fugue --loadfmap="${subject_path}"/fieldmap_rads.nii.gz --despike --savefmap="${subject_path}"/fieldmap_rads.nii.gz
fugue --loadfmap="${subject_path}"/fieldmap_rads.nii.gz -m --savefmap="${subject_path}"/fieldmap_rads.nii.gz

fslmaths "${subject_path}"/fieldmap_rads.nii.gz -mul "${subject_path}"/fieldmap_mask_final.nii.gz "${subject_path}"/fieldmap_rads.nii.gz

mv "${subject_path}"/fieldmap_mask_final.nii.gz "${subject_path}"/new_fieldmap_mask.nii.gz
mv "${subject_path}"/fieldmap_ph1_unwrapped.nii.gz "${subject_path}"/new_fieldmap_ph1_unwrapped.nii.gz
mv "${subject_path}"/fieldmap_ph2_unwrapped.nii.gz "${subject_path}"/new_fieldmap_ph2_unwrapped.nii.gz
mv "${subject_path}"/fieldmap_rads.nii.gz "${subject_path}"/new_fieldmap_rads.nii.gz

echo "Step 1 done."

echo "Step 2 processing T1..."
fsl_anat -i ${subject_path}/T1
echo "Step 2 done."

echo "Step 3 processing asl..."
asl_file --data=${subject_path}/asldata --ntis=1 --iaf=ctb --ibf=tis --diff --mean=asldiffdata_mean
#mcflirt -in ${subject_path}/asldata -out ${subject_path}/asldata_mc

oxford_asl -i ${subject_path}/asldata.nii -o ${subject_path}/oxasl_voxel_calib --spatial --iaf=ctb --ibf=tis --tis 3.6 --casl --bolus 1.8 -c ${subject_path}/aslcalib --tr 10 --fslanat=${subject_path}/T1.anat --te=9 --slicedt=0.03 --mc --pvcorr --cmethod voxel 
oxford_asl -i ${subject_path}/asldata.nii -o ${subject_path}/oxasl_distcorr_voxel_calib --spatial --iaf=ctb --ibf=tis --tis 3.6 --casl --bolus 1.8 -c ${subject_path}/aslcalib --tr 10 --fslanat=${subject_path}/T1.anat --te=9 --slicedt=0.03 --fmap=${subject_path}/new_fieldmap_rads --fmapmag=${subject_path}/new_fieldmap_mag --fmapmagbrain=${subject_path}/new_fieldmap_mag_brain --echospacing=0.0005 --pedir=-y --mc --pvcorr  --cmethod voxel  
echo "Step 3 done."

echo "Step 4 analysing results..."

echo "Running region analysis..."
echo "Not done yet."

echo "Creating a tigher brain mask for comparing the old and new results..."
fslchfiletype NIFTI ${subject_path}/analysis/oxasl/native_space/perfusion_calib ${subject_path}/perfusion_calib
fslchfiletype NIFTI ${subject_path}/analysis/oxasl_distcorr/native_space/perfusion_calib ${subject_path}/perfusion_calib_distcorr
rm -rf ${subject_path}/processed
mkdir ${subject_path}/processed
bet ${subject_path}/T1.anat/T1 ${subject_path}/processed/T1_brain_mask -f 0.6 -o -g -0.3
convert_xfm -omat ${subject_path}/oxasl_voxel_calib/native_space/struct2asl.mat -inverse ${subject_path}/oxasl_voxel_calib/native_space/asl2struct.mat
flirt -applyxfm -in ${subject_path}/processed/T1_brain_mask -ref ${subject_path}/oxasl_voxel_calib/native_space/perfusion -out ${subject_path}/processed/brain_mask_inasl -interp trilinear -paddingsize 1 -init ${subject_path}/oxasl_voxel_calib/native_space/struct2asl.mat
fslmaths ${subject_path}/processed/brain_mask_inasl -ero ${subject_path}/processed/brain_erode_mask_inasl

echo "Producing motion traces..."
mcflirt -in ${subject_path}/asldata -out ${subject_path}/processed/asldata_mc  -plots
fsl_tsplot -i ${subject_path}/processed/asldata_mc.par  -t "rotations" -u 1 --start=1 --finish=3 -a x,y,z -w 640 -h 200 -o ${subject_path}/processed/"${subject}_rots.png"
fsl_tsplot -i ${subject_path}/processed/asldata_mc.par  -t "translations" -u 1 --start=4 --finish=6 -a x,y,z -w 640 -h 200 -o ${subject_path}/processed/"${subject}_trans.png"
echo "Step 4 done."

echo "${subject} done."






