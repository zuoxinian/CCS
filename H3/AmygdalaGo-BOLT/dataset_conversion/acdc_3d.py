import numpy as np
import SimpleITK as sitk
from utils import ResampleXYZAxis, ResampleFullImageToRef
import os
import random
import yaml

def ResampleCMRImage(imImage, imLabel, save_path_t1, save_path='./', patient_name=None, target_spacing=(1., 1., 1.)):

    # assert imImage.GetSpacing() == imLabel.GetSpacing()
    # assert imImage.GetSize() == imLabel.GetSize()

    # print()


    spacing = imImage.GetSpacing()
    origin = imImage.GetOrigin()

    print(imImage.GetSpacing(),  imLabel.GetSpacing(),  imImage.GetOrigin(),  imLabel.GetOrigin())


    npimg = sitk.GetArrayFromImage(imImage)
    nplab = sitk.GetArrayFromImage(imLabel)
    z, y, x = npimg.shape

    if not os.path.exists('%s'%(save_path)):
        os.mkdir('%s'%(save_path))
    
    tmp_img = npimg
    tmp_lab = nplab

    tmp_itkimg = sitk.GetImageFromArray(tmp_img)
    tmp_itkimg.SetSpacing(spacing[0:3])
    tmp_itkimg.SetOrigin(origin[0:3])
    tmp_itkimg.SetDirection((1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0))

    tmp_itklab = sitk.GetImageFromArray(tmp_lab)
    tmp_itklab.SetSpacing(spacing[0:3])
    tmp_itklab.SetOrigin(origin[0:3])
    tmp_itklab.SetDirection((1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0))


    #re_img = ResampleXYZAxis(tmp_itkimg, space=(target_space[0], target_space[1], target_space[2]))
    #re_lab = ResampleFullImageToRef(tmp_itklab, re_img)
    # interp xy plane using Bilinear, while interp z axis using NearestNeighbor. Follow nnUNet
    re_img_xy = ResampleXYZAxis(tmp_itkimg, space=(target_spacing[0], target_spacing[1], spacing[2]), interp=sitk.sitkBSpline)
    re_lab_xy = ResampleFullImageToRef(tmp_itklab, re_img_xy)

    re_img_xyz = ResampleXYZAxis(re_img_xy, space=(target_spacing[0], target_spacing[1], target_spacing[2]), interp=sitk.sitkNearestNeighbor)
    re_lab_xyz = ResampleFullImageToRef(re_lab_xy, re_img_xyz)
    print(re_img_xyz.GetSpacing(),  re_lab_xyz.GetSpacing(),  re_img_xyz.GetOrigin(),  re_lab_xyz.GetOrigin())


    # sitk.WriteImage(re_img_xyz, '%s/%s'%(r'I:\master\Data\RawData\my_train_test_427_1\pre\amygdala_segmentation_warp', patient_name))
    sitk.WriteImage(re_lab_xyz, '%s/%s'%(r'I:\master\Data\RawData\my_train_test_427_1\pre\amygdala_segmentation_warp', patient_name))


if __name__ == '__main__':


    tgt_path = r'I:\master\Data\RawData\my_train_test_427_1\amygdala_segmentation'
    src_path = r'I:\master\Data\RawData\my_train_test_427_1\pre\acdc_3d_unet_warp'
    save_path =  tgt_path +  '_warp'
    files = os.listdir(r'I:\master\Data\RawData\my_train_test_427_1\pre\acdc_3d_unet_warp')
    for name in files:
        t1w = os.path.join(src_path, name)
        pred = os.path.join(tgt_path, name)
        itk_img = sitk.ReadImage(t1w)
        itk_lab = sitk.ReadImage(pred)
        ResampleCMRImage(itk_img, itk_lab, src_path + '_warp', save_path, name)

