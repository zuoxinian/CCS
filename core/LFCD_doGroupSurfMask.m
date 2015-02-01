function [gmask] = LFCD_doGroupSurfMask( subjects_list, subjects_dir, fsaverage, grpmask_dir, prefix_mask )
% Summary of this function goes here
%   Detailed explanation goes here
%   
% ZuoXN@psych.ac.cn

%% Load the subjects list and vertex-adjcency matrix
subjects = importdata(subjects_list); load([fsaverage '.mat']);
lh_gmask = ones(numel(lh_nbrs),1); rh_gmask = ones(numel(rh_nbrs),1);  
%% Loop Subjects
for ss=1:numel(subjects)
    disp(['Loading Subject ' num2str(subjects(ss)) ' Surface Mask ...'])
    %LH
    lh_fname = [subjects_dir '/' num2str(subjects(ss)) ...
        '/func/mask/brain.' fsaverage '.lh.nii.gz'];
    surfMask = load_nifti(lh_fname);
    lh_gmask = lh_gmask.*surfMask.vol;
    %RH
    rh_fname = [subjects_dir '/' num2str(subjects(ss)) ...
        '/func/mask/brain.' fsaverage '.rh.nii.gz'];
    surfMask = load_nifti(rh_fname);
    rh_gmask = rh_gmask.*surfMask.vol;
end
%% Save Surf Mask
surfMask.vol = lh_gmask;
save_nifti(surfMask, [grpmask_dir '/' prefix_mask '.' fsaverage '.lh.nii.gz']);
surfMask.vol = rh_gmask;
save_nifti(surfMask, [grpmask_dir '/' prefix_mask '.' fsaverage '.rh.nii.gz']);

%% Return for debug
gmask = [lh_gmask; rh_gmask];