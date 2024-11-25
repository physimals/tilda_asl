#!/bin/bash

#SBATCH --partition=imgpascalq

#SBATCH --job-name=myjob
#SBATCH --nodes=1

#SBATCH --ntasks-per-node=1

#SBATCH --mem=8g

#SBATCH --qos=img
#SBATCH --time=50:00:00
#SBATCH --export=NONE

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
work_dir=
subject_dir=
output_dir=
roi_dir=
subject_id=
T1_folder="BRC_T1"
HCP_T1_folder="T1w"
while [ "$1" != "" ]
do
    case $1 in
        --path )        shift
                                work_dir=$1
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
subject_dir=${work_dir}/"sub-${subject_id}"

echo "Processing asl..."


#HCP T1 brain with tob PVE (surface-based pipeline)
#oxasl -i ${subject_dir}/"asldata_${subject_id}.nii" -o ${subject_dir}/oxasl_surf  --iaf=ct --order=rtl --tis 3.6 --casl --bolus 1.8 -c ${subject_dir}/"aslcalib_${subject_id}.nii" --tr 10 -s ${subject_dir}/${HCP_T1_folder}/T1w_acpc_dc_restore.nii.gz --struc-brain=${subject_dir}/${HCP_T1_folder}/T1w_acpc_dc_restore_brain.nii.gz --te=9 --slicedt=0.03 --wm-seg=${subject_dir}/processed/PVEs/surface/tob_pve_WM.nii.gz --gm-seg=${subject_dir}/processed/PVEs/surface/tob_pve_GM.nii.gz  --csf-seg=${subject_dir}/processed/PVEs/surface/tob_pve_FAST_CSF.nii.gz --fmap=${subject_dir}/fieldmaps/new_fieldmap_rads --fmapmag=${subject_dir}/fieldmaps/new_fieldmap_mag --fmapmagbrain=${subject_dir}/fieldmaps/new_fieldmap_mask  --echospacing=0.0005 --pedir=-y --mc --pvcorr  --cmethod=refregion,voxelwise --tissref=csf,wm --debug --overwrite  --region-analysis --add-mni-atlas=${roi_dir}/HO_R_Cerebral_WM_thr80.nii.gz,${roi_dir}/HO_L_Cerebral_WM_thr80.nii.gz,${roi_dir}/MNI_seg_max_prob_masked_RandL.nii.gz,${roi_dir}/VascularTerritories_ero.nii.gz --add-mni-atlas-labels=${roi_dir}/HO_R_Cerebral_WM_thr80.txt,${roi_dir}/HO_L_Cerebral_WM_thr80.txt,${roi_dir}/MNI_seg_max_prob_masked_RandL.txt,${roi_dir}/VascularTerritories_ero.txt --save-native-rois --output-mni 

#HCP T1 brain and FAST PVE (volumetric pipeline)(default)
#oxasl -i ${subject_dir}/"asldata_${subject_id}.nii" -o ${subject_dir}/oxasl_vol  --iaf=ct --order=rtl --tis 3.6 --casl --bolus 1.8 -c ${subject_dir}/"aslcalib_${subject_id}.nii" --tr 10 -s ${subject_dir}/${HCP_T1_folder}/T1w_acpc_dc_restore.nii.gz  --struc-brain=${subject_dir}/${HCP_T1_folder}/T1w_acpc_dc_restore_brain.nii.gz --te=9 --slicedt=0.03 --fmap=${subject_dir}/fieldmaps/new_fieldmap_rads --fmapmag=${subject_dir}/fieldmaps/new_fieldmap_mag --fmapmagbrain=${subject_dir}/fieldmaps/new_fieldmap_mask  --echospacing=0.0005 --pedir=-y --mc --pvcorr  --cmethod=refregion,voxelwise --tissref=csf,wm --debug --overwrite  --region-analysis --add-mni-atlas=${roi_dir}/HO_R_Cerebral_WM_thr80.nii.gz,${roi_dir}/HO_L_Cerebral_WM_thr80.nii.gz,${roi_dir}/MNI_seg_max_prob_masked_RandL.nii.gz,${roi_dir}/VascularTerritories_ero.nii.gz --add-mni-atlas-labels=${roi_dir}/HO_R_Cerebral_WM_thr80.txt,${roi_dir}/HO_L_Cerebral_WM_thr80.txt,${roi_dir}/MNI_seg_max_prob_masked_RandL.txt,${roi_dir}/VascularTerritories_ero.txt   --save-native-rois --output-mni 

#volumetric method with 50% gm pv
oxasl_region_analysis --oxasl-dir ${subject_dir}/oxasl_vol --perfusion ${subject_dir}/oxasl_vol/output/native/calib_voxelwise/perfusion.nii.gz --perfusion-var ${subject_dir}/oxasl_vol/output/native/calib_voxelwise/perfusion_var.nii.gz --output  ${subject_dir}/oxasl_vol_50gm_pv --pure-gm-thresh=0.5 --add-mni-atlas=${roi_dir}/HO_R_Cerebral_WM_thr80.nii.gz,${roi_dir}/HO_L_Cerebral_WM_thr80.nii.gz,${roi_dir}/MNI_seg_max_prob_masked_RandL.nii.gz,${roi_dir}/VascularTerritories_ero.nii.gz --add-mni-atlas-labels=${roi_dir}/HO_R_Cerebral_WM_thr80.txt,${roi_dir}/HO_L_Cerebral_WM_thr80.txt,${roi_dir}/MNI_seg_max_prob_masked_RandL.txt,${roi_dir}/VascularTerritories_ero.txt


echo "Sub-${subject_id} processing done."

