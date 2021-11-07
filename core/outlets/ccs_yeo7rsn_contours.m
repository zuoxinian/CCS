function [medialwall_lh, medialwall_rh, map_yeo2011_lh, map_yeo2011_rh, ...
    mapc_yeo2011_lh, mapc_yeo2011_rh, cmap_yeo2011] = ccs_yeo7rsn_contours(fs_home, ccs_dir, fsaverage)
%% Notes
%   Inputs:
%       fs_home -- FREESURFER home directory
%       ccs_dir -- CCS home directory
%       fsaverage -- surface model in Freesurfer
%   Outputs:
%       medialwall_lh -- index vector for lh medial wall vertices
%       medialwall_rh -- index vector for rh medial wall vertices
%       map_yeo2011_lh -- index vector for lh Yeo2011 networks
%       map_yeo2011_rh -- index vector for rh Yeo2011 networks
%       mapc_yeo2011_lh -- index vector for lh countour of Yeo2011 networks
%       mapc_yeo2011_rh -- index vector for rh countour of Yeo2011 networks
%       cmap_yeo2011 -- colormap for Yeo2011 networks
%
% Written by Xi-Nian Zuo: zuoxn@psych.ac.cn
% Last modified: 2015/10/16.

%Add paths to MATLAB
ccs_matlab = [ccs_dir '/matlab'];
addpath([fs_home '/matlab'])
addpath(genpath(ccs_matlab))
addpath(genpath([ccs_dir '/vistool']))

%%Left Hemisphere
fsANNOT = [fs_home '/subjects/' fsaverage '/label/' ...
    'lh.Yeo2011_7Networks_N1000.annot']; 
ccsANNOT = [ccs_dir '/parcellation/ParcelsYeo2011/' fsaverage ...
    '/label/lh.Yeo2011_7Networks_N1000.annot'];
if exist(fsANNOT,'file')
    [vertices_yeo2011_lh, label_yeo2011_lh, colortable_yeo2011_lh] = ...
        read_annotation(fsANNOT);
else
    [vertices_yeo2011_lh, label_yeo2011_lh, colortable_yeo2011_lh] = ...
        read_annotation(ccsANNOT);
end
cmap_yeo2011 = colortable_yeo2011_lh.table(2:8,1:3)/255;%cmap
numVertex_lh = numel(vertices_yeo2011_lh);
medialwall_lh = zeros(numVertex_lh,1);
map_yeo2011_lh = zeros(numVertex_lh,1);
for vID=1:numVertex_lh
    tmpLabel = label_yeo2011_lh(vID,1);
    tmpIndex = colortable_yeo2011_lh.table(1,5);
    if tmpLabel==tmpIndex
        medialwall_lh(vID) = 1;
    end
    for netID=2:8
        tmpIndex = colortable_yeo2011_lh.table(netID,5);
        if tmpLabel==tmpIndex
            map_yeo2011_lh(vID) = netID-1;
        end
    end
end
%Right Hemisphere
fsANNOT = [fs_home '/subjects/' fsaverage '/label/' ...
    'rh.Yeo2011_7Networks_N1000.annot']; 
ccsANNOT = [ccs_dir '/parcellation/ParcelsYeo2011/' fsaverage ...
    '/label/rh.Yeo2011_7Networks_N1000.annot'];
if exist(fsANNOT,'file')
    [vertices_yeo2011_rh, label_yeo2011_rh, colortable_yeo2011_rh] = ...
        read_annotation(fsANNOT);
else
    [vertices_yeo2011_rh, label_yeo2011_rh, colortable_yeo2011_rh] = ...
        read_annotation(ccsANNOT);
end
numVertex_rh = numel(vertices_yeo2011_rh);
medialwall_rh = zeros(numVertex_rh,1);
map_yeo2011_rh = zeros(numVertex_rh,1);
for vID=1:numVertex_rh
    tmpLabel = label_yeo2011_rh(vID,1);
    tmpIndex = colortable_yeo2011_rh.table(1,5);
    if tmpLabel==tmpIndex
        medialwall_rh(vID) = 1;
    end
    for netID=1:8
        tmpIndex = colortable_yeo2011_rh.table(netID,5);
        if tmpLabel==tmpIndex
            map_yeo2011_rh(vID) = netID-1;
        end
    end
end

%Contours-LH
fsANNOT = [fs_home '/subjects/' fsaverage '/label/' ...
    'lh.Yeo2011_7Networks_N1000.split_components.annot'];
ccsANNOT = [ccs_dir '/parcellation/ParcelsYeo2011/' fsaverage ...
    '/lh.Yeo2011_7Networks_N1000.split_components.annot'];
if exist(fsANNOT,'file')
    [~, label_yeo2011split_lh, colortable_yeo2011split_lh] = read_annotation(fsANNOT);
else
    [~, label_yeo2011split_lh, colortable_yeo2011split_lh] = read_annotation(ccsANNOT);
end
mapc_yeo2011_lh = zeros(numVertex_lh,1);
for vID=1:numVertex_lh
    tmpLabel = label_yeo2011split_lh(vID,1);
    tmpIndex = colortable_yeo2011split_lh.table(1,5);
    if tmpLabel==tmpIndex
        mapc_yeo2011_lh(vID) = 1;
    end
end
mapc_yeo2011_lh = mapc_yeo2011_lh - medialwall_lh;
%Contours-RH
fsANNOT = [fs_home '/subjects/' fsaverage '/label/' ...
    'rh.Yeo2011_7Networks_N1000.split_components.annot'];
ccsANNOT = [ccs_dir '/parcellation/ParcelsYeo2011/' fsaverage ...
    '/rh.Yeo2011_7Networks_N1000.split_components.annot'];
if exist(fsANNOT,'file')
    [~, label_yeo2011split_rh, colortable_yeo2011split_rh] = read_annotation(fsANNOT);
else
    [~, label_yeo2011split_rh, colortable_yeo2011split_rh] = read_annotation(ccsANNOT);
end
mapc_yeo2011_rh = zeros(numVertex_rh,1);
for vID=1:numVertex_rh
    tmpLabel = label_yeo2011split_rh(vID,1);
    tmpIndex = colortable_yeo2011split_rh.table(1,5);
    if tmpLabel==tmpIndex
        mapc_yeo2011_rh(vID) = 1;
    end
end
mapc_yeo2011_rh = mapc_yeo2011_rh - medialwall_rh;
