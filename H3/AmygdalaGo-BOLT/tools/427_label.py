import os
import numpy as np
import SimpleITK as sitk


gt_path = r"I:\master\Data\RawData\my_train_test_427_1\amygdala_segmentation"
gt_files = os.listdir(gt_path)
for i in range(len(gt_files)):
    name = gt_files[i]
    print(name)
    file_path = os.path.join(gt_path, name)
    itk_gt = sitk.ReadImage(file_path)
    gt = sitk.GetArrayFromImage(itk_gt)
    z, y, x = gt.shape

    gt = gt.astype(np.uint8)

    ar, num=np.unique(gt, return_counts=True)

    print(ar, num)
            
