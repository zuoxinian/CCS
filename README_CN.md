---
title: CCS的安装及使用
updated: 2021-11-07 03:05:09Z
created: 2021-11-06 02:25:00Z
latitude: 39.92850000
longitude: 116.38500000
altitude: 0.0000
---

# **CCS的安装及使用**

## 1.运行平台
目前CCS的数据预处理支持在Linux和Mac OX两个平台上运行，同时CCS的计算及运行需要下列运行平台
* Matlab R2007a及以上版本
* Python 3.0以上版本，建议安装Anaconda工具包 https://www.anaconda.com/products/individual#Downloads

## 2.预装软件
安装CCS前需将其运行所需的配套软件进行安装：
* AFNI https://afni.nimh.nih.gov/pub/dist/doc/htmldoc/background_install/main_toc.html
* FreeSurfer https://surfer.nmr.mgh.harvard.edu/
* FSL  https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation
* SPM12 https://www.fil.ion.ucl.ac.uk/spm/
* CAT12 http://www.neuro.uni-jena.de/cat/index.html#DOWNLOAD
* 安装docker及Deepbet https://github.com/HumanBrainED/NHP-BrainExtraction

## 3.安装和配置CCS系统
在将CCS_APP文件夹下载至指定位置后，需要对系统环境变量进行配置，将CCS_APP的路径写入环境变量中。通常在Linux或Mac OX系统中存储环境变量的文件为bashrc或bash_profile，请安装者首先确定在自己的系统中所使用的环境变量文件名称。下面以bashrc为例，在命令行中运行下列命令即可完成环境变量的配置：
```bash
echo "export CCS_APP=/dir-to-your-CCS_APP/CCS_APP/" >> ~/.bashrc
```

在添加CCS_APP路径过后，可以检查CCS_APP是否成功写入环境变量：
```bash
echo $CCS_APP
```
如屏幕中显示了您CCS_APP所在的目录即表示CCS环境变量配置成功。

## 4.数据预处理
在按照上述步骤成功安装CCS及相应的影响处理软件后，即可开始将数据进行预处理。

### 4.1 原始数据的整理
在获得原始的dicom数据后，需要将其压缩并转换成BIDS格式。具体的转换方法可参照BIDS格式的官网：https://bids.neuroimaging.io/ 。目前已有多种自动化的工具可将将原始的dicom数据转换成BIDS格式，如[dcm2bids](https://unfmontreal.github.io/Dcm2Bids/) 。

### 4.2 数据转换
在将原始数据整理成BIDS格式后，CCS会根据BIDS的格式生成用于数据处理的文件夹。通常我们以CCS来命名该文件夹，并将其同原始的BIDS数据存放于同一文件夹下。运行ccs_pre_bidsccs.py命令可完成上述操作。
```bash
BIDS_DIR=/your_project_dir/BIDS
CCS_DIR=/your_project_dir/CCS
python $CCS_APP/ccs_pre_bids2ccs.py --BIDS_DIR $BIDS_DIR --CCS_DIR $CCS_DIR
```

### 4.3 结构像预处理
在开始结构像预处理前，首先需要对CCS的工作路径，FreeSurfer的存储路径及需要处理的被试编号进行定义，如需要处理001号被试的数据：
```bash
CCS_DIR=/your_project_dir/CCS
SUBJECTS_DIR=/your_project_dir/FreeSurfer
subject=/your_project_dir/CCS/001
```

首先，进行结构像前处理，包括图像降噪、颅骨剥离等步骤。
```bash
$CCS_APP/ccs_anat_01_pre_freesurfer.sh $CCS_DIR $SUBJECTS_DIR $subject

```
完成上述步骤后，需对颅骨剥离效果进行检查，以确定是否继续进行下一步数据处理。
CCS结构像预处理的后两步分别为皮层重建流水线和结构像配准流水线，在进行这两部预处理时需要先后输下列命令：
```bash
$CCS_APP/ccs_anat_02_freesurfer.sh $CCS_DIR $SUBJECTS_DIR $subject
$CCS_APP/ccs_anat_03_postfs.sh $CCS_DIR $SUBJECTS_DIR $subject
```

### 4.4 静息态功能像预处理
功能像预处理首先需要对CCS_APP目录下的template_preproc_funcpart.sh文件进行修改，填入功能像对应的参数：
- CCS_DIR  （/your_project_dir/CCS）
- SUBJECTS_DIR （/your_project_dir/FreeSurfer）
- rest_dir_name (default:rest)
- rest_name (default:rest)
-  TR (default 2s)
-  numDropping (Dropping first 10s of rest data. default:5 )
- sliceOrder (Tpattern: see helps from AFNI command 3dTshift, default: alt+z, if the sequece is multi-band:mbd)
- FWHM (default: 6)

在对上述template内容修改完成后，即可运行下列命令开始功能图像的预处理。
```bash
CCS_DIR=/your_project_dir/CCS
subject=001
mkdir -p $CCS_DIR/$subject/scripts/
sed "s/CCSsubjectname/$subject/" $CCS_APP/template_preproc_funcpart.sh > $CCS_DIR/$subject/scripts/ccs_preproc_funcpart.sh
$CCS_DIR/$subject/scripts/ccs_preproc_funcpart.sh
```
