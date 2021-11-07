clear all; clc

%% dir settings (may not usable for you and you have to change them...)
ana_dir = '/Volumes/RAID/projects/nki_lifespan';
work_dir = [ana_dir '/group/Circos'];
func_dir_name = 'func'; rest_name = 'rest';
ccs_matlab_dir = '/Users/mac/Projects/ccs_matlab';
ccs_bash_dir = '/Users/mac/Projects/ccs_bash';
fs_home = '/opt/freesurfer'; fsaverage = 'fsaverage5';
%Set up the path to matlab function in Freesurfer release
addpath([fs_home '/matlab'])
sub_list = [ana_dir '/scripts/subjects_lifespan149.list'];
subjects = num2cell(importdata(sub_list));
numSubjects = numel(subjects);

%% load Destrieux2010 parcels
%full names
Destrieux2010 = importdata([ccs_matlab_dir '/etc/Destrieux2010.dat']);
%abbr names
Destrieux2010_abbr = importdata([ccs_matlab_dir '/etc/Destrieux2010_abbr.dat']);
%RGB codes
Destrieux2010_rgb = load([ccs_matlab_dir '/etc/Destrieux2010_rgb.dat']);

%% Load regional volume, cotical thickness and area.
% get correct order of the parcels
fthickness = [ana_dir '/group/FS/aparc.a2009s.thickness.lh.txt'];
tmpdata = importdata(fthickness); tmpparcels = cell(74,1);
for k=1:74
    tmpstring = tmpdata.textdata{1,k+1};
    tmpparcels{k} = tmpstring(4:end-10);
end
idx_reorder = zeros(74,1);
for k=1:74
    idx_reorder(k) = ccs_strfind(tmpparcels, Destrieux2010{k});
end
% mean thickness
CT_lh = tmpdata.data(:,idx_reorder);
fthickness = [ana_dir '/group/FS/aparc.a2009s.thickness.rh.txt'];
tmpdata = importdata(fthickness);
CT_rh = tmpdata.data(:,idx_reorder);
% mean area
farea = [ana_dir '/group/FS/aparc.a2009s.area.lh.txt'];
tmpdata = importdata(farea);
AREA_lh = tmpdata.data(:,idx_reorder);
farea = [ana_dir '/group/FS/aparc.a2009s.area.rh.txt'];
tmpdata = importdata(farea);
AREA_rh = tmpdata.data(:,idx_reorder);
% mean curvature
fcurv = [ana_dir '/group/FS/aparc.a2009s.meancurv.lh.txt'];
tmpdata = importdata(fcurv);
CURV_lh = tmpdata.data(:,idx_reorder);
fcurv = [ana_dir '/group/FS/aparc.a2009s.meancurv.rh.txt'];
tmpdata = importdata(fcurv);
CURV_rh = tmpdata.data(:,idx_reorder);
% mean volume
fvol = [ana_dir '/group/FS/aparc.a2009s.volume.lh.txt'];
tmpdata = importdata(fvol);
VOL_lh = tmpdata.data(:,idx_reorder);
fvol = [ana_dir '/group/FS/aparc.a2009s.volume.rh.txt'];
tmpdata = importdata(fvol);
VOL_rh = tmpdata.data(:,idx_reorder);
% subcortical areas: only volume
segStats = importdata([ana_dir '/group/FS/aseg.stats.txt']);
tmpData = segStats.data; tmpHeaders = segStats.colheaders;
idx_subcort = 75:82; name_subcort = ccs_subcell(Destrieux2010, idx_subcort);
numSubcort = numel(idx_subcort); 
% lh
idx_aseg_subcort_lh = zeros(numSubcort,1);
for k=1:numSubcort
    tmpParcel = ['Left-' name_subcort{k}];
    idx_aseg_subcort_lh(k) = ccs_strfind(tmpHeaders, tmpParcel);
end
VOL_lh_subcort = tmpData(:, idx_aseg_subcort_lh);
% rh
idx_aseg_subcort_rh = zeros(numSubcort,1);
for k=1:numSubcort
    tmpParcel = ['Right-' name_subcort{k}];
    idx_aseg_subcort_rh(k) = ccs_strfind(tmpHeaders, tmpParcel);
end
VOL_rh_subcort = tmpData(:, idx_aseg_subcort_rh);
% brain-stem
VOL_brainstem = tmpData(:, ccs_strfind(tmpHeaders, 'Brain-Stem'));
% icv
VOL_icv = tmpData(:, ccs_strfind(tmpHeaders, 'IntraCranialVol')); 
VOL_gm = tmpData(:, ccs_strfind(tmpHeaders, 'TotalGrayVol'));
% Shape into the metric vectors
VOL = [VOL_lh VOL_lh_subcort VOL_rh VOL_rh_subcort VOL_brainstem];
%save
save([work_dir '/metricsMorph.mat'], 'CT_lh', 'CT_rh', 'VOL', 'VOL_icv', 'VOL_gm', ...
    'AREA_lh', 'AREA_rh', 'CURV_lh', 'CURV_rh')

%% Compute individual network metrics for DTI derived Connectome
numROI = 165;
DCsconn = zeros(numSubjects, numROI); zDCsconn = DCsconn;
BCsconn = zeros(numSubjects, numROI); zBCsconn = BCsconn;
for k=1:numSubjects
    disp(['Calculating connectivity matrix for subject ' num2str(subjects{k}) ' ...'])
    dti_dir = [ana_dir '/' num2str(subjects{k}) '/dti64'];
    load([dti_dir '/graph/numFibersConn.mat']);
    %weighted
    AdjMat = numFibersConn/numFibers;
    %centrality
    DCsconn(k, :) =  IPN_centDegree(AdjMat);
    BCsconn(k, :) = IPN_centBetweenness(AdjMat, 1);
    zDCsconn(k, :) = zscore(DCsconn(k, :));
    zBCsconn(k, :) = zscore(BCsconn(k, :));
end
%save results
save([work_dir '/metricsSCONN.mat'], 'DCsconn', 'zDCsconn', 'BCsconn', 'zBCsconn')

%% Compute individual network metrics for RFMRI derived Connectome
numROI = 165;
DCfconn = zeros(numSubjects, numROI); zDCfconn = DCfconn;
ECfconn = zeros(numSubjects, numROI); zECfconn = ECfconn;
for k=1:numSubjects
    disp(['Computing Network Centrality for Subject: ' num2str(subjects{k}) ' ...'])
    tmpConn = load([ana_dir '/' num2str(subjects{k}) '/func/graph/pearsonConn.mat']);
    AdjMat = tmpConn.pearsonConn; AdjMat(AdjMat < 0) = 0; % ignore negative correlation
    %Centrality
    DCfconn(k, :) =  IPN_centDegree(AdjMat);
    ECfconn(k, :) = IPN_centEigenvector(AdjMat);
    zDCfconn(k, :) = zscore(DCfconn(k, :));
    zECfconn(k, :) = zscore(ECfconn(k, :));    
end
[ALFFfconn, FALFFfconn] = lfcd_06_singlesubjectParcelALFF( ana_dir, sub_list, ...
    rest_name, func_dir_name );
[CCCfconn, ReHofconn] = lfcd_06_singlesubjectParcelCCC( ana_dir, sub_list, ...
    rest_name, func_dir_name );
%save results
save([work_dir '/metricsFCONN.mat'], 'DCfconn', 'zDCfconn', 'ECfconn', 'zECfconn', ...
    'ALFFfconn', 'FALFFfconn', 'CCCfconn', 'ReHofconn')
