%% dir settings (may not usable for you and you have to change them...)
clear all; clc
meta_dir = '/Volumes/DJICopilot/REST-meta-PD';
ana_dir = [meta_dir '/nmm'];
fig_dir = [ana_dir '/group/figures'];
ccs_dir = '/Users/mac/Projects/CCS';
ccs_matlab = [ccs_dir '/matlab'];
ccs_vistool = [ccs_dir '/vistool'];
fs_home = '/Applications/freesurfer'; 
fsaverage = 'fsaverage5';

%% Set up the path to matlab function in Freesurfer release
addpath(genpath(ccs_matlab)) %ccs matlab scripts
addpath(genpath(ccs_vistool)) %ccs matlab scripts
addpath(genpath([fs_home '/matlab'])) %freesurfer matlab scripts

%% load centile charts
ftable = [ana_dir '/data/alff/gamlss.input.csv'];
charts_raw = readtable(ftable, 'Delimiter', ',');
histALFF = charts_raw.Var2;
ftable = [ana_dir '/data/alff/gamlss.predict.csv'];
charts = readtable(ftable, 'Delimiter', ',');
age_predict = ccs_core_double4cell(charts.Var2(2:end));
centile95 = ccs_core_double4cell(charts.Var7(2:end));
centile50 = ccs_core_double4cell(charts.Var5(2:end));
%male chart
ftable = [ana_dir '/data/alff/gamlss.predict.males.csv'];
charts_males = readtable(ftable, 'Delimiter', ',');
centile95_males = ccs_core_double4cell(charts_males.Var7(2:end));
centile50_males = ccs_core_double4cell(charts_males.Var5(2:end));
%female chart
ftable = [ana_dir '/data/alff/gamlss.predict.females.csv'];
charts_females = readtable(ftable, 'Delimiter', ',');
centile95_females = ccs_core_double4cell(charts_females.Var7(2:end));
centile50_females = ccs_core_double4cell(charts_females.Var5(2:end));

%% cohort-wise brain-behavior association studies
wALFF = []; UDPRS = []; Site = []; ALFF = [];
P_nmm = ones(15,1); R_nmm = zeros(15,1);
for chtID=1:15
    if chtID<10
        flist_cohort = [meta_dir '/info/Cohort_0' num2str(chtID) '.xlsx'];
    else
        flist_cohort = [meta_dir '/info/Cohort_' num2str(chtID) '.xlsx'];
    end
    [~,sheets,~] = xlsfinfo(flist_cohort);
    [num,txt,raw] = xlsread(flist_cohort,sheets{1});
    siteAge = num(:,1);
    siteSex = txt(3:end,4);
    siteGrp = txt(3:end,3);
    siteALFF = num(:,6);
    siteUDPRS = num(:,5);
    numSubj = numel(siteAge);
    idxPD = [];
    %get grp label
    for subjID=1:numSubj
        if strcmp(siteGrp{subjID},'PD')
            idxPD = [idxPD; subjID];
        end
    end
    ALFF_PD = siteALFF(idxPD);
    UDPRS_PD = siteUDPRS(idxPD);
    %t-test with nmm
    numPD = numel(idxPD);
    wALFF_PD = zeros(numPD,1);
    for subjID=1:numPD
        tmpALFF = siteALFF(idxPD(subjID));
        tmpage = siteAge(idxPD(subjID));
        tmpsex = siteSex(idxPD(subjID));
        [~,idxAGE] = min(abs(age_predict-tmpage));
        if strcmp(tmpsex,'f')
            muALFF = centile50_females(idxAGE);
            sdALFF = (centile95_females(idxAGE)-centile50_females(idxAGE))/2;
        else
            muALFF = centile50_males(idxAGE);
            sdALFF = (centile95_males(idxAGE)-centile50_males(idxAGE))/2;
        end
        wALFF_PD(subjID) = (tmpALFF-muALFF)/sdALFF;
    end
    idxPD_UDPRS = ~isnan(UDPRS_PD);
    wALFF_PD_tmp = wALFF_PD(idxPD_UDPRS);
    ALFF_PD_tmp = ALFF_PD(idxPD_UDPRS);
    UDPRS_PD_tmp = UDPRS_PD(idxPD_UDPRS);
    if sum(idxPD_UDPRS)>0
        Site = [Site; ones(numel(idxPD_UDPRS),1)*chtID];
        wALFF = [wALFF; wALFF_PD_tmp];
        ALFF = [ALFF; ALFF_PD_tmp];
        UDPRS = [UDPRS; UDPRS_PD_tmp];
        %Pearson correlation
        [tmpR,tmpP] = corrcoef(wALFF_PD_tmp,UDPRS_PD_tmp);
        R_nmm(chtID) = tmpR(2,1);
        P_nmm(chtID) = tmpP(2,1);
    end
end
[tmpR,tmpP] = corrcoef(wALFF,UDPRS);
%[tmpR0,tmpP0] = corrcoef(ALFF,UDPRS);