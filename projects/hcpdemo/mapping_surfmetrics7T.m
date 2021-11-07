clear all; clc
ana_dir = '/Users/mac/Projects/HCP/7T';
hcpdemo_dir = '/Users/mac/Downloads/Frontiers_LaTeX_Templates/hcpdemo';
ccs_dir = '/Users/mac/Projects/CCS';
spm_dir = [ccs_dir '/extool/spm12'];
ccs_matlab = [ccs_dir '/matlab'];
ccs_vistool = [ccs_dir '/vistool'];
fs_home = '/opt/freesurfer51'; 
cifti_matlab = [ccs_dir '/extool/cifti'];
atlas_dir = [ccs_dir '/extool/hcpworkbench/resources/32k_ConteAtlas_v2'];
work_dir = '/Volumes/extHD1/projects/hcp7T';
fsubjects = [work_dir '/scripts/subjects.7T.list'];
ftestsubj = [work_dir '/scripts/subjects.test.list'];
%Set up the path to matlab function in Freesurfer release
addpath(hcpdemo_dir);
addpath(genpath(ccs_matlab)) %ccs matlab scripts
addpath(genpath(ccs_vistool)) %ccs matlab scripts
addpath(genpath(cifti_matlab)) %cifti paths
addpath(genpath([fs_home '/matlab'])) %freesurfer matlab scripts

%% Load subjects list: pick up subjects with all 4 scans of 3T/7T
[~, ~, raw] = xlsread([work_dir '/scripts/behavioral.subs64.xls'],'Sheet1');
raw = raw(2:end,:);
gender = raw(:,4);
subs = raw(:,1);
nsubs = numel(subs);
rest_name = {'rfMRI_REST1_7T_PA', 'rfMRI_REST2_7T_AP', ...
    'rfMRI_REST3_7T_PA', 'rfMRI_REST4_7T_AP'}; 
nscans = numel(rest_name);

%% Generate surface mask: detect subjects missing any rfMRI scans
for k=1:nsubs
    for sid=1:nscans
        func_dir_name = ['MNINonLinear/Results/' rest_name{sid}];
        if isnumeric(subs{k})
            %disp(['Loading rfMRI for subjpct ' num2str(subs{k}) ': ' rest_name{sid} ' ...'])
            func_dir = [work_dir '/' num2str(subs{k}) '/' func_dir_name];
        else
            %disp(['Loading rfMRI for subject ' subs{k} ': ' rest_name{sid} ' ...'])
            func_dir = [work_dir '/' subs{k} '/' func_dir_name];
        end
        % load bold time series
        fbold = [func_dir '/' rest_name{sid} ...
            '_Atlas_1.6mm_MSMAll_hp2000_clean.dtseries.nii'];
        if ~exist(fbold,'file')
            [k subs{k}]
        end
    end
end
idx_subs = setdiff(1:64,[5 27]);
subs_final = subs(idx_subs); nsubs = numel(subs_final);

%% Estimated Symmetric Surfaces at group level
clearvars lh_inflated_average rh_inflated_average surf59kHCP64_lh surf59kHCP64_rh
%lh surfaces
fSURF = [work_dir '/' num2str(subs_final{1}) '/MNINonLinear/fsaverage_LR59k/' ...
    num2str(subs_final{1}) '.L.inflated.59k_fs_LR.surf.gii'];
lh_inflated = gifti(fSURF); 
lh_inflated_average.faces = lh_inflated.faces;
lh_inflated_average.vertices = lh_inflated.vertices;
%rh surfaces
fSURF = [work_dir '/' num2str(subs_final{1}) '/MNINonLinear/fsaverage_LR59k/' ...
    num2str(subs_final{1}) '.R.inflated.59k_fs_LR.surf.gii'];
rh_inflated = gifti(fSURF); 
rh_inflated_average.faces = rh_inflated.faces;
rh_inflated_average.vertices = rh_inflated.vertices;
for k=2:nsubs
    num2str(subs_final{k})
    %lh surfaces
    fSURF = [work_dir '/' num2str(subs_final{k}) '/MNINonLinear/fsaverage_LR59k/' ...
        num2str(subs_final{k}) '.L.inflated.59k_fs_LR.surf.gii'];
    lh_inflated = gifti(fSURF); 
    lh_inflated_average.faces = lh_inflated_average.faces + ...
        lh_inflated.faces;
    lh_inflated_average.vertices = lh_inflated_average.vertices + ...
        lh_inflated.vertices;
    %rh surfaces
    fSURF = [work_dir '/' num2str(subs_final{k}) '/MNINonLinear/fsaverage_LR59k/' ...
        num2str(subs_final{k}) '.R.inflated.59k_fs_LR.surf.gii'];
    rh_inflated = gifti(fSURF); 
    rh_inflated_average.faces = rh_inflated_average.faces + ...
        rh_inflated.faces;
    rh_inflated_average.vertices = rh_inflated_average.vertices + ...
        rh_inflated.vertices;
end
%make HCP62 surface structure
surf59kHCP62_lh.tri = lh_inflated_average.faces/nsubs;
surf59kHCP62_lh.coord = lh_inflated_average.vertices'/nsubs; 
numVertices_lh = size(lh_inflated_average.vertices,1);
surf59kHCP62_rh.tri = rh_inflated_average.faces/nsubs;
surf59kHCP62_rh.coord = rh_inflated_average.vertices'/nsubs; 
numVertices_rh = size(rh_inflated_average.vertices,1);
%save
fsurf59k = [ana_dir '/surf59kHCP62.inflated.mat'];
save(fsurf59k, 'surf59kHCP62_lh', 'surf59kHCP62_rh')

%% Generate masks: this only needs run at the first time
brainmask59k_lh = zeros(numVertices_lh,nsubs,4); 
brainmask59k_rh = zeros(numVertices_rh,nsubs,4);
for k=1:nsubs
    for sid=1:nscans
        func_dir_name = ['MNINonLinear/Results/' rest_name{sid}];
        if isnumeric(subs_final{k})
            disp(['Loading rfMRI for subjpct ' num2str(subs_final{k}) ': ' rest_name{sid} ' ...'])
            func_dir = [work_dir '/' num2str(subs_final{k}) '/' func_dir_name];
        else
            disp(['Loading rfMRI for subject ' subs_final{k} ': ' rest_name{sid} ' ...'])
            func_dir = [work_dir '/' subs_final{k} '/' func_dir_name];
        end
        % load bold time series
        fbold = [func_dir '/' rest_name{sid} ...
            '_Atlas_1.6mm_MSMAll_hp2000_clean.dtseries.nii'];
        if exist(fbold,'file')
            boldts = ft_read_cifti(fbold);
            boldts_lh = boldts.x6mm_msmall_hp2000_clean(boldts.brainstructure==1,:);
            boldts_rh = boldts.x6mm_msmall_hp2000_clean(boldts.brainstructure==2,:);
            clear boldts
            % lh mask
            tmpstd = std(boldts_lh,0,2);
            brainmask59k_lh(tmpstd>0,k,sid) = 1;
            % rh mask
            tmpstd = std(boldts_rh,0,2);
            brainmask59k_rh(tmpstd>0,k,sid) = 1;
        end
    end
end
fmask = [ana_dir '/brainmask59k.mat'];
save(fmask, 'brainmask59k_lh', 'brainmask59k_rh')

%% Prepare variables of surface metrics
load([ana_dir '/brainmask59k.mat']);
grpmask_lh = mean(mean(brainmask59k_lh,2),3); %group mask
numVertices_lh = numel(grpmask_lh);
idxmask_lh = find(grpmask_lh==1); 
grpmask_rh = mean(mean(brainmask59k_rh,2),3);
numVertices_rh = numel(grpmask_rh);
idxmask_rh = find(grpmask_rh==1);
grpmask_brain = [grpmask_lh; grpmask_rh];
idxmask_brain = find(grpmask_brain==1);
numVertices_mask = numel(idxmask_brain);
grpmask_hemi = grpmask_lh.*grpmask_rh;
idxmask_hemi = find(grpmask_hemi==1);
% ALFF and FALFF
boldalff_lh = zeros(numVertices_lh,nsubs,4); 
boldalff_rh = zeros(numVertices_rh,nsubs,4); %alff
boldfalff_lh = boldalff_lh; boldfalff_rh = boldalff_rh; %falff
% REHO
load([ana_dir '/HCP62_surf59kgraph_nbrs.mat']) %reho nbrs
boldreho2_lh = boldalff_lh; boldreho2_rh = boldalff_rh; %reho2
boldreho4_lh = boldalff_lh; boldreho4_rh = boldalff_rh; %reho4
% VMHC
boldvmhc = boldalff_lh; %vmhc

%% Loop subjects: the above surface metrics
for k=1:nsubs
    for sid=1:nscans
        func_dir_name = ['MNINonLinear/Results/' rest_name{sid}];
        if isnumeric(subs_final{k})
            disp(['Loading rfMRI for subject ' num2str(subs_final{k}) ': ' rest_name{sid} ' ...'])
            func_dir = [work_dir '/' num2str(subs_final{k}) '/' func_dir_name];
        else
            disp(['Loading rfMRI for subject ' subs_final{k} ': ' rest_name{sid} ' ...'])
            func_dir = [work_dir '/' subs_final{k} '/' func_dir_name];
        end
        % load bold time series
        fbold = [func_dir '/' rest_name{sid} ...
            '_Atlas_1.6mm_MSMAll_hp2000_clean.dtseries.nii'];
        boldts = ft_read_cifti(fbold);
        boldts_lh = boldts.x6mm_msmall_hp2000_clean(boldts.brainstructure==1,:);
        boldts_rh = boldts.x6mm_msmall_hp2000_clean(boldts.brainstructure==2,:);
        tslength = size(boldts_lh,2);
        clear boldts
        disp('compute alff and falff ...')
        [tmpalff, tmpfalff] = ccshcp_core_alffmat(boldts_lh(idxmask_lh,:)', 0.72);
        boldalff_lh(idxmask_lh,k,sid) = tmpalff;
        boldfalff_lh(idxmask_lh,k,sid) = tmpfalff;
        clear tmpalff tmpfalff
        [tmpalff, tmpfalff] = ccshcp_core_alffmat(boldts_rh(idxmask_rh,:)', 0.72);
        boldalff_rh(idxmask_rh,k,sid) = tmpalff;
        boldfalff_rh(idxmask_rh,k,sid) = tmpfalff;
        clear tmpalff tmpfalff
        disp('compute reho2 and reho4 ...')
        tmpreho2 = ccshcp_core_reho(boldts_lh', lh_nbrs(:,2));
        tmpreho4 = ccshcp_core_reho(boldts_lh', lh_nbrs(:,4));
        boldreho2_lh(:,k,sid) = tmpreho2;
        boldreho4_lh(:,k,sid) = tmpreho4;
        clear tmpreho2 tmpreho4
        tmpreho2 = ccshcp_core_reho(boldts_rh', rh_nbrs(:,2));
        tmpreho4 = ccshcp_core_reho(boldts_rh', rh_nbrs(:,4));
        boldreho2_rh(:,k,sid) = tmpreho2;
        boldreho4_rh(:,k,sid) = tmpreho4;
        clear tmpreho2 tmpreho4
        disp('compute the vmhc ...')
        zboldlh_masked = zscore(boldts_lh(idxmask_hemi,:),1,2);
        zboldrh_masked = zscore(boldts_rh(idxmask_hemi,:),1,2);
        tmpvmhc = sum(zboldlh_masked.*zboldrh_masked,2)/tslength;
        boldvmhc(idxmask_hemi,k,sid) = tmpvmhc;
    end
end
%save all maps
fout = [ana_dir '/hcp62.rfmri.Conte59k.7T.mat'];
save(fout, 'boldalff_lh', 'boldalff_rh', 'boldfalff_lh', 'boldfalff_rh', ...
    'boldreho2_lh', 'boldreho2_rh', 'boldreho4_lh', 'boldreho4_rh', 'boldvmhc')
