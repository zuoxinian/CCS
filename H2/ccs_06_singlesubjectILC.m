function [ err ] = ccs_06_singlesubjectILC( ana_dir, sub_list, rest_name, func_dir_name )
%CCS_06_SINGLESUBJECTILC Computing the VOXEL-WISE ILC.
%   ana_dir -- full path of the analysis directory
%   sub_list -- full path of the list of subjects
%   rest_name -- the name of rest raw data (no extention)
%   func_dir_name -- the name of functional directory
%
% Author: Xi-Nian Zuo at IPCAS, Aug., 05, 2012.
% Last Modified: Xi-Nian Zuo at IPCAS, Aug., 02, 2014.

if nargin < 4
    disp('Usage: ccs_06_singlesubjectILC( ana_dir, sub_list, rest_name, func_dir_name)')
    exit
end
%% SUBINFO
subs = importdata(sub_list); nsubs = numel(subs);
if ~iscell(subs)
    subs = num2cell(subs);
end

%% LOOP SUBJECTS
for k=1:nsubs
    if isnumeric(subs{k})
        disp(['Loading RfMRI data for subject ' num2str(subs{k}) ' ...'])
        func_dir = [ana_dir '/' num2str(subs{k}) '/' func_dir_name];
    else
        disp(['Loading RfMRI data for subject ' subs{k} ' ...'])
        func_dir = [ana_dir '/' subs{k} '/' func_dir_name];
    end
    ilc_dir = [func_dir '/ILC']; mkdir(ilc_dir);
    maskfname = [func_dir '/' rest_name '_pp_mask.nii.gz'];
    maskHDR = load_nifti(maskfname); %FS version
    maskvol = squeeze(maskHDR.vol); 
    dims = maskHDR.dim(2:4); %FS version
    xmax = dims(1) ; ymax = dims(2) ; zmax = dims(3);
    infname = [func_dir '/' rest_name '_pp_sm0.nii.gz'];
    rfmriHDR = load_nifti(infname); %FS version
    rfmrivol = squeeze(rfmriHDR.vol);
    ILCvol = zeros(size(maskvol));
    ii = 0 ; % counter of voxels
    for x=2:xmax-1
        for y=2:ymax-1
            for z=2:zmax-1
                if ~mod(ii,5000); 
                    disp(['Completing ' num2str(ii/prod(dims)*100) ...
                        ' percent voxels processed ...'])
                end
                if maskvol(x,y,z) > 0 %*(x-1)*(y-1)*(z-1)*(x-xmax)*(y-ymax)*(z-zmax) > 0
                    tmp_ts = ccs_get3x3x3ts(rfmrivol,x,y,z);
                    center_ts = tmp_ts(:,14);
                    nbrs_ts = tmp_ts(:,[1:13 15:27]);              
                    r_tmp = IPN_fastCorr(center_ts, nbrs_ts(:,std(nbrs_ts)>0));
                    ILCvol(x,y,z) = tanh(mean(atanh(r_tmp)));
                end
                ii = ii + 1;
            end
        end
    end
    % Save R (correlation) map
    fout = [ilc_dir '/ILC_sm0_Rmap.nii.gz'];
    maskHDR.datatype = 16; maskHDR.descrip = ['CCS ' date];
    maskHDR.vol = ILCvol ; err = save_nifti(maskHDR, fout);
    % Save Fisher-Z map
    fout = [ilc_dir '/ILC_sm0_Zmap.nii.gz'];
    ILCvol(maskvol > 0) = atanh(ILCvol(maskvol > 0));
    maskHDR.vol = ILCvol ; err = save_nifti(maskHDR, fout);
end
