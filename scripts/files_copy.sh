#!/bin/bash
# Copy raw data to workspace.


Usage()
{
  echo "Usage:files_copy --input <input_dir> --output <output_dir>"
  echo " "
  echo " "
  echo "The raw data path for TILDA is /gpfs01/share/TILDA/Raw_nii_files_for_MC_pCASL_T1_B0_M0"
  echo " -h | --help             help"
  echo " "
  echo " "
}

input_dir=
output_dir=

while [ "$1" != "" ]
do
    case $1 in
        --input )		shift
								input_dir=$1
								;;
        --output )		shift
								output_dir=$1
								;;
														
        -h | --help )           Usage
								exit
								;;
        * )                     Usage
								exit 1
    esac
    shift
done

echo "Copying files from ${input_dir} to ${output_dir}..."

mkdir $output_dir

# Copy and rename all files
for SUBJDIR in $input_dir/sub-*; do
	id=${SUBJDIR:0-7}
	sub_id="sub-$id"
	input_path="${input_dir}/${sub_id}"
     	output_path="${output_dir}/${sub_id}"

	mkdir $output_path

	cp  ${input_path}/*_pCASL_Baseline* $output_path/asldata_${sub_id}.nii
	cp  ${input_path}/*_WIP_pCASL_M0* $output_path/aslcalib_${sub_id}.nii
	cp  ${input_path}/*__WIP_MPRAGE_T13D_SENSE* $output_path/T1_${sub_id}.nii
	cp  ${input_path}/*_WIP_B0_map_ASL_CLEAR*_ph_1* $output_path/fieldmap_mag1_${sub_id}.nii
	cp  ${input_path}/*_WIP_B0_map_ASL_CLEAR*_ph_2* $output_path/fieldmap_mag2_${sub_id}.nii
	cp  ${input_path}/*_WIP_B0_map_ASL_CLEAR*_ph_3* $output_path/fieldmap_ph1_${sub_id}.nii
	cp  ${input_path}/*_WIP_B0_map_ASL_CLEAR*_ph_4* $output_path/fieldmap_ph2_${sub_id}.nii
done



