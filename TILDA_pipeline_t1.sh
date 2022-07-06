#!/bin/bash
# Run BRC structural pipeline for all subjects under specified folder

 
module load brc-pipelines-img

Usage()
{
	echo "Usage: TILDA_pipeline_t1 --path <data_dir> --output <output_dir>"
	echo "To run BRC structural pipeline for all subjects in specified folder"
	echo " "
}

if [ $# -eq 0 ] ; then Usage; exit 0; fi
subject_dir=
output_dir=


while [ "$1" != "" ]
do
    case $1 in
        --path )        shift
                                subject_dir=$1
                                ;;
	--output )        shift
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

# Name of BRC structural pipeline folder
subject_folder="BRC_T1"

# Run BRC  structural pipeline for all subjects under $subject_dir
for SUBJDIR in $subject_dir/sub-*; do
	id=${SUBJDIR:0-7}
	input_path="${subject_dir}/${sub_id}"
     	output_path="${output_dir}/${sub_id}"
	struc_preproc.sh --input ${input_path}/T1_${id}.nii --path ${output_path} --subject ${subject_folder}  --subseg --freesurfer
done

echo "${subject} BRC structural pipeline done."






