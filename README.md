# tilda_asl
Analysis pipeline code for ASL data from The Irish Longitudinal study on Ageing



# Usage

1. files_copy.sh

Copy raw data to work space. The integrity of each subject needs to be checked! Subjects with absent or duplicate data need to be fixed manually.

Example usage: 
``` 
bash files_copy.sh --input /gpfs01/share/TILDA/Raw_nii_files_for_MC_pCASL_T1_B0_M0 --output  /gpfs01/share/TILDA/test_pipeline/DATA
```

2. TILDA_pipeline_t1.sh

Run BRC structural pipeline for all subjects under specified folder.

Example usage: 
``` 
bash TILDA_pipeline_t1.sh --path /gpfs01/share/TILDA/test_pipeline/DATA --output /gpfs01/share/TILDA/test_pipeline/DATA
```

3. TILDA_pipeline_oxasl.sh 

Run oxasl for a single subject.

Example usage: 
``` 
bash TILDA_oxasl_batch.sh --path /gpfs01/share/TILDA/test_pipeline/DATA --output /gpfs01/share/TILDA/test_pipeline/DATA --roi /gpfs01/share/TILDA/test_pipeline/ukb_rois  -id 1327832
```

4. TILDA_oxasl_batch.sh

Run oxasl for all subjects under specified folder.

Example usage: 
``` 
bash TILDA_oxasl_batch.sh --path /gpfs01/share/TILDA/test_pipeline/DATA --output /gpfs01/share/TILDA/test_pipeline/DATA --roi /gpfs01/share/TILDA/test_pipeline/ukb_rois
```



# Processed TILDA Description


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

### Raw data:

T1_${SUBJECT_ID}.nii - T1 image

fieldmap_*_${SUBJECT_ID}.nii - field maps

aslcalib_${SUBJECT_ID}.nii - calibration image/ M0

asldata_${SUBJECT_ID}.nii - perfusion image/pCASL

### T1 processing (BRC structural pipeline https://github.com/SPMIC-UoN/BRC_Pipeline):

[BRC_T1] - structural processed folder

### Fieldmap processing (FSL):

new_fieldmap_rads.nii.gz - fieldmap in radians

### Perfusion processing (oxasl https://github.com/physimals/oxasl):

[oxasl] - oxasl processed folder





