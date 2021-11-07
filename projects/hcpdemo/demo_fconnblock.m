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
% creat colormap
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

%% Visualization of Yeo2011 7Networks
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(Yeo2011RSN_lh, surfConte69_lh, '7RSN', 'white', 'true'); 
colormap([[0.5 0.5 0.5]; cmap_7networks]); SurfStatColLim([-0.5 7.5]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/yeo2011networks/7RSN_Conte69_32K_lh.jpg';
print('-djpeg', '-r300', figout); close
%rh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(Yeo2011RSN_rh, surfConte69_rh, '7RSN', 'white', 'true'); 
colormap([[0.5 0.5 0.5]; cmap_7networks]); SurfStatColLim([-0.5 7.5]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/yeo2011networks/7RSN_Conte69_32K_rh.jpg';
print('-djpeg', '-r300', figout); close

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

%% Visualization of Brain Masks
%lh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(grpmask_lh, surfConte69_lh, 'brain', 'white', 'true'); 
colormap([[0.5 0.5 0.5]; [1 0 0]]); SurfStatColLim([-0.5 1.5]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/brainmasks/grpmask_Conte69_32K_lh.jpg';
print('-djpeg', '-r300', figout); close
%rh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(grpmask_rh, surfConte69_rh, 'brain', 'white', 'true'); 
colormap([[0.5 0.5 0.5]; [1 0 0]]); SurfStatColLim([-0.5 1.5]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/brainmasks/grpmask_Conte69_32K_rh.jpg';
print('-djpeg', '-r300', figout); close

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

%% Block-wise computation
Yeo2011RSN_masked_lh = Yeo2011RSN_lh.*grpmask_lh;
idxYeo2011RSN_lh = cell(7,1); netnodenum_lh = zeros(7,1);
for netid=1:7
    tmpidx = find(Yeo2011RSN_masked_lh==netid);
    idxYeo2011RSN_lh{netid} = tmpidx;
    netnodenum_lh(netid) = numel(tmpidx);
end
Yeo2011RSN_masked_rh = Yeo2011RSN_rh.*grpmask_rh;
idxYeo2011RSN_rh = cell(7,1); netnodenum_rh = zeros(7,1);
for netid=1:7
    tmpidx = find(Yeo2011RSN_masked_rh==netid);
    idxYeo2011RSN_rh{netid} = tmpidx;
    netnodenum_rh(netid) = numel(tmpidx);
end
netnodenum = netnodenum_lh + netnodenum_rh;
% get idx for blocks
idx_block_lh = []; idx_block_rh = [];
for netid=1:7
    start_lh = 1 + numel(idx_block_lh) + numel(idx_block_rh);
    end_lh = netnodenum_lh(netid) + numel(idx_block_lh) + numel(idx_block_rh);
    idx_block_lh = [idx_block_lh; (start_lh:end_lh)'];
    start_rh = 1 + end_lh;
    end_rh = netnodenum_rh(netid) + end_lh;
    idx_block_rh = [idx_block_rh; (start_rh:end_rh)'];
end
%perform block-wise vertex graph computation
[fconnmat, yeo2011posmat, yeo2011negmat, corr_thr] = ...
    ccshcp_core_bwvgraph(boldts_lh, boldts_rh, ...
    idxYeo2011RSN_lh, idxYeo2011RSN_rh, 0.1, 0);

%% Plot blocks
for netidII=1:7
    for netidJJ=1:netidII
        tmpcolor = 0.5*(cmap_7networks(netidII,:)+cmap_7networks(netidJJ,:));
        tmpcorr = blockmat{netidII, netidJJ}; tmpcorr(tmpcorr>0)=1;
        figure('Units', 'pixels', 'Position', ...
            [100 100 round(netnodenum(netidJJ)/10) ...
            round(netnodenum(netidII)/10)]); hold on;
        axis equal; axes('position', [0 0 1 1]); axis off; 
        spy(tmpcorr,0); xch = get(gca, 'children'); set(xch, 'color', tmpcolor);
        set(gcf, 'PaperPositionMode', 'auto');
        print('-dtiff', ['figures/networkblocks/network.block' num2str(netidII) ...
            num2str(netidJJ) '.tif'])
        close;
    end
end

%% Compute and visualize network degree centrality maps
fconnmat = atanh(spdiags(zeros(sum(netnodenum),1),0,fconnmat)); %remove all 1s elements
fconnmat(isinf(fconnmat)) = 0; %need to revise ccs_core_fastCoRR.m
%calculate DC
tmpdc = ccshcp_core_dc(fconnmat);
if nnz(tmpdc)<length(tmpdc)
    full_graph = 0;
else
	full_graph = 1;
end
bolddc_lh = zeros(numVertices_lh,1);
bolddc_lh(cell2mat(idxYeo2011RSN_lh)) = tmpdc(idx_block_lh);
bolddc_rh = zeros(numVertices_rh,1);
bolddc_rh(cell2mat(idxYeo2011RSN_rh)) = tmpdc(idx_block_rh);
%visualization
cmap_mean = jet(256); cmap_mean(1,:) = 0.5;
%lh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(bolddc_lh, surfConte69_lh, 'DC', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpdc)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/centrality/DC_Conte69_32K_lh.jpg';
print('-djpeg', '-r300', figout); close
%rh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(bolddc_rh, surfConte69_rh, 'DC', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpdc)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/centrality/DC_Conte69_32K_rh.jpg';
print('-djpeg', '-r300', figout); close

%% Compute and visualize network subgraph centrality maps
idx_fullconn = find(tmpdc>0); tmpsc = zeros(size(tmpdc));
tmpsc(idx_fullconn) = ccshcp_core_sc(fconnmat(idx_fullconn,idx_fullconn), 'w');
boldsc_lh = zeros(numVertices_lh,1);
boldsc_lh(cell2mat(idxYeo2011RSN_lh)) = tmpsc(idx_block_lh);
boldsc_rh = zeros(numVertices_rh,1);
boldsc_rh(cell2mat(idxYeo2011RSN_rh)) = tmpsc(idx_block_rh);
%visualization
cmap_mean = jet(256); cmap_mean(1,:) = 0.5;
%lh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldsc_lh, surfConte69_lh, 'SC', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 0.05*max(tmpsc)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/centrality/SC_Conte69_32K_lh.jpg';
print('-djpeg', '-r300', figout); close
%rh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldsc_rh, surfConte69_rh, 'SC', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 0.05*max(tmpsc)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/centrality/SC_Conte69_32K_rh.jpg';
print('-djpeg', '-r300', figout); close

%% Compute and visualize network eigenvector centrality maps
idx_fullconn = find(tmpdc>0); tmpec = zeros(size(tmpdc));
tmpec(idx_fullconn) = ccshcp_core_ec(fconnmat(idx_fullconn,idx_fullconn));
boldec_lh = zeros(numVertices_lh,1);
boldec_lh(cell2mat(idxYeo2011RSN_lh)) = tmpec(idx_block_lh);
boldec_rh = zeros(numVertices_rh,1);
boldec_rh(cell2mat(idxYeo2011RSN_rh)) = tmpec(idx_block_rh);
%visualization
cmap_mean = jet(256); cmap_mean(1,:) = 0.5;
%lh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldec_lh, surfConte69_lh, 'EC', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpec)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/centrality/EC_Conte69_32K_lh.jpg';
print('-djpeg', '-r300', figout); close
%rh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldec_rh, surfConte69_rh, 'EC', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmpec)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/centrality/EC_Conte69_32K_rh.jpg';
print('-djpeg', '-r300', figout); close

%% Compute and visualize network Google pagerank centrality maps
idx_fullconn = find(tmpdc>0); tmppc = zeros(size(tmpdc));
tmppc(idx_fullconn) = ccshcp_core_pc(fconnmat(idx_fullconn,idx_fullconn));
boldpc_lh = zeros(numVertices_lh,1);
boldpc_lh(cell2mat(idxYeo2011RSN_lh)) = tmppc(idx_block_lh);
boldpc_rh = zeros(numVertices_rh,1);
boldpc_rh(cell2mat(idxYeo2011RSN_rh)) = tmppc(idx_block_rh);
%visualization
cmap_mean = jet(256); cmap_mean(1,:) = 0.5;
%lh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldpc_lh, surfConte69_lh, 'PC', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmppc)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/centrality/PC_Conte69_32K_lh.jpg';
print('-djpeg', '-r300', figout); close
%rh
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(boldpc_rh, surfConte69_rh, 'PC', 'white', 'true'); 
colormap(cmap_mean); SurfStatColLim([0 max(tmppc)]);
set(gcf, 'PaperPositionMode', 'auto');
figout = 'figures/centrality/PC_Conte69_32K_rh.jpg';
print('-djpeg', '-r300', figout); close
