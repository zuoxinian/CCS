function [ cALFF, cFALFF, cPLFF, cFPLFF] = ccshcp_core_alff(ts, TR, f_lp, f_hp )
% CCSHCP_CORE_ALFF Compute the amplitude/phase of low-frequency fluctuations (LFFs) by using 
% stationary (classic FFT).
%
%   Detailed explanation:
%    INPUT:
%       ts -- original time series
%       TR -- sampling segment in time domain
%       f_lp -- low frequency point
%       f_hp -- high freqency point
% Credits:
%      Xi-Nian Zuo, PhD of Applied Mathematics
%      Institue of Psychology, Chinese Academy of Sciences.
%      Email: zuoxn@psych.ac.cn or zuoxinian@gmail.com
%      Website: http://lfcd.psych.ac.cn

%% Predefine variables
fs = 1/TR ; N = length(ts);
if nargin < 2
    disp('Need TR information!')
end
if nargin < 3
    f_lp = 0.01;
end
if nargin <4
    f_hp = 0.1;
end
if rem(N,2)==0, 
  f_idx = 1:N/2;
else
  f_idx = 1:(N+1)/2;
end
f = (f_idx-1)/N; % default fs = 1, Xu Ting corrected at Dec 13, 2012.
%% compute time-frequency representation
cALFF=0; cFALFF=0; cPLFF=0; cFPLFF=0;
if std(ts)>0
% frequnecies of interest
idx_lp = find(f(f_idx) <= (1/fs)*f_lp, 1, 'last') + 1;
idx_hp = find(f >= (1/fs)*f_hp, 1, 'first') - 1;
% compute classic spectrum
ts = ts - mean(ts); % deal with DC component
ts_fft = fft(ts, N);
caspd = abs(ts_fft)/N;%amplitude spectrum
cpspd = angle(ts_fft)*180/pi;%phase spectrum in degrees
%% compute ALFF/fALFF
%cALFF
caspd_lf = caspd(idx_lp:idx_hp); 
cALFF = sum(caspd_lf);
%cALFF = sqrt(sum(cspd_lf));% To be compared in future. 
%total AFF
tAFF = sum(caspd(f_idx));
%tAFF = sqrt(sum(cspd(f_idx)));% To be compared in future. 
%FALFF
cFALFF = cALFF/tAFF;
%% compute PLFF/fPLFF
nfp = numel(idx_lp:idx_hp);
%cPLFF
cpspd_lf = cpspd(idx_lp:idx_hp); 
cPLFF = sum(cpspd_lf)/nfp;
%total PFF
tPFF = sum(cpspd(f_idx))/numel(f_idx);
%FPLFF
cFPLFF = cPLFF/tPFF;
end

