function [ err ] = ccs_06_singlesubjectQCP( ana_dir, sub_list, rest_name, func_dir_name, smooth, gs )
%LFCD_05_SINGLESUBJECTQC Computing various metrics for quality control resting state fmri data.
%   ana_dir -- full path of the analysis directory
%   sub_list -- full path of the list of subjects
%   rest_name -- the name of rest raw data (no extention)
%   func_dir_name -- the name of functional directory
%   smooth -- if spatial smoothing applied
%   gs -- if remove global signal
%
% Author: Xi-Nian Zuo at IPCAS, 
%   Created: Feb., 3, 2012.
%   Revised: Jan., 15, 2013.

if nargin < 6
    disp('Usage: ccs_05_singlesubjectQC( ana_dir, sub_list, rest_name, func_dir_name, smooth, gs)')
    exit
end
%% SUBINFO
fid = fopen(sub_list) ;
tmpcell = textscan(fid, '%s'); 
fclose(fid);
subjects = tmpcell{1} ; nsubs = numel(subjects);
%stSNR = zeros(nsubs,1) ; vtSNR = zeros(nsubs,1);
%% LOOP SUBJECTS
for k=1:nsubs
    if isnumeric(subjects{k})
        titlestr = num2str(subjects{k});
    else
        titlestr = subjects{k};
    end
    disp(['Generating QC metrics on RfMRI data for subject ' titlestr ' ...'])
    func_dir = [ana_dir '/' titlestr '/' func_dir_name];
    f1D = [func_dir '/' rest_name '_mc.1D'];
    if strcmp(smooth, 'true')
        if strcmp(gs, 'true')
            fpp = [func_dir '/gs-removal/' rest_name '_pp_sm6.nii.gz'];
        else
            fpp = [func_dir '/' rest_name '_pp_sm6.nii.gz'];
        end
    else
        if strcmp(gs, 'true')
            fpp = [func_dir '/gs-removal/' rest_name '_pp_sm0.nii.gz'];
        else
            fpp = [func_dir '/' rest_name '_pp_sm0.nii.gz'];
        end
    end
    if ~exist(fpp, 'file')
        fpp = [func_dir '/' rest_name '_gms.nii.gz'];
    end
    if strcmp(gs, 'true')
        fres = [func_dir '/gs-removal/' rest_name '_res-gs.nii.gz'];
    else
        fres = [func_dir '/' rest_name '_res.nii.gz'];
    end
    %fmean = [func_dir '/' rest_name '_pp_mean.nii.gz'];
    fmask = [func_dir '/' rest_name '_pp_mask.nii.gz'];
    %read mask
    maskHDR = load_nifti(fmask); %FS version
    mask3D = maskHDR.vol; dim = maskHDR.dim(2:4); %FS version
    %read pp data
    restHDR = load_nifti(fpp); %FS version
    rest4D = restHDR.vol; dims = restHDR.dim(2:5); %FS version
    %compute tSNR: slice-based is more sensitive to head motion
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
    stSNR = mean(slice_tSNR(slice_tSNR > 0));
    %compute tSNR: volume-based is more sensitive to thermal noise
    mask = find(reshape(mask3D,numel(mask3D),1)>0);
    restMAT = reshape(rest4D,numel(mask3D),dims(4));
    snrMAT = mean(restMAT(mask,:),2)./std(restMAT(mask,:),0,2);
    vtSNR = mean(squeeze(snrMAT));
    %Compute FD
    [FD, mc_metrics, ~] = LFCD_IPN_computeMC(f1D);
    %Compute DVARS
    %meanHDR = load_nifti(fmean); %FS version
    mean3D = squeeze(mean(rest4D,4)); %dim = meanHDR.dim(2:4); %FS version
    mean1D = reshape(mean3D, numel(mean3D), 1);
    if ~exist(fres, 'file')
        restHDR = load_nifti(fpp); %FS version
    else
        restHDR = load_nifti(fres); %FS version
    end
    rest4D = restHDR.vol; dims = restHDR.dim(2:5); %FS version
    rest2D = reshape(rest4D, numel(mean3D), dims(4));
    meanMAT = repmat(mean1D(mask), 1, dims(4));
    restMAT = (rest2D(mask,:)/100).*meanMAT+meanMAT;
    restDIFF = diff(restMAT,1,2);
    DVARS = sqrt(sum(restDIFF.^2)/numel(mask))/100;
    idx_FD = find(FD > 0.5); idx_DVARS = find(DVARS > 500);% 5% psc
    %idx_interp0 = intersect(idx_FD, idx_DVARS) + 1;
    %idx_interp1 = union(intersect(idx_FD+2, idx_DVARS+1), ...
    %    intersect(idx_FD+1, idx_DVARS+1)); %neighbour spin history
    %idx_interp2 = union(intersect(idx_FD, idx_DVARS+1), ...
    %    intersect(idx_FD+1, idx_DVARS+2));
    %idx_interp12 = union(idx_interp1, idx_interp2);
    %idx_interp3 = union(intersect(idx_FD+1, idx_DVARS+2), ...
    %    intersect(idx_FD+1, idx_DVARS+1)); %neighbour spin history
    %idx_interp4 = union(intersect(idx_FD+1, idx_DVARS), ...
    %    intersect(idx_FD+2, idx_DVARS+1));
    %idx_interp34 = union(idx_interp3, idx_interp4);
    idx_img = zeros(2,dims(4));
    idx_img(1,intersect(idx_FD+1,1:dims(4))) = 1; 
    idx_img(1,intersect(idx_FD,1:dims(4))) = 1;
    idx_img(1,intersect(idx_FD+2,1:dims(4))) = 1; 
    idx_img(1,intersect(idx_FD+3,1:dims(4))) = 1;
    idx_img(2,intersect(idx_DVARS+1,1:dims(4))) = 1; 
    idx_img(2,intersect(idx_DVARS,1:dims(4))) = 1;
    idx_img(2,intersect(idx_DVARS+2,1:dims(4))) = 1; 
    idx_img(2,intersect(idx_DVARS+3,1:dims(4))) = 1;
    idx_interp = find((idx_img(1,:) + idx_img(2,:)) == 2);
    disp(['There are total ' num2str(numel(idx_interp)) ' positions to be scrubbed!'])
    %Visualization
    if strcmp(gs, 'true')
        qc_dir = [func_dir '/QC-gs'];
    else
        qc_dir = [func_dir '/QC']; 
    end
    if ~exist(qc_dir, 'dir'); mkdir(qc_dir); end
    figure('Units', 'pixels', 'Position', [100 100 800 500]); hold on
    subplot(311), plot([0; FD],'Color',[0 0.5 0.75], 'LineWidth',2), 
    title(titlestr) ; hold on, 
    plot(1:dims(4),repmat(0.5,dims(4),1), 'r-.') 
    axis tight; ylabel('FD (mm)')
    subplot(312), plot([2.5 DVARS/100], 'Color',[0 0.5 0.75], 'LineWidth',2), hold on,
    plot(1:dims(4),repmat(5,dims(4),1), 'r-.') 
    axis tight; ylabel('DVARS (\Delta%BOLDx10)')
    idx_img = zeros(2,dims(4)); idx_img(1,idx_FD+1) = 1;  idx_img(2,idx_DVARS+1) = 1;
    subplot(313), imagesc(idx_img)
    axis tight, xlabel('Frame (time point) #')
    %Save metrics and figures
    set(gcf, 'PaperPositionMode', 'auto')
    print('-dpng', '-r300', [qc_dir '/data_scrubbing.png']), close
    save([qc_dir '/FD.1D'], 'FD', '-ASCII')
    save([qc_dir '/DVARS.1D'], 'DVARS', '-ASCII')
    save([qc_dir '/vtSNR.dat'], 'vtSNR', '-ASCII')
    save([qc_dir '/stSNR.dat'], 'stSNR', '-ASCII')
    save([qc_dir '/head_motion_summary.dat'], 'mc_metrics', '-ASCII')
    fout = [qc_dir '/' rest_name '_interp.nii.gz'];
    if exist(fout, 'file')
        delete(fout)
    end
    if ~isempty(idx_interp)
        save([qc_dir '/position_scrubbing.dat'], 'idx_interp', '-ASCII')
        %Data interperlate
        if exist(fres, 'file')
            numVoxel = numel(mask);
            for n=1:numVoxel
                if ~mod(n,500); 
                    disp(['Completing data scrubbing in ' num2str(n/numVoxel*100) ' percent voxels ...'])
                end
                tmp_ts = restMAT(n,:);
                frame_remain = setdiff(1:dims(4),idx_interp);
                if numel(frame_remain) < numel(idx_interp)
                    disp('The data is too dirty! Not used for further analyses.')
                else
                    tmp_ts(idx_interp) = interp1(frame_remain,tmp_ts(frame_remain),idx_interp,'nearest');
                    restMAT(n,:) = tmp_ts;
                end
            end
            rest2D(mask,:) = 100*(restMAT - meanMAT)./meanMAT;
            restHDR.vol = reshape(rest2D, dims(1), dims(2), dims(3), dims(4));
            restHDR.descrip = ['CCS ' date];
            err = save_nifti(restHDR, fout);
        end
    else
        disp('No Need to scrubbing the data for this subject! Good data quality.')
    end
    err = 0;
end