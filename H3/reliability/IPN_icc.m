%% Computes the interclass correlations for indexing the reliability analysis 
%% according to shrout & fleiss' schema.
function [ICC,ICCL,ICCU] = IPN_icc(x,cse,typ)
% INPUT:
%   x   - ratings data matrix, data whose columns represent different
%         ratings/raters & whose rows represent different cases or 
%         targets being measured. Each target is assumed too be a random
%         sample from a population of targets.
%   cse - 1 2 or 3: 1 if each target is measured by a different set of 
%         raters from a population of raters, 2 if each target is measured
%         by the same raters, but that these raters are sampled from a 
%         population of raters, 3 if each target is measured by the same 
%         raters and these raters are the only raters of interest.
%   typ - 'single' or 'k': denotes whether the ICC is based on a single
%         measurement or on an average of k measurements, where 
%         k = the number of ratings/raters.
%    
% REFERENCE:
%   Shrout PE, Fleiss JL. Intraclass correlations: uses in assessing rater
%   reliability. Psychol Bull. 1979;86:420-428
%
% NOTE:
%   This code was mainly modified with the Kevin's codes in web. 
%   (London kevin.brownhill@kcl.ac.uk)
%
% XINIAN ZUO
% Email: zuoxinian@gmail.com

% if isanova
%     [p,table,stats] = anova1(x',{},'off');
%     ICC=(table{2,4}-table{3,4})/(table{2,4}+table{3,3}/(table{2,3}+1)*table{3,4});
% else
    
%k is the number of raters, and n is the number of tagets
[n,k]=size(x);
%mean per target
mpt = mean(x,2);
%mean per rater/rating
mpr = mean(x);
%get total mean
tm = mean(x(:));
%within target sum sqrs
tmp = (x - repmat(mpt,1,k)).^2;
WSS = sum(tmp(:));
%within target mean sqrs
WMS = WSS / (n*(k - 1));
%between rater sum sqrs
RSS = sum((mpr - tm).^2) * n;
%between rater mean sqrs
RMS = RSS / (k - 1);
%between target sum sqrs
BSS = sum((mpt - tm).^2) * k;
%between targets mean squares
BMS = BSS / (n - 1);
%residual sum of squares
ESS = WSS - RSS;
%residual mean sqrs
EMS = ESS / ((k - 1) * (n - 1));
switch cse
    case 1
        switch typ
            case 'single'
                ICC = (BMS - WMS) / (BMS + (k - 1) * WMS);
            case 'k'
                ICC = (BMS - WMS) / BMS;
            otherwise
               error('Wrong value for input typ') 
        end
    case 2
        switch typ
            case 'single'
                ICC = (BMS - EMS) / (BMS + (k - 1) * EMS + k * (RMS - EMS) / n);
            case 'k'
                ICC = (BMS - EMS) / (BMS + (RMS - EMS) / n);
            otherwise
               error('Wrong value for input typ') 
        end
    case 3
        switch typ
            case 'single'
                ICC = (BMS - EMS) / (BMS + (k - 1) * EMS);
            case 'k'
                ICC = (BMS - EMS) / BMS;
            otherwise
               error('Wrong value for input typ') 
        end
    otherwise
        error('Wrong value for input cse')
end