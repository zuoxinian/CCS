%% ANOVA with repeated measures - DREAM demo1
clear all; clc; load('dream1_FD.mat')
boyAge = HM(1:42,1); girlAge = HM(43:84,1);
boyHM = HM(1:42,2:6); girlHM = HM(43:84,2:6); 
lnHM = log(HM); 
%frequency index
Freq = [1 2 3 4 5]';

%% ages: 3-6
idxBoy = find((boyAge>=3)&(boyAge<7)); numBoys = numel(idxBoy);
idxGirl = find((girlAge>=3)&(girlAge<7)); numGirls = numel(idxGirl);
boyHM1 = boyHM(idxBoy,:); girlHM1 = girlHM(idxGirl,:);
%gender 
Gender = cell(numBoys+numGirls,1);
for idxB=1:numBoys
    Gender{idxB,1} = 'Boy';
end
for idxG=(numBoys+1):(numBoys+numGirls)
    Gender{idxG,1} = 'Girl';
end
%frequency bands
HM1 = [boyHM1; girlHM1];
t1 = table(Gender,HM1(:,1),HM1(:,2),HM1(:,3),HM1(:,4),HM1(:,5),...
'VariableNames',{'Gender','f1','f2','f3','f4','f5'});
%Fit a repeated measures model
rm1 = fitrm(t1,'f1-f5 ~ Gender','WithinDesign',Freq);
%Perform repeated measures analysis of variance.
ranovatbl1 = ranova(rm1);
%frequency bands: log scale
lnHM1 = log(HM1);
lnt1 = table(Gender,lnHM1(:,1),lnHM1(:,2),lnHM1(:,3),lnHM1(:,4),lnHM1(:,5),...
'VariableNames',{'Gender','f1','f2','f3','f4','f5'});
%Fit a repeated measures model: log scale
rm1_ln = fitrm(lnt1,'f1-f5 ~ Gender','WithinDesign',Freq);
%Perform repeated measures analysis of variance: log scale
ranovatbl1_ln = ranova(rm1_ln);

%% ages: 7-10
idxBoy = find((boyAge>=7)&(boyAge<10)); numBoys = numel(idxBoy);
idxGirl = find((girlAge>=7)&(girlAge<10)); numGirls = numel(idxGirl);
boyHM2 = boyHM(idxBoy,:); girlHM2 = girlHM(idxGirl,:);
%gender 
Gender = cell(numBoys+numGirls,1);
for idxB=1:numBoys
    Gender{idxB,1} = 'Boy';
end
for idxG=(numBoys+1):(numBoys+numGirls)
    Gender{idxG,1} = 'Girl';
end
%frequency bands
HM2 = [boyHM2; girlHM2];
t2 = table(Gender,HM2(:,1),HM2(:,2),HM2(:,3),HM2(:,4),HM2(:,5),...
'VariableNames',{'Gender','f1','f2','f3','f4','f5'});
%Fit a repeated measures model
rm2 = fitrm(t2,'f1-f5 ~ Gender','WithinDesign',Freq);
%Perform repeated measures analysis of variance.
ranovatbl2 = ranova(rm2);
%frequency bands: log scale
lnHM2 = log(HM2);
lnt2 = table(Gender,lnHM2(:,1),lnHM2(:,2),lnHM2(:,3),lnHM2(:,4),lnHM2(:,5),...
'VariableNames',{'Gender','f1','f2','f3','f4','f5'});
%Fit a repeated measures model: log scale
rm2_ln = fitrm(lnt2,'f1-f5 ~ Gender','WithinDesign',Freq);
%Perform repeated measures analysis of variance: log scale
ranovatbl2_ln = ranova(rm2_ln);

%% ages: 10-17
idxBoy = find((boyAge>=10)&(boyAge<17)); numBoys = numel(idxBoy);
idxGirl = find((girlAge>=10)&(girlAge<17)); numGirls = numel(idxGirl);
boyHM3 = boyHM(idxBoy,:); girlHM3 = girlHM(idxGirl,:);
%gender 
Gender = cell(numBoys+numGirls,1);
for idxB=1:numBoys
    Gender{idxB,1} = 'Boy';
end
for idxG=(numBoys+1):(numBoys+numGirls)
    Gender{idxG,1} = 'Girl';
end
%frequency bands
HM3 = [boyHM3; girlHM3];
t3 = table(Gender,HM3(:,1),HM3(:,2),HM3(:,3),HM3(:,4),HM3(:,5),...
'VariableNames',{'Gender','f1','f2','f3','f4','f5'});
%Fit a repeated measures model
rm3 = fitrm(t3,'f1-f5 ~ Gender','WithinDesign',Freq);
%Perform repeated measures analysis of variance.
ranovatbl3 = ranova(rm3);
%frequency bands: log scale
lnHM3 = log(HM3);
lnt3 = table(Gender,lnHM3(:,1),lnHM3(:,2),lnHM3(:,3),lnHM3(:,4),lnHM3(:,5),...
'VariableNames',{'Gender','f1','f2','f3','f4','f5'});
%Fit a repeated measures model: log scale
rm3_ln = fitrm(lnt3,'f1-f5 ~ Gender','WithinDesign',Freq);
%Perform repeated measures analysis of variance: log scale
ranovatbl3_ln = ranova(rm3_ln);
