#!/bin/bash
#Save subjects in given csv file(produced by file_copy.py) with subject ID to new path and re-index.




base_path=
processed_path="/gpfs01/share/TILDA/Processed_pCASL/Baseline"
name=()
id=()
path=()
index=1
npath=()


while [ "$1" != "" ]
do
    case $1 in
        --path )		shift
								base_path=$1
								;;
														
        -h | --help )           Usage
								exit
								;;
        * )                     Usage
								exit 1
    esac
    shift
done

echo "Copying files to ${base_path}..."

cat subjects_map.csv  | while read line
do
        OLD_IFS="$IFS"
        IFS=","
        arr=($line)
        OLD_IFS="$OLD_IFS"
	
        if [ ${arr[0]} == "subject_id" ]
        then 
                continue
        fi 

     	new_path="$base_path/sub-${index}"
	npath+=($new_path)
        mkdir $new_path
        cp -r "${processed_path}/${arr[0]} dicom/analysis" $new_path/
	cp /${arr[1]}/*_pCASL_Baseline* $new_path/asldata.nii
	cp  /${arr[1]}/*_WIP_pCASL_M0* $new_path/aslcalib.nii
	cp  /${arr[1]}/*__WIP_MPRAGE_T13D_SENSE* $new_path/T1.nii
	cp  /${arr[1]}/*_WIP_B0_map_ASL_CLEAR*_ph_1* $new_path/fieldmap_mag1.nii
	cp  /${arr[1]}/*_WIP_B0_map_ASL_CLEAR*_ph_2* $new_path/fieldmap_mag2.nii
	cp  /${arr[1]}/*_WIP_B0_map_ASL_CLEAR*_ph_3* $new_path/fieldmap_ph1.nii
	cp  /${arr[1]}/*_WIP_B0_map_ASL_CLEAR*_ph_4* $new_path/fieldmap_ph2.nii
	index=$((index+1))
done 


for(( i =0;i<${#npath[@]};i++))
do
echo ${npath[i]};
done;
