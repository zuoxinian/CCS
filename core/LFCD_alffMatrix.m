function [ cALFF, cFALFF] = LFCD_alffMatrix(tsmat, TR, f_lp, f_hp )
% LFCD_ALFF Compute the amplitude/phase of low-frequency fluctuations (LFFs) by using 
% stationary (classic FFT).
%
%   Detailed explanation:
%    INPUT:
%       tsmat -- original time series
%       TR -- sampling segment in time domain
%       f_lp -- low frequency point
%       f_hp -- high freqency point
% Credits:
%      Xi-Nian Zuo, PhD of Applied Mathematics
%      Institue of Psychology, Chinese Academy of Sciences.
%      Email: zuoxn@psych.ac.cn or zuoxinian@gmail.com
%      Website: http://lfcd.psych.ac.cn

%% Predefine variables
[Nt, Ns] = size(tsmat); %Nt: number of time points; Ns: number of samples
if nargin < 2
    disp('Need TR information!')
end
if nargin < 3
    f_lp = 0.01;
end
if nargin <4
    f_hp = 0.1;
end
cALFF = zeros(Ns,1); cFALFF = zeros(Ns,1);
for samid=1:Ns
    ts = tsmat(:,samid);
    [cALFF(samid), cFALFF(samid)] = LFCD_alff(ts, TR, f_lp, f_hp);
end

