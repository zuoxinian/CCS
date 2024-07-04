% Script for generating clusters with random surface locations. 
% Author: Dong HaoMing
% The functions and commands applied here to rotate the surface are from the Spin-Test toolbox (https://github.com/spin-test/spin-test).
%% path setting
clear all;close all;
Fsdir=['/opt/software/freesurfer'];
addpath(genpath(Fsdir))
ccs_dir = ['/opt/software/CCS/ccs_develop/'];
addpath(genpath(ccs_dir))
Spindir = ['/path/github/spin-test-master/'];
addpath(genpath(Spindir));
maskdir = ['/dir/surfFC/output/']; % directory saving the areas with the largest Euclidean distance between groups
pngdir = [outdir '/Figure/'];
agegroup = {'child','adolescent'};


Type = ['T90_area500'];
fmasklh = [maskdir '/' Type '/euclideandist.lh.cluster.bin.T90_500.nii.gz']; % load the mask to be permutated
fmaskrh = [maskdir '/' Type '/euclideandist.rh.cluster.bin.T90_500.nii.gz'];
masklhhdr = load_nifti(fmasklh);
masklh = masklhhdr.vol;
maskrhhdr = load_nifti(fmaskrh);
maskrh = maskrhhdr.vol;
csvdir = [maskdir '/' Type '/spin_csv'];
mkdir(csvdir)
fmasklhcsv = [csvdir '/' Type '_lhmask.csv;']
fmaskrhcsv = [csvdir '/' Type '_rhmask.csv;']
csvwrite(fmasklhcsv,masklh);
csvwrite(fmaskrhcsv,maskrh);
permno = 500; % how many spins
outPerm = [Type '_SpinPermu_' num2str(permno) '.mat'];
wsname = sprintf([csvdir '/' outPerm]);


s_lh1 = SurfStatReadSurf([Fsdir '/subjects/fsaverage5/surf/lh.pial']);
s_rh1 =  SurfStatReadSurf([Fsdir '/subjects/fsaverage5/surf/rh.pial']);
surf_coord = [s_lh1.coord s_rh1.coord];
tmps_lh1 = SurfStatReadSurf([Fsdir '/subjects/fsaverage5/surf/lh.inflated']);
tmps_rh1 =  SurfStatReadSurf([Fsdir '/subjects/fsaverage5/surf/rh.inflated']);
tmps_lh2 = SurfStatReadSurf([Fsdir '/subjects/fsaverage5/surf/lh.mid']);
tmps_rh2 =  SurfStatReadSurf([Fsdir '/subjects/fsaverage5/surf/rh.mid']);
tmps_lh.tri = tmps_lh1.tri;
tmps_lh.coord = tmps_lh1.coord*0.7 + tmps_lh2.coord*0.3;
tmps_rh.tri = tmps_rh1.tri;
tmps_rh.coord = tmps_rh1.coord*0.7 + tmps_rh2.coord*0.3;
MWl = zeros(1,10242);
MWr = zeros(1,10242);
[vl, left_labels, ctl] = read_annotation(fullfile(Fsdir,'/subjects/fsaverage5/label/lh.aparc.a2009s.annot'));
MWl(left_labels==1644825)=1;


% right:
[vr,right_labels,ctr] = read_annotation(fullfile(Fsdir,'/subjects/fsaverage5/label/rh.aparc.a2009s.annot'));
MWr(right_labels==1644825)=1;
MW = [MWl MWr];
pngdir = [csvdir '/png'];
mkdir(pngdir);
odir = [csvdir '/random_mask/'] % directory to save random masks
mkdir(odir)
k = 1;
% Rendering the initial mask
fout = [pngdir '/0000mask_lh.png']; 
figure('visible','off')
tmplh = masklh; 
SurfStatViewData(tmplh,tmps_lh1);
saveas(gcf,fout,'png')
close
fout = [pngdir '/0000mask_rh.png'];
figure('visible','off')
tmprh = maskrh; 
SurfStatViewData(tmprh,tmps_rh1);
saveas(gcf,fout,'png')
close

t=1;
datal=importdata(fmasklhcsv); %datal = datal.data(); % .data() part may or may not be needed
datar=importdata(fmaskrhcsv);%datar = datar.data(); % .data() part may or may not be needed
[vl, left_labels, ctl] = read_annotation(fullfile(Fsdir,'/subjects/fsaverage5/label/lh.aparc.a2009s.annot'));
datal(left_labels==1644825)=NaN;

% right:
[vr,right_labels,ctr] = read_annotation(fullfile(Fsdir,'/subjects/fsaverage5/label/rh.aparc.a2009s.annot'));
datar(right_labels==1644825)=NaN;

%%extract the corresponding sphere surface coordinates for rotation
[verticesl, ~] = freesurfer_read_surf(fullfile(Fsdir,'subjects/fsaverage5/surf/lh.sphere'));
[verticesr, ~] = freesurfer_read_surf(fullfile(Fsdir,'subjects/fsaverage5/surf/rh.sphere'));
rng('default');

while k<permno+1
    t
    [tmpbigrotl,tmpbigrotr] = SpinPermuFSD(datal,datar,verticesl,verticesr);
    Permumask = [tmpbigrotl tmpbigrotr];
    Permumask(isnan(Permumask)) = 0;
    if sum(MW .* Permumask) == 0 % ensure that the rotated mask is not overlapped with the medial wall, otherwise the number of vertex is not identical across permutations         
    tmplh = Permumask(1:10242);
    tmprh = Permumask(10243:end);
    N = sprintf('%04s',num2str(k));
    %fout = [pngdir '/' N 'mask_lh.png'];
    %figure('visible','off')
    %SurfStatViewData(tmplh,tmps_lh1);
    %saveas(gcf,fout,'png')
    %close
    masklhhdr.vol = tmplh;
    fout = [odir '/' N 'mask_lh.nii.gz'];
    save_nifti(masklhhdr,fout);
    fout = [pngdir '/' N 'mask_rh.png'];
    %figure('visible','off')
    %SurfStatViewData(tmprh,tmps_rh1);
    %saveas(gcf,fout,'png')
    %close
    maskrhhdr.vol = tmprh;
    fout = [odir '/' N 'mask_rh.nii.gz'];
    save_nifti(maskrhhdr,fout);
    t=t+1;
    k = k+1;
    end
end