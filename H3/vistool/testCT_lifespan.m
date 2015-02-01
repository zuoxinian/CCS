clear all ; clc
%% test RFT-FDR: 2dReHo lifespan changes
work_dir = '/Users/mac/Documents/MATLAB/vis';
ana_dir = '/Users/mac/Documents/MATLAB/nki_lifespan';
fig_dir = [ana_dir '/figures'];
if ~exist(fig_dir, 'dir')
    mkdir(ana_dir, 'figures')
end
diraverage = '/opt/freesurfer/subjects/fsaverage';
s = SurfStatReadSurf( {... 
    [diraverage '/surf/lh.pial'], ... 
    [diraverage '/surf/rh.pial']} );

%% Run FWE-FDR cluster level correction: linear trajectory models
vwthresh = 0.01; FWEthresh = 0.025;
%lh thickness
yfile = [ana_dir '/morph/lh.thickness.10.nii.gz'];
glmdir = [ana_dir '/morph/g2v2.thickness.lh'];
sgn = 1;
r = ccs_mri_surfrft_jlbr(yfile,glmdir,vwthresh,sgn);
sgn = -1;
r = ccs_mri_surfrft_jlbr(yfile,glmdir,vwthresh,sgn);
%rh thickness
yfile = [ana_dir '/morph/rh.thickness.10.nii.gz'];
glmdir = [ana_dir '/morph/g2v2.thickness.rh'];
sgn = 1;
r = ccs_mri_surfrft_jlbr(yfile,glmdir,vwthresh,sgn);
sgn = -1;
r = ccs_mri_surfrft_jlbr(yfile,glmdir,vwthresh,sgn);

%% Run FWE-FDR cluster level correction: quadratic trajectory models
%lh reho
yfile = [ana_dir '/morph/lh.thickness.10.nii.gz'];
glmdir = [ana_dir '/morph/g2v3.thickness.lh'];
sgn = 1;
r = ccs_mri_surfrft_jlbr(yfile,glmdir,vwthresh,sgn);
sgn = -1;
r = ccs_mri_surfrft_jlbr(yfile,glmdir,vwthresh,sgn);
%rh reho
yfile = [ana_dir '/morph/rh.thickness.10.nii.gz'];
glmdir = [ana_dir '/morph/g2v3.thickness.rh'];
sgn = 1;
r = ccs_mri_surfrft_jlbr(yfile,glmdir,vwthresh,sgn);
sgn = -1;
r = ccs_mri_surfrft_jlbr(yfile,glmdir,vwthresh,sgn);

%% Lifespan changes: linear trajectory
%lh reho
dirglmstats = [ana_dir '/morph/g2v2.thickness.lh/g1g2.age'];
fsig = [dirglmstats '/sig.mgh'];
lh_sig = load_mgh(fsig); lh_tmpsig = zeros(size(lh_sig));
fsig = [dirglmstats '/sig.cw.pos.mgh'];
lh_cw_possig = load_mgh(fsig);
idx = find(lh_cw_possig >= (-log10(FWEthresh)));
if ~isempty(idx)
    lh_tmpsig(idx) = lh_sig(idx);
end
fsig = [dirglmstats '/sig.cw.neg.mgh'];
lh_cw_negsig = load_mgh(fsig);
idx = find(lh_cw_negsig <= log10(FWEthresh));
lh_tmpsig(idx) = lh_sig(idx);
%rh reho
dirglmstats = [ana_dir '/morph/g2v2.thickness.rh/g1g2.age'];
fsig = [dirglmstats '/sig.mgh'];
rh_sig = load_mgh(fsig); rh_tmpsig = zeros(size(rh_sig));
fsig = [dirglmstats '/sig.cw.pos.mgh'];
rh_cw_possig = load_mgh(fsig);
idx = find(rh_cw_possig >= (-log10(FWEthresh)));
if ~isempty(idx)
    rh_tmpsig(idx) = rh_sig(idx);
end
fsig = [dirglmstats '/sig.cw.neg.mgh'];
rh_cw_negsig = load_mgh(fsig);
idx = find(rh_cw_negsig <= log10(FWEthresh));
rh_tmpsig(idx) = rh_sig(idx);
%visualization
if ~isempty(find([lh_tmpsig; rh_tmpsig])>0)
    ccs_SurfStatView([lh_tmpsig; rh_tmpsig], [diraverage '/surf'], ...
        'inflated', 'true', [fig_dir '/thickness.age.linear.inflated.jpeg'])
    ccs_SurfStatView([lh_tmpsig; rh_tmpsig], [diraverage '/surf'], ...
        'white', 'true', [fig_dir '/thickness.age.linear.white.jpeg'])
end

%% Lifespan changes: quaratic trajectory
%lh reho
dirglmstats = [ana_dir '/morph/g2v3.thickness.lh/g1g2.age2'];
fsig = [dirglmstats '/sig.mgh'];
lh_sig = load_mgh(fsig); lh_tmpsig = zeros(size(lh_sig));
fsig = [dirglmstats '/sig.cw.pos.mgh'];
lh_cw_possig = load_mgh(fsig);
idx = find(lh_cw_possig >= (-log10(FWEthresh)));
if ~isempty(idx)
    lh_tmpsig(idx) = lh_sig(idx);
end
fsig = [dirglmstats '/sig.cw.neg.mgh'];
lh_cw_negsig = load_mgh(fsig);
idx = find(lh_cw_negsig <= log10(FWEthresh));
lh_tmpsig(idx) = lh_sig(idx);
%rh reho
dirglmstats = [ana_dir '/morph/g2v3.thickness.rh/g1g2.age2'];
fsig = [dirglmstats '/sig.mgh'];
rh_sig = load_mgh(fsig); rh_tmpsig = zeros(size(rh_sig));
fsig = [dirglmstats '/sig.cw.pos.mgh'];
rh_cw_possig = load_mgh(fsig);
idx = find(rh_cw_possig >= (-log10(FWEthresh)));
if ~isempty(idx)
    rh_tmpsig(idx) = rh_sig(idx);
end
fsig = [dirglmstats '/sig.cw.neg.mgh'];
rh_cw_negsig = load_mgh(fsig);
idx = find(rh_cw_negsig <= log10(FWEthresh));
rh_tmpsig(idx) = rh_sig(idx);
%visualization
if ~isempty(find([lh_tmpsig; rh_tmpsig])>0)
    ccs_SurfStatView([lh_tmpsig; rh_tmpsig], [diraverage '/surf'], ...
        'inflated', 'true', [fig_dir '/thickness.age.quad.inflated.jpeg'])
    ccs_SurfStatView([lh_tmpsig; rh_tmpsig], [diraverage '/surf'], ...
        'white', 'true', [fig_dir '/thickness.age.quad.white.jpeg'])
end

%% Lifespan changes: sex differences
%lh reho
dirglmstats = [ana_dir '/morph/g2v2.thickness.lh/group.diff'];
fsig = [dirglmstats '/sig.mgh'];
lh_sig = load_mgh(fsig); lh_tmpsig = zeros(size(lh_sig));
fsig = [dirglmstats '/sig.cw.pos.mgh'];
lh_cw_possig = load_mgh(fsig);
idx = find(lh_cw_possig >= (-log10(FWEthresh)));
if ~isempty(idx)
    lh_tmpsig(idx) = lh_sig(idx);
end
fsig = [dirglmstats '/sig.cw.neg.mgh'];
lh_cw_negsig = load_mgh(fsig);
idx = find(lh_cw_negsig <= log10(FWEthresh));
if ~isempty(idx)
    lh_tmpsig(idx) = lh_sig(idx);
end
%rh reho
dirglmstats = [ana_dir '/morph/g2v2.thickness.rh/group.diff'];
fsig = [dirglmstats '/sig.mgh'];
rh_sig = load_mgh(fsig); rh_tmpsig = zeros(size(rh_sig));
fsig = [dirglmstats '/sig.cw.pos.mgh'];
rh_cw_possig = load_mgh(fsig);
idx = find(rh_cw_possig >= (-log10(FWEthresh)));
if ~isempty(idx)
    rh_tmpsig(idx) = rh_sig(idx);
end
fsig = [dirglmstats '/sig.cw.neg.mgh'];
rh_cw_negsig = load_mgh(fsig);
idx = find(rh_cw_negsig <= log10(FWEthresh));
if ~isempty(idx)
    rh_tmpsig(idx) = rh_sig(idx);
end
%visualization
if ~isempty(find([lh_tmpsig; rh_tmpsig])>0)
    ccs_SurfStatView([lh_tmpsig; rh_tmpsig], [diraverage '/surf'], ...
        'inflated', 'true', [fig_dir '/thickness.sex.inflated.jpeg'])
    ccs_SurfStatView([lh_tmpsig; rh_tmpsig], [diraverage '/surf'], ...
        'white', 'true', [fig_dir '/thickness.sex.white.jpeg'])
end
