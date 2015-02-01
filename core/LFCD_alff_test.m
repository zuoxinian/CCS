function [ cALFF, sALFF, wALFF, cFALFF, sFALFF, wFALFF] = LFCD_alff_test(ts, TR, f_lp, f_hp )
% LFCD_ALFF Compute the amplitude of low-frequency fluctuations (LFFs) by using both 
% stationary (classic FFT) and non-stationary (short-time FT and wavelet) timeseries analysis.
% Note: please first install time-frequency toolbox (TFTB) from the link below:
%  http://tftb.nongnu.org/

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
%      Website: http://lfcd/psych.ac.cn

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
f = f_idx/N; % default fs = 1
%% compute time-frequency representation
% frequnecies of interest
idx_lp = find(f(f_idx) <= (1/fs)*f_lp, 1, 'last') + 1;
idx_hp = find(f >= (1/fs)*f_hp, 1, 'first') - 1;
% compute classic spectrum
cspd = abs(fft(ts, N)).^2;
% Short-time FFT
tfr_stft = tfrstft(ts, 1:N, N);
% Wavelet Spectrum
[~, ~, f_morelet, wt] = tfrscalo(ts, 1:N, sqrt(N), f(2), f(idx_hp));
%% compute ALFF/fALFF
%cALFF
cspd_lf = cspd(idx_lp:idx_hp); cALFF = sqrt(sum(cspd_lf)); 
%sALFF
spd = abs(tfr_stft(f_idx,:)).^2; 
spd_lf = spd(idx_lp:idx_hp,:); sALFF = sqrt(sum(spd_lf(:)));
%wALFF
scalo = abs(wt).^2;
idx_wlp = find(f_morelet <= (1/fs)*f_lp, 1, 'last') + 1;
scalo_lf = scalo(idx_wlp:end,:); wALFF = sqrt(sum(scalo_lf(:)));
%total AFF
tAFF = sqrt(sum(cspd(f_idx)));
%FALFF
cFALFF = cALFF/tAFF; sFALFF = sALFF/tAFF; wFALFF = wALFF/tAFF; 

end

