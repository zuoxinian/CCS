function [cmap_out, cmap] = ccs_extractcolormaps(fIMAGE, ncolors, nseg)
%CCS_EXTRACTCOLORMAPs Extract a set of colormaps from an image including
% the colorbars (e.g., from a paper or website) for brain visualization.
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
%   created at 06/08/16.

if nargin < 2 
    ncolors = 256; nseg = 0;
elseif nargin < 3
    nseg = 0; 
end

cmap_img = imread(fIMAGE);
[nr, nc, ~] = size(cmap_img);
cmap = []; cmap_out = [];
%scan row by row
cmap_img = double(cmap_img); cmapID = 0;
for rowID=1:(nr-1)
    midCol = round(nc/2); 
    tmpmidcol = squeeze(cmap_img(:,midCol,:));
    tmpcolor1 = tmpmidcol(rowID,:);
    tmpcolor2 = tmpmidcol(rowID+1,:);
    condL1 = (sum(tmpcolor1-255)==0) || (sum(tmpcolor1)==0);%white or black
    condL2 = (sum(tmpcolor2-255)==0) || (sum(tmpcolor2)==0);
    %detect start row
    if (condL1) && (~condL2)
        startRow = rowID + 1;
        cmapID = cmapID + 1;
    end
    %detect end row
    if (~condL1) && (condL2)
        endRow = rowID;
        midcmapRow = round(0.5*(startRow+endRow));
        tmpmidrow = squeeze(cmap_img(midcmapRow,:,:));
        %scan column by column
        for colID=1:(nc-1)
            tmpcolor3 = tmpmidrow(colID,:);
            tmpcolor4 = tmpmidrow(colID+1,:);
            condC1 = (sum(tmpcolor3-255)==0) || (sum(tmpcolor3)==0);
            condC2 = (sum(tmpcolor4-255)==0) || (sum(tmpcolor4)==0);
            %detect start column
            if (condC1) && (~condC2)
                startCol = colID + 1;
            end
            %detect end column
            if (~condC1) && (condC2)
                endCol = colID;
            end
        end
        idxcmap = round(linspace(startCol, endCol, ncolors));
        tmpcmap = squeeze(cmap_img(midcmapRow,idxcmap,:));
        %no need this for high version MATLAB but may for some lower version MATLAB
        if max(tmpcmap(:)) > 1 
            tmpcmap = double(tmpcmap)/255;
        else
            tmpcmap = double(tmpcmap);
        end
        %segment into discrete colors
        if nseg > 0
            tmpcmap_out = zeros(nseg, 3);
            step = fix(ncolors/nseg);
            for k = 1:nseg
                tmpcmap_out(k,:) = tmpcmap(round(0.5*(2*k-1)*step), :);
            end
        else
            tmpcmap_out = tmpcmap;
        end
        %set up the cell of colormaps
        cmap{cmapID} = tmpcmap;
        cmap_out{cmapID} = tmpcmap_out;
    end
end

