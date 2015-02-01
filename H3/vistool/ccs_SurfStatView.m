function [fnum_lh, fnum_rh] = ccs_SurfStatView( sig, dirsurf, typesurf, ...
    ifcurv, figout, fhot, fcold)
%CCS_SURFSTATVIEW 
% View and save surface data (with an option for overlay curvature).
% 
%USAGE:
% [ err ] = ccs_SurfStatView( sig, dirsurf, ifcurv, figout );
% 
% sig           = v x 1 vector of significance data (normally -log10(P)), 
%                 v=#vertices, zeros(1,v) if empty.
% dirsurf       = full path of directory for underlay surfaces 
%                 (e.g., ${FREESURFER}/subjects/fsaverage/surf).
% typesurf      = one of the three: pial, white, inflated.
% ifcurv        = if use curvature for visualization (true or false).
% figout        = full path of the name of the output figure
% fhot          = full path of the fname of the positive colormap.
% fcold         = full path of the fname of the negative colormap.
%
%AUTHOR:
% Xi-Nian Zuo, Institutue of Psychology, CAS
% Email: zuoxn@psych.ac.cn or zuoxinian@gmail.com
% Website: http://lfcd.psych.ac.cn
%
%REVISIONS:
% created at 12/03/12.
% revised at 12/07/12.

if nargin < 6; fhot = 'hotcolors.tif'; fcold = 'coldcolors.tif'; end
if nargin < 7; fcold = 'coldcolors.tif'; end

fs_home = dirsurf(1:end-24);
addpath([fs_home '/matlab']);
s = SurfStatReadSurf( {...
    [dirsurf '/lh.' typesurf], ... 
    [dirsurf '/rh.' typesurf]} );

%load curvature
fcurv = [dirsurf '/lh.curv'];
[curv_lh, fnum_lh] = read_curv(fcurv);
fcurv = [dirsurf '/rh.curv'];
[curv_rh, fnum_rh] = read_curv(fcurv);
curv = [curv_lh; curv_rh];

%comprise the surfaces 
idx_cluster = find(sig ~= 0);
minsig = min(sig(idx_cluster));
maxsig = max(sig(idx_cluster));
if minsig > 0
    cmap_pos = zeros(256,3);
    sig((curv<0)&(sig==0)) = minsig/4;
    sig((curv>0)&(sig==0)) = minsig/2; 
    %setup the colormap
    idx_keycurv1 = round(256*minsig/maxsig/3);
    idx_keycurv2 = fix(256*minsig/maxsig);
    cmap_pos((idx_keycurv2+1):256,:) = ...
        ccs_mkcolormap(fhot,256-idx_keycurv2);
    if strcmp(ifcurv, 'true')
        cmap_pos(1:idx_keycurv1,:) = 0.75; 
        cmap_pos(1+idx_keycurv1:idx_keycurv2,:) = 0.25;
    else
        cmap_pos(1:idx_keycurv2,:) = 0.5;
    end
    figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
    SurfStatView( sig, s, 'Significance: -log10(P)' ); 
    colormap(cmap_pos); SurfStatColLim([0 maxsig]);
    set(gcf, 'PaperPositionMode', 'auto');
    print('-djpeg', '-r300', figout); close
elseif maxsig < 0
    asig = abs(sig); cmap_neg = zeros(256,3);
    maxasig = max(asig(idx_cluster));
    minasig = min(asig(idx_cluster));
    asig((curv<0)&(asig==0)) = minasig/4;
    asig((curv>0)&(asig==0)) = minasig/2; 
    %setup the colormap
    idx_keycurv1 = round(256*minasig/maxasig/3);
    idx_keycurv2 = fix(256*minasig/maxasig);
    cmap_neg((idx_keycurv2+1):256,:) = ...
        ccs_mkcolormap(fcold,256-idx_keycurv2);
    if strcmp(ifcurv, 'true')
        cmap_neg(1:idx_keycurv1,:) = 0.75; 
        cmap_neg(1+idx_keycurv1:idx_keycurv2,:) = 0.25;
    else
        cmap_neg(1:idx_keycurv2,:) = 0.5;
    end
    figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
    SurfStatView( asig, s, 'Significance: -log10(P)' ); 
    colormap(cmap_neg); SurfStatColLim([0 maxasig]);
    set(gcf, 'PaperPositionMode', 'auto');
    print('-djpeg', '-r300', figout); close
else
    asig = abs(sig); cmap = zeros(256,3);
    maxasig = max(abs(sig(idx_cluster)));
    minasig = min(abs(sig(idx_cluster)));
    sig((curv<0)&(asig==0)) = minasig/4;
    sig((curv>0)&(asig==0)) = minasig/2;
    %setup the colormap
    idx_keycurv1 = round(128*minasig/maxasig/3);
    idx_keycurv2 = fix(128*minasig/maxasig);
    cmap((idx_keycurv2+1+128):256,:) = ...
        ccs_mkcolormap(fhot,128-idx_keycurv2);
    cmap((128-idx_keycurv2):-1:1,:) = ...
        ccs_mkcolormap(fcold,128-idx_keycurv2);
    if strcmp(ifcurv, 'true')
        cmap((128-idx_keycurv1):(128+idx_keycurv1),:) = 0.75; 
        cmap((128-idx_keycurv2+1):(128-idx_keycurv1-1),:) = 0.25;
        cmap((128+idx_keycurv1+1):(128+idx_keycurv2),:) = 0.25;
    else
        cmap((128-idx_keycurv2+1):(128+idx_keycurv2),:) = 0.5;
    end
    figure('Units', 'pixel', 'Position', [100 100 800 800]); axis off
    SurfStatView( sig, s, 'Significance: -log10(P)' ); 
    colormap(cmap); SurfStatColLim([-maxasig maxasig]);
    set(gcf, 'PaperPositionMode', 'auto');
    print('-djpeg', '-r300', figout); close
end

