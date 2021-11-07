function [gmask] = ccs_07_grp_SurfaceMask( ana_dir, sub_list, func_dir_name, grpmask_dir, prefix_mask, fs_home, fsaverage )
%CCS_07_GROUPSURFACEMASK Computing the masks on the surface for group-level analyses.
%   ana_dir -- full path of the analysis directory
%   sub_list -- full path of the list of subjects
%   func_dir_name -- the name of functional directory
%   grpmask_dir -- full path of the group mask directory 
%   prefix_mask -- the prefix of mask name
%   fs_home -- freesurfer home directory
%   fsaverage -- the fsaverage file name
%
% Author: Xi-Nian Zuo at IPCAS, Dec., 17, 2011.
% Last Modified: Xi-Nian Zuo at IPCAS, Aug., 02, 2014.

if nargin < 7
    disp('Usage: ccs_07_grp_SurfcaceMask( ana_dir, sub_list, func_dir_name, grpmask_dir, prefix_mask, fs_home, fsaverage )')
    exit
end
%% FSAVERAGE: Searching labels in aparc.a2009s.annot
fannot = [fs_home '/subjects/' fsaverage '/label/lh.aparc.a2009s.annot'];
[vertices_lh,~,~] = read_annotation(fannot);
nVertices_lh = numel(vertices_lh);
fannot = [fs_home '/subjects/' fsaverage '/label/rh.aparc.a2009s.annot'];
[vertices_rh,~,~] = read_annotation(fannot);
nVertices_rh = numel(vertices_rh);
clear fannot
%% SUBINFO
subs = textread(sub_list,'%s'); 
nsubs = numel(subs);
lh_gmask = ones(nVertices_lh,1); rh_gmask = ones(nVertices_rh,1);  
%% Loop Subjects
for ss=1:nsubs
    if isnumeric(subs{ss})
        disp(['Loading Surface Masks for subject ' num2str(subs{ss}) ' ...'])
        func_dir = [ana_dir '/' num2str(subs{ss}) '/' func_dir_name];
    else
        disp(['Loading Surface Masks for subject ' subs{ss} ' ...'])
        func_dir = [ana_dir '/' subs{ss} '/' func_dir_name];
    end
    mask_dir = [func_dir '/mask'];
    %LH
    lh_fname = [mask_dir '/brain.' fsaverage '.lh.nii.gz'];
    surfMask = load_nifti(lh_fname);
    lh_gmask = lh_gmask.*surfMask.vol;
    %RH
    rh_fname = [mask_dir '/brain.' fsaverage '.rh.nii.gz'];
    surfMask = load_nifti(rh_fname);
    rh_gmask = rh_gmask.*surfMask.vol;
end
%% Save Surf Mask
if ~exist(grpmask_dir, 'dir')
    mkdir(grpmask_dir)
end
surfMask.descrip = ['CCS ' date]; surfMask.vol = lh_gmask;
save_nifti(surfMask, [grpmask_dir '/lh.' prefix_mask '.' fsaverage '.nii.gz']);
surfMask.descrip = ['CCS ' date]; surfMask.vol = rh_gmask;
save_nifti(surfMask, [grpmask_dir '/rh.' prefix_mask '.' fsaverage '.nii.gz']);

%% Return for debug
gmask = [lh_gmask; rh_gmask];