# linux
python train.py --model utnetv2 --dimension 3d --dataset acdc --batch_size 1 --unique_name acdc_3d_utnetv2 --gpu 0 >> utnetv2.txt
python train.py --model unet  --dimension 3d --dataset acdc --batch_size 1 --unique_name acdc_3d_unet --gpu 1 >> unet.txt
python train.py --model unet++ --dimension 3d --dataset acdc --batch_size 1 --unique_name acdc_3d_unet++ --gpu 0 >> unet++.txt
python train.py --model unetr  --dimension 3d --dataset acdc --batch_size 1 --unique_name acdc_3d_unetr --gpu 2 >> unetr.txt
python train.py --model resunet  --dimension 3d --dataset acdc --batch_size 1 --unique_name acdc_3d_resunet --gpu 1 >> resunet.txt

python test.py --model utnetv2 --dimension 3d --dataset acdc --batch_size 1 --unique_name acdc_3d_utnetv2 --gpu 0 >> utnetv2_test.txt

python test.py --model resunet  --dimension 3d --dataset acdc --batch_size 1 --unique_name acdc_3d_resunet --gpu 1 --load  >> resunet_test.txt

python test.py --model unet  --dimension 3d --dataset acdc --batch_size 1 --unique_name acdc_3d_unet --gpu 0 >> unet_test.txt
python test.py --model unet++ --dimension 3d --dataset acdc --batch_size 1 --unique_name acdc_3d_unet++ --gpu 0 >> unet++_test.txt

python test.py --model utnetv2 --dimension 3d --dataset acdc --batch_size 1 --unique_name acdc_3d_utnetv2 --gpu 0 >> utnetv2_test.txt


# windows
& D:/Program/Anaconda/python.exe i:/master/Code/as_v1.0/test.py --model utnetv2 --dimension 3d --dataset acdc --batch_size 1 --unique_name acdc_3d_utnetv2

& D:/Program/Anaconda/python.exe i:/master/Code/as_v1.0/test.py --model unet --dimension 3d --dataset acdc --batch_size 1 --unique_name acdc_3d_unet

# visual 

python inference.py --model unet  --dimension 3d --dataset acdc --batch_size 1 --unique_name acdc_3d_unet --gpu 0


python inference.py --model utnetv2  --dimension 3d --dataset acdc --batch_size 1 --unique_name acdc_3d_utnetv2 --gpu 0
