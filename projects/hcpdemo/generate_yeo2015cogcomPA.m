clear all; clc
ana_dir = '/Users/mac/Downloads/Frontiers_LaTeX_Templates/hcpdemo';
ccs_dir = '/Volumes/RAID5/CCS';
ccs_matlab = [ccs_dir '/matlab'];
ccs_vistool = [ccs_dir '/vistool'];
cifti_matlab = [ana_dir '/matlab/cifti-matlab-master'];
fs_home = '/Applications/freesurfer6dev/freesurfer'; 
freesurfer_home = [ana_dir '/FreeSurfer']; 
%Set up the path to matlab function in Freesurfer release
addpath(genpath(ccs_matlab)) %ccs matlab scripts
addpath(genpath(ccs_vistool)) %ccs matlab scripts
addpath(genpath(cifti_matlab)) %freesurfer matlab scripts
addpath(genpath([fs_home '/matlab'])) %freesurfer matlab scripts

%% Load a sample map of the nifti maps
fsample = ['/Volumes/SeagateBackupPlusDrive/Data/STROKE/' ...
    'ccsData/XWS015_YYY_1/rest1/mask/brain.fsaverage.lh.nii.gz'];
niihdr_lh = load_nifti(fsample); niihdr_lh.datatype = 16;
fsample = ['/Volumes/SeagateBackupPlusDrive/Data/STROKE/' ...
    'ccsData/XWS015_YYY_1/rest1/mask/brain.fsaverage.rh.nii.gz'];
niihdr_rh = load_nifti(fsample); niihdr_rh.datatype = 16;

%% Load yeo2015 cognitive component probability maps and convert them into nifti maps
fYeoCC = [fs_home '/subjects/fsaverage/label/' ...
    'lh.Yeo_Brainmap_12Comp_PrActGivenComp.mgz'];
mriCC_lh = MRIread(fYeoCC); volCC_lh = squeeze(mriCC_lh.vol);
fYeoCC = [fs_home '/subjects/fsaverage/label/' ...
    'rh.Yeo_Brainmap_12Comp_PrActGivenComp.mgz'];
mriCC_rh = MRIread(fYeoCC); volCC_rh = squeeze(mriCC_rh.vol);
for numCC=1:12
    prefixCC = ['Brainmap_12Comp_' num2str(numCC) '_PrActGivenComp'];
    %lh
    niihdr_lh.vol = volCC_lh(:,numCC);
    fOutCC = [ana_dir '/matlab/FreeSurfer/lh.' prefixCC '.nii.gz'];
    err1 = save_nifti(niihdr_lh, fOutCC);
    %rh
    niihdr_rh.vol = volCC_rh(:,numCC);
    fOutCC = [ana_dir '/matlab/FreeSurfer/rh.' prefixCC '.nii.gz'];
    err2 = save_nifti(niihdr_rh, fOutCC);
end
