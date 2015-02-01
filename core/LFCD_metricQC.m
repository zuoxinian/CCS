clear all; clc
ccs_dir = '/home/xinian/projects/ccs20111210';
ana_dir ='/media/buslink/Inside_projects/test-retest/nyu';
sub_list = [ana_dir '/scripts/subjects_list25.txt'];
rest_name = 'rest';
grpmask_dir = [ana_dir '/group/masks'];
fs_home = '/lfcd_app/freesurfer';
fsaverage = 'fsaverage5';

%% test subject
subjects = importdata(sub_list);
f1D = [ana_dir '/' subjects{1} '/func_1/' rest_name '_mc.1D'];
frest = [ana_dir '/' subjects{1} '/func_1/' rest_name '.nii.gz'];
fpp = [ana_dir '/' subjects{1} '/func_1/' rest_name '_pp.nii.gz'];
fres = [ana_dir '/' subjects{1} '/func_1/' rest_name '_res.nii.gz'];
fmean = [ana_dir '/' subjects{1} '/func_1/' rest_name '_pp_mean.nii.gz'];
fmask = [ana_dir '/' subjects{1} '/func_1/' rest_name '_pp_mask.nii.gz'];
maskHDR = load_nifti(fmask); %FS version
mask3D = maskHDR.vol; dim = maskHDR.dim(2:4); %FS version
restHDR = load_nifti(fpp); %FS version
rest4D = restHDR.vol; dims = restHDR.dim(2:5); %FS version
%% compute tSNR: slice-based is more sensitive to head motion
slice_tSNR = zeros(dim(3),1);
for s=1:dim(3)
    disp(['Computing temporal SNR for the ' num2str(s) '-th slice ...'])
    maskSLICE = reshape(squeeze(mask3D(:,:,s)),numel(mask3D(:,:,s)),1);
    mask = find(maskSLICE>0);
    if ~isempty(mask)
        restSLICE = reshape(squeeze(rest4D(:,:,s,:)),numel(mask3D(:,:,s)),dims(4));
        restSLICE_masked = restSLICE(mask,:);
        restSLICE_mean = mean(restSLICE_masked);
        slice_tSNR(s) = mean(restSLICE_mean)/std(restSLICE_mean);
    end
end
stSNR = mean(slice_tSNR(slice_tSNR > 0))
%% compute tSNR: volume-based is more sensitive to thermal noise
mask = find(reshape(mask3D,numel(mask3D),1)>0);
restMAT = reshape(rest4D,numel(mask3D),dims(4));
snrMAT = mean(restMAT(mask,:),2)./std(restMAT(mask,:),0,2);
vtSNR = mean(squeeze(snrMAT))
%% Compute FD
FD = LFCD_IPN_computeMC(f1D);
%% Compute DVARS
meanHDR = load_nifti(fmean); %FS version
mean3D = meanHDR.vol; dim = meanHDR.dim(2:4); %FS version
mean1D = reshape(mean3D, numel(mean3D), 1);
restHDR = load_nifti(fres); %FS version
rest4D = restHDR.vol; dims = restHDR.dim(2:5); %FS version
rest2D = reshape(rest4D, numel(mean3D), dims(4));
meanMAT = repmat(mean1D(mask), 1, dims(4));
restMAT = (rest2D(mask,:)/100).*meanMAT+meanMAT;
restDIFF = [restMAT(:,1)-restMAT(:,end) diff(restMAT,1,2)];
DVARS = sqrt(sum(restDIFF.^2)/numel(mask))/100;
