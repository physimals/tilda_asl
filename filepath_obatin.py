import os
import shutil
import csv
import argparse

parser = argparse.ArgumentParser(description='Input the filename path.')
parser.add_argument('--input', '-in', help='the path of subject ids(one number for one line)', required=True)
#parser.add_argument('--output', '-out', help='output id-path maps', required=True)
args = parser.parse_args()


def obtain_subjects(subject_list_path):
    subjects_path = []
    subjects_ids = []
    base_path = "/gpfs01/share/TILDA/Raw_nii_files_for_MC_pCASL_T1_B0_M0/"

    with open(subject_list_path, "r+", ) as file:
        lines = file.readlines()
        for line in lines:
            subjects_ids.append(line.strip())

    index = 1
    data_map = []
    total_subjects = os.listdir(base_path)
    for id in subjects_ids:
        for subject in total_subjects:
            if id in subject:
                path = base_path+subject
                subjects_path.append(path)
                data_map.append({"id":id, "path":path, "index":index})
                index += 1

    with open("subjects_map.csv", "w+") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["subject_id", "path", "new_index"])
        for i in data_map:
            writer.writerow([i["id"], i["path"], i["index"]])

    with open("subjects_path.txt", "w+") as file:
        for line in subjects_path:
            file.write(line+'\n')



if __name__ == '__main__':
    subject_list_path = args.input
    obtain_subjects(subject_list_path)