%% dir settings (may not usable fpr you and you have to change them...)
clear all; clc
ana_dir = '/Users/mac/Downloads/Frontiers_LaTeX_Templates/hcpdemo';
ccs_dir = '/Volumes/RAID5/CCS';
ccs_matlab = [ccs_dir '/matlab'];
ccs_vistool = [ccs_dir '/vistool'];
work_dir = '/Volumes/RAID5/u100HCP';
fs_home = '/opt/freesurfer51';
cifti_matlab = [ccs_dir '/extool/cifti'];
atlas_dir = [ccs_dir '/extool/hcpworkbench/resources/32k_ConteAtlas_v2'];
%Set up the path to matlab function in Freesurfer release
addpath(genpath(ccs_matlab)) %ccs matlab scripts
addpath(genpath(ccs_vistool)) %ccs matlab scripts
addpath(genpath(cifti_matlab)) %cifti paths
addpath(genpath([fs_home '/matlab'])) %freesurfer matlab scripts

%% Load Symmetric Surfaces
disp('Loading Conte69.inflated.32k_fs_LR surfaces ...')
%lh
fSURF = [atlas_dir '/Conte69.L.inflated.32k_fs_LR.surf.gii'];
lh_inflated = gifti(fSURF); numVertices_lh = size(lh_inflated.vertices,1); %lh
%make Conte69 surface structure
surfConte69_lh.tri = lh_inflated.faces;
surfConte69_lh.coord = lh_inflated.vertices'; 
%rh
fSURF = [atlas_dir '/Conte69.R.inflated.32k_fs_LR.surf.gii'];
rh_inflated = gifti(fSURF); numVertices_rh = size(rh_inflated.vertices,1); %rh
surfConte69_rh.tri = rh_inflated.faces;
surfConte69_rh.coord = rh_inflated.vertices';
%
disp('Loading Conte69.very_inflated.32k_fs_LR surfaces ...')
%lh
fSURF = [atlas_dir '/Conte69.L.very_inflated.32k_fs_LR.surf.gii'];
lh_vinflated = gifti(fSURF); 
surfvConte69_lh.tri = lh_vinflated.faces;
surfvConte69_lh.coord = lh_vinflated.vertices'; 
%rh
fSURF = [atlas_dir '/Conte69.R.very_inflated.32k_fs_LR.surf.gii'];
rh_vinflated = gifti(fSURF);
surfvConte69_rh.tri = rh_vinflated.faces;
surfvConte69_rh.coord = rh_vinflated.vertices';

%% Load Colormaps
fcolor = [ccs_dir '/vistool/coldcolors.tif'];
cmap_cold = ccs_mkcolormap(fcolor);
fcolor = [ccs_dir '/vistool/hotcolors.tif'];
cmap_hot = ccs_mkcolormap(fcolor); 
cmap_diff = [cmap_cold(end:-2:1,:); cmap_hot(1:2:end,:)];
cmap_diff([127 128 129],:) = 0.55; %cmap_mean(128,:) = 0.5;
%matplot default
cmap_viridis = viridis(256); 
fcolor = [ccs_dir '/vistool/fimages/PLASMA.png'];
cmap_plasma = ccs_mkcolormap(fcolor); 
%caret single direction
fcolor = [ccs_dir '/vistool/fimages/Purple-Red_Caret.tif'];
cmap_caret = ccs_mkcolormap(fcolor);
cmap_icc = cmap_caret;
cmap_icc(1:52,:) = 0.5; 
cmap_icc(20:32,:) = 0.25; %repmat([0 0 1],13,1);

%% Load network contour information and test
load([ccs_dir '/vistool/conte32k_yeo7networks_contour_lh.mat']);
load([ccs_dir '/vistool/conte32k_yeo7networks_contour_rh.mat']);

%% Prepare directory of Saving ReHo4 Surfaces
samplemap = load([ana_dir '/classic/R_output/boldreho4_with_IQ_CR.mat']);
if ~exist([ana_dir '/classic/figures/reho4'], 'dir')
    errmkdir = mkdir([ana_dir '/classic/figures'], 'reho4');
end
fig_dir = [ana_dir '/classic/figures/reho4'];

%% Group mean maps
tmpmap_lh = samplemap.metric_lgP_lh.*sign(samplemap.metric_t_lh);
tmpmap_rh = samplemap.metric_lgP_rh.*sign(samplemap.metric_t_rh);
cmin = 3; % uncorrected p < 0.001
tmpmap = [tmpmap_lh; tmpmap_rh];
cmax = 0.2*max(abs(tmpmap));
if cmax > cmin
    cint = round(128*cmin/cmax);
    idxhot = (128+cint+1):256;
    idxcool = 1:(128-cint-1);
    cmapcut_diff = cmap_plasma;
    cmapcut_diff((128-cint):(128+cint),:) = 0.5;%stopped here
    idxyeoc = (128+round(0.50*cint)-2):(128+round(0.50*cint)+2);
    cmapcut_diff(idxyeoc,:) = repmat([0.25 1 0.25],numel(idxyeoc),1);
    %render lh surfaces
    tmpmap_lh(abs(tmpmap_lh)<cmin) = 0;
    tmpmap_lh((rsncSurf_lh)==1) = 0.5*cmin;
    figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
    SurfStatView(tmpmap_lh, surfvConte69_lh, ' ', 'white', 'true'); 
    colormap(cmapcut_diff); SurfStatColLim([-cmax cmax]);
    set(gcf, 'PaperPositionMode', 'auto');
    figout = [fig_dir '/metric.logP.lh.png'];
    print('-dpng', '-r300', figout); close
    %render rh surfaces
    tmpmap_rh(abs(tmpmap_rh)<cmin) = 0;
    tmpmap_rh((rsncSurf_rh)==1) = 0.5*cmin;
    figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
    SurfStatView(tmpmap_rh, surfvConte69_rh, ' ', 'white', 'true'); 
    colormap(cmapcut_diff); SurfStatColLim([-cmax cmax]);
    set(gcf, 'PaperPositionMode', 'auto');
    figout = [fig_dir '/metric.logP.rh.png'];
    print('-dpng', '-r300', figout); close
end

%% inter-day icc maps
cmax = 1.0; cmin = 0.2; %range of color mapping
cmap_icc = cmap_plasma;
cmap_icc(1:52,:) = 0.5; 
cmap_icc(20:32,:) = 0.25;
tmpicc_lh = samplemap.icc_day_lh;
tmpicc_rh = samplemap.icc_day_rh;
%render lh surfaces
tmpicc_lh(abs(tmpicc_lh)<=cmin) = 0;
tmpicc_lh((rsncSurf_lh)==1) = 0.5*cmin;
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(tmpicc_lh, surfvConte69_lh, ' ', 'white', 'true'); 
colormap(cmap_icc); SurfStatColLim([0 cmax]);
set(gcf, 'PaperPositionMode', 'auto');
figout = [fig_dir '/icc.day.lh.png'];
print('-dpng', '-r300', figout); close
%rh: brainmap
tmpicc_rh(abs(tmpicc_rh)<=cmin) = 0;
tmpicc_rh((rsncSurf_rh)==1) = 0.5*cmin;
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(tmpicc_rh, surfvConte69_rh, ' ', 'white', 'true'); 
colormap(cmap_icc); SurfStatColLim([0 cmax]);
set(gcf, 'PaperPositionMode', 'auto');
figout = [fig_dir '/icc.day.rh.png'];
print('-dpng', '-r300', figout); close

%% inter-scan icc maps
tmpicc_lh = samplemap.icc_session_lh;
tmpicc_rh = samplemap.icc_session_rh;
%render lh surfaces
tmpicc_lh(abs(tmpicc_lh)<=cmin) = 0;
tmpicc_lh((rsncSurf_lh)==1) = 0.5*cmin;
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(tmpicc_lh, surfvConte69_lh, ' ', 'white', 'true'); 
colormap(cmap_icc); SurfStatColLim([0 cmax]);
set(gcf, 'PaperPositionMode', 'auto');
figout = [fig_dir '/icc.session.lh.png'];
print('-dpng', '-r300', figout); close
%rh: brainmap
tmpicc_rh(abs(tmpicc_rh)<=cmin) = 0;
tmpicc_rh((rsncSurf_rh)==1) = 0.5*cmin;
figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
SurfStatView(tmpicc_rh, surfvConte69_rh, ' ', 'white', 'true'); 
colormap(cmap_icc); SurfStatColLim([0 cmax]);
set(gcf, 'PaperPositionMode', 'auto');
figout = [fig_dir '/icc.session.rh.png'];
print('-dpng', '-r300', figout); close

%% sex effect maps
tmpmap_lh = samplemap.sex_lgP_lh.*sign(samplemap.sex_t_lh);
tmpmap_rh = samplemap.sex_lgP_rh.*sign(samplemap.sex_t_rh);
cmin = 3; % uncorrected p < 0.001
tmpmap = [tmpmap_lh; tmpmap_rh];
cmax = max(abs(tmpmap));
if cmax > cmin
    cint = round(128*cmin/cmax);
    idxhot = (128+cint+1):256;
    idxcool = 1:(128-cint-1);
    cmapcut_diff = cmap_plasma;
    cmapcut_diff((128-cint):(128+cint),:) = 0.5;%stopped here
    idxyeoc = (128+round(0.50*cint)-2):(128+round(0.50*cint)+2);
    cmapcut_diff(idxyeoc,:) = repmat([0.25 1 0.25],numel(idxyeoc),1);
    %render lh surfaces
    tmpmap_lh(abs(tmpmap_lh)<cmin) = 0;
    tmpmap_lh((rsncSurf_lh)==1) = 0.5*cmin;
    figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
    SurfStatView(tmpmap_lh, surfvConte69_lh, ' ', 'white', 'true'); 
    colormap(cmapcut_diff); SurfStatColLim([-cmax cmax]);
    set(gcf, 'PaperPositionMode', 'auto');
    figout = [fig_dir '/sex.logP.lh.png'];
    print('-dpng', '-r300', figout); close
    %render rh surfaces
    tmpmap_rh(abs(tmpmap_rh)<cmin) = 0;
    tmpmap_rh((rsncSurf_rh)==1) = 0.5*cmin;
    figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
    SurfStatView(tmpmap_rh, surfvConte69_rh, ' ', 'white', 'true'); 
    colormap(cmapcut_diff); SurfStatColLim([-cmax cmax]);
    set(gcf, 'PaperPositionMode', 'auto');
    figout = [fig_dir '/sex.logP.rh.png'];
    print('-dpng', '-r300', figout); close
end

%% IQ-CR effect maps
tmpmap_lh = samplemap.IQ_CR_lgP_lh.*sign(samplemap.IQ_CR_t_lh);
tmpmap_rh = samplemap.IQ_CR_lgP_rh.*sign(samplemap.IQ_CR_t_rh);
cmin = 3; % uncorrected p < 0.001
tmpmap = [tmpmap_lh; tmpmap_rh];
cmax = max(abs(tmpmap));
if cmax > cmin
    cint = round(128*cmin/cmax);
    idxhot = (128+cint+1):256;
    idxcool = 1:(128-cint-1);
    cmapcut_diff = cmap_plasma;
    cmapcut_diff((128-cint):(128+cint),:) = 0.5;%stopped here
    idxyeoc = (128+round(0.50*cint)-2):(128+round(0.50*cint)+2);
    cmapcut_diff(idxyeoc,:) = repmat([0.25 1 0.25],numel(idxyeoc),1);
    %render lh surfaces
    tmpmap_lh(abs(tmpmap_lh)<cmin) = 0;
    tmpmap_lh((rsncSurf_lh)==1) = 0.5*cmin;
    figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
    SurfStatView(tmpmap_lh, surfvConte69_lh, ' ', 'white', 'true'); 
    colormap(cmapcut_diff); SurfStatColLim([-cmax cmax]);
    set(gcf, 'PaperPositionMode', 'auto');
    figout = [fig_dir '/IQ_CR.logP.lh.png'];
    print('-dpng', '-r300', figout); close
    %render rh surfaces
    tmpmap_rh(abs(tmpmap_rh)<cmin) = 0;
    tmpmap_rh((rsncSurf_rh)==1) = 0.5*cmin;
    figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
    SurfStatView(tmpmap_rh, surfvConte69_rh, ' ', 'white', 'true'); 
    colormap(cmapcut_diff); SurfStatColLim([-cmax cmax]);
    set(gcf, 'PaperPositionMode', 'auto');
    figout = [fig_dir '/IQ_CR.logP.rh.png'];
    print('-dpng', '-r300', figout); close
end
