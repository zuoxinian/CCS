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

%% Load yeo2011 network confidence maps and convert them into nifti maps
for numRSN=[7 17]
    prefixRSN = ['Yeo2011_' num2str(numRSN) 'NetworksConfidence_N1000'];
    %LH
    fYeoCI = [fs_home '/subjects/fsaverage/label/lh.' prefixRSN '.mgz'];
    mriCI_lh = MRIread(fYeoCI); niihdr_lh.vol = mriCI_lh.vol;
    fOutCI = [ana_dir '/matlab/FreeSurfer/lh.' prefixRSN '.nii.gz'];
    err1 = save_nifti(niihdr_lh, fOutCI);
    %RH
    fYeoCI = [fs_home '/subjects/fsaverage/label/rh.' prefixRSN '.mgz'];
    mriCI_rh = MRIread(fYeoCI); niihdr_rh.vol = mriCI_rh.vol;
    fOutCI = [ana_dir '/matlab/FreeSurfer/rh.' prefixRSN '.nii.gz'];
    err2 = save_nifti(niihdr_rh, fOutCI);
end
