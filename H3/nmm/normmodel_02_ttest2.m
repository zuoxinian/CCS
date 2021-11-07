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

%% cohort-wise comparisons
p = ones(15,1); t = zeros(15,1); ci = zeros(15,2); stats = cell(15,1);
p_nmm = ones(15,1); t_nmm = zeros(15,1); ci_nmm = zeros(15,2); stats_nmm = cell(15,1);
%p_bayes = ones(15,1); t_bayes = zeros(15,1);
for chtID=1:15
    if chtID<10
        flist_cohort = [meta_dir '/info/Cohort_0' num2str(chtID) '.xlsx'];
    else
        flist_cohort = [meta_dir '/info/Cohort_' num2str(chtID) '.xlsx'];
    end
    [~,sheets,~] = xlsfinfo(flist_cohort);
    [num,txt,raw] = xlsread(flist_cohort,sheets{1});
    age = num(:,1);
    sex = txt(3:end,4);
    grp = txt(3:end,3);
    ALFF = num(:,6);
    numSubj = numel(age);
    idxHC = []; idxPD = [];
    %get grp label
    for subjID=1:numSubj
        if strcmp(grp{subjID},'PH')
            idxHC = [idxHC; subjID];
        else
            idxPD = [idxPD; subjID];
        end
    end
    %t-test2
    ALFF_PD = ALFF(idxPD);
    ALFF_HC = ALFF(idxHC);
    [~,p(chtID),ci(chtID,:),stats{chtID,1}] = ttest2(ALFF_PD,ALFF_HC);
    t(chtID) = stats{chtID,1}.tstat;
    %t-test with nmm
    numPD = numel(idxPD);
    wALFF_PD = zeros(numPD,1);
    for subjID=1:numPD
        tmpALFF = ALFF(idxPD(subjID));
        tmpage = age(idxPD(subjID));
        tmpsex = sex(idxPD(subjID));
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
    [~,p_nmm(chtID),ci_nmm(chtID,:),stats_nmm{chtID,1}] = ttest(wALFF_PD);
    t_nmm(chtID) = stats_nmm{chtID,1}.tstat;
    %t-test with Bayesian adjustation
    %[p_bayes(chtID),t_bayes(chtID)] = ccs_ttest2_bayesadj(ALFF_PD,ALFF_HC,histALFF);
end


