function [qcmetrics] = ccs_06_singlesubjectqcpRFMRI(ccsana_dir, sub_list, ...
    func_dir_name, rest_name)
%CCS_06_SINGLESUBJECTQCPSMRI Computing metrics for structural MRI.
%   ccsana_dir -- full path of the analysis directory
%   sub_list -- full path of the list of subjects
%   func_dir_name -- name of the functional directory name
%   rest_name -- name of the rfMRI image
% Programs needed: SPM12, FreeSurfer MATLAB toolbox, CCS
%
% See http://preprocessed-connectomes-project.org/quality-assessment-protocol/index.html
% Author: Xi-Nian Zuo at IPCAS, March., 23, 2016.

if nargin < 4
    disp('Usage: ccs_06_singlesubjectqcpRFMRI(ccsana_dir, sub_list, fs_sub_dir, anat_dir_name, func_dir_name, rest_name)')
    exit
end

%% SUBINFO
fid = fopen(sub_list);
tmpcell = textscan(fid, '%s'); 
fclose(fid);
subs = tmpcell{1} ; nsubs = numel(subs);

%% LOOP SUBJECTS
funcEFC = zeros(nsubs,1); funcFBER = zeros(nsubs,1);
sfwhm_x = zeros(nsubs,1); sfwhm_y= zeros(nsubs,1);
sfwhm_z = zeros(nsubs,1); sfwhm = zeros(nsubs,1);
tfwhm_x = zeros(nsubs,1); tfwhm_y= zeros(nsubs,1);
tfwhm_z = zeros(nsubs,1); tfwhm = zeros(nsubs,1);
meanFD = zeros(nsubs,1); numFD = meanFD; percFD = meanFD;
stSNR = zeros(nsubs,1); vtSNR = zeros(nsubs,1);
meanMDI = zeros(nsubs,1); meanOD = meanMDI; 
normDVARS = meanMDI; pnormDVARS = meanMDI; rawDVARS = meanMDI;
for k=1:nsubs
    if isnumeric(subs{k}) 
        disp(['Computing QCP metrics for subject ' num2str(subs{k}) ' ...'])
        sub_dir = [ccsana_dir '/' num2str(subs{k})];
    else
        disp(['Computing QCP metrics for subject ' subs{k} ' ...'])
        sub_dir = [ccsana_dir '/' subs{k}];
    end
    func_dir = [sub_dir '/' func_dir_name];
    if exist(func_dir, 'dir')
        fOrig = [func_dir '/mean_func_mc.nii.gz'];
        fT2 = [func_dir '/example_func.nii.gz'];
        mri = MRIread(fT2); volT2 = mri.vol;
        mri = MRIread(fOrig); volOrig = mri.vol;
        fBM = [func_dir '/' rest_name '_pp_mask.nii.gz'];
        mri = MRIread(fBM); volBM = mri.vol;
        %air (back ground) voxels
        idxAir = (volT2<(0.05*max(volT2(:))));
        %brain mask
        idxBrain = (volBM>0);
        %tissue (fore ground) voxels
        idxTissue = idxBrain;
        
        %% Spatial Functional Metrics
        tmpBG = volOrig(idxAir); 
        tmpFG = volOrig(idxTissue);
        tmpBM = volOrig(idxBrain); 
        %Entropy Focus Criterion: EFC
        funcEFC(k) = log10(-wentropy(tmpBM(:),'shannon'));
        %Foreground to Background Energy Ratio: FBER
        funcFBER(k) = mean(tmpFG(:).^2)/mean(tmpBG(:).^2);
        %Smoothness of Voxels
        fFWHM = [func_dir '/qcp/sFWHM.dat'];
        if exist(fFWHM, 'file')
            tmpsFWHM = load(fFWHM);
            tmpsFWHM = mean(tmpsFWHM);
            sfwhm_x(k) = tmpsFWHM(1); 
            sfwhm_y(k) = tmpsFWHM(2); 
            sfwhm_z(k) = tmpsFWHM(3); 
            sfwhm(k) = mean(tmpsFWHM);
        end
        
        %% Functional Metrics
        f1D = [func_dir '/' rest_name '_mc.1D'];
        mc_f = load(f1D);
        mc_dS = mc_f(:,4); mc_dL = mc_f(:,5); mc_dP = mc_f(:,6); 
        mc_roll = mc_f(:,1); mc_pitch = mc_f(:,2); mc_yaw = mc_f(:,3);
        rmc_dS = diff(mc_dS); rmc_dL = diff(mc_dL); rmc_dP = diff(mc_dP);
        rmc_roll = diff(mc_roll); rmc_pitch = diff(mc_pitch); rmc_yaw = diff(mc_yaw);
        FD = abs(rmc_dS) + abs(rmc_dL) + abs(rmc_dP) + ...
            50*abs(rmc_roll*pi/180) + 50*abs(rmc_pitch*pi/180) + 50*abs(rmc_yaw*pi/180);
        fFD = [func_dir '/qcp/FD.dat'];
        dlmwrite(fFD, FD);
        %summary FD metrics
        meanFD(k) = mean(FD); 
        numFD(k) = nnz(find(FD>0.2)); 
        percFD(k) = numFD(k)/numel(FD); 
        %compute tSNR: slice-based is more sensitive to head motion
        fppBOLD = [func_dir '/' rest_name '_pp_sm6.nii.gz'];
        mri = MRIread(fppBOLD); rest4D = mri.vol; dims = size(rest4D);
        slice_tSNR = zeros(dims(3),1);
        for s=1:dims(3)
            maskSLICE = reshape(squeeze(volBM(:,:,s)),numel(volBM(:,:,s)),1);
            mask = find(maskSLICE>0);
            if ~isempty(mask)
                restSLICE = reshape(squeeze(rest4D(:,:,s,:)), ...
                    numel(volBM(:,:,s)),dims(4));
                restSLICE_masked = restSLICE(mask,:);
                restSLICE_mean = mean(restSLICE_masked);
                if std(restSLICE_mean)>0
                    slice_tSNR(s) = mean(restSLICE_mean)/std(restSLICE_mean);
                end
            end
        end
        stSNR(k) = mean(slice_tSNR(slice_tSNR > 0));
        %compute tSNR: volume-based is more sensitive to thermal noise
        mask = find(reshape(volBM,numel(volBM),1)>0);
        restMAT = reshape(rest4D,numel(volBM),dims(4));
        snrMAT = mean(restMAT(mask,:),2)./std(restMAT(mask,:),0,2);
        vtSNR(k) = mean(squeeze(snrMAT));
        %Smoothness of Voxels
        fFWHM = [func_dir '/qcp/tFWHM.dat'];
        if exist(fFWHM, 'file')
            tmptFWHM = load(fFWHM);
            tmptFWHM = mean(tmptFWHM);
            tfwhm_x(k) = tmptFWHM(1); 
            tfwhm_y(k) = tmptFWHM(2); 
            tfwhm_z(k) = tmptFWHM(3); 
            tfwhm(k) = mean(tmptFWHM);
        end
        %MDI
        fMDI = load([func_dir '/qcp/MDI.dat']);
        meanMDI(k) = mean(fMDI);
        %Fraction of outliers
        fOD = load([func_dir '/qcp/outliers.dat']);
        meanOD(k) = mean(fOD);
        %DVARS
        DVARS = load([func_dir '/qcp/DVARS.dat']);
        normDVARS(k) = mean(DVARS(:,1));
        rawDVARS(k) = mean(DVARS(:,2));
        pnormDVARS(k) = mean(DVARS(:,3));
        %rest scan loop end
    end
end
qcmetrics = table(funcFBER, funcEFC, sfwhm, sfwhm_x, sfwhm_y, sfwhm_z, ...
    tfwhm, tfwhm_x, tfwhm_y, tfwhm_z, meanFD, numFD, percFD, ...
    stSNR, vtSNR, meanMDI, meanOD, normDVARS, rawDVARS, pnormDVARS);
