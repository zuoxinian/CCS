function [ ALFF, FALFF ] = ccs_06_singlesubjectParcelALFF( ana_dir, sub_list, rest_name, func_dir_name )
%CCS_06_SINGLESUBJECTPARCELALFF Computing the PAREL-WISE ALFF.
%   ana_dir -- full path of the analysis directory
%   sub_list -- full path of the list of subjects
%   rest_name -- the name of rest raw data (no extention)
%   func_dir_name -- the name of functional directory
%
% Notes:
%   It is dangerous to averge timeseries within a large parcel regarding its high inhomogenity. 
%   We thus first compute the ALFF/FALFF values across all voxels and then average their ALFF/FALFF.
%
% Author: Xi-Nian Zuo at IPCAS, Dec., 11, 2012.
if nargin < 4
    disp('Usage: ccs_06_singlesubjectParcelALFF( ana_dir, sub_list, rest_name, func_dir_name)')
    exit
end
%% SUBINFO
subs = importdata(sub_list); nsubs = numel(subs);
if ~iscell(subs)
    subs = num2cell(subs);
end

%% LOOP SUBJECTS
numROI = 165; ALFF = zeros(nsubs, numROI); FALFF = zeros(nsubs, numROI);
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
    %dims = maskHDR.dim(2:4); %FS version
    %xmax = dims(1) ; ymax = dims(2) ; zmax = dims(3);
    maskvol = squeeze(maskHDR.vol);  
    %load 165 parcels
    parcelfname = [func_dir '/segment/parcels165.nii.gz'];
    parcelHDR = load_nifti(parcelfname);
    parcelvol = squeeze(parcelHDR.vol);
    %load ALFF map
    alfffname = [func_dir '/ALFF/ALFF.nii.gz'];
    alffHDR = load_nifti(alfffname); %FS version
    alffvol = squeeze(alffHDR.vol);
    %load FALFF map
    falfffname = [func_dir '/ALFF/fALFF.nii.gz'];
    falffHDR = load_nifti(falfffname); %FS version
    falffvol = squeeze(falffHDR.vol);
    for ii=1:numROI
        tmp = alffvol(maskvol.*parcelvol == ii);
        ALFF(k,ii) = mean(tmp(:));
        tmp = falffvol(maskvol.*parcelvol == ii);
        FALFF(k,ii) = mean(tmp(:));
    end
end
