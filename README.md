# tilda_asl
Analysis pipeline code for ASL data from The Irish Longitudinal stuDy on Ageing



# Usage

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