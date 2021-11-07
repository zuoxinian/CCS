function [qcmetrics] = ccs_06_singlesubjectqcpSMRI(fsana_dir, ccsana_dir, ...
    anat_dir_name, sub_list)
%CCS_06_SINGLESUBJECTQCPSMRI Computing metrics for structural MRI.
%   fsana_dir -- full path of the freesurfer analysis directory
%   ccsana_dir -- full path of the ccs analysis directory
%   anat_dir_name -- name of the anatomical directory
%   sub_list -- full path of the list of subjects
% Programs needed: SPM12, FreeSurfer MATLAB toolbox, CCS
%
% See http://preprocessed-connectomes-project.org/quality-assessment-protocol/index.html
% Author: Xi-Nian Zuo at IPCAS, March., 19, 2016.

if nargin < 4
    disp('Usage: ccs_06_singlesubjectqcpSMRI(fsana_dir, ccsana_dir, anat_dir_name, sub_list)')
    exit
end

%% SUBINFO
fid = fopen(sub_list);
tmpcell = textscan(fid, '%s'); 
fclose(fid);
subs = tmpcell{1} ; nsubs = numel(subs);

%% LOOP SUBJECTS
anatCNR = zeros(nsubs,1); gmSNR = zeros(nsubs,1); wmSNR = zeros(nsubs,1);
Qi1 = zeros(nsubs,1); anatEFC = zeros(nsubs,1); anatFBER = zeros(nsubs,1);
fwhm_x = zeros(nsubs,1); fwhm_y= zeros(nsubs,1);
fwhm_z = zeros(nsubs,1); fwhm = zeros(nsubs,1);
for k=1:nsubs
    if isnumeric(subs{k}) 
        disp(['Computing QCP metrics for subject ' num2str(subs{k}) ' ...'])
        fssub_dir = [fsana_dir '/' num2str(subs{k})];
        ccssub_dir = [ccsana_dir '/' num2str(subs{k})];
    else
        disp(['Computing QCP metrics for subject ' subs{k} ' ...'])
        fssub_dir = [fsana_dir '/' subs{k}];
        ccssub_dir = [ccsana_dir '/' subs{k}];
    end
    %% Spatial Anatomical Images
    fOrig = [fssub_dir '/mri/orig.mgz'];
    mri = MRIread(fOrig); volOrig = mri.vol;
    fT1 = [fssub_dir '/mri/T1.mgz'];
    mri = MRIread(fT1); volT1 = mri.vol;
    fBM = [fssub_dir '/mri/brainmask.mgz'];
    mri = MRIread(fBM); volBM = mri.vol;
    %air (back ground) voxels
    idxAir = (volBM<2)&(volOrig >0)&(volOrig < 20); %(volT1==0)&(volOrig~=0);
    %tissue (fore ground) voxels
    idxTissue = (volT1~=0);
    %brain mask
    idxBrain = (volBM>=2);
    %% Brain Segmentation Atlas
    fseg = [fssub_dir '/mri/aseg.mgz'];
    mri = MRIread(fseg); volAseg = mri.vol;
    %unique label
    %uniLabels = unique(volAseg(:));
    %%gray matter voxels
    idxGM = (volAseg==3)|(volAseg==42)|(volAseg==8)|(volAseg==47);%no striatum
    %%white matter voxels
    idxWM = (volAseg==2)|(volAseg==41)|(volAseg==7)|(volAseg==46);%no striatum
    %%csf voxels
    %idxCSF = (volAseg==4)|(volAseg==43)|(volAseg==5)|(volAseg==44)...
    %    |(volAseg==31)|(volAseg==63);%csf ventricles
    %% Spatial Anatomical Metrics
    tmpBG = volOrig(idxAir); tmpFG = volOrig(idxTissue); 
    %fg_mean = mean(tmpFG(:)); fg_std = std(tmpFG(:)); 
    %fg_size = nnz(idxTissue(:)); bg_mean = mean(tmpBG(:)); 
    bg_std = std(tmpBG(:)); bg_size = nnz(idxAir(:));
    tmpGM = volOrig(idxGM); tmpWM = volOrig(idxWM); %tmpCSF = volOrig(idxCSF);
    gm_mean = mean(tmpGM(:)); %gm_std = std(tmpGM(:)); gm_size = nnz(idxGM(:));
    wm_mean = mean(tmpWM(:)); %wm_std = std(tmpWM(:)); wm_size = nnz(idxWM(:));
    %csf_mean = mean(tmpCSF(:)); csfm_std = std(tmpCSF(:)); csf_size = nnz(idxCSF(:));
    %Contrast to Noise Ratio: CNR    
    anatCNR(k,1) = abs(gm_mean - wm_mean)/bg_std;
    %Entropy Focus Criterion: EFC
    tmpBM = volOrig(idxBrain); anatEFC(k,1) = log10(-wentropy(tmpBM(:),'shannon'));
    %Foreground to Background Energy Ratio: FBER
    anatFBER(k,1) = mean(tmpFG(:).^2)/mean(tmpBG(:).^2);
    %Smoothness of Voxels
    fFWHM = [ccssub_dir '/' anat_dir_name '/qcp/FWHM.dat'];
    if exist(fFWHM, 'file')
        tmpFWHM = load(fFWHM);
        fwhm_x(k,1) = tmpFWHM(1); 
        fwhm_y(k,1) = tmpFWHM(2); 
        fwhm_z(k,1) = tmpFWHM(3); 
        fwhm(k,1) = mean(tmpFWHM);
    end
    %Artifact Detection: Qi1
    [histBG, centX] = hist(tmpBG(:));
    %idxX1 = (histBG==max(histBG));
    X1 = centX(histBG==max(histBG));
    idxAirThreshed = (volOrig>X1); %idxAirThreshed = (volT1==0)&(volOrig>X1);
    imgAirThreshed = zeros(size(volOrig));
    imgAirThreshed(idxAirThreshed) = volOrig(idxAirThreshed);
    tmpArtifect = spm_erode(imgAirThreshed); %need spm12
    tmpArtifect = spm_dilate(tmpArtifect); %need spm12
    tmpArtBG = tmpArtifect(idxAir);
    Qi1(k,1) = nnz(tmpArtBG)/bg_size;
    %Signal to Noise Ratio: SNR
    gmSNR(k,1) = gm_mean/bg_std; 
    wmSNR(k,1) = wm_mean/bg_std;
end
qcmetrics = table(anatCNR, gmSNR, wmSNR, anatFBER, anatEFC, Qi1, ...
    fwhm, fwhm_x, fwhm_y, fwhm_z);
