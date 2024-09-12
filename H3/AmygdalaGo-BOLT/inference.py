import torch
import numpy as np
from model.utils import get_model
import yaml
import argparse
import os
import warnings
import torch
from inference.utils import get_inference
import numpy as np
import SimpleITK as sitk

warnings.filterwarnings("ignore", category=UserWarning)



def pipline(net, data, args):
    net.eval()
    inference = get_inference(args)
    with torch.no_grad():
        images, img_origin, name = data
        inputs = images.float().cuda()
        img_origin = img_origin
        pred = inference(net, inputs, args)
        _, label_pred = torch.max(pred, dim=1)
        img_origin[:] = 0
        z1, y1, x1 = 25, 100, 50
        img_origin[z1:z1+48, y1:y1+64, x1:x1+80] = label_pred.data.cpu().numpy()
        pred_array = img_origin
        outp = sitk.GetImageFromArray(pred_array)

        save_path = 'prediction/' + name  # acdc_3d_utnetv2, acdc_3d_unet
        print(f"prediction save to: {save_path}")
        sitk.WriteImage(outp, save_path)



def get_parser():
    parser = argparse.ArgumentParser(description='PyTorch Conv-Trans Segmentation')
    parser.add_argument('--inputdata', type=str, default=r'./app_demo_data/inputs/001_1.nii.gz', help='dataset name')
    parser.add_argument('--dataset', type=str, default='acdc', help='dataset name')
    parser.add_argument('--model', type=str, default='utnetv2', help='model name')
    parser.add_argument('--dimension', type=str, default='3d', help='2d model or 3d model')
    parser.add_argument('--pretrain', action='store_true', help='if use pretrained weight for init')
    parser.add_argument('--batch_size', default=1, type=int, help='batch size') # acdc_3d_utnetv2, acdc_3d_unet
    parser.add_argument('--load', type=str, default='./checkpoint_v1.0/bolt.pth', help='load pretrained model')
    parser.add_argument('--cp_path', type=str, default='./checkpoint_v1.0/', help='checkpoint path')
    parser.add_argument('--log_path', type=str, default='./log/', help='log path')
    parser.add_argument('--unique_name', type=str, default='acdc_3d_utnetv2', help='unique experiment name')
    
    parser.add_argument('--gpu', type=str, default='0')

    args = parser.parse_args()

    config_path = 'config/%s/%s_%s.yaml'%(args.dataset, args.model, args.dimension)
    if not os.path.exists(config_path):
        raise ValueError("The specified configuration doesn't exist: %s"%config_path)

    print('Loading configurations from %s'%config_path)

    with open(config_path, 'r') as f:
        config = yaml.load(f, Loader=yaml.SafeLoader)

    for key, value in config.items():
        setattr(args, key, value)

    return args
    

def init_network(args):
    net = get_model(args, pretrain=args.pretrain)

    if args.load:
        net.load_state_dict(torch.load(args.load)) #, map_location=torch.device('cpu')
        print('Model loaded from {}'.format(args.load))

    if args.ema:
        ema_net = get_model(args, pretrain=args.pretrain)
        for p in ema_net.parameters():
            p.requires_grad_(False)
    else:
        ema_net = None
    return net, ema_net 

def load_data(path_img):
    itk_img = sitk.ReadImage(path_img)
    img = sitk.GetArrayFromImage(itk_img)
    img = img.astype(np.float32)
    img_ori = img
    print(img.shape)
    
    
    import matplotlib
#     matplotlib.use('TkAgg')
    from matplotlib import pylab as plt
    num = 1
#     for i in range(30, 62):
#     plt.subplot(10, 10, num)
#     plt.imshow(img[70,:, :], cmap='gray')
#     num += 1
#     plt.show()
#     plt.savefig(f'./debug/1.png')
    img = img[25:73, 100:164, 50:130]
    
    tensor_img = torch.from_numpy(img).float()
    tensor_img = tensor_img.unsqueeze(0).unsqueeze(0)
    name = os.path.basename(path_img)
    return tensor_img, img_ori, name


def main():
    args = get_parser()
    os.environ['CUDA_VISIBLE_DEVICES'] = args.gpu
    args.log_path = args.log_path + '%s/'%args.dataset
   
    net, _ = init_network(args)
    net.cuda()
    img = load_data(args.inputdata)

    pipline(net, img, args)

if __name__ == '__main__':
    main()