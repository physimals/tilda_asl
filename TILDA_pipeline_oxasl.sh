#!/bin/bash

#SBATCH --partition=defq

#SBATCH --nodes=8

#SBATCH --ntasks-per-node=1

#SBATCH --mem=4g

#SBATCH --time=10:00:00


module load fsl-img/6.0.5
module load oxasl-img


Usage()
{
	echo "Usage: TILDA_pipeline_oxasl --path <subject_dir_path> --output <output_dir_path> --roi <roi_path>  --id <subject_id>"
	echo " "
	echo " "
	echo "All four options are compulsory"
	echo "--path	: the path of the subject(e.g ../DATA/sub-1327832)"
	echo "--id	: the index of the subject(7 digits no prefix)"
	echo " "
}

if [ $# -eq 0 ] ; then Usage; exit 0; fi

subject_dir=
output_dir=
roi_dir=
subject_id=
T1_folder="BRC_T1"

while [ "$1" != "" ]
do
    case $1 in
        --path )        shift
                                subject_dir=$1
                                ;;
	--output )        shift
                                output_dir=$1
                                ;;
	--roi )        shift
                                roi_dir=$1
                                ;;
	--id )        shift
                                subject_id=$1
                                ;;                        
        -h | --help )           Usage
                                exit
                                ;;
        * )                     Usage
                                exit 1
    esac
    shift
done


echo "Processing sub-${subject_id}"
echo "Step 1 processing fieldmaps..."
mkdir ${subject_dir}/fieldmaps

fslmaths "${subject_dir}/fieldmap_mag1_${subject_id}".nii -add 3.14 "${subject_dir}"/fieldmaps/fieldmap_magshift1.nii.gz
fslmaths "${subject_dir}/fieldmap_mag2_${subject_id}".nii -add 3.14 "${subject_dir}"/fieldmaps/fieldmap_magshift2.nii.gz

fslroi "${subject_dir}"/fieldmaps/fieldmap_magshift2.nii.gz "${subject_dir}"/fieldmaps/fieldmap_magshift2_expand.nii.gz 0 80 0 80 -1 15

bet "${subject_dir}"/fieldmaps/fieldmap_magshift2_expand.nii.gz "${subject_dir}"/fieldmaps/fieldmap_mag_brain.nii.gz -f 0.6

fslmaths "${subject_dir}"/fieldmaps/fieldmap_mag_brain.nii.gz -bin "${subject_dir}"/fieldmaps/fieldmap_mag_brain_mask.nii.gz
fslmaths "${subject_dir}"/fieldmaps/fieldmap_mag_brain_mask.nii.gz -ero "${subject_dir}"/fieldmaps/fieldmap_mask_ero.nii.gz

fslroi "${subject_dir}"/fieldmaps/fieldmap_mask_ero.nii.gz "${subject_dir}"/fieldmaps/fieldmap_mask_final.nii.gz 0 80 0 80 1 13

prelude -a "${subject_dir}"/fieldmaps/fieldmap_magshift1.nii.gz -p "${subject_dir}/fieldmap_ph1_${subject_id}".nii -o "${subject_dir}"/fieldmaps/fieldmap_ph1_unwrapped.nii.gz -m "${subject_dir}"/fieldmaps/fieldmap_mask_final.nii.gz
prelude -a "${subject_dir}"/fieldmaps/fieldmap_magshift2.nii.gz -p "${subject_dir}/fieldmap_ph2_${subject_id}".nii -o "${subject_dir}"/fieldmaps/fieldmap_ph2_unwrapped.nii.gz -m "${subject_dir}"/fieldmaps/fieldmap_mask_final.nii.gz

fslmaths "${subject_dir}"/fieldmaps/fieldmap_ph1_unwrapped.nii.gz -sub "${subject_dir}"/fieldmaps/fieldmap_ph2_unwrapped.nii.gz -mul 1000 -div 5.32 "${subject_dir}"/fieldmaps/fieldmap_rads.nii.gz -odt float

fugue --loadfmap="${subject_dir}"/fieldmaps/fieldmap_rads.nii.gz -s 1 --savefmap="${subject_dir}"/fieldmaps/fieldmap_rads.nii.gz
fugue --loadfmap="${subject_dir}"/fieldmaps/fieldmap_rads.nii.gz --despike --savefmap="${subject_dir}"/fieldmaps/fieldmap_rads.nii.gz
fugue --loadfmap="${subject_dir}"/fieldmaps/fieldmap_rads.nii.gz -m --savefmap="${subject_dir}"/fieldmaps/fieldmap_rads.nii.gz

fslmaths "${subject_dir}"/fieldmaps/fieldmap_rads.nii.gz -mul "${subject_dir}"/fieldmaps/fieldmap_mask_final.nii.gz "${subject_dir}"/fieldmaps/fieldmap_rads.nii.gz

mv "${subject_dir}"/fieldmaps/fieldmap_mask_final.nii.gz "${subject_dir}"/fieldmaps/new_fieldmap_mask.nii.gz
mv "${subject_dir}"/fieldmaps/fieldmap_ph1_unwrapped.nii.gz "${subject_dir}"/fieldmaps/new_fieldmap_ph1_unwrapped.nii.gz
mv "${subject_dir}"/fieldmaps/fieldmap_ph2_unwrapped.nii.gz "${subject_dir}"/fieldmaps/new_fieldmap_ph2_unwrapped.nii.gz
mv "${subject_dir}"/fieldmaps/fieldmap_rads.nii.gz "${subject_dir}"/fieldmaps/new_fieldmap_rads.nii.gz

echo "Step 1 done."

echo "Step 2 processing asl..."
#asl_file --data=${subject_dir}/asldata_${subject_id} --ntis=1 --iaf=ctb --ibf=tis --diff --mean=${subject_dir}/asldiffdata_mean
oxasl -i ${subject_dir}/"asldata_${subject_id}" -o ${subject_dir}/oxasl --iaf=ct --order=rtl --tis 3.6 --casl --bolus 1.8 -c ${subject_dir}/"aslcalib_${subject_id}" --tr 10 -s ${subject_dir}/${T1_folder}/analysis/anatMRI/T1/processed/data/T1_unbiased.nii.gz --wm-seg=${subject_dir}/${T1_folder}/analysis/anatMRI/T1/processed/seg/tissue/sing_chan/T1_pve_WM.nii.gz --gm-seg=${subject_dir}/${T1_folder}/analysis/anatMRI/T1/processed/seg/tissue/sing_chan/T1_pve_GM.nii.gz --csf-seg=${subject_dir}/${T1_folder}/analysis/anatMRI/T1/processed/seg/tissue/sing_chan/T1_pve_CSF.nii.gz --struc-brain=${subject_dir}/${T1_folder}/analysis/anatMRI/T1/processed/data/T1_unbiased_brain.nii.gz --struc2std-warp=${subject_dir}/${T1_folder}/analysis/anatMRI/T1/preproc/reg/T1_2_std_warp_field.nii.gz --te=9 --slicedt=0.03 --fmap=${subject_dir}/fieldmaps/new_fieldmap_rads --fmapmag=${subject_dir}/fieldmaps/fieldmap_magshift2 --fmapmagbrain=${subject_dir}/fieldmaps/new_fieldmap_mask --echospacing=0.0005 --pedir=-y --mc --pvcorr  --cmethod=refregion,voxelwise --tissref=csf,wm --debug --overwrite  --region-analysis --add-mni-atlas=$roi/HO_R_Cerebral_WM_thr80.nii.gz,$roi/HO_L_Cerebral_WM_thr80.nii.gz,$roi/MNI_seg_max_prob_masked_RandL.nii.gz,$roi/VascularTerritories_ero.nii.gz --add-mni-atlas-labels=$roi/HO_R_Cerebral_WM_thr80.txt,$roi/HO_L_Cerebral_WM_thr80.txt,$roi/MNI_seg_max_prob_masked_RandL.txt,$roi/VascularTerritories_ero.txt  --save-native-rois

echo "Step 2 done."

echo "Step 3 producing motion traces..."
mcflirt -in ${subject_dir}/asldata_${subject_id} -out ${subject_dir}/processed/asldata_mc  -plots
fsl_tsplot -i ${subject_dir}/processed/asldata_mc.par  -t "rotations" -u 1 --start=1 --finish=3 -a x,y,z -w 640 -h 200 -o ${subject_dir}/processed/"sub-${subject_id}_rots.png"
fsl_tsplot -i ${subject_dir}/processed/asldata_mc.par  -t "translations" -u 1 --start=4 --finish=6 -a x,y,z -w 640 -h 200 -o ${subject_dir}/processed/"sub-${subject_id}_trans.png"
echo "Step 3 done."


echo "Sub-${subject_id} processing done."
