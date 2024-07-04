% Script for rendering the gradient map on the FreeSurfer fsaverageX surface.
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
embdir = ['/your_emb_dir/'];

%% surface structure loading for rendering
s_lh1 = SurfStatReadSurf([Fsdir '/subjects/fsaverage/surf/lh.inflated']);
s_rh1 =  SurfStatReadSurf([Fsdir '/subjects/fsaverage/surf/rh.inflated']);
s_lh2 = SurfStatReadSurf([Fsdir '/subjects/fsaverage/surf/lh.mid']);
s_rh2 =  SurfStatReadSurf([Fsdir '/subjects/fsaverage/surf/rh.mid']);
s_lh.tri = s_lh1.tri;
s_lh.coord = s_lh1.coord*0.7 + s_lh2.coord*0.3;
s_rh.tri = s_rh1.tri;
s_rh.coord = s_rh1.coord*0.7 + s_rh2.coord*0.3;
fcb = ['/path/colormap.png']; % load your colormap for surface rendering
cmap = ccs_mkcolormap(fcb);

%% brainmask loading (if you have)
maskdir = ['/directory/of/brainmask/files/'];
lhmask = load_nifti([maskdir '/brainmask_lh_fs.nii.gz']);
lhmask = lhmask.vol;
rhmask = load_nifti([fmaskdir '/brainmask_rh_fs.nii.gz']);
rhmask = rhmask.vol;
brainmask = [lhmask;rhmask];
surfnum = sum(brainmask);


%% rendering surface gradient maps
for gg = 1:2
        femb = [embdir '/' agegroup{gg} 'emb.npy' ];  % load gradient map
        emb = readNPY(femb);
        surfemb = zeros(surfnum,size(emb,2));        
        surfemb(brainmask == 1,:) = emb;
        % rendering the first two gradient maps
        for ee = 1:2            
            figure('visible','off')      
						SurfStatViewData(surfemb(1:surfnum/2,ee),tmps_lh1);
						colormap(cmap) % change the colormap         
            fout = [ pngdir '/emb' num2str(ee) '_lh.png']);
            saveas(gcf,fout,'png')
            close
            figure('visible','off')
            SurfStatViewData(surfemb(surfnum/2+1:end,ee),tmps_rh1);
						colormap(cmap) % change the colormap         
            fout = [ pngdir '/emb' num2str(ee) '_rh.png']);
            saveas(gcf,fout,'png')
            close         
end


%% rendering surface gradient maps with network/areas dropped off
fcmask = ['/directory/of/network/mask/dorpped/off'];
fNetmasklh = sprintf([fcmask '/euclideandist.lh.cluster.T90_500.nii.gz']);
Netlh = load_nifti(fNetmasklh);
Netlh =Netlh.vol;
fNetmaskrh = sprintf([fcmask '/euclideandist.rh.cluster.T90_500.nii.gz']);
Netrh = load_nifti(fNetmaskrh);
Netrh = Netrh.vol;
Netmask = [Netlh;Netrh];

ebrainmask = brainmask .* (1-Netmask);
elhmask = ebrainmask(1:10242);
erhmask = ebrainmask(10243:end);
for gg = 1:2
    femb = sprintf([embdir '/' agegroup{gg} '_exclude_cluster_T90_500_emb.npy' ]);
    emb = readNPY(femb);
    surfemb = zeros(20484,size(emb,2));
    
    surfemb(ebrainmask == 1,:) = emb;
    for ee = 1:2
        figure('visible','off')
        [~,cb,~] = SurfStatViewData(surfemb(1:surfnum/2,ee),tmps_lh1);
        fout = sprintf([ pngdir '/' agegroup{gg} '_emb' num2str(ee) '_exclude_net_lh.png']);
        saveas(gcf,fout,'png')
        close
        figure('visible','off')
        [~,cb,~] = SurfStatViewData(surfemb(surfnum/2+1:end),tmps_rh1);
        fout = sprintf([ pngdir '/' agegroup{gg} '_emb' num2str(ee) '_exclude_net_rh.png']);
        saveas(gcf,fout,'png')
        close
        
    end
end
