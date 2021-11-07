function [tp_regressors, network_maps] = ccs_06_singlesubject2dDualRegress( ana_dir, ...
    sub_list, rest_name, func_dir_name, ccs_home, fsaverage)
%CCS_06_SINGLESUBJECT2dDualRegress Computing the RSFC on the surface.
%   ana_dir -- full path of the analysis directory
%   sub_list -- full path of the list of subjects
%   rest_name -- the name of rest raw data (no extention)
%   func_dir_name -- the name of functional directory
%   ccs_home -- the ccs home directory
%   fsaverage -- the fsaverage file name
%
%   Note: need to add different ways of define seed regions.

% Author: Xi-Nian Zuo at IPCAS, Nov., 10, 2015.

if nargin < 6
    disp('Usage: ccs_06_singlesubject2dDualRegress( ana_dir, sub_list, rest_name, func_dir_name, ccs_home, fsaverage)')
    exit
end

%% Load yeo2011 templates
%LH
fYeoLH = [ccs_home '/parcellation/ParcelsYeo2011/fsaverage5/label/lh.Yeo2011_7Networks_N1000.annot'];
[vertices_Yeo_lh,label_Yeo_lh,colortable_Yeo_lh] = read_annotation(fYeoLH);
nVertices_lh = numel(vertices_Yeo_lh);
Yeo_names_lh = colortable_Yeo_lh.struct_names;
Yeo_labels_lh = colortable_Yeo_lh.table;
Yeo_lh = zeros(size(label_Yeo_lh)); 
for k=2:numel(Yeo_names_lh)
    tmpname = Yeo_names_lh{k};
    idx_label = ccs_strfind(Yeo_names_lh,tmpname);
    Yeo_idx = find(label_Yeo_lh == Yeo_labels_lh(idx_label,5));
    Yeo_lh(Yeo_idx) = k-1;
end
%RH
fYeoRH = [ccs_home '/parcellation/ParcelsYeo2011/fsaverage5/label/rh.Yeo2011_7Networks_N1000.annot'];
[vertices_Yeo_rh,label_Yeo_rh,colortable_Yeo_rh] = read_annotation(fYeoRH);
nVertices_rh = numel(vertices_Yeo_rh);
Yeo_names_rh = colortable_Yeo_rh.struct_names;
Yeo_labels_rh = colortable_Yeo_rh.table;
Yeo_rh = zeros(size(label_Yeo_rh));
for k=2:numel(Yeo_names_rh)
    tmpname = Yeo_names_rh{k};
    idx_label = ccs_strfind(Yeo_names_rh,tmpname);
    Yeo_idx = find(label_Yeo_rh == Yeo_labels_rh(idx_label,5));
    Yeo_rh(Yeo_idx) = k-1;
end
Yeo2011 = [Yeo_lh; Yeo_rh]; nVertices = nVertices_lh + nVertices_rh;

%% Load yeo2011 network confidence maps
%LH
fYeoCI = [ccs_home '/parcellation/ParcelsYeo2011/fsaverage5/label/' ...
    'lh.Yeo2011_7NetworksConfidence_N1000.mgz'];
mriCI_lh = MRIread(fYeoCI); volCI_lh = mriCI_lh.vol';
%RH
fYeoCI = [ccs_home '/parcellation/ParcelsYeo2011/fsaverage5/label/' ...
    'rh.Yeo2011_7NetworksConfidence_N1000.mgz'];
mriCI_rh = MRIread(fYeoCI); volCI_rh = mriCI_rh.vol';
%BH
Yeo2011CI = [volCI_lh; volCI_rh]; Yeo2011CI(Yeo2011CI<0) = 0;

%% SUBINFO
fid = fopen(sub_list);
tmpcell = textscan(fid, '%s'); 
fclose(fid);
subs = tmpcell{1} ; nsubs = numel(subs);

%% LOOP SUBJECTS
for k=1:nsubs
    if isnumeric(subs{k}) %Modified in Oct 28, 2015.
        disp(['Performing Dual Regression for subject ' num2str(subs{k}) ' ...'])
        func_dir = [ana_dir '/' num2str(subs{k}) '/' func_dir_name];
    else
        disp(['Performing Dual Regression for subject ' subs{k} ' ...'])
        func_dir = [ana_dir '/' subs{k} '/' func_dir_name];
    end
    dr_dir = [func_dir '/DR']; mask_dir = [func_dir '/mask'];
    if ~exist(dr_dir,'dir')
        mkdir(dr_dir);
    end
    %lh
    fname = [func_dir '/' rest_name '.pp.sm6.' fsaverage '.lh.nii.gz'];
    tmphdr_lh = load_nifti(fname); volBOLD_lh = squeeze(tmphdr_lh.vol); 
    DR_lh = zeros(nVertices_lh,1); clear tmphdr_lh
    fmask = [mask_dir '/brain.' fsaverage '.lh.nii.gz'];
    maskhdr_lh = load_nifti(fmask); mask_lh = squeeze(maskhdr_lh.vol);
    %rh
    fname = [func_dir '/' rest_name '.pp.sm6.' fsaverage '.rh.nii.gz'];
    tmphdr_rh = load_nifti(fname); volBOLD_rh = squeeze(tmphdr_rh.vol);
    DR_rh = zeros(nVertices_rh,1); clear tmphdr_rh
    fmask = [mask_dir '/brain.' fsaverage '.rh.nii.gz'];
    maskhdr_rh = load_nifti(fmask); mask_rh = squeeze(maskhdr_rh.vol);
    %bh
    volBOLD = [volBOLD_lh; volBOLD_rh]; 
    mask = [mask_lh; mask_rh]; idx_mask = find(mask>0);
    Yeo2011_masked = Yeo2011(mask==1);
    Yeo2011CI_masked = Yeo2011CI(mask==1);
    volBOLD_masked = volBOLD(mask==1,:);
    %spatial regressors
    sp_regressors = zeros(numel(Yeo2011_masked), 7);
    for mapID=1:7
        tmpmask = zeros(size(Yeo2011_masked));
        tmpmask(Yeo2011_masked==mapID) = 1;
        sp_regressors(:,mapID) = Yeo2011CI_masked.*tmpmask;
    end
    %Spatial Regression
    numTRs = size(volBOLD_masked,2);
    tp_regressors = zeros(numTRs,7);
    for trID=1:numTRs
        tmpY = volBOLD_masked(:,trID);
        tp_regressors(trID,:) = regress(tmpY, sp_regressors);
    end
    fTP = [dr_dir '/tp_regressors.txt'];
    dlmwrite(fTP, tp_regressors,'delimiter','\t')
    %Temporal Regression
    network_maps = zeros(nVertices, 7);
    for vtxID=1:nnz(mask)
        tmpY = volBOLD(idx_mask(vtxID),:);
        tmpB = regress(tmpY', tp_regressors);
        network_maps(idx_mask(vtxID),:) = tmpB;
    end
    for netID=1:7
        tmpvol = network_maps(:,netID);
        %lh
        nethdr_lh = maskhdr_lh;
        nethdr_lh.datatype = 16; nethdr_lh.descrip = ['CCS ' date];
        nethdr_lh.vol = tmpvol(1:nVertices_lh); 
        fout = [dr_dir '/lh.yeo2011.network' num2str(netID) '.' fsaverage '.nii.gz'];
        err = save_nifti(nethdr_lh, fout);
        %rh
        nethdr_rh = maskhdr_rh;
        nethdr_rh.datatype = 16; nethdr_rh.descrip = ['CCS ' date];
        nethdr_rh.vol = tmpvol((1+nVertices_lh):end); 
        fout = [dr_dir '/rh.yeo2011.network' num2str(netID) '.' fsaverage '.nii.gz'];
        err = save_nifti(nethdr_rh, fout);
    end
end

