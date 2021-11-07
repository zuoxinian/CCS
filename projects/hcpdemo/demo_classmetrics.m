%% dir settings (may not usable fpr you and you have to change them...)
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

%% Load Symmetric Surfaces
fSURF = [ana_dir '/matlab/32k_ConteAtlas_v2/Conte69.L.inflated.32k_fs_LR.surf.gii'];
lh_inflated = gifti(fSURF); numVertices_lh = size(lh_inflated.vertices,1); %lh
%make Conte69 surface structure
surfConte69_lh.tri = lh_inflated.faces;
surfConte69_lh.coord = lh_inflated.vertices'; 
%rh
fSURF = [ana_dir '/matlab/32k_ConteAtlas_v2/Conte69.R.inflated.32k_fs_LR.surf.gii'];
rh_inflated = gifti(fSURF); numVertices_rh = size(rh_inflated.vertices,1); %rh
surfConte69_rh.tri = rh_inflated.faces;
surfConte69_rh.coord = rh_inflated.vertices'; 

%% Load group masks
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

%% Load BOLD time series
rest_name = {'rfMRI_REST1_LR', 'rfMRI_REST1_RL', ...
    'rfMRI_REST2_LR', 'rfMRI_REST2_RL'}; 
nscans = numel(rest_name);
func_dir_name = ['MNINonLinear/Results/' rest_name{1}];
func_dir = [work_dir '/100307/' func_dir_name];
fbold = [func_dir '/' rest_name{1} '_Atlas_MSMAll_hp2000_clean.dtseries.nii'];
boldts = ft_read_cifti(fbold);
boldts_lh = boldts.dtseries(boldts.brainstructure==1,:);
boldts_rh = boldts.dtseries(boldts.brainstructure==2,:);
tslength = size(boldts_lh,2); clear boldts

%% Compute MEAN and STD maps
boldmean_lh = zeros(numVertices_lh,1); %mean
boldmean_rh = zeros(numVertices_rh,1); 
boldstd_lh = boldmean_lh; %std
boldstd_rh = boldmean_rh;
%compute
tmpmean = mean(boldts_lh(idxmask_lh,:),2); 
tmpstd = std(boldts_lh(idxmask_lh,:),0,2);
boldmean_lh(idxmask_lh,1) = tmpmean;
boldstd_lh(idxmask_lh,1) = tmpstd;
clear tmpmean tmpstd
tmpmean = mean(boldts_rh(idxmask_rh,:),2); 
tmpstd = std(boldts_rh(idxmask_rh,:),0,2);
boldmean_rh(idxmask_rh,1) = tmpmean;
boldstd_rh(idxmask_rh,1) = tmpstd;
clear tmpmean tmpstd
%visualization: mean
cmap_mean = jet(256); cmap_mean(1,:) = 0.5;
tmpmean = [boldmean_lh; boldmean_rh];
%lh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldmean_lh, surfConte69_lh, 'mean', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpmean)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/descstats/mean_Conte69_32K_lh.jpg';
print('-djpeg', '-r300', figout); close
%rh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldmean_rh, surfConte69_rh, 'mean', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpmean)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/descstats/mean_Conte69_32K_rh.jpg';
print('-djpeg', '-r300', figout); close
%visualization: std
tmpstd = [boldstd_lh; boldstd_rh];
%lh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldstd_lh, surfConte69_lh, 'std', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpstd)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/descstats/std_Conte69_32K_lh.jpg';
print('-djpeg', '-r300', figout); close
%rh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldstd_rh, surfConte69_rh, 'std', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpstd)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/descstats/std_Conte69_32K_rh.jpg';
print('-djpeg', '-r300', figout); close

%% Compute ALFF and FALFF maps
boldalff_lh = zeros(numVertices_lh,1); %alff
boldalff_rh = zeros(numVertices_rh,1); 
boldfalff_lh = boldalff_lh; %falff
boldfalff_rh = boldalff_rh;
%compute
[tmpalff, tmpfalff] = ccshcp_core_alffmat(boldts_lh(idxmask_lh,:)', 0.72);
boldalff_lh(idxmask_lh) = tmpalff;
boldfalff_lh(idxmask_lh) = tmpfalff;
clear tmpalff tmpfalff
[tmpalff, tmpfalff] = ccshcp_core_alffmat(boldts_rh(idxmask_rh,:)', 0.72);
boldalff_rh(idxmask_rh) = tmpalff;
boldfalff_rh(idxmask_rh) = tmpfalff;
clear tmpalff tmpfalff
%visualization: alff
tmpalff = [boldalff_lh; boldalff_rh];
%lh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldalff_lh, surfConte69_lh, 'alff', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpalff)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/lffmetrics/alff_Conte69_32K_lh.jpg';
print('-djpeg', '-r300', figout); close
%rh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldalff_rh, surfConte69_rh, 'alff', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpalff)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/lffmetrics/alff_Conte69_32K_rh.jpg';
print('-djpeg', '-r300', figout); close
%visualization: falff
tmpfalff = [boldfalff_lh; boldfalff_rh];
%lh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldfalff_lh, surfConte69_lh, 'falff', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpfalff)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/lffmetrics/falff_Conte69_32K_lh.jpg';
print('-djpeg', '-r300', figout); close
%rh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldfalff_rh, surfConte69_rh, 'falff', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpfalff)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/lffmetrics/falff_Conte69_32K_rh.jpg';
print('-djpeg', '-r300', figout); close

%% Compute REHO2 and REHO4 maps
boldreho2_lh = zeros(numVertices_lh,1); %alff
boldreho2_rh = zeros(numVertices_rh,1); 
boldfreho4_lh = boldreho2_lh; %falff
boldfreho4_rh = boldreho2_rh;
%compute
load([ana_dir '/matlab/Conte69_surfgraph_nbrs.mat']) %reho nbrs
boldreho2_lh = ccshcp_core_reho(boldts_lh', lh_nbrs(:,2));
boldreho4_lh = ccshcp_core_reho(boldts_lh', lh_nbrs(:,4));
boldreho2_rh = ccshcp_core_reho(boldts_rh', rh_nbrs(:,2));
boldreho4_rh = ccshcp_core_reho(boldts_rh', rh_nbrs(:,4));
%visualization: reho2
tmpreho = [boldreho2_lh; boldreho2_rh];
%lh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldreho2_lh, surfConte69_lh, 'reho', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpreho)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/reho/reho2_Conte69_32K_lh.jpg';
print('-djpeg', '-r300', figout); close
%rh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldreho2_rh, surfConte69_rh, 'reho', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpreho)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/reho/reho2_Conte69_32K_rh.jpg';
print('-djpeg', '-r300', figout); close
%visualization: reho4
tmpreho = [boldreho4_lh; boldreho4_rh];
%lh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldreho4_lh, surfConte69_lh, 'reho', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpreho)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/reho/reho4_Conte69_32K_lh.jpg';
print('-djpeg', '-r300', figout); close
%rh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldreho4_rh, surfConte69_rh, 'reho', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpreho)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/reho/reho4_Conte69_32K_rh.jpg';
print('-djpeg', '-r300', figout); close

%% Compute seed-based iFC
tmpfc_lh = zeros(numVertices_lh,1); tmpfc_rh = zeros(numVertices_rh,1); 
boldpcc_lh = tmpfc_lh; boldpcc_rh = tmpfc_rh; %pcc-ifc
boldsma_lh = tmpfc_lh; boldsma_rh = tmpfc_rh; %sma-ifc
boldips_lh = tmpfc_lh; boldips_rh = tmpfc_rh; %ips-ifc
clear tmpfc_lh tmpfc_rh
%get seeds on the surface
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
% compute pcc seed-based ifc
switch seedhemi{1}
    case 'lh'
        seed_ts = mean(boldts_lh(cell2mat(seeds{1}),:));
    case 'rh'
    	seed_ts = mean(boldts_rh(cell2mat(seeds{1}),:));
    otherwise
        disp('Please assign the hemisphere for the seed.')
end
tmpifc = ccshcp_core_fastcorr(boldts_lh(idxmask_lh,:)', seed_ts');
boldpcc_lh(idxmask_lh) = tmpifc;
tmpifc = ccshcp_core_fastcorr(boldts_rh(idxmask_rh,:)', seed_ts');
boldpcc_rh(idxmask_rh) = tmpifc;
%visualization: pcc
tmpfc = [boldpcc_lh; boldpcc_rh];
cmap_fc = jet(256); cmap_fc(128:129,:) = 0.5;
cmax = max(abs(tmpfc));
%lh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldpcc_lh, surfConte69_lh, 'pcc ifc'); 
colormap(cmap_fc); SurfStatColLim([-cmax cmax]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/seedfc/pccFC_Conte69_32K_lh.jpg';
print('-djpeg', '-r300', figout); close
%rh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldpcc_rh, surfConte69_rh, 'pcc ifc'); 
colormap(cmap_fc); SurfStatColLim([-cmax cmax]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/seedfc/pccFC_Conte69_32K_rh.jpg';
print('-djpeg', '-r300', figout); close
% compute sma seed-based ifc
switch seedhemi{2}
    case 'lh'
        seed_ts = mean(boldts_lh(cell2mat(seeds{2}),:));
    case 'rh'
    	seed_ts = mean(boldts_rh(cell2mat(seeds{2}),:));
    otherwise
        disp('Please assign the hemisphere for the seed.')
end
tmpifc = ccshcp_core_fastcorr(boldts_lh(idxmask_lh,:)', seed_ts');
boldsma_lh(idxmask_lh) = tmpifc;
tmpifc = ccshcp_core_fastcorr(boldts_rh(idxmask_rh,:)', seed_ts');
boldsma_rh(idxmask_rh) = tmpifc;
%visualization: pcc
tmpfc = [boldsma_lh; boldsma_rh];
cmax = max(abs(tmpfc));
%lh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldsma_lh, surfConte69_lh, 'sma ifc'); 
colormap(cmap_fc); SurfStatColLim([-cmax cmax]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/seedfc/smaFC_Conte69_32K_lh.jpg';
print('-djpeg', '-r300', figout); close
%rh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldsma_rh, surfConte69_rh, 'sma ifc'); 
colormap(cmap_fc); SurfStatColLim([-cmax cmax]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/seedfc/smaFC_Conte69_32K_rh.jpg';
print('-djpeg', '-r300', figout); close
% compute ips seed-based ifc
switch seedhemi{3}
    case 'lh'
        seed_ts = mean(boldts_lh(cell2mat(seeds{3}),:));
    case 'rh'
    	seed_ts = mean(boldts_rh(cell2mat(seeds{3}),:));
    otherwise
        disp('Please assign the hemisphere for the seed.')
end
tmpifc = ccshcp_core_fastcorr(boldts_lh(idxmask_lh,:)', seed_ts');
boldips_lh(idxmask_lh) = tmpifc;
tmpifc = ccshcp_core_fastcorr(boldts_rh(idxmask_rh,:)', seed_ts');
boldips_rh(idxmask_rh) = tmpifc;
%visualization: ips
tmpfc = [boldips_lh; boldips_rh];
cmax = max(abs(tmpfc));
%lh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldips_lh, surfConte69_lh, 'ips ifc'); 
colormap(cmap_fc); SurfStatColLim([-cmax cmax]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/seedfc/ipsFC_Conte69_32K_lh.jpg';
print('-djpeg', '-r300', figout); close
%rh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldips_rh, surfConte69_rh, 'ips ifc'); 
colormap(cmap_fc); SurfStatColLim([-cmax cmax]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/seedfc/ipsFC_Conte69_32K_rh.jpg';
print('-djpeg', '-r300', figout); close

%% Compute VMHC maps
boldvmhc_lh = zeros(numVertices_lh,1); boldvmhc_rh = zeros(numVertices_rh,1);
zboldlh_masked = zscore(boldts_lh(idxmask_hemi,:),1,2);
zboldrh_masked = zscore(boldts_rh(idxmask_hemi,:),1,2);
tmpvmhc = sum(zboldlh_masked.*zboldrh_masked,2)/tslength;
boldvmhc(idxmask_hemi) = tmpvmhc;
clear zboldlh_masked zboldrh_masked tmpvmhc
%visualization
cmax = max(abs(boldvmhc));
%lh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldvmhc, surfConte69_lh, 'vmhc'); 
colormap(cmap_fc); SurfStatColLim([-cmax cmax]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/vmhc/vmhc_Conte69_32K.jpg';
print('-djpeg', '-r300', figout); close

%% Compute DUAL REGRESSION maps
fRSN = [ana_dir '/matlab/32k_ConteAtlas_v2/RSN-networks.L.32k_fs_LR.label.gii'];
lh_RSN = gifti(fRSN); labelRSN_lh = lh_RSN.labels; ctableRSN_lh = lh_RSN.cdata;
fRSN = [ana_dir '/matlab/32k_ConteAtlas_v2/RSN-networks.R.32k_fs_LR.label.gii'];
rh_RSN = gifti(fRSN); labelRSN_rh = rh_RSN.labels; ctableRSN_rh = rh_RSN.cdata;
%CI maps
fCI = [ana_dir '/matlab/32k_ConteAtlas_v2/Yeo2011_7NetworksConfidence_N1000.L.32k_fs_LR.gii'];
lh_CI = gifti(fCI); CI_lh = lh_CI.cdata;
fCI = [ana_dir '/matlab/32k_ConteAtlas_v2/Yeo2011_7NetworksConfidence_N1000.R.32k_fs_LR.gii'];
rh_CI = gifti(fCI); CI_rh = rh_CI.cdata;
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
bolddrts = zeros(1200,7); %time series
% compute dual regression
tp_regressors = zeros(tslength,7);%spatial
tmpboldts = [boldts_lh; boldts_rh];
for trID=1:tslength
    tmpY = tmpboldts(idxmask_brain,trID);
    tp_regressors(trID,:) = regress(tmpY, ...
        sp_regressors(idxmask_brain,:));
end
bolddrts(:,:) = tp_regressors;
network_maps = zeros(numVertices_mask,7);%temporal
for vtxID=1:numVertices_mask
    tmpY = tmpboldts(idxmask_brain(vtxID),:);
    network_maps(vtxID,:) = regress(tmpY', tp_regressors);
end
bolddrrsn_lh = zeros(numVertices_lh,7); %spatial networks
bolddrrsn_rh = zeros(numVertices_rh,7);
tmprsn_lh = network_maps(1:numel(idxmask_lh),:);
bolddrrsn_lh(idxmask_lh,:) = tmprsn_lh;
tmprsn_rh = network_maps((1+numel(idxmask_lh)):end,:);
bolddrrsn_rh(idxmask_rh,:) = tmprsn_rh;
clear tmpY tp_regressors network_maps
% visualization
for netID=1:7
    tmpfc = [bolddrrsn_lh(:,netID); bolddrrsn_rh(:,netID)];
    cmax = max(abs(tmpfc));
    %lh
    figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
    SurfStatView(bolddrrsn_lh(:,netID), surfConte69_lh, 'dr ifc'); 
    colormap(cmap_fc); SurfStatColLim([-cmax cmax]);
    set(gcf, 'PaperPositionMode', 'auto');
    figout = ['figures/dualregression/RSN' num2str(netID) ...
        '_Conte69_32K_lh.jpg'];
    print('-djpeg', '-r300', figout); close
    %rh
    figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
    SurfStatView(bolddrrsn_rh(:,netID), surfConte69_rh, 'dr ifc'); 
    colormap(cmap_fc); SurfStatColLim([-cmax cmax]);
    set(gcf, 'PaperPositionMode', 'auto');
    figout = ['figures/dualregression/RSN' num2str(netID) ...
        '_Conte69_32K_rh.jpg'];
    print('-djpeg', '-r300', figout); close
end
