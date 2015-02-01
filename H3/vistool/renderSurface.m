%% dir settings (may not usable fpr you and you have to change them...)
clear all; clc
ana_dir ='/Users/casfconn/Documents/Papers/Preparation/2dReHo/ASD/draft';
ccs_dir = '/Opt/CCS';
ccs_matlab_dir = [ccs_dir '/matlab'];
addpath(genpath(ccs_matlab_dir));
fs_home = '/opt/freesurfer';
addpath(genpath([fs_home '/matlab']));
vis_tool_dir = '/Users/casfconn/Documents/CoRR/SDATA/!pool/ccs_vistool';
fig_dir = [ana_dir '/figures'];
fsaverage = 'fsaverage5';

%% Read hemi surfaces
FS_lh = SurfStatReadSurf({[fs_home '/subjects/' fsaverage ...
    '/surf/lh.inflated']} );
FS_rh = SurfStatReadSurf({[fs_home '/subjects/' fsaverage ...
    '/surf/rh.inflated']} );

%% The Patients VS. Controls
fcolor = [vis_tool_dir '/fimages/FireIce.tif'];
cmap = ccs_mkcolormap(fcolor); cmap(128:129,:) = 0.5;
load([ana_dir '/matrix/sig_group.mat'])
sig_lh = sig_group(1:numel(sig_group)/2);
sig_rh = sig_group(numel(sig_group)/2+1:end);
cmax = max(abs(sig_group));
%Visualization: lh
figure('Units', 'pixels', 'Position', [100 100 800 800]); axis off
SurfStatView(sig_lh, FS_lh, 'Significance (-logP): ASD vs. HC');
colormap(cmap) ; SurfStatColLim([-cmax cmax])
%Export to JPG
set(gcf, 'PaperPositionMode', 'auto');
print('-djpeg', '-r300', [fig_dir '/sig.asd-hc.inflated.lh.jpg'])
close;
%Visualization: rh
figure('Units', 'pixels', 'Position', [100 100 800 800]); axis off
SurfStatView(sig_rh, FS_rh, 'Significance (-logP): ASD vs. HC');
colormap(cmap) ; SurfStatColLim([-cmax cmax])
%Export to JPG
set(gcf, 'PaperPositionMode', 'auto');
print('-djpeg', '-r300', [fig_dir '/sig.asd-hc.inflated.rh.jpg'])
close;

%% The Diag-Age Interaction
load([ana_dir '/matrix/sig_group_x_age.mat'])
sig_lh = sig_group_x_age(1:numel(sig_group)/2);
sig_rh = sig_group_x_age(numel(sig_group)/2+1:end);
cmax = max(abs(sig_group_x_age));
%Visualization: lh
figure('Units', 'pixels', 'Position', [100 100 800 800]); axis off
SurfStatView(sig_lh, FS_lh, 'Significance (-logP): Diagnosis x Age');
colormap(cmap) ; SurfStatColLim([-cmax cmax])
%Export to JPG
set(gcf, 'PaperPositionMode', 'auto');
print('-djpeg', '-r300', [fig_dir '/sig.diag-x-age.inflated.lh.jpg'])
close;
%Visualization: rh
figure('Units', 'pixels', 'Position', [100 100 800 800]); axis off
SurfStatView(sig_rh, FS_rh, 'Significance (-logP): Diagnosis x Age');
colormap(cmap) ; SurfStatColLim([-cmax cmax])
%Export to JPG
set(gcf, 'PaperPositionMode', 'auto');
print('-djpeg', '-r300', [fig_dir '/sig.diag-x-age.inflated.rh.jpg'])
close;

%% The Site Effects
load([ana_dir '/matrix/sig_site.mat'])
sig_lh = sig_site(1:numel(sig_group)/2);
sig_rh = sig_site(numel(sig_group)/2+1:end);
cmax = max(abs(sig_site));
%Visualization: lh
figure('Units', 'pixels', 'Position', [100 100 800 800]); axis off
SurfStatView(sig_lh, FS_lh, 'Significance (-logP): Site Variability');
colormap(cmap) ; SurfStatColLim([-cmax cmax])
%Export to JPG
set(gcf, 'PaperPositionMode', 'auto');
print('-djpeg', '-r300', [fig_dir '/sig.site.inflated.lh.jpg'])
close;
%Visualization: rh
figure('Units', 'pixels', 'Position', [100 100 800 800]); axis off
SurfStatView(sig_rh, FS_rh, 'Significance (-logP): Site Variability');
colormap(cmap) ; SurfStatColLim([-cmax cmax])
%Export to JPG
set(gcf, 'PaperPositionMode', 'auto');
print('-djpeg', '-r300', [fig_dir '/sig.site.inflated.rh.jpg'])
close;

%% The Number of Repliations
fcolor = [vis_tool_dir '/fimages/Purple-Red_Caret.tif'];
cmapCARET16 = zeros(16,3); cmapCARET16(1,:) = 0.5;
cmapCARET16(2:16,:) = ccs_mkcolormap(fcolor,15);
dlmwrite([fig_dir '/cmap_caret16.txt'],cmapCARET16,' ')
%plots
load([ana_dir '/matrix/numReplications.mat'])
sig_lh = numReplications(1:numel(sig_group)/2);
sig_rh = numReplications(numel(sig_group)/2+1:end);
%Visualization: lh
figure('Units', 'pixels', 'Position', [100 100 800 800]); axis off
SurfStatView(sig_lh, FS_lh, 'NumRep: Site Variability');
colormap(cmapCARET16) ; SurfStatColLim([0 15])
%Export to JPG
set(gcf, 'PaperPositionMode', 'auto');
print('-djpeg', '-r300', [fig_dir '/num.replication.inflated.lh.jpg'])
close;
%Visualization: rh
figure('Units', 'pixels', 'Position', [100 100 800 800]); axis off
SurfStatView(sig_rh, FS_rh, 'NumRep: Site Variability');
colormap(cmapCARET16) ; SurfStatColLim([0 15])
%Export to JPG
set(gcf, 'PaperPositionMode', 'auto');
print('-djpeg', '-r300', [fig_dir '/num.replication.inflated.rh.jpg'])
close;
