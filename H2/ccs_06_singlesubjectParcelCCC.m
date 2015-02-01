function [ CCC, ReHo ] = ccs_06_singlesubjectParcelCCC( ana_dir, sub_list, rest_name, func_dir_name )
%CCS_06_SINGLESUBJECTPARCELCCC Computing the PAREL-WISE concordance correlation coefficient.
%   ana_dir -- full path of the analysis directory
%   sub_list -- full path of the list of subjects
%   rest_name -- the name of rest raw data (no extention)
%   func_dir_name -- the name of functional directory
%
% Author: Xi-Nian Zuo at IPCAS, Dec., 11, 2012.
if nargin < 4
    disp('Usage: ccs_06_singlesubjectParcelCCC( ana_dir, sub_list, rest_name, func_dir_name)')
    exit
end
%% SUBINFO
subs = importdata(sub_list); nsubs = numel(subs);
if ~iscell(subs)
    subs = num2cell(subs);
end

%% LOOP SUBJECTS
numROI = 165; CCC = zeros(nsubs, numROI); ReHo = zeros(nsubs, numROI); 
for k=1:nsubs
    if isnumeric(subs{k})
        disp(['Loading RfMRI data for subject ' num2str(subs{k}) ' ...'])
        func_dir = [ana_dir '/' num2str(subs{k}) '/' func_dir_name];
    else
        disp(['Loading RfMRI data for subject ' subs{k} ' ...'])
        func_dir = [ana_dir '/' subs{k} '/' func_dir_name];
    end
    %load mask file
    maskfname = [func_dir '/' rest_name '_pp_mask.nii.gz'];
    maskHDR = load_nifti(maskfname); %FS version
    dims = maskHDR.dim(2:4); %FS version
    maskvol = reshape(squeeze(maskHDR.vol), prod(dims),1);  
    %load 165 parcels
    parcelfname = [func_dir '/segment/parcels165.nii.gz'];
    parcelHDR = load_nifti(parcelfname);
    parcelvol = reshape(squeeze(parcelHDR.vol), prod(dims),1);
    %load prefunc data
    fname = [func_dir '/' rest_name '_pp_sm0.nii.gz'];
    rfmriHDR = load_nifti(fname); %FS version
    tpoints = rfmriHDR.dim(5);
    rfmrivol = reshape(squeeze(rfmriHDR.vol), prod(dims), tpoints);
    for ii=1:numROI
        tmpts = rfmrivol(maskvol.*parcelvol == ii,:);
        CCC(k,ii) = IPN_ccc(tmpts');
        ReHo(k,ii) = IPN_kendallW(tmpts', 1);
    end
end
