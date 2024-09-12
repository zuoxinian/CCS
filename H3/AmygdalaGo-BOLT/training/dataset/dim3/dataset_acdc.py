import os
import torch
import torch.nn as nn
import torch.nn.functional as F
import numpy as np
from torch.utils.data import Dataset
import SimpleITK as sitk
import yaml
import math
import random
import pdb
from training import augmentation

class CMRDataset(Dataset):
    def __init__(self, args, mode='train', k_fold=5, k=0, seed=0):
        
        self.mode = mode
        self.args = args

        assert mode in ['train', 'test']

        img_name_list = os.listdir(args.data_root + '/T1/')
        import sys
        result=[]
        with open('./special_data1.txt','r') as f:
            for line in f:
                result.append(list(line.strip('\n').split(',')))
        # print(result)
        img_name_list = result

        length = len(img_name_list)
        # test_name_list = img_name_list
        test_name_list = img_name_list
        # print(test_name_list)
        train_name_list = img_name_list
        # train_name_list = img_name_list[50 : ]
        # test_name_list = [test_name_list[0]]

        if mode == 'train':
            img_name_list1 = train_name_list
        else:
            img_name_list1 = test_name_list


        print('Start loading %s data'%self.mode)

        path = args.data_root

        self.img_list = []
        self.lab_list = []

        for name in img_name_list1:
            lab_name = name[0]
            # print(name)
            img_name = lab_name[:-11] + '.nii.gz'
            itk_img = (os.path.join(path, 'T1', img_name))
            itk_lab = (os.path.join(path, 'amygdala_segmentation', lab_name))

            self.img_list.append(itk_img)
            self.lab_list.append(itk_lab)

    def __len__(self):
        if self.mode == 'train':
            return len(self.img_list) 
        else:
            return len(self.img_list)



    def __getitem__(self, idx):
        
        idx = idx % len(self.img_list)
        
        path_img = self.img_list[idx]
        path_lab = self.lab_list[idx]
        name = os.path.split(path_lab)[1]
        


        itk_img = sitk.ReadImage(path_img)
        itk_lab = sitk.ReadImage(path_lab)

        spacing = np.array(itk_lab.GetSpacing()).tolist()
        spacing_l = spacing[::-1]  # itk axis order is inverse of numpy axis order


        tensor_img, tensor_lab, img_origin, lab_origin = self.preprocess(path_img, itk_img, itk_lab)

        tensor_img = tensor_img.unsqueeze(0)
        tensor_lab = tensor_lab.unsqueeze(0)
        # print(tensor_lab.max(), tensor_img.max(),tensor_lab.min(), tensor_img.min())

        assert tensor_img.shape == tensor_lab.shape

        if self.mode == 'train':
            return tensor_img, tensor_lab, path_lab, len(self.img_list)
        else:
            return tensor_img, tensor_lab, np.array(spacing_l),  img_origin, lab_origin, (name)




    def preprocess(self, path_img, itk_img, itk_lab):
        
        img = sitk.GetArrayFromImage(itk_img)
        lab = sitk.GetArrayFromImage(itk_lab)
        z, y, x = img.shape
        print(img.max(), img.min(), '1')

        img = img.astype(np.float32)
        print(img.max(), img.min(), '2')
        lab = lab.astype(np.uint8)
        
        img_origin = img
        lab_origin = lab

        # z1, y1, x1 =26, 95, 50





        # img = img[z1:z1+48, y1:y1+64, x1:x1+80]
        # lab = lab[z1:z1+48, y1:y1+64, x1:x1+80]

        # base
        lab = lab[25:73, 100:164, 50:130]
        img = img[25:73, 100:164, 50:130]


        lab[lab == 2] = 1
        lab_origin[lab_origin==2] = 1
        import matplotlib
        matplotlib.use('TkAgg')
        from matplotlib import pylab as plt
        num = 1
        # for i in range(30, 62):
        #     plt.subplot(10, 10, num)
        #     plt.imshow(img_origin[i,:, :], cmap='gray')
        #     num += 1
        # plt.show()

        ar,num=np.unique(lab,return_counts=True)
        ar1,num1=np.unique(lab_origin,return_counts=True)
        

        print(path_img, ar, num, num1, num[1] == num1[1])

        tensor_img = torch.from_numpy(img).float()
        tensor_lab = torch.from_numpy(lab).long()

        return tensor_img, tensor_lab, img_origin, lab_origin
