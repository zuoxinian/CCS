function [ ] = IPN_doSingleSubject_regionCENT_dosenbach2010( infname, maskfname, template_list, outfprefix, p )
% Summary of this function goes here
%   Detailed explanation goes here
% Xinian.Zuo@nyumc.org
if nargin < 5
    p = 0.005; 
end
n_thr = length(p);
r_thr = zeros(n_thr,1);
s_thr = zeros(n_thr,1);
%% Extracting timeseries data
% Read R-fMRI preprocessed data
[nii, dims] = read_avw(infname);
n_tp = dims(4);
tmp = reshape(nii, prod(dims(1:3)), n_tp);
clear nii
% Read mask data
[nii, dim] = read_avw(maskfname);
mask = reshape(nii, prod(dim(1:3)), 1);
clear nii
% Read template data
ROI_list = importdata(template_list);
numROIs = length(ROI_list);
ROI_TS = zeros(dims(4), numROIs);
R = zeros(numROIs,numROIs);
Zf = R; Zs = R;
id_effROIs_buffer = zeros(numROIs);
for k=1:numROIs
    [nii, dim] = read_avw(ROI_list{k});
    ROI = reshape(nii, prod(dim(1:3)), 1);
    clear nii
    ROI_inmask = ROI.*mask;
    idx = (ROI_inmask > 0);
    if nnz(idx) > 1
        id_effROIs_buffer(k) = k;
        ROI_TS(:,k) = mean(tmp(idx,:))';
    end
    clear idx ROI
end
cc_idx = [1:97 99:108 111 112 114:119 123:126 129 132:137 139 141 142 145:149 152:154 156:160];
id_effROIs = intersect(cc_idx, id_effROIs_buffer(id_effROIs_buffer > 0));
num_effROIs = length(id_effROIs);
%% Computation: RSFC
R = IPN_fastCorr(ROI_TS, ROI_TS);
R = R - diag(diag(R));
Reff = R(id_effROIs, id_effROIs);
Zf = atanh(R);
Zs = Zf*sqrt(dims(4) - 3);
%% Computation: CENT
%binary
DCb = zeros(num_effROIs, length(r_thr)); ECb = zeros(num_effROIs, length(r_thr)); PCb = zeros(num_effROIs, length(r_thr));
SCb = zeros(num_effROIs, length(r_thr)); CCb = zeros(num_effROIs, length(r_thr)); BCb = zeros(num_effROIs, length(r_thr));
%weighted
DCw = zeros(num_effROIs, length(r_thr)); ECw = zeros(num_effROIs, length(r_thr)); PCw = zeros(num_effROIs, length(r_thr));
SCw = zeros(num_effROIs, length(r_thr)); CCw = zeros(num_effROIs, length(r_thr)); BCw = zeros(num_effROIs, length(r_thr));
for n=1:length(r_thr)
    r_thr(n) = IPN_pval2corr(1-p(n), n_tp);
    [tmp_corr_b, s_thr(n)] = IPN_gretna_R2b(Reff, 'r', r_thr(n));
    tmp_corr_w = tmp_corr_b.*Reff;
    %degree
    tmp = IPN_centDegree(tmp_corr_b);
    DCb(:, n) = tmp;
    DCw(:, n) = IPN_centDegree(tmp_corr_w);
    %eigenvector
    disp(['p-value = ' num2str(p(n)) ': eigenvector centrality'])
    ECb(:, n) = IPN_centEigenvector(tmp_corr_b);
    ECw(:, n) = IPN_centEigenvector(tmp_corr_w);
    %pagerank
    disp(['p-value = ' num2str(p(n)) ': page-rank centrality'])
    PCb(:, n) = IPN_centPagerank(tmp_corr_b);
    PCw(:, n) = IPN_centPagerank(tmp_corr_w);
    %subgraph
    if prod(tmp) == 0
        disp('Notice: not a fully connected graph!')
        disp(['p-value = ' num2str(p(n)) ': subgraph centrality'])
        SCb(:, n) = IPN_centSubgraph(tmp_corr_b);
    else
        disp(['p-value = ' num2str(p(n)) ': subgraph centrality'])
        SCb(:, n) = IPN_centSubgraph(tmp_corr_b);
        SCw(:, n) = IPN_centSubgraph(tmp_corr_w, 'w');
    end
    %closeness
    disp(['p-value = ' num2str(p(n)) ': closeness centrality'])
    CCb(:, n) = IPN_centCloseness(tmp_corr_b,0);
    CCw(:, n) = IPN_centCloseness(tmp_corr_w,0);
    %betweenness
    disp(['p-value = ' num2str(p(n)) ': betweenness centrality'])
    BCb(:, n) = IPN_centBetweenness(tmp_corr_b, 0);
    BCw(:, n) = IPN_centBetweenness(tmp_corr_w, 0);
end
save([outfprefix '/ts_dosenbach2010.mat'], 'ROI_TS')
save([outfprefix '/rsfc_dosenbach2010.mat'], 'R', 'Reff', 'Zf', 'Zs', 'id_effROIs')
save([outfprefix '/cent_dosenbach2010.mat'], 'DCb', 'ECb', 'PCb', 'SCb', 'CCb', 'BCb', ...
    'DCw', 'ECw', 'PCw', 'SCw', 'CCw', 'BCw', 'r_thr', 's_thr')