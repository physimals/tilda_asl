#!/bin/bash

#SBATCH --partition=defq

#SBATCH --nodes=8

#SBATCH --ntasks-per-node=1

#SBATCH --mem=4g

#SBATCH --time=10:00:00

#SBATCH --array=1-10

#module load fsl-img/6.0.5
module load brc-pipelines-img
module load oxfordasl-img

Usage()
{
  echo " "
}

if [ $# -eq 0 ] ; then Usage; exit 0; fi
subject_path=
subject="sub-${SLURM_ARRAY_TASK_ID}"
rois_folder="../ukb_rois"

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

subject_t1="${subject_path}/T1.nii"
T1_subject_folder="BRC_T1_result"



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
#fsl_anat -i ${subject_path}/T1
#struc_preproc.sh --input ${subject_t1} --path ${subject_path} --subject ${T1_subject_folder} --freesurfer --subseg 
echo "Step 2 done."

echo "Step 3 processing asl and region analysis..."
asl_file --data=${subject_path}/asldata --ntis=1 --iaf=ctb --ibf=tis --diff --mean=asldiffdata_mean

#region-analysis version
oxford_asl -i ${subject_path}/asldata.nii -o ${subject_path}/oxford_asl_results --spatial --iaf=ctb --ibf=tis --tis 3.6 --casl --bolus 1.8 -c ${subject_path}/aslcalib --tr 10 -s ${subject_path}/${T1_subject_folder}/analysis/anatMRI/T1/processed/data/T1_unbiased.nii.gz --warp=${subject_path}/${T1_subject_folder}/analysis/anatMRI/T1/preproc/reg/T1_2_std_warp_field.nii.gz --sbrain=${subject_path}/${T1_subject_folder}/analysis/anatMRI/T1/processed/data/T1_unbiased_brain --te=9 --slicedt=0.03 --fmap=${subject_path}/new_fieldmap_rads --fmapmag=${subject_path}/fieldmap_magshift2 --fmapmagbrain=${subject_path}/new_fieldmap_mask --echospacing=0.0005 --pedir=-y --mc --pvcorr  --cmethod=both  --debug --region-analysis --region-analysis-atlas=${rois_folder}/HO_R_Cerebral_WM_thr80.nii.gz --region-analysis-atlas-labels=${rois_folder}/HO_R_Cerebral_WM_thr80.txt --region-analysis-atlas=${rois_folder}/HO_L_Cerebral_WM_thr80.nii.gz --region-analysis-atlas-labels=${rois_folder}/HO_L_Cerebral_WM_thr80.txt --region-analysis-atlas=${rois_folder}/MNI_seg_max_prob_masked_RandL.nii.gz --region-analysis-atlas-labels=${rois_folder}/MNI_seg_max_prob_masked_RandL.txt --region-analysis-atlas=${rois_folder}/VascularTerritories_ero.nii.gz --region-analysis-atlas-labels=${rois_folder}/VascularTerritories_ero.txt --region-analysis-save-rois
#oxford_asl -i ${subject_path}/asldata.nii -o ${subject_path}/oxford_asl_results --spatial --iaf=ctb --ibf=tis --tis 3.6 --casl --bolus 1.8 -c ${subject_path}/aslcalib --tr 10 -s ${subject_path}/${T1_subject_folder}/analysis/anatMRI/T1/processed/data/T1_unbiased.nii.gz -t ${subject_path}/${T1_subject_folder}/analysis/anatMRI/T1/preproc/reg/T1_2_std.mat --te=9 --slicedt=0.03 --fmap=${subject_path}/new_fieldmap_rads --fmapmag=${subject_path}/fieldmap_magshift2 --fmapmagbrain=${subject_path}/new_fieldmap_mask --echospacing=0.0005 --pedir=-y --mc --pvcorr  --cmethod=both  --debug --region-analysis --region-analysis-atlas=${rois_folder}/HO_R_Cerebral_WM_thr80.nii.gz --region-analysis-atlas-labels=${rois_folder}/HO_R_Cerebral_WM_thr80.txt --region-analysis-atlas=${rois_folder}/HO_L_Cerebral_WM_thr80.nii.gz --region-analysis-atlas-labels=${rois_folder}/HO_L_Cerebral_WM_thr80.txt --region-analysis-atlas=${rois_folder}/MNI_seg_max_prob_masked_RandL.nii.gz --region-analysis-atlas-labels=${rois_folder}/MNI_seg_max_prob_masked_RandL.txt --region-analysis-atlas=${rois_folder}/VascularTerritories_ero.nii.gz --region-analysis-atlas-labels=${rois_folder}/VascularTerritories_ero.txt --region-analysis-save-rois

echo "Step 3 done."


echo "Step 4 analysing results..."

echo "Creating a tigher brain mask for comparing the old and new results..."
fslchfiletype NIFTI ${subject_path}/analysis/oxasl/native_space/perfusion_calib ${subject_path}/perfusion_calib
fslchfiletype NIFTI ${subject_path}/analysis/oxasl_distcorr/native_space/perfusion_calib ${subject_path}/perfusion_calib_distcorr
rm -rf ${subject_path}/processed
mkdir ${subject_path}/processed
bet ${subject_path}/${T1_subject_folder}/analysis/anatMRI/T1/processed/data/T1 ${subject_path}/processed/T1_brain_mask -f 0.6 -o -g -0.3
convert_xfm -omat ${subject_path}/oxford_asl_results/native_space/voxelwise/struct2asl.mat -inverse ${subject_path}/oxford_asl_results/native_space/voxelwise/asl2struct.mat
flirt -applyxfm -in ${subject_path}/processed/T1_brain_mask -ref ${subject_path}/oxford_asl_results/native_space/voxelwise/perfusion -out ${subject_path}/processed/brain_mask_inasl -interp trilinear -paddingsize 1 -init ${subject_path}/oxford_asl_results/native_space/voxelwise/struct2asl.mat
fslmaths ${subject_path}/processed/brain_mask_inasl -ero ${subject_path}/processed/brain_erode_mask_inasl

echo "Producing motion traces..."
mcflirt -in ${subject_path}/asldata -out ${subject_path}/processed/asldata_mc  -plots
fsl_tsplot -i ${subject_path}/processed/asldata_mc.par  -t "rotations" -u 1 --start=1 --finish=3 -a x,y,z -w 640 -h 200 -o ${subject_path}/processed/"${subject}_rots.png"
fsl_tsplot -i ${subject_path}/processed/asldata_mc.par  -t "translations" -u 1 --start=4 --finish=6 -a x,y,z -w 640 -h 200 -o ${subject_path}/processed/"${subject}_trans.png"
echo "Step 4 done."


ehco "Step 5 processing PWI..."
#post analysis
debug_folder=${subject_path}/oxford_asl_results/fsl_*_ox_asl
debug_path=$(echo ${debug_folder})
fslmaths ${debug_path}/diffdata_mean -Tmean ${debug_path}/pwi_cor
applywarp -i ${debug_path}/asldata_orig.nii.gz -r ${debug_path}/nativeref.nii.gz -o ${debug_path}/asldata_mc_not_distco --premat=${debug_path}/asldata.cat --rel --interp=trilinear --paddingsize=1 --super --superlevel=a
asl_file --data=${debug_path}/asldata_mc_not_distco --ntis=1 --iaf=ctb --ibf=tis --diff --mean=${debug_path}/diffdata_mc_not_distco_mean
fslmaths ${debug_path}/diffdata_mc_not_distco_mean -Tmean ${debug_path}/pwi_mc_not_distco
echo "Step 5 done."



echo "${subject} done."







