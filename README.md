# tilda_asl
Analysis pipeline code for ASL data from The Irish Longitudinal stuDy on Ageing



# Usage

## Prepare data

1.  keep interested subjects' ids in a text file, for example, subjects_ids.txt (one id for one line), and then run filepath_obtain.py (it will output the absolute paths of subjects)
```
python filepath_obtain.py -in subjects_ids.txt
```

2. copy interested subjects to local space(you will specify the output folder)
```
bash file_copy.sh --path /gpfs01/share/TILDA/your_local_folder
```

3. processing part is similar to other scripts but utilizes *sbatch* to run on HPC, and you only need to specify the output folder like in step 2.
```
sbatch TILDA_processing.sh --path  /gpfs01/share/TILDA/your_local_folder
```

P.S. The dataset path is hard-coded in above scripts.

## Process


1. Oxford_asl

To use oxford_asl pipleine, the script named `TILDA_pipeline.sh` is under `/gpfs01/share/TILDA/test_pipeline/scripts` on HPC, the output path can be specified using --path. 

```
sbatch /gpfs01/share/TILDA/test_pipeline/scripts/TILDA_pipeline.sh --path /gpfs01/share/TILDA/test_pipeline/TILDA_analysis 
```
1. Oxasl

To use oxasl pipleine, the script named `TILDA_pipeline_oxasl.sh` is under `/gpfs01/share/TILDA/test_pipeline/scripts` on HPC, the output path can be specified using --path.
```
sbatch /gpfs01/share/TILDA/test_pipeline/scripts/TILDA_pipeline_oxasl.sh --path /gpfs01/share/TILDA/test_pipeline/TILDA_analysis/oxasl_results
```

## Results

Some results(of 10 subjects) are produced for checking. For oxford_asl, the output is under `/gpfs01/share/TILDA/test_pipeline/TILDA_analysis` on HPC, and for oxasl, the output is under `/gpfs01/share/TILDA/test_pipeline/TILDA_analysis/oxford_asl_display` on HPC.



# TILDA Description
### Jian Hu 21.6.2022


## Data Description

Total: 484

Unusable: 5

Duplicate: 1

Usable: 478

Raw data folder: /gpfs01/share/TILDA/Raw_nii_files_for_MC_pCASL_T1_B0_M0

Current data folder:/gpfs01/share/TILDA/test_pipeline/DATA

Data mapping relationships: /gpfs01/share/TILDA/test_pipeline/DATA/subjects_map.csv

Subjects with incomplete data: 1316180,  1271915, 1289072, 1335474, 1268350 (unusable)

Subjects with mutliple data:1326157, 1327419, 1322221, 1285670, 1309595, 1331415, 1330490 

(some images are acquired mutliple times due to some reason(motion, artifact...), the latest one of each sequence is kept)

Duplicate subject: 1295763

## Processed results & Folder structure

Raw data:
T1_${SUBJECT_ID}.nii - T1 image
fieldmap_*_${SUBJECT_ID}.nii - field maps
aslcalib_${SUBJECT_ID}.nii - calibration image/ M0
asldata_${SUBJECT_ID}.nii - perfusion image/pCASL

T1 processing (BRC structural pipeline https://github.com/SPMIC-UoN/BRC_Pipeline):
[BRC_T1] - structural processed folder

Fieldmap processing (FSL)
new_fieldmap_rads.nii.gz - fieldmap in radians

Perfusion processing (oxasl https://github.com/physimals/oxasl):
[oxasl] - oxasl processed folder





