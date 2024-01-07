#!/bin/bash
#SBATCH --time=10:00:00

#SBATCH --job-name=myjob 

#####SBATCH --coprocessor=cuda

#SBATCH --partition=imgvoltaq 

#SBATCH --nodes=1 

#SBATCH --ntasks-per-node=1 

#SBATCH --mem=8g

#SBATCH --qos=img 

#SBATCH -e slurm-%j.err 

#SBATCH --export=NONE 


module load workbench-img
module load freesurfer-img
module load fsl-img


input_dir=/gpfs01/share/TILDA/test_pipeline/DATA
output_dir=/gpfs01/share/TILDA/test_pipeline/DATA


i=0
# Copy and rename all files
for SUBJDIR in $input_dir/sub-*; do
    id=${SUBJDIR:0-7}
    sub_id="sub-$id"
    input_path="${input_dir}/${sub_id}"
    output_path="${output_dir}/${sub_id}"
    echo ${sub_id}

    
    ############################using HCP pipeline to project ASL onto cortical surface (standard space + 32k)(currently using)###################################
    mkdir -p ${input_path}/processed/MNI/32k_fs_space/no_weighted/surf_pvc
    mkdir -p ${input_path}/processed/MNI/32k_fs_space/no_weighted/surf_nonpvc
    mkdir -p ${input_path}/processed/MNI/32k_fs_space/weighted/surf_pvc
    mkdir -p ${input_path}/processed/MNI/32k_fs_space/weighted/surf_nonpvc


    wb_command -volume-math '1 / var'  ${input_path}/processed/MNI/32k_fs_space/weighted/surf_nonpvc/perfusion_precision.nii.gz -var var ${input_path}/oxasl_surf/output/std/calib_voxelwise/perfusion_var.nii.gz
    wb_command -volume-math '1 / var'  ${input_path}/processed/MNI/32k_fs_space/weighted/surf_pvc/perfusion_precision.nii.gz -var var ${input_path}/oxasl_surf/output_pvcorr/std/calib_voxelwise/perfusion_var.nii.gz

    wb_command -volume-math '1 / var'  ${input_path}/processed/MNI/32k_fs_space/no_weighted/surf_nonpvc/perfusion_precision.nii.gz -var var ${input_path}/oxasl_surf/output/std/calib_voxelwise/perfusion_var.nii.gz
    wb_command -volume-math '1 / var'  ${input_path}/processed/MNI/32k_fs_space/no_weighted/surf_pvc/perfusion_precision.nii.gz -var var ${input_path}/oxasl_surf/output_pvcorr/std/calib_voxelwise/perfusion_var.nii.gz

    for Hemisphere in L R ; do

        #Precision-weighted ribbon-constrained volume to surface mapping
        #of the ASL-derived variable
       
        #weighted nonpvc
        fsl_sub -T 10000 wb_command -volume-to-surface-mapping \
                                ${input_path}/oxasl_surf/output/std/calib_voxelwise/perfusion.nii.gz \
                                ${input_path}/MNINonLinear/fsaverage_LR32k/"$sub_id"."$Hemisphere".midthickness.32k_fs_LR.surf.gii \
                                ${input_path}/processed/MNI/32k_fs_space/weighted/surf_nonpvc/"$sub_id"."$Hemisphere".midthickness.32k_fs_LR.func.gii \
                                -ribbon-constrained \
                                ${input_path}/MNINonLinear/fsaverage_LR32k/"$sub_id"."$Hemisphere".white.32k_fs_LR.surf.gii \
                                ${input_path}/MNINonLinear/fsaverage_LR32k/"$sub_id"."$Hemisphere".pial.32k_fs_LR.surf.gii \
                                -volume-roi \
                                ${input_path}/processed/MNI/32k_fs_space/weighted/surf_nonpvc/perfusion_precision.nii.gz \
                                -weighted \
                                -bad-vertices-out \
                                ${input_path}/processed/MNI/32k_fs_space/weighted/surf_nonpvc/"$sub_id"."$Hemisphere".badvert_ribbonroi.32k_fs_LR.func.gii

        #weighted pvc
       fsl_sub -T 10000 wb_command -volume-to-surface-mapping \
                                ${input_path}/oxasl_surf/output_pvcorr/std/calib_voxelwise/perfusion.nii.gz \
                                ${input_path}/MNINonLinear/fsaverage_LR32k/"$sub_id"."$Hemisphere".midthickness.32k_fs_LR.surf.gii \
                                ${input_path}/processed/MNI/32k_fs_space/weighted/surf_pvc/"$sub_id"."$Hemisphere".midthickness.32k_fs_LR.func.gii \
                                -ribbon-constrained \
                                ${input_path}/MNINonLinear/fsaverage_LR32k/"$sub_id"."$Hemisphere".white.32k_fs_LR.surf.gii \
                                ${input_path}/MNINonLinear/fsaverage_LR32k/"$sub_id"."$Hemisphere".pial.32k_fs_LR.surf.gii \
                                -volume-roi \
                                ${input_path}/processed/MNI/32k_fs_space/weighted/surf_pvc/perfusion_precision.nii.gz \
                                -weighted \
                                -bad-vertices-out \
                                ${input_path}/processed/MNI/32k_fs_space/weighted/surf_pvc/"$sub_id"."$Hemisphere".badvert_ribbonroi.32k_fs_LR.func.gii
     
        #no_weighted nonpvc
        fsl_sub -T 10000 wb_command -volume-to-surface-mapping \
                                ${input_path}/oxasl_surf/output/std/calib_voxelwise/perfusion.nii.gz \
                                ${input_path}/MNINonLinear/fsaverage_LR32k/"$sub_id"."$Hemisphere".midthickness.32k_fs_LR.surf.gii \
                                ${input_path}/processed/MNI/32k_fs_space/no_weighted/surf_nonpvc/"$sub_id"."$Hemisphere".midthickness.32k_fs_LR.func.gii \
                                -ribbon-constrained \
                                ${input_path}/MNINonLinear/fsaverage_LR32k/"$sub_id"."$Hemisphere".white.32k_fs_LR.surf.gii \
                                ${input_path}/MNINonLinear/fsaverage_LR32k/"$sub_id"."$Hemisphere".pial.32k_fs_LR.surf.gii \
                                -bad-vertices-out \
                                ${input_path}/processed/MNI/32k_fs_space/no_weighted/surf_nonpvc/"$sub_id"."$Hemisphere".badvert_ribbonroi.32k_fs_LR.func.gii

        #no_weighted pvc
       fsl_sub -T 10000 wb_command -volume-to-surface-mapping \
                                ${input_path}/oxasl_surf/output_pvcorr/std/calib_voxelwise/perfusion.nii.gz \
                                ${input_path}/MNINonLinear/fsaverage_LR32k/"$sub_id"."$Hemisphere".midthickness.32k_fs_LR.surf.gii \
                                ${input_path}/processed/MNI/32k_fs_space/no_weighted/surf_pvc/"$sub_id"."$Hemisphere".midthickness.32k_fs_LR.func.gii \
                                -ribbon-constrained \
                                ${input_path}/MNINonLinear/fsaverage_LR32k/"$sub_id"."$Hemisphere".white.32k_fs_LR.surf.gii \
                                ${input_path}/MNINonLinear/fsaverage_LR32k/"$sub_id"."$Hemisphere".pial.32k_fs_LR.surf.gii \
                                -bad-vertices-out \
                                ${input_path}/processed/MNI/32k_fs_space/no_weighted/surf_pvc/"$sub_id"."$Hemisphere".badvert_ribbonroi.32k_fs_LR.func.gii



    done


    #####Dex####################(standard space + 32k)( currently using)
    ###############################################
    ############weighted
    mkdir -p  ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/weighted/Dex/pvc/left
    mkdir -p  ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/weighted/Dex/pvc/right
    mkdir -p  ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/weighted/Dex/nonpvc/left
    mkdir -p  ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/weighted/Dex/nonpvc/right



    fsl_sub -T 10000 python /gpfs01/share/TILDA/test_pipeline/test/tilda/surf_roi_analysis.py --metric  ${input_path}/processed/MNI/32k_fs_space/weighted/surf_pvc/"$sub_id".L.midthickness.32k_fs_LR.func.gii --atlas ${input_path}/MNINonLinear/fsaverage_LR32k/${sub_id}.L.aparc.32k_fs_LR.label.gii --output ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/weighted/Dex/pvc/left --type ${sub_id}_pvc_perfusion_dex --hemi left
    fsl_sub -T 10000 python /gpfs01/share/TILDA/test_pipeline/test/tilda/surf_roi_analysis.py --metric  ${input_path}/processed/MNI/32k_fs_space/weighted/surf_pvc/"$sub_id".R.midthickness.32k_fs_LR.func.gii --atlas ${input_path}/MNINonLinear/fsaverage_LR32k/${sub_id}.R.aparc.32k_fs_LR.label.gii --output ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/weighted/Dex/pvc/right --type ${sub_id}_pvc_perfusion_dex --hemi right

    fsl_sub -T 10000 python /gpfs01/share/TILDA/test_pipeline/test/tilda/surf_roi_analysis.py --metric  ${input_path}/processed/MNI/32k_fs_space/weighted/surf_nonpvc/"$sub_id".L.midthickness.32k_fs_LR.func.gii --atlas ${input_path}/MNINonLinear/fsaverage_LR32k/${sub_id}.L.aparc.32k_fs_LR.label.gii --output ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/weighted/Dex/nonpvc/left --type ${sub_id}_nonpvc_perfusion_dex --hemi left
    fsl_sub -T 10000 python /gpfs01/share/TILDA/test_pipeline/test/tilda/surf_roi_analysis.py --metric  ${input_path}/processed/MNI/32k_fs_space/weighted/surf_nonpvc/"$sub_id".R.midthickness.32k_fs_LR.func.gii --atlas ${input_path}/MNINonLinear/fsaverage_LR32k/${sub_id}.R.aparc.32k_fs_LR.label.gii --output ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/weighted/Dex/nonpvc/right --type ${sub_id}_nonpvc_perfusion_dex --hemi right


    ############unweighted
    mkdir -p  ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/no_weighted/Dex/pvc/left
    mkdir -p  ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/no_weighted/Dex/pvc/right
    mkdir -p  ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/no_weighted/Dex/nonpvc/left
    mkdir -p  ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/no_weighted/Dex/nonpvc/right



    fsl_sub -T 10000 python /gpfs01/share/TILDA/test_pipeline/test/tilda/surf_roi_analysis.py --metric  ${input_path}/processed/MNI/32k_fs_space/no_weighted/surf_pvc/"$sub_id".L.midthickness.32k_fs_LR.func.gii --atlas ${input_path}/MNINonLinear/fsaverage_LR32k/${sub_id}.L.aparc.32k_fs_LR.label.gii --output ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/no_weighted/Dex/pvc/left --type ${sub_id}_pvc_perfusion_dex --hemi left
    fsl_sub -T 10000 python /gpfs01/share/TILDA/test_pipeline/test/tilda/surf_roi_analysis.py --metric  ${input_path}/processed/MNI/32k_fs_space/no_weighted/surf_pvc/"$sub_id".R.midthickness.32k_fs_LR.func.gii --atlas ${input_path}/MNINonLinear/fsaverage_LR32k/${sub_id}.R.aparc.32k_fs_LR.label.gii --output ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/no_weighted/Dex/pvc/right --type ${sub_id}_pvc_perfusion_dex --hemi right

    fsl_sub -T 10000 python /gpfs01/share/TILDA/test_pipeline/test/tilda/surf_roi_analysis.py --metric  ${input_path}/processed/MNI/32k_fs_space/no_weighted/surf_nonpvc/"$sub_id".L.midthickness.32k_fs_LR.func.gii --atlas ${input_path}/MNINonLinear/fsaverage_LR32k/${sub_id}.L.aparc.32k_fs_LR.label.gii --output ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/no_weighted/Dex/nonpvc/left --type ${sub_id}_nonpvc_perfusion_dex --hemi left
    fsl_sub -T 10000 python /gpfs01/share/TILDA/test_pipeline/test/tilda/surf_roi_analysis.py --metric  ${input_path}/processed/MNI/32k_fs_space/no_weighted/surf_nonpvc/"$sub_id".R.midthickness.32k_fs_LR.func.gii --atlas ${input_path}/MNINonLinear/fsaverage_LR32k/${sub_id}.R.aparc.32k_fs_LR.label.gii --output ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/no_weighted/Dex/nonpvc/right --type ${sub_id}_nonpvc_perfusion_dex --hemi right
    ############


    #####DK####################(standard space+native space)
    ###############################################
    ############weighted
    mkdir -p  ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/weighted/DK/pvc/left
    mkdir -p  ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/weighted/DK/pvc/right
    mkdir -p  ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/weighted/DK/nonpvc/left
    mkdir -p  ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/weighted/DK/nonpvc/right



    fsl_sub -T 10000 python /gpfs01/share/TILDA/test_pipeline/test/tilda/surf_roi_analysis.py --metric  ${input_path}/processed/MNI/32k_fs_space/weighted/surf_pvc/"$sub_id".L.midthickness.32k_fs_LR.func.gii --atlas ${input_path}/MNINonLinear/fsaverage_LR32k/${sub_id}.L.aparc.a2009s.32k_fs_LR.label.gii --output ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/weighted/DK/pvc/left --type ${sub_id}_pvc_perfusion_dk --hemi left
    fsl_sub -T 10000 python /gpfs01/share/TILDA/test_pipeline/test/tilda/surf_roi_analysis.py --metric  ${input_path}/processed/MNI/32k_fs_space/weighted/surf_pvc/"$sub_id".R.midthickness.32k_fs_LR.func.gii --atlas ${input_path}/MNINonLinear/fsaverage_LR32k/${sub_id}.R.aparc.a2009s.32k_fs_LR.label.gii --output ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/weighted/DK/pvc/right --type ${sub_id}_pvc_perfusion_dk --hemi right

    fsl_sub -T 10000 python /gpfs01/share/TILDA/test_pipeline/test/tilda/surf_roi_analysis.py --metric  ${input_path}/processed/MNI/32k_fs_space/weighted/surf_nonpvc/"$sub_id".L.midthickness.32k_fs_LR.func.gii --atlas ${input_path}/MNINonLinear/fsaverage_LR32k/${sub_id}.L.aparc.a2009s.32k_fs_LR.label.gii --output ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/weighted/DK/nonpvc/left --type ${sub_id}_nonpvc_perfusion_dk --hemi left
    fsl_sub -T 10000 python /gpfs01/share/TILDA/test_pipeline/test/tilda/surf_roi_analysis.py --metric  ${input_path}/processed/MNI/32k_fs_space/weighted/surf_nonpvc/"$sub_id".R.midthickness.32k_fs_LR.func.gii --atlas ${input_path}/MNINonLinear/fsaverage_LR32k/${sub_id}.R.aparc.a2009s.32k_fs_LR.label.gii --output ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/weighted/DK/nonpvc/right --type ${sub_id}_nonpvc_perfusion_dk --hemi right


    ############unweighted
    mkdir -p  ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/no_weighted/DK/pvc/left
    mkdir -p  ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/no_weighted/DK/pvc/right
    mkdir -p  ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/no_weighted/DK/nonpvc/left
    mkdir -p  ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/no_weighted/DK/nonpvc/right



    fsl_sub -T 10000 python /gpfs01/share/TILDA/test_pipeline/test/tilda/surf_roi_analysis.py --metric  ${input_path}/processed/MNI/32k_fs_space/no_weighted/surf_pvc/"$sub_id".L.midthickness.32k_fs_LR.func.gii --atlas ${input_path}/MNINonLinear/fsaverage_LR32k/${sub_id}.L.aparc.a2009s.32k_fs_LR.label.gii --output ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/no_weighted/DK/pvc/left --type ${sub_id}_pvc_perfusion_dk --hemi left
    fsl_sub -T 10000 python /gpfs01/share/TILDA/test_pipeline/test/tilda/surf_roi_analysis.py --metric  ${input_path}/processed/MNI/32k_fs_space/no_weighted/surf_pvc/"$sub_id".R.midthickness.32k_fs_LR.func.gii --atlas ${input_path}/MNINonLinear/fsaverage_LR32k/${sub_id}.R.aparc.a2009s.32k_fs_LR.label.gii --output ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/no_weighted/DK/pvc/right --type ${sub_id}_pvc_perfusion_dk --hemi right

    fsl_sub -T 10000 python /gpfs01/share/TILDA/test_pipeline/test/tilda/surf_roi_analysis.py --metric  ${input_path}/processed/MNI/32k_fs_space/no_weighted/surf_nonpvc/"$sub_id".L.midthickness.32k_fs_LR.func.gii --atlas ${input_path}/MNINonLinear/fsaverage_LR32k/${sub_id}.L.aparc.a2009s.32k_fs_LR.label.gii --output ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/no_weighted/DK/nonpvc/left --type ${sub_id}_nonpvc_perfusion_dk --hemi left
    fsl_sub -T 10000 python /gpfs01/share/TILDA/test_pipeline/test/tilda/surf_roi_analysis.py --metric  ${input_path}/processed/MNI/32k_fs_space/no_weighted/surf_nonpvc/"$sub_id".R.midthickness.32k_fs_LR.func.gii --atlas ${input_path}/MNINonLinear/fsaverage_LR32k/${sub_id}.R.aparc.a2009s.32k_fs_LR.label.gii --output ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/no_weighted/DK/nonpvc/right --type ${sub_id}_nonpvc_perfusion_dk --hemi right
    ############(standard space + 32k)( currently using)





    
    
    




    ######################download surface-based analysis (currently using) ###################################################
    ##################weighted##################################
    mkdir -p /gpfs01/share/TILDA/test_pipeline/test/region_analysis/MNI/32k_fs_space/weighted/DK/nonpvc
    cp ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/weighted/DK/nonpvc/left/sub-*.csv /gpfs01/share/TILDA/test_pipeline/test/region_analysis/MNI/32k_fs_space/weighted/DK/nonpvc/
    cp ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/weighted/DK/nonpvc/right/sub-*.csv /gpfs01/share/TILDA/test_pipeline/test/region_analysis/MNI/32k_fs_space/weighted/DK/nonpvc/

    mkdir -p /gpfs01/share/TILDA/test_pipeline/test/region_analysis/MNI/32k_fs_space/weighted/DK/pvc
    cp ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/weighted/DK/pvc/left/sub-*.csv /gpfs01/share/TILDA/test_pipeline/test/region_analysis/MNI/32k_fs_space/weighted/DK/pvc/
    cp ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/weighted/DK/pvc/right/sub-*.csv /gpfs01/share/TILDA/test_pipeline/test/region_analysis/MNI/32k_fs_space/weighted/DK/pvc/


    mkdir -p /gpfs01/share/TILDA/test_pipeline/test/region_analysis/MNI/32k_fs_space/weighted/Dex/nonpvc
    cp ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/weighted/Dex/nonpvc/left/sub-*.csv /gpfs01/share/TILDA/test_pipeline/test/region_analysis/MNI/32k_fs_space/weighted/Dex/nonpvc/
    cp ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/weighted/Dex/nonpvc/right/sub-*.csv /gpfs01/share/TILDA/test_pipeline/test/region_analysis/MNI/32k_fs_space/weighted/Dex/nonpvc/

    mkdir -p /gpfs01/share/TILDA/test_pipeline/test/region_analysis/MNI/32k_fs_space/weighted/Dex/pvc
    cp ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/weighted/Dex/pvc/left/sub-*.csv /gpfs01/share/TILDA/test_pipeline/test/region_analysis/MNI/32k_fs_space/weighted/Dex/pvc/
    cp ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/weighted/Dex/pvc/right/sub-*.csv /gpfs01/share/TILDA/test_pipeline/test/region_analysis/MNI/32k_fs_space/weighted/Dex/pvc/

    #########################no_weighted################################
    mkdir -p /gpfs01/share/TILDA/test_pipeline/test/region_analysis/MNI/32k_fs_space/no_weighted/DK/nonpvc
    cp ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/no_weighted/DK/nonpvc/left/sub-*.csv /gpfs01/share/TILDA/test_pipeline/test/region_analysis/MNI/32k_fs_space/no_weighted/DK/nonpvc/
    cp ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/no_weighted/DK/nonpvc/right/sub-*.csv /gpfs01/share/TILDA/test_pipeline/test/region_analysis/MNI/32k_fs_space/no_weighted/DK/nonpvc/

    mkdir -p /gpfs01/share/TILDA/test_pipeline/test/region_analysis/MNI/32k_fs_space/no_weighted/DK/pvc
    cp ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/no_weighted/DK/pvc/left/sub-*.csv /gpfs01/share/TILDA/test_pipeline/test/region_analysis/MNI/32k_fs_space/no_weighted/DK/pvc/
    cp ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/no_weighted/DK/pvc/right/sub-*.csv /gpfs01/share/TILDA/test_pipeline/test/region_analysis/MNI/32k_fs_space/no_weighted/DK/pvc/


    mkdir -p /gpfs01/share/TILDA/test_pipeline/test/region_analysis/MNI/32k_fs_space/no_weighted/Dex/nonpvc
    cp ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/no_weighted/Dex/nonpvc/left/sub-*.csv /gpfs01/share/TILDA/test_pipeline/test/region_analysis/MNI/32k_fs_space/no_weighted/Dex/nonpvc/
    cp ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/no_weighted/Dex/nonpvc/right/sub-*.csv /gpfs01/share/TILDA/test_pipeline/test/region_analysis/MNI/32k_fs_space/no_weighted/Dex/nonpvc/

    mkdir -p /gpfs01/share/TILDA/test_pipeline/test/region_analysis/MNI/32k_fs_space/no_weighted/Dex/pvc
    cp ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/no_weighted/Dex/pvc/left/sub-*.csv /gpfs01/share/TILDA/test_pipeline/test/region_analysis/MNI/32k_fs_space/no_weighted/Dex/pvc/
    cp ${SUBJDIR}/processed/MNI/32k_fs_space/region_analysis/no_weighted/Dex/pvc/right/sub-*.csv /gpfs01/share/TILDA/test_pipeline/test/region_analysis/MNI/32k_fs_space/no_weighted/Dex/pvc/


    ############################################################




    ###############################download volumetric region analysis######################################
    cp ${input_path}/oxasl_vol/output/native/calib_voxelwise/roi_stats.csv  /gpfs01/share/TILDA/test_pipeline/test/region_analysis/nonpvc/roi_stats_${id}.csv
    cp ${input_path}/oxasl_vol/output_pvcorr/native/calib_voxelwise/roi_stats_gm.csv  /gpfs01/share/TILDA/test_pipeline/test/region_analysis/pvc/roi_stats_gm_${id}.csv
    cp ${input_path}/oxasl_vol/output_pvcorr/native/calib_voxelwise/roi_stats_wm.csv  /gpfs01/share/TILDA/test_pipeline/test/region_analysis/pvc/roi_stats_wm_${id}.csv
    ###############################END download volumetric region analysis######################################




done

echo 'Done.'



