function   dc = IPN_centDegree(CIJ)
% INPUTS
%   CIJ - connection/adjacent matrix

% OUTPUTS
%   dc - degree (i.e., num of edges linking to a node)
% AUTHOR:
%   Xi-Nian Zuo, Ph.D. of Applied Mathematics
%   Institute of Psychology, Chinese Academy of Sciences.
%   Email: ZuoXN@psych.ac.cn
%   Website: lfcd.psych.ac.cn

%if ifcorr
%    dc = sum(atanh(CIJ)); %Fisher-z transformation
%else
%    dc = sum(CIJ);
%end
dc = sum(CIJ);
dc = double(reshape(dc, length(dc), 1));