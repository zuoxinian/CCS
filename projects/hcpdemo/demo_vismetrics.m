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

%% Load Yeo2011 Seven Resting State Networks
%lh
fRSN = [ana_dir '/matlab/32k_ConteAtlas_v2/RSN-networks.L.32k_fs_LR.label.gii'];
lh_RSN = gifti(fRSN); labelRSN_lh = lh_RSN.labels; ctableRSN_lh = lh_RSN.cdata;
numName_lh = numel(labelRSN_lh.name);
Yeo2011RSN_lh = zeros(numVertices_lh,1); 
for mapID=1:7
    tmpname = ['7Networks_' num2str(mapID)];
    for nameID=1:numName_lh
        if strcmp(tmpname, labelRSN_lh.name{nameID})
            tmpIDX = find(ctableRSN_lh(:,1)==labelRSN_lh.key(nameID));
            Yeo2011RSN_lh(tmpIDX) = mapID;
        end
    end
end
%rh
fRSN = [ana_dir '/matlab/32k_ConteAtlas_v2/RSN-networks.R.32k_fs_LR.label.gii'];
rh_RSN = gifti(fRSN); labelRSN_rh = rh_RSN.labels; ctableRSN_rh = rh_RSN.cdata;
numName_rh = numel(labelRSN_rh.name);
Yeo2011RSN_rh = zeros(numVertices_rh,1); 
for mapID=1:7
    tmpname = ['7Networks_' num2str(mapID)];
    for nameID=1:numName_rh
        if strcmp(tmpname, labelRSN_rh.name{nameID})
            tmpIDX = find(ctableRSN_rh(:,1)==labelRSN_rh.key(nameID));
            Yeo2011RSN_rh(tmpIDX) = mapID;
        end
    end
end
% creat colors for the 7 networks
cmap_7networks = zeros(7,3);
for mapID=1:7
    tmpname = ['7Networks_' num2str(mapID)];
    for nameID=1:numName_lh
        if strcmp(tmpname, labelRSN_lh.name{nameID})
            tmpIDX = find(ctableRSN_lh(:,1)==labelRSN_lh.key(nameID));
            cmap_7networks(mapID,:) = labelRSN_lh.rgba(nameID,1:3);
        end
    end
end
%colormaps
cmap_mean = jet(256); cmap_mean(1,:) = 0.5;
cmap_fc = jet(256); cmap_fc(128:129,:) = 0.5;

%% Load Surface Metrics
samplemap = load([ana_dir '/classic/100307.mat']);

%% Compute and visualize mean maps
boldmean_lh = mean(samplemap.boldmean_lh,2);
boldmean_rh = mean(samplemap.boldmean_rh,2);
tmpmap = [boldmean_lh; boldmean_rh];
%lh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldmean_lh, surfConte69_lh, 'MEAN', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpmap)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/descstats/avgMean_Conte69_32K_lh.jpg';
print('-djpeg', '-r300', figout); close
%rh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldmean_rh, surfConte69_rh, 'MEAN', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpmap)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/descstats/avgMEAN_Conte69_32K_rh.jpg';
print('-djpeg', '-r300', figout); close

%% Compute and visualize std maps
boldstd_lh = mean(samplemap.boldstd_lh,2);
boldstd_rh = mean(samplemap.boldstd_rh,2);
tmpmap = [boldstd_lh; boldstd_rh];
%lh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldstd_lh, surfConte69_lh, 'STD', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpmap)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/descstats/avgSTD_Conte69_32K_lh.jpg';
print('-djpeg', '-r300', figout); close
%rh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldstd_rh, surfConte69_rh, 'STD', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpmap)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/descstats/avgSTD_Conte69_32K_rh.jpg';
print('-djpeg', '-r300', figout); close

%% Compute and visualize alff maps
boldalff_lh = mean(samplemap.boldalff_lh,2);
boldalff_rh = mean(samplemap.boldalff_rh,2);
tmpmap = [boldalff_lh; boldalff_rh];
%lh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldalff_lh, surfConte69_lh, 'ALFF', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpmap)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/lffmetrics/avgALFF_Conte69_32K_lh.jpg';
print('-djpeg', '-r300', figout); close
%rh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldalff_rh, surfConte69_rh, 'ALFF', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpmap)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/lffmetrics/avgALFF_Conte69_32K_rh.jpg';
print('-djpeg', '-r300', figout); close

%% Compute and visualize falff maps
boldfalff_lh = mean(samplemap.boldfalff_lh,2);
boldfalff_rh = mean(samplemap.boldfalff_rh,2);
tmpmap = [boldfalff_lh; boldfalff_rh];
%lh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldfalff_lh, surfConte69_lh, 'FALFF', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpmap)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/lffmetrics/avgFALFF_Conte69_32K_lh.jpg';
print('-djpeg', '-r300', figout); close
%rh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldfalff_rh, surfConte69_rh, 'FALFF', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpmap)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/lffmetrics/avgFALFF_Conte69_32K_rh.jpg';
print('-djpeg', '-r300', figout); close

%% Compute and visualize reho2 maps
boldreho2_lh = mean(samplemap.boldreho2_lh,2);
boldreho2_rh = mean(samplemap.boldreho2_rh,2);
tmpmap = [boldreho2_lh; boldreho2_rh];
%lh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldreho2_lh, surfConte69_lh, 'ReHo', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpmap)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/reho/avgReHo2_Conte69_32K_lh.jpg';
print('-djpeg', '-r300', figout); close
%rh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldreho2_rh, surfConte69_rh, 'ReHo', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpmap)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/reho/avgReHo2_Conte69_32K_rh.jpg';
print('-djpeg', '-r300', figout); close

%% Compute and visualize reho4 maps
boldreho4_lh = mean(samplemap.boldreho4_lh,2);
boldreho4_rh = mean(samplemap.boldreho4_rh,2);
tmpmap = [boldreho4_lh; boldreho4_rh];
%lh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldreho4_lh, surfConte69_lh, 'ReHo', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpmap)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/reho/avgReHo4_Conte69_32K_lh.jpg';
print('-djpeg', '-r300', figout); close
%rh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldreho4_rh, surfConte69_rh, 'ReHo', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpmap)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/reho/avgReHo4_Conte69_32K_rh.jpg';
print('-djpeg', '-r300', figout); close

%% Compute and visualize pcc ifc maps
boldpcc_lh = mean(samplemap.boldpcc_lh,2);
boldpcc_rh = mean(samplemap.boldpcc_rh,2);
tmpmap = [boldpcc_lh; boldpcc_rh]; cmax = max(abs(tmpmap));
%lh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldpcc_lh, surfConte69_lh, 'iFC'); 
colormap(cmap_fc); SurfStatColLim([-cmax cmax]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/seedfc/avgPCC_Conte69_32K_lh.jpg';
print('-djpeg', '-r300', figout); close
%rh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldpcc_rh, surfConte69_rh, 'iFC'); 
colormap(cmap_fc); SurfStatColLim([-cmax cmax]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/seedfc/avgPCC_Conte69_32K_rh.jpg';
print('-djpeg', '-r300', figout); close

%% Compute and visualize sma ifc maps
boldsma_lh = mean(samplemap.boldsma_lh,2);
boldsma_rh = mean(samplemap.boldsma_rh,2);
tmpmap = [boldsma_lh; boldsma_rh]; cmax = max(abs(tmpmap));
%lh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldsma_lh, surfConte69_lh, 'iFC'); 
colormap(cmap_fc); SurfStatColLim([-cmax cmax]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/seedfc/avgSMA_Conte69_32K_lh.jpg';
print('-djpeg', '-r300', figout); close
%rh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldsma_rh, surfConte69_rh, 'iFC'); 
colormap(cmap_fc); SurfStatColLim([-cmax cmax]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/seedfc/avgSMA_Conte69_32K_rh.jpg';
print('-djpeg', '-r300', figout); close

%% Compute and visualize ips ifc maps
boldips_lh = mean(samplemap.boldips_lh,2);
boldips_rh = mean(samplemap.boldips_rh,2);
tmpmap = [boldips_lh; boldips_rh]; cmax = max(abs(tmpmap));
%lh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldips_lh, surfConte69_lh, 'iFC'); 
colormap(cmap_fc); SurfStatColLim([-cmax cmax]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/seedfc/avgIPS_Conte69_32K_lh.jpg';
print('-djpeg', '-r300', figout); close
%rh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldips_rh, surfConte69_rh, 'iFC'); 
colormap(cmap_fc); SurfStatColLim([-cmax cmax]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/seedfc/avgIPS_Conte69_32K_rh.jpg';
print('-djpeg', '-r300', figout); close

%% Compute and visualize vmhc maps
boldvmhc = mean(samplemap.boldvmhc,2);
cmax = max(abs(boldvmhc));
%lh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldvmhc, surfConte69_lh, 'VMHC'); 
colormap(cmap_fc); SurfStatColLim([-cmax cmax]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/vmhc/avgVMHC_Conte69_32K.jpg';
print('-djpeg', '-r300', figout); close

%% Compute and visualize DR maps
for netID=1:7
    bolddrrsn_lh = mean(squeeze(samplemap.bolddrrsn_lh(:,netID)),2);
    bolddrrsn_rh = mean(squeeze(samplemap.bolddrrsn_rh(:,netID)),2);
    tmpmap = [bolddrrsn_lh; bolddrrsn_rh];
    cmax = max(abs(tmpmap));
    %lh
    figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
    SurfStatView(bolddrrsn_lh, surfConte69_lh, 'dr ifc'); 
    colormap(cmap_fc); SurfStatColLim([-cmax cmax]);
    set(gcf, 'PaperPositionMode', 'auto');
    figout = ['figures/dualregression/avgRSN' num2str(netID) ...
        '_Conte69_32K_lh.jpg'];
    print('-djpeg', '-r300', figout); close
    %rh
    figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
    SurfStatView(bolddrrsn_rh, surfConte69_rh, 'dr ifc'); 
    colormap(cmap_fc); SurfStatColLim([-cmax cmax]);
    set(gcf, 'PaperPositionMode', 'auto');
    figout = ['figures/dualregression/avgRSN' num2str(netID) ...
        '_Conte69_32K_rh.jpg'];
    print('-djpeg', '-r300', figout); close
end

%% Compute and visualize network degree centrality maps
bolddc_lh = mean(samplemap.bolddc_lh,2);
bolddc_rh = mean(samplemap.bolddc_rh,2);
tmpmap = [bolddc_lh; bolddc_rh];
%lh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(bolddc_lh, surfConte69_lh, 'DC', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpmap)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/centrality/avgDC_Conte69_32K_lh.jpg';
print('-djpeg', '-r300', figout); close
%rh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(bolddc_rh, surfConte69_rh, 'DC', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpmap)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/centrality/avgDC_Conte69_32K_rh.jpg';
print('-djpeg', '-r300', figout); close

%% Compute and visualize network eigenvector centrality maps
boldec_lh = mean(samplemap.boldec_lh,2);
boldec_rh = mean(samplemap.boldec_rh,2);
tmpmap = [boldec_lh; boldec_rh];
%lh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldec_lh, surfConte69_lh, 'EC', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpmap)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/centrality/avgEC_Conte69_32K_lh.jpg';
print('-djpeg', '-r300', figout); close
%rh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldec_rh, surfConte69_rh, 'EC', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpmap)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/centrality/avgEC_Conte69_32K_rh.jpg';
print('-djpeg', '-r300', figout); close

%% Compute and visualize network subgraph centrality maps
boldsc_lh = mean(samplemap.boldsc_lh,2);
boldsc_rh = mean(samplemap.boldsc_rh,2);
tmpmap = [boldsc_lh; boldsc_rh];
%lh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldsc_lh, surfConte69_lh, 'SC', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 0.05*max(tmpmap)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/centrality/avgSC_Conte69_32K_lh.jpg';
print('-djpeg', '-r300', figout); close
%rh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldsc_rh, surfConte69_rh, 'SC', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 0.05*max(tmpmap)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/centrality/avgSC_Conte69_32K_rh.jpg';
print('-djpeg', '-r300', figout); close

%% Compute and visualize network Google pagerank centrality maps
boldpc_lh = mean(samplemap.boldpc_lh,2);
boldpc_rh = mean(samplemap.boldpc_rh,2);
tmpmap = [boldpc_lh; boldpc_rh];
%lh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldpc_lh, surfConte69_lh, 'PC', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpmap)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/centrality/avgPC_Conte69_32K_lh.jpg';
print('-djpeg', '-r300', figout); close
%rh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldpc_rh, surfConte69_rh, 'PC', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpmap)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/centrality/avgPC_Conte69_32K_rh.jpg';
print('-djpeg', '-r300', figout); close
