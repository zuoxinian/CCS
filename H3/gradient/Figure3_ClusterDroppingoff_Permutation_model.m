% Permuted null model of dropping off random clusters
% Author: Dong HaoMing
%% path setting
clear all;close all;
Fsdir=['/opt/software/freesurfer'];
addpath(genpath(Fsdir))
ccs_dir = ['/opt/software/CCS/ccs_develop/'];
addpath(genpath(ccs_dir))
npypath = ['/opt/github/npy-matlab-master/'];
addpath(genpath(npypath))

outdir = ['/dir/surfFC/output/'];
pngdir = [outdir '/Figure/'];
mkdir(pngdir)
agegroup = {'child','adolescent'};


%% surface structure loading for rendering
s_lh1 = SurfStatReadSurf([Fsdir '/subjects/fsaverage5/surf/lh.inflated']);
s_rh1 =  SurfStatReadSurf([Fsdir '/subjects/fsaverage5/surf/rh.inflated']);
s_lh2 = SurfStatReadSurf([Fsdir '/subjects/fsaverage5/surf/lh.mid']);
s_rh2 =  SurfStatReadSurf([Fsdir '/subjects/fsaverage5/surf/rh.mid']);
s_lh.tri = s_lh1.tri;
s_lh.coord = s_lh1.coord*0.7 + s_lh2.coord*0.3;
s_rh.tri = s_rh1.tri;
s_rh.coord = s_rh1.coord*0.7 + s_rh2.coord*0.3;
fcb = ['/path/colormap.png']; % load your colormap for surface rendering
cmap = ccs_mkcolormap(fcb);

%% brainmask loading (if you have)
maskdir = ['/home/donghm/Projects/Subcortical_Gradient/'];
lhmask = load_nifti([maskdir '/brainmask_lh_fs.nii.gz']);
lhmask = lhmask.vol;
rhmask = load_nifti([fmaskdir '/brainmask_rh_fs.nii.gz']);
rhmask = rhmask.vol;
brainmask = [lhmask;rhmask];
surfnum = sum(brainmask);

embdir = ['/dir/emb/output/']; % directory saving the gradient maps derived from dropping off random clusters
maskdir = [ '/dir/random_mask/']; % directory saving random masks in the previous step
refembdir = ['/Gradients_Margulies2016/Gradients_Margulies2016/fsaverage/']; % directory saveing the adults gradients from Margulies et al., 2016, PNAS
frefemblh = [refembdir '/hcp.adult.embed.grad_1.L.fsa5.func.nii.gz']; % load the first transmodal gradient in the adults population
frefembrh = [refembdir '/hcp.adult.embed.grad_1.R.fsa5.func.nii.gz'];
refemblhhdr = load_nifti(frefemblh);
refemblh = refemblhhdr.vol;
refembrhhdr = load_nifti(frefembrh);
refembrh = refembrhhdr.vol;
refemb = [refemblh ; refembrh];
frefemblh2 = [refembdir '/hcp.adult.embed.grad_2.L.fsa5.func.nii.gz']; % load the second unimodal gradient in the adults population
frefembrh2 = [refembdir '/hcp.adult.embed.grad_2.R.fsa5.func.nii.gz'];
refemblhhdr2 = load_nifti(frefemblh2);
refemblh2 = refemblhhdr2.vol;
refembrhhdr2 = load_nifti(frefembrh2);
refembrh2 = refembrhhdr2.vol;
refemb2 = [refemblh2 ; refembrh2];


%% Looping for the 500 permutations to generate the null distribution
Null_dist=[];
Null_dist2=[];
  
for cc = 1:500
    disp(num2str(cc))
    tmpname = sprintf(['%04s'],num2str(cc));
    fmasklh =  [maskdir '/' tmpname 'mask_lh.nii.gz'];
    fmaskrh = [maskdir '/' tmpname 'mask_rh.nii.gz'];
    masklhhdr = load_nifti(fmasklh);
    maskrhhdr = load_nifti(fmaskrh);
    masklh = masklhhdr.vol;
    maskrh = maskrhhdr.vol;
    clustermask = [masklh';maskrh'];
    embmask = brainmask .* (1- clustermask);
    femb = [embdir '/DropOff_' tmpname '_emb.npy']; % load gradient results dropping off randomly permuted cluster at each iteration.
    emb = readNPY(femb);
    emb1 = zeros(size(brainmask));
    emb1(embmask==1) = emb(:,1);
    tmpcorr = IPN_fastCorr(emb1,refemb); % caculate the correlation between the permuted gradients and adults gradients.
    Null_dist = [Null_dist abs(tmpcorr)];
    emb2 = zeros(size(brainmask));       
    emb2(embmask==1) = emb(:,2);
    tmpcorr2 = IPN_fastCorr(emb2,refemb2);
    Null_dist2 = [Null_dist2 abs(tmpcorr2)];
end    


%%
femb2test = [embdir '/child_exclude_cluster_T90_500_emb.npy']; % load the orginal children gradient maps derived from dropping off unpermutated ventral attention mask
tmpemb2test = readNPY(femb2test);
fmasklh = [mask_outdir '/euclideandist.lh.cluster.bin.T90_500.nii.gz']; % load the orginal unpermutated ventral attention mask 
mask2testlhhdr = load_nifti(fmasklh);
mask2testlh = mask2testlhhdr.vol;
fmaskrh = [mask_outdir '/euclideandist.rh.cluster.bin.T90_500.nii.gz']; % load the orginal unpermutated ventral attention mask
mask2testrhhdr = load_nifti(fmaskrh);
mask2testrh = mask2testrhhdr.vol;
mask2test = [mask2testlh;mask2testrh];
mask2test = brainmask .* (1-mask2test);

Femb2test = zeros(size(brainmask)); % First gradient map dropping off ventral attention areas to be examined
Femb2test(mask1test==1) = tmpemb2test(:,1);
Fcorr2test = IPN_fastCorr(Semb2test,refemb); % caculate the correlation between the first gradient dropping off ventral attention areas in children and adults transmodal gradient.
%p = numel(find( Null_dist>Corr2test))/numel(Null_dist);
pabs = numel(find( Null_distabs>abs(Fcorr2test)))/numel(Null_distabs); % caculte the percentiles of the orginal gradient in the null distribution

Semb2test = zeros(size(brainmask)); % Second gradient map to be examined
Semb2test(mask2test==1) = tmpemb2test(:,2);
Scorr2test = IPN_fastCorr(Femb2test,refemb2); % caculate the correlation between the second gradient dropping off ventral attention areas in children and adults unimodal gradient.
%p2 = numel(find( Null_dist2>Scorr2test))/numel(Null_dist2);
pabs2 = numel(find( Null_distabs2>abs(Scorr2test)))/numel(Null_distabs2); % caculte the percentiles of the orginal gradient in the null distribution

%% Histogram Figures
pngdir = [ '/directory/to/save/Figure/'];
figure('visible','off')
histogram(Null_dist)
set(gca, 'box','off')
fout = [pngdir '/T90_A500_Permutation500_emb1.png'];
saveas(gcf,fout,'png')
close


figure('visible','off')
histogram(Null_dist2)
set(gca, 'box','off')
fout = [pngdir '/AbsT90_A500_Permutation500_emb2.png'];
saveas(gcf,fout,'png')
close

