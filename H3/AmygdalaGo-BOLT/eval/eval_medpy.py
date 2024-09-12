from medpy.io import load
from medpy.metric.binary import dc
import os
path = '/home/hhedeeplearning/share/dongbo/zuo/zuoxinian_data/freesurfer6_split/freesurfer6_wave1/freesurfer6_wave1_right/'
files = os.listdir(path)
for i in files:
	# print(i)
	if i[-5:] == 'R.nii':
		# print('dongbo')
		image_data, image_header = load('/home/hhedeeplearning/share/dongbo/zuo/zuoxinian_data/freesurfer6_split/freesurfer6_wave1/freesurfer6_wave1_right/' + i)
		label_data, label_header = load('/home/hhedeeplearning/share/dongbo/zuo/zuoxinian_data/amygdala_segmentation/' + (i[:3]) + '_1_seg.nii.gz')


		label_data[label_data == 1] = 0

		print(dc(image_data, label_data))