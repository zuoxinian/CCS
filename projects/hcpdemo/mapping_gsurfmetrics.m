clear all; clc
ana_dir = '/Users/mac/Downloads/Frontiers_LaTeX_Templates/hcpdemo';
ccs_dir = '/Volumes/RAID5/CCS';
ccs_matlab = [ccs_dir '/matlab'];
ccs_vistool = [ccs_dir '/vistool'];
work_dir = '/Volumes/RAID5/u100HCP';
fs_home = '/opt/freesurfer'; 
fsubjects = [work_dir '/subjects_u100.list'];
ftestsubj = [work_dir '/subject_100307.list'];
cifti_matlab = [ana_dir '/matlab/cifti-matlab-master'];
%Set up the path to matlab function in Freesurfer release
addpath(genpath(ccs_matlab)) %ccs matlab scripts
addpath(genpath(ccs_vistool)) %ccs matlab scripts
addpath(genpath(cifti_matlab)) %cifti paths
addpath(genpath([fs_home '/matlab'])) %freesurfer matlab scripts

%% Load subjects list
fid = fopen(fsubjects); tmpcell = textscan(fid, '%s'); 
fclose(fid); subs = tmpcell{1} ; nsubs = numel(subs);
rest_name = {'rfMRI_REST1_LR', 'rfMRI_REST1_RL', ...
    'rfMRI_REST2_LR', 'rfMRI_REST2_RL'}; nscans = numel(rest_name);

%% Load brain masks
load([ana_dir '/brainmask.mat'])
grpmask_lh = mean(mean(brainmask_lh,2),3); %group mask
idxmask_lh = find(grpmask_lh==1); 
grpmask_rh = mean(mean(brainmask_rh,2),3);
idxmask_rh = find(grpmask_rh==1);
grpmask_brain = [grpmask_lh; grpmask_rh];
idxmask_brain = find(grpmask_brain==1);
numVertices_mask = numel(idxmask_brain);
grpmask_hemi = grpmask_lh.*grpmask_rh;
idxmask_hemi = find(grpmask_hemi==1);

%% Loop subjects
gsurfmetrics = zeros(nsubs,17);
for k=1:nsubs
    fmetrics = [ana_dir '/classic/' num2str(subs{k}) '.mat'];
    tmpmetrics = load(fmetrics);
    %mean and std
    