#!/bin/bash

module load fsl-img/6.0.5
module load oxasl-img

Usage()
{
	echo "Usage: TILDA_oxasl_batch --path <data_dir> --output <output_dir> --roi <roi_dir>"
	echo "To run oxasl in batch for all subjects in specified folder."
	echo "All three options are compulsory."
}

if [ $# -eq 0 ] ; then Usage; exit 0; fi
subject_dir=
output_dir=
roi_dir=
subject_folder="oxasl"

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
        -h | --help )           Usage
                                exit
                                ;;
        * )                     Usage
                                exit 1
    esac
    shift
done

for SUBJDIR in $subject_dir/sub-*; do
	id=${SUBJDIR:0-7}

	#sbatch TILDA_fieldmap_process.sh --path ${subject_dir} --output "${output_dir}/sub-${id}" --roi ${roi_dir} --id $id

	sbatch TILDA_pipeline_oxasl.sh --path /gpfs01/share/TILDA/test_pipeline/DATA/sub-$id --output /gpfs01/share/TILDA/test_pipeline/DATA/sub-$id --roi /gpfs01/share/TILDA/test_pipeline/ukb_rois --id $id
done

echo "All jobs created."

