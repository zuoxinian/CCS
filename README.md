Connectome Computation System (CCS)
===

![Functional Organization of CCS](https://github.com/zuoxinian/CCS/blob/master/manual/Figure1_CCS-GeneralDesign.png)

If you use or are inspired by CCS, please credit it both the github link and the two key references:

1. Ting Xu, Zhi Yang, Lili Jiang, Xiu-Xia Xing, Xi-Nian Zuo. 2015. [A Connectome Computation System for discovery science of brain](https://github.com/zuoxinian/CCS/blob/master/manual/ccs.paper.pdf). *Science Bulletin*, 60(1): 86-95.
2. Xia-Xiu Xing, Ting Xu, Chao Jiang, Yin-Shan Wang, Xi-Nian Zuo. 2022. [Connectome Computation System: 2015–2021 updates](https://github.com/zuoxinian/CCS/blob/master/manual/ccs.updates.2015-2021.pdf). *Science Bulletin*, 67(5): 448-451.

# Install and Run CCS

## 1. Running Platform 
CCS  can be used on Linux/Unix and Mac systems.  You also need to install:
* Matlab above R2007a
* Python 3.0 or Above. We suggest you to install Anaconda toolbox https://www.anaconda.com/products/individual#Downloads

## 2. Requirements 
CCS needs to install these neuroimage tools in order to run ourt pipeline (use the most recent versions):
* AFNI https://afni.nimh.nih.gov/pub/dist/doc/htmldoc/background_install/main_toc.html
* FreeSurfer https://surfer.nmr.mgh.harvard.edu/
* FSL  https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FslInstallation
* SPM12 https://www.fil.ion.ucl.ac.uk/spm/
* CAT12 http://www.neuro.uni-jena.de/cat/index.html#DOWNLOAD
* Docker and DeepBet https://github.com/HumanBrainED/NHP-BrainExtraction

## 3. Install CCS
After downloading the CCS_APP folder to the specified location, you need to configure the system environment variables and write the path of CCS_APP into the environment. Usually, the environment variables are saved at bashrc or bash_profile on Linux or Mac OX systems. Please first check the name of the environment variable file used on your system and type the following sentence on your command line.
```bash
echo "export CCS_APP=/dir-to-your-CCS_APP/CCS_APP/" >> ~/.bashrc
```
After adding the CCS_APP path, you can check whether CCS_APP has been successfully installed.
```bash
echo $CCS_APP
```
If the screen shows the directory where your CCS_APP is located, the CCS environment variable has been successfully configured.
* * *

## 4. Data Preprocessing
Once the CCS and the corresponding isoftware have been successfully installed according to the above steps, the data can be pre-processed.

### 4.1 Data Organizing
After obtaining the raw dicom data, it needs to be compressed and converted to BIDS format. The specific conversion method can be found on the BIDS format website：https://bids.neuroimaging.io/ 。There are several automated tools available to convert raw dicom data into BIDS format, such as [dcm2bids](https://unfmontreal.github.io/Dcm2Bids/).

### 4.2 Transform into CCS
After organingz the raw data into BIDS format, CCS will generate a folder for data processing based on the BIDS format, usually we name the folder as CCS and store it in the same folder as the raw BIDS data. This is done by running the ccs_pre_bidsccs.py command.
```bash
BIDS_DIR=/your_project_dir/BIDS
CCS_DIR=/your_project_dir/CCS
python $CCS_APP/ccs_pre_bids2ccs.py --BIDS_DIR $BIDS_DIR --CCS_DIR $CCS_DIR
```

### 4.3 Structural image pre-processing
Before starting the structural image pre-processing, the working path of CCS, the storage path of FreeSurfer and the subject number to be processed need to be defined first.
```bash
CCS_DIR=/your_project_dir/CCS
SUBJECTS_DIR=/your_project_dir/FreeSurfer
subject=/your_project_dir/CCS/001
```

First, structural image pre-processing is performed, including steps such as denoising and skull stripping.
```bash
$CCS_APP/sampleScripts/ccs_anat_01_pre_freesurfer.sh $CCS_DIR $SUBJECTS_DIR $subject

```
Once these steps have been completed, the skull stripping effect needs to be checked to determine whether to continue with the next step of data processing.
The second two steps of the CCS structural image pre-processing are the cortical reconstruction pipeline and the structural image alignment pipeline, as the following commands.
```bash
$CCS_APP/sampleScripts/ccs_anat_02_freesurfer.sh $CCS_DIR $SUBJECTS_DIR $subject
$CCS_APP/sampleScripts/ccs_anat_03_postfs.sh $CCS_DIR $SUBJECTS_DIR $subject
```

### 4.4 Resting-state functional image pre-processing
The preprocessing of the functional image starts with modifying the template_preproc_funcpart.sh file in the CCS_APP directory by filling in the parameters corresponding to the functional image:
- CCS_DIR  /your_project_dir/CCS
- SUBJECTS_DIR /your_project_dir/FreeSurfer
- rest_dir_name (default:rest)
- rest_name (default:rest)
-  TR (default 2s)
-  numDropping (Dropping first 10s of rest data. default:5 )
- sliceOrder (Tpattern: see helps from AFNI command 3dTshift, default: alt+z, if the sequece is multi-band:mbd)
- FWHM (default: 6)

After modifying the contents of the template , the following command can be run to start the pre-processing of the functional image.
```bash
CCS_DIR=/your_project_dir/CCS
subject=001
mkdir -p $CCS_DIR/$subject/scripts/
sed "s/CCSsubjectname/$subject/" $CCS_APP/sampleScripts/template_preproc_funcpart.sh > $CCS_DIR/$subject/scripts/ccs_preproc_funcpart.sh
$CCS_DIR/$subject/scripts/ccs_preproc_funcpart.sh
