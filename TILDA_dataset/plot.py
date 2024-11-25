

import matplotlib.pyplot as plt
#plt.rcParams["font.sans-serif"]=["SimHei"]#输出图像的标题可以为中文正常输出
#plt.rcParams["axes.unicode_minus"]=False #可以正常输出图线里的负号
name_list = ["Baseline", "Co2oct", "Raw_nii_files"]
width = 0.1
x = list(range(len(name_list)))
fig, ax = plt.subplots()

#offical
#real subjects
#processed
#unprocessed
offical = [544,148,468]
total = [584,128,483]#[[544], [554,4],[540,44]]
processed = [540,112,478]#[[544], [554,4],[540,44]]
unique = [562, 128, 482]
ax.bar(x,offical, width)

for i in range(len(x)):
    x[i] = x[i] + width

ax.bar(x,total, width, tick_label = name_list, label='blue')

for i in range(len(x)):
    x[i] = x[i] + width
ax.bar(x,processed, width, tick_label = name_list, label='blue')

for i in range(len(x)):
    x[i] = x[i] + width
ax.bar(x,unique, width, tick_label = name_list, label='blue')
#ax.bar(x,name_list, co2oct, width, label='blue')
#ax.bar(x,name_list, Raw_nii_files, width, label='blue')




plt.xlabel("Folder",fontsize=10)
plt.ylabel("Number of subjects",fontsize=10)
plt.title("Data statistics",fontsize=15)
plt.show()










'''
num_list = [554,[554,4],[540,44]]
num_list1 = [0.976, 0.914,0.90]

x = list(range(len(num_list)))
total_width, n = 0.6, 2
width = total_width / n
plt.bar(x, num_list, width=width, label="LogisticRegression", fc = "b")

for a,b in zip(x,num_list):   #柱子上的数字显示
    plt.text(a,b,'%.3f'%b,ha='center',va='bottom',fontsize=10);
for i in range(len(x)):
    x[i] = x[i] + width
plt.bar(x, num_list1, width=width, label="RandomForest", tick_label = name_list, fc ="r")

plt.xlabel("Folder",fontsize=10)
plt.ylabel("Number of subjects",fontsize=10)
plt.title("Data statistics",fontsize=15)
for a,b in zip(x,num_list1):
 plt.text(a,b,'%.3f'%b,ha='center',va='bottom',fontsize=10);
plt.legend(fontsize=8)
plt.show()
'''