%% Basic settings
clear all ; clc
fs_home = '/Optapplications/freesurfer'; 
work_dir = '/Users/XINIAN/Documents/MATLAB/proj38_vol2surf';
%Set up the path to matlab function in Freesurfer release
addpath([fs_home '/matlab'])

%% Volume: number of voxels in grey matter
ReHo_dir = '/Users/XINIAN/Documents/ManuscriptDraft/ReHo_TRT/data';
fgreymask = [ReHo_dir '/masks/tissues/MNI152_T1_3mm_grey.nii.gz'];
% Read grey mask
greymaskhdr = load_nifti(fgreymask); 
greymaskvol = greymaskhdr.vol;
grey_thr = 0.1;
idx_grey = find(greymaskvol >= grey_thr);
numel(idx_grey)
greymaskvol_cortex = greymaskhdr.vol;
greymaskvol_cortex(:,:,1:13) = 0;
idx_grey_cortex = find(greymaskvol_cortex >= grey_thr);
numel(idx_grey_cortex)

%% Surface: number of vertices in cortex
%fsaverage 5 - 4mm vertex spacing
fsaverage = 'fsaverage5';
fsavg5 = {[fs_home '/subjects/' fsaverage '/surf/lh.pial'], ...
           [fs_home '/subjects/' fsaverage '/surf/rh.pial']};
s5 = SurfStatReadSurf( fsavg5 );
num_triangles = size(s5.tri,1) 
num_verices = size(s5.coord,2) 
%fsaverage 7 - 1mm vertex spacing
fsaverage = 'fsaverage';
fsavg7 = {[fs_home '/subjects/' fsaverage '/surf/lh.pial'], ...
           [fs_home '/subjects/' fsaverage '/surf/rh.pial']};
s7 = SurfStatReadSurf( fsavg7 );
num_triangles = size(s7.tri,1) 
num_verices = size(s7.coord,2) 
%fsaverage 3 - ?mm vertex spacing
fsaverage = 'fsaverage3';
fsavg3 = {[fs_home '/subjects/' fsaverage '/surf/lh.pial'], ...
           [fs_home '/subjects/' fsaverage '/surf/rh.pial']};
s3 = SurfStatReadSurf( fsavg3 );
num_triangles = size(s3.tri,1) 
num_verices = size(s3.coord,2) 
%fsaverage 4 - ?mm vertex spacing
fsaverage = 'fsaverage4';
fsavg4 = {[fs_home '/subjects/' fsaverage '/surf/lh.pial'], ...
           [fs_home '/subjects/' fsaverage '/surf/rh.pial']};
s4 = SurfStatReadSurf( fsavg4 );
num_triangles = size(s4.tri,1) 
num_verices = size(s4.coord,2) 
%fsaverage 6 - 2mm vertex spacing
fsaverage = 'fsaverage6';
fsavg6 = {[fs_home '/subjects/' fsaverage '/surf/lh.pial'], ...
           [fs_home '/subjects/' fsaverage '/surf/rh.pial']};
s6 = SurfStatReadSurf( fsavg6 );
num_triangles = size(s6.tri,1) 
num_verices = size(s6.coord,2) 