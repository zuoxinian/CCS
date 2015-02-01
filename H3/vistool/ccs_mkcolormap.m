function [cmap_out, cmap] = ccs_mkcolormap(fIMAGE, ncolors, nseg)
%CCS_MKCOLORMAP Generate a colormap from a image including the colorbar
% (e.g., from a paper or website) for AFNI visualization.
%
%INPUTS:
%   fIMAGE -- A colorbar image from published papers or other softwares;
%   ncolors -- Number of colors (default 256);
%   nseg - Number of color segments (default 0);
%
%OUTPUTS:
%   cmap -- Colormap usable in MATLAB;
%   cmap_out -- Colormap with nseg color segments.
%
%USAGE:
%   1). dlmwrite('figure/cmap_heritp.txt',cmap,' ')
%   2). MakeColorMap -f cmap_heritp.txt -nc 256 -ah cmap_heritp > cmap_heritp.pal
%   3). Modify the head line in cmap_heritp.pal to "cmap_heritp:red_to_blue"
%
%AUTHOR:
% Xi-Nian Zuo, Institutue of Psychology, CAS
% Email: zuoxn@psych.ac.cn or zuoxinian@gmail.com
% Website: http://lfcd.psych.ac.cn
%
%REVISIONS:
%   created at 12/01/10.
%   revised at 12/07/12.

if nargin < 2 
    ncolors = 256; nseg = 0;
elseif nargin < 3
    nseg = 0; 
end

cmap_img = imread(fIMAGE);
[nr, nc, ~] = size(cmap_img);
if nc > nr % A horizonal colorbar
    nr_rs = round(nr*ncolors/nc);
    cmap_rs = imresize(cmap_img,[nr_rs ncolors]);
    cmap = squeeze(cmap_rs(round(nr_rs/2),:,:));
else       % A veritical colorbar
    nc_rs = round(nc*ncolors/nr);
    cmap_rs = imresize(cmap_img,[ncolors nc_rs]);
    cmap = squeeze(cmap_rs(:,round(nc_rs/2),:));
    cmap = cmap(end:-1:1,:);
end
%no need this for high version MATLAB but may for some lower version MATLAB
if max(cmap(:)) > 1 
    cmap = double(cmap)/255;
else
    cmap = double(cmap);
end

if nseg > 0
    cmap_out = zeros(nseg, 3);
    step = fix(ncolors/nseg);
    for k = 1:nseg
        cmap_out(k,:) = cmap(round(0.5*(2*k-1)*step), :);
    end
else
    cmap_out = cmap;
end