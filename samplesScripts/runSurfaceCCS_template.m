clear all; clc ;
ana_dir ='/Volumes/RAID/projects/indi/NKI-RS'; %change to your directory
ccs_dir = [ana_dir '/scripts/ccs_beta']; %change to your ccs directory
ccs_matlab = [ccs_dir '/matlab'];
subs126_list = [ana_dir '/scripts/subjects_final126.list']; %change to yours
sub_test = [ana_dir '/scripts/subjects_test.list'];
rest_name = 'rest';
grpmask_dir = [ana_dir '/group/masks'];
grptemplate_dir = [ana_dir '/group/templates'];
fs_home = '/opt/freesurfer';
addpath(genpath([fs_home '/matlab']));
fsaverage = 'fsaverage5';

%% Adding paths to matlab
addpath(genpath(ccs_matlab)) %ccs matlab scripts
addpath(genpath([fs_home '/matlab'])) %freesurfer matlab scripts

%% Generating surface masks
gmask126 = ccs_07_grp_SurfaceMask( ana_dir, subs126_list, 'func', grpmask_dir, ...
    'NKI-RS126', fs_home, fsaverage );
% visualize the masks
s = SurfStatReadSurf( {... 
    [fs_home '/subjects/' fsaverage '/surf/lh.inflated'], ...
    [fs_home '/subjects/' fsaverage '/surf/rh.inflated']} );
%subs126
figure('Units', 'pixels', 'Position', [100 100 800 800]); axis off
SurfStatView(gmask126, s, 'FCONN Masks');
colormap([[0.5 0.5 0.5]; [1 0 0]]) ; SurfStatColLim( [0 1.5] )
set(gcf, 'PaperPositionMode', 'auto');
print('-djpeg', '-r300', [ana_dir '/group/masks/NKI-RS126_surfmask.jpg'])
close;

%% ALFF
func_dir_name = 'func_10mins';
err = ccs_06_singlesubject2dALFF(ana_dir, subs126_list, rest_name, 2.5, ...
        func_dir_name, fs_home, fsaverage);

%% ReHo
fs_vertex_adj = [ccs_matlab '/core/lfcd_ipn_tlbx/mat/' fsaverage '_adj.mat'];
func_dir_name = 'func_10mins';
%ReHo1
err = ccs_06_singlesubject2dReHo(ana_dir, subs126_list, rest_name, ...
    func_dir_name, fsaverage, fs_vertex_adj, 1);
%ReHo2
err = ccs_06_singlesubject2dReHo(ana_dir, subs126_list, rest_name, ...
    func_dir_name, fsaverage, fs_vertex_adj, 2);

%% RSFC
seeds_name = {'G_cingul-Post-dorsal'}; seeds_hemi = {'lh'};
func_dir_name = 'func_10mins';
err = ccs_06_singlesubject2dSFC( ana_dir, sub_list, rest_name, func_dir_name, ...
        seeds_name, seeds_hemi, fs_home, fsaverage);

%% GRAPH
gs_removal = 'false';
grp_mask_lh = [ana_dir '/group/masks/lh.NKI-RS126.' fsaverage '.nii.gz'];
grp_mask_rh = [ana_dir '/group/masks/rh.NKI-RS126.' fsaverage '.nii.gz'];
fgmask_surf ={grp_mask_lh, grp_mask_rh};
func_dir_name = 'func_10mins';
err = ccs_06_singlesubjectRFMRIparcels(ana_dir, subs126_list, func_dir_name, ...
    rest_name, ccs_dir, gs_removal, fsaverage, fgmask_surf);

%% VNCM
cent_idx = [1 0 1 0]; p_thr = [0.001];
func_dir_name = 'func_10mins';
% Surface
err = lfcd_06_singlesubject2dVNCM(ana_dir, subs_list, rest_name, func_dir_name, ...
        cent_idx, fs_home, fsaverage, p_thr, grp_mask_lh, grp_mask_rh, 'false');
%Volume
maskfname = [ana_dir '/group/masks/mask_4mm.nii.gz'];
gmfname = [ccs_dir '/templates/MNI152_T1_4mm_grey.nii.gz'];
gm_thr = 0.20;
ccs_06_singlesubjectVNCM( ana_dir, sub_list, rest_name, func_dir_name, ...
        cent_idx, maskfname, p_thr, gmfname, gm_thr );
