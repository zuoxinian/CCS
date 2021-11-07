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

%% Load Symmetric Surfaces: test subject
fid = fopen(ftestsubj); tmpcell = textscan(fid, '%s'); 
fclose(fid); testsub = tmpcell{1};
%load surfaces
fSURF = [work_dir '/' testsub{1} '/MNINonLinear/fsaverage_LR59k/' ...
    testsub{1} '.L.inflated.59k_fs_LR.surf.gii'];
lh_inflated = gifti(fSURF); numVertices_lh = size(lh_inflated.vertices,1); %lh
%make Conte69 surface structure
surfConte69_lh.tri = lh_inflated.faces;
surfConte69_lh.coord = lh_inflated.vertices'; 
%rh
fSURF = [work_dir '/' testsub{1} '/MNINonLinear/fsaverage_LR59k/' ...
    testsub{1} '.R.inflated.59k_fs_LR.surf.gii'];
rh_inflated = gifti(fSURF); numVertices_rh = size(rh_inflated.vertices,1); %rh
%make Conte69 surface structure
surfConte69_rh.tri = rh_inflated.faces;
surfConte69_rh.coord = rh_inflated.vertices'; 

%% Load subjpcts list
fid = fopen(fsubjects); tmpcell = textscan(fid, '%s'); 
fclose(fid); subs = tmpcell{1} ; nsubs = numel(subs);
rest_name = {'rfMRI_REST1_7T_PA', 'rfMRI_REST2_7T_AP', ...
    'rfMRI_REST3_7T_PA', 'rfMRI_REST4_7T_AP'}; 
nscans = numel(rest_name);

%% Generate surface mask: detect files
pk = 0; subjects_prfmri = [];
for k=1:nsubs
    for sid=1:nscans
        func_dir_name = ['MNINonLinear/Results/' rest_name{sid}];
        if isnumeric(subs{k})
            disp(['Loading rfMRI for subjpct ' num2str(subs{k}) ': ' rest_name{sid} ' ...'])
            func_dir = [work_dir '/' num2str(subs{k}) '/' func_dir_name];
        else
            disp(['Loading rfMRI for subject ' subs{k} ': ' rest_name{sid} ' ...'])
            func_dir = [work_dir '/' subs{k} '/' func_dir_name];
        end
        % load bold time series
        fbold = [func_dir '/' rest_name{sid} ...
            '_Atlas_1.6mm_MSMAll_hp2000_clean.dtseries.nii'];
        if ~exist(fbold,'file')
            pk = pk + 1;
            subjects_prfmri{pk} = num2str(subs{k});
        end
    end
end

%% Generate masks: this only needs run at the first time
fsubjects = [work_dir '/scripts/subjects.7T.subs71.list'];
fid = fopen(fsubjects); tmpcell = textscan(fid, '%s'); 
fclose(fid); subs = tmpcell{1} ; nsubs = numel(subs);
brainmask_lh = zeros(numVertices_lh,nsubs,4); 
brainmask_rh = zeros(numVertices_rh,nsubs,4);
for k=1:nsubs
    for sid=1:nscans
        func_dir_name = ['MNINonLinear/Results/' rest_name{sid}];
        if isnumeric(subs{k})
            disp(['Loading rfMRI for subjpct ' num2str(subs{k}) ': ' rest_name{sid} ' ...'])
            func_dir = [work_dir '/' num2str(subs{k}) '/' func_dir_name];
        else
            disp(['Loading rfMRI for subject ' subs{k} ': ' rest_name{sid} ' ...'])
            func_dir = [work_dir '/' subs{k} '/' func_dir_name];
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
            brainmask_lh(tmpstd>0,k,sid) = 1;
            % rh mask
            tmpstd = std(boldts_rh,0,2);
            brainmask_rh(tmpstd>0,k,sid) = 1;
        end
    end
end
fmask = [ana_dir '/brainmask.mat'];
save(fmask, 'brainmask_lh', 'brainmask_rh')

%% Prepare variables of surface metrics
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
% MEAN and STD
boldmean_lh = zeros(numVertices_lh,4); %mean
boldmean_rh = zeros(numVertices_rh,4); 
boldstd_lh = boldmean_lh; boldstd_rh = boldmean_rh; %std
% ALFF and FALFF
boldalff_lh = boldmean_lh; boldalff_rh = boldmean_rh; %alff
boldfalff_lh = boldmean_lh; boldfalff_rh = boldmean_rh; %falff
% REHO
load([ana_dir '/matlab/Conte69_surfgraph_nbrs.mat']) %reho nbrs
boldreho2_lh = boldmean_lh; boldreho2_rh = boldmean_rh; %reho2
boldreho4_lh = boldmean_lh; boldreho4_rh = boldmean_rh; %reho4
% SEED IFC
seed_coords = [-6 -58 28; -2 10 48; 26 -58 48]; %seeds preparation: pcc/sma/ips
conte69_home = [ana_dir '/matlab/32k_ConteAtlas_v2'];
[seedvertex, seedhemi] = ccshcp_seedvertex_conte69(seed_coords, conte69_home);
seeds = cell(numel(seedhemi),1);
for idxseed=1:numel(seedhemi)
    if strcmp(seedhemi{idxseed}, 'lh')
        seeds{idxseed,1} = lh_nbrs(seedvertex(idxseed),3);
    end
    if strcmp(seedhemi{idxseed}, 'rh')
        seeds{idxseed,1} = rh_nbrs(seedvertex(idxseed),3);
    end
end        
boldpcc_lh = boldmean_lh; boldpcc_rh = boldmean_rh; %pcc-ifc
boldsma_lh = boldmean_lh; boldsma_rh = boldmean_rh; %sma-ifc
boldips_lh = boldmean_lh; boldips_rh = boldmean_rh; %ips-ifc
% VMHC
boldvmhc = boldmean_lh; %vmhc
% DUAL REGRESSION
sp_reg_lh = zeros(numel(CI_lh), 7); sp_reg_rh = zeros(numel(CI_rh), 7);
numName_lh = numel(labelRSN_lh.name); numName_rh = numel(labelRSN_rh.name);
for mapID=1:7
    nameRSN = ['7Networks_' num2str(mapID)];
    %lh
    for nameID=1:numName_lh
        if strcmp(nameRSN, labelRSN_lh.name{nameID})
            tmpIDX = find(ctableRSN_lh(:,1)==labelRSN_lh.key(nameID));
            sp_reg_lh(tmpIDX,mapID) = CI_lh(tmpIDX);
        end
    end
    %rh
    for nameID=1:numName_rh
        if strcmp(nameRSN, labelRSN_rh.name{nameID})
            tmpIDX = find(ctableRSN_rh(:,1)==labelRSN_rh.key(nameID));
            sp_reg_rh(tmpIDX,mapID) = CI_rh(tmpIDX);
        end
    end    
end
sp_regressors = [sp_reg_lh; sp_reg_rh];
bolddrrsn_lh = zeros(numVertices_lh,7,4); %spatial networks
bolddrrsn_rh = zeros(numVertices_rh,7,4);
bolddrts = zeros(1200,7,4); %time series
% NETWORK CENTRALITY
Yeo2011RSN_masked_lh = Yeo2011RSN_lh.*grpmask_lh;
idxYeo2011RSN_lh = cell(7,1); netnodenum_lh = zeros(7,1);
for netid=1:7
    tmpidx = find(Yeo2011RSN_masked_lh==netid);
    idxYeo2011RSN_lh{netid} = tmpidx;
    netnodenum_lh(netid) = numel(tmpidx);
end
clear tmpidx
Yeo2011RSN_masked_rh = Yeo2011RSN_rh.*grpmask_rh;
idxYeo2011RSN_rh = cell(7,1); netnodenum_rh = zeros(7,1);
for netid=1:7
    tmpidx = find(Yeo2011RSN_masked_rh==netid);
    idxYeo2011RSN_rh{netid} = tmpidx;
    netnodenum_rh(netid) = numel(tmpidx);
end
netnodenum = netnodenum_lh + netnodenum_rh;
clear tmpidx
%block indices
idx_block_lh = []; idx_block_rh = [];
for netid=1:7
    start_lh = 1 + numel(idx_block_lh) + numel(idx_block_rh);
    end_lh = netnodenum_lh(netid) + numel(idx_block_lh) + numel(idx_block_rh);
    idx_block_lh = [idx_block_lh; (start_lh:end_lh)'];
    start_rh = 1 + end_lh;
    end_rh = netnodenum_rh(netid) + end_lh;
    idx_block_rh = [idx_block_rh; (start_rh:end_rh)'];
end
%surface centrality metrics
bolddc_lh = boldmean_lh; bolddc_rh = boldmean_rh; %dc
boldpc_lh = boldmean_lh; boldpc_rh = boldmean_rh; %pc
boldsc_lh = boldmean_lh; boldsc_rh = boldmean_rh; %sc
boldec_lh = boldmean_lh; boldec_rh = boldmean_rh; %ec

%% Loop subjects: the above surface metrics
for k=2:nsubs
    for sid=1:nscans
        func_dir_name = ['MNINonLinear/Results/' rest_name{sid}];
        if isnumeric(subs{k})
            disp(['Loading rfMRI for subject ' num2str(subs{k}) ': ' rest_name{sid} ' ...'])
            func_dir = [work_dir '/' num2str(subs{k}) '/' func_dir_name];
        else
            disp(['Loading rfMRI for subject ' subs{k} ': ' rest_name{sid} ' ...'])
            func_dir = [work_dir '/' subs{k} '/' func_dir_name];
        end
        % load bold time series
        fbold = [func_dir '/' rest_name{sid} ...
            '_Atlas_MSMAll_hp2000_clean.dtseries.nii'];
        boldts = ft_read_cifti(fbold);
        boldts_lh = boldts.dtseries(boldts.brainstructure==1,:);
        boldts_rh = boldts.dtseries(boldts.brainstructure==2,:);
        tslength = size(boldts_lh,2);
        clear boldts
        disp('compute mean and std ...')
        tmpmean = mean(boldts_lh(idxmask_lh,:),2); 
        tmpstd = std(boldts_lh(idxmask_lh,:),0,2);
        boldmean_lh(idxmask_lh,sid) = tmpmean;
        boldstd_lh(idxmask_lh,sid) = tmpstd;
        clear tmpmean tmpstd
        tmpmean = mean(boldts_rh(idxmask_rh,:),2); 
        tmpstd = std(boldts_rh(idxmask_rh,:),0,2);
        boldmean_rh(idxmask_rh,sid) = tmpmean;
        boldstd_rh(idxmask_rh,sid) = tmpstd;
        clear tmpmean tmpstd
        disp('compute alff and falff ...')
        [tmpalff, tmpfalff] = ccshcp_core_alffmat(boldts_lh(idxmask_lh,:)', 0.72);
        boldalff_lh(idxmask_lh,sid) = tmpalff;
        boldfalff_lh(idxmask_lh,sid) = tmpfalff;
        clear tmpalff tmpfalff
        [tmpalff, tmpfalff] = ccshcp_core_alffmat(boldts_rh(idxmask_rh,:)', 0.72);
        boldalff_rh(idxmask_rh,sid) = tmpalff;
        boldfalff_rh(idxmask_rh,sid) = tmpfalff;
        clear tmpalff tmpfalff
        disp('compute reho2 and reho4 ...')
        tmpreho2 = ccshcp_core_reho(boldts_lh', lh_nbrs(:,2));
        tmpreho4 = ccshcp_core_reho(boldts_lh', lh_nbrs(:,4));
        boldreho2_lh(:,sid) = tmpreho2;
        boldreho4_lh(:,sid) = tmpreho4;
        clear tmpreho2 tmpreho4
        tmpreho2 = ccshcp_core_reho(boldts_rh', rh_nbrs(:,2));
        tmpreho4 = ccshcp_core_reho(boldts_rh', rh_nbrs(:,4));
        boldreho2_rh(:,sid) = tmpreho2;
        boldreho4_rh(:,sid) = tmpreho4;
        clear tmpreho2 tmpreho4
        disp('compute pcc seed-based ifc ...')
        switch seedhemi{1}
            case 'lh'
                seed_ts = mean(boldts_lh(cell2mat(seeds{1}),:));
            case 'rh'
                seed_ts = mean(boldts_rh(cell2mat(seeds{1}),:));
            otherwise
                disp('Please assign the hemisphere for the seed.')
        end
        tmpifc = ccshcp_core_fastcorr(boldts_lh(idxmask_lh,:)', seed_ts');
        boldpcc_lh(idxmask_lh,sid) = tmpifc;
        tmpifc = ccshcp_core_fastcorr(boldts_rh(idxmask_rh,:)', seed_ts');
        boldpcc_rh(idxmask_rh,sid) = tmpifc;
        disp('compute sma seed-based ifc ...')
        switch seedhemi{2}
            case 'lh'
                seed_ts = mean(boldts_lh(cell2mat(seeds{2}),:));
            case 'rh'
                seed_ts = mean(boldts_rh(cell2mat(seeds{2}),:));
            otherwise
                disp('Please assign the hemisphere for the seed.')
        end
        tmpifc = ccshcp_core_fastcorr(boldts_lh(idxmask_lh,:)', seed_ts');
        boldsma_lh(idxmask_lh,sid) = tmpifc;
        tmpifc = ccshcp_core_fastcorr(boldts_rh(idxmask_rh,:)', seed_ts');
        boldsma_rh(idxmask_rh,sid) = tmpifc;
        disp('compute ips seed-based ifc ...')
        switch seedhemi{3}
            case 'lh'
                seed_ts = mean(boldts_lh(cell2mat(seeds{3}),:));
            case 'rh'
                seed_ts = mean(boldts_rh(cell2mat(seeds{3}),:));
            otherwise
                disp('Please assign the hemisphere for the seed.')
        end
        tmpifc = ccshcp_core_fastcorr(boldts_lh(idxmask_lh,:)', seed_ts');
        boldips_lh(idxmask_lh,sid) = tmpifc;
        tmpifc = ccshcp_core_fastcorr(boldts_rh(idxmask_rh,:)', seed_ts');
        boldips_rh(idxmask_rh,sid) = tmpifc;
        clear tmpifc
        disp('compute the vmhc ...')
        zboldlh_masked = zscore(boldts_lh(idxmask_hemi,:),1,2);
        zboldrh_masked = zscore(boldts_rh(idxmask_hemi,:),1,2);
        tmpvmhc = sum(zboldlh_masked.*zboldrh_masked,2)/tslength;
        boldvmhc(idxmask_hemi,sid) = tmpvmhc;
        clear zboldlh_masked zboldrh_masked tmpvmhc
        disp('compute dual regression ...')
        tp_regressors = zeros(tslength,7);%spatial
        tmpboldts = [boldts_lh; boldts_rh];
        for trID=1:tslength
            tmpY = tmpboldts(idxmask_brain,trID);
            tp_regressors(trID,:) = regress(tmpY, ...
                sp_regressors(idxmask_brain,:));
        end
        bolddrts(:,:,sid) = tp_regressors;
        network_maps = zeros(numVertices_mask,7);%temporal
        for vtxID=1:numVertices_mask
            tmpY = tmpboldts(idxmask_brain(vtxID),:);
            network_maps(vtxID,:) = regress(tmpY', tp_regressors);
        end
        tmprsn_lh = network_maps(1:numel(idxmask_lh),:);
        bolddrrsn_lh(idxmask_lh,:,sid) = tmprsn_lh;
        tmprsn_rh = network_maps((1+numel(idxmask_lh)):end,:);
        bolddrrsn_rh(idxmask_rh,:,sid) = tmprsn_rh;
        clear tmpY tmprsn_lh tmprsn_rh tp_regressors network_maps tmpboldts
        disp('compute network centrality ...')
        [fconnmat, yeo2011posmat, yeo2011negmat, corr_thr] = ...
            ccshcp_core_bwvgraph(boldts_lh, boldts_rh, ... 
            idxYeo2011RSN_lh, idxYeo2011RSN_rh, 0.1, 0);
        fconnmat = atanh(spdiags(zeros(sum(netnodenum),1),0,fconnmat)); %remove all 1s elements
        fconnmat(isinf(fconnmat)) = 0; %remove inf elements
        %dc
        tmpdc = ccshcp_core_dc(fconnmat);
        bolddc_lh(cell2mat(idxYeo2011RSN_lh),sid) = tmpdc(idx_block_lh);
        bolddc_rh(cell2mat(idxYeo2011RSN_rh),sid) = tmpdc(idx_block_rh);
        %ec and sc
        idx_fullconn = find(tmpdc>0); 
        tmpsc = zeros(size(tmpdc)); tmpec = zeros(size(tmpdc));
        [tmpec(idx_fullconn), tmpsc(idx_fullconn)] = ...
            ccshcp_core_scec(fconnmat(idx_fullconn,idx_fullconn), 'w');
        boldec_lh(cell2mat(idxYeo2011RSN_lh),sid) = tmpec(idx_block_lh);
        boldec_rh(cell2mat(idxYeo2011RSN_rh),sid) = tmpec(idx_block_rh);
        boldsc_lh(cell2mat(idxYeo2011RSN_lh),sid) = tmpsc(idx_block_lh);
        boldsc_rh(cell2mat(idxYeo2011RSN_rh),sid) = tmpsc(idx_block_rh);
        %pc
        tmppc = zeros(size(tmpdc));
        tmppc(idx_fullconn) = ccshcp_core_pc(fconnmat(idx_fullconn,idx_fullconn));
        boldpc_lh(cell2mat(idxYeo2011RSN_lh),sid) = tmppc(idx_block_lh);
        boldpc_rh(cell2mat(idxYeo2011RSN_rh),sid) = tmppc(idx_block_rh);
        clear tmpdc tmpec tmpsc tmppc
    end
    %save all maps
    fout = [ana_dir '/classic/' num2str(subs{k}) '.mat'];
    save(fout, 'boldmean_lh', 'boldmean_rh', 'boldstd_lh', 'boldstd_rh', ...
    	'boldalff_lh', 'boldalff_rh', 'boldfalff_lh', 'boldfalff_rh', ...
        'boldreho2_lh', 'boldreho2_rh', 'boldreho4_lh', 'boldreho4_rh', ...
        'boldpcc_lh', 'boldpcc_rh', 'boldsma_lh', 'boldsma_rh', ...
        'boldvmhc', 'bolddrrsn_lh', 'bolddrrsn_rh', 'bolddrts', ...
        'bolddc_lh', 'bolddc_rh', 'boldec_lh', 'boldec_rh', ...
        'boldsc_lh', 'boldsc_rh', 'boldpc_lh', 'boldpc_rh', ...
        'boldips_lh', 'boldips_rh', 'yeo2011posmat', 'yeo2011negmat')
end
