import os
import csv
import xlrd

baseline_list = []
with open("baseline.csv", "r", encoding='ISO-8859-1') as csvfile:
    reader = csv.reader(csvfile)
    next(reader)
    for row in reader:
        #print(row)
        baseline_list.append(row[0][:7])
        #print(row)

exclusions = []
#excel = xlrd.open_workbook("TILDA_ASL_Exclusions_1_10_21.xls")
excel = xlrd.open_workbook("CaoiASLmapscreening_SK.xlsx", "r")
sheet = excel.sheet_by_index(0)
for s in range(1, sheet.nrows):
    exclusions.append(str(sheet.cell(s, 0).value)[:7])



unique_baseline = []
unique_excl = []
common_subjects = []
l1=list(set(baseline_list))
l2=list(set(exclusions))


for s in l1:
    if s not in l2:
        unique_baseline.append(s)
    if s in exclusions:
        common_subjects.append(s)


for s in l2:
    if s not in l1:
        unique_excl.append(s)

print("original length:")
print("subjects in baseline:", len(baseline_list))
print("subjects in exclusion:", len(exclusions))
#print(baseline_list)
print("unique subjects in baseline:", len(l1))
print("unique subjects in exclusion:", len(l2))



for i in unique_baseline:
    print(i,)
print('-------------------------------')
for i in unique_excl:
    print(i,)

print(len(common_subjects))