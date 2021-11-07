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

%% get subjects list - 15 cohorts
age = []; sex = []; grp = []; ALFF = [];
for chtID=1:15
    if chtID<10
        flist_cohort = [meta_dir '/info/Cohort_0' num2str(chtID) '.xlsx'];
    else
        flist_cohort = [meta_dir '/info/Cohort_' num2str(chtID) '.xlsx'];
    end
    [~,sheets,~] = xlsfinfo(flist_cohort);
    [num,txt,raw] = xlsread(flist_cohort,sheets{1});
    age = [age; num(:,1)];
    sex = [sex; txt(3:end,4)];
    grp = [grp; txt(3:end,3)];
    ALFF = [ALFF; num(:,6)];
end

%% prepare control samples for GAMLSS
numSubj = numel(age); idxHC = [];
for subjID=1:numSubj
    if strcmp(grp{subjID},'PH')
        idxHC = [idxHC; subjID];
    end
end
%sex differ
age_HC = age(idxHC); ALFF_HC = ALFF(idxHC); sex_HC = sex(idxHC);
idxHC_female = []; idxHC_male = [];
numHC = numel(age_HC);
for subjID=1:numHC
    if strcmp(sex_HC{subjID},'f')
        idxHC_female = [idxHC_female; subjID];
    else
        idxHC_male = [idxHC_male; subjID];
    end
end
%% save data into txt files
fmdir = [ana_dir '/data/alff'];
%both
gamlss = [age_HC ALFF_HC];
fgamlss = [fmdir '/gamlss.input.csv'];
csvwrite(fgamlss, gamlss);
%male
age_males = age_HC(idxHC_male);
metric_males = ALFF_HC(idxHC_male);
gamlss = [age_males metric_males];
fgamlss = [fmdir '/gamlss.males.input.csv'];
csvwrite(fgamlss, gamlss);
%female
age_females = age_HC(idxHC_female);
metric_females = ALFF_HC(idxHC_female);
gamlss = [age_females metric_females];
fgamlss = [fmdir '/gamlss.females.input.csv'];
csvwrite(fgamlss, gamlss);
