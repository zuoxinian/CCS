%% Computes multiple frequency bands of low frequency oscillations
function freqbands = ccs_core_lfobands(samp_numbers, samp_interval)
%% Oscillation bands follow a linear progression in the natural logarithmic scale.
% INPUTS:
%   samp_numbers - number of samples of a timeseries
%   samp_interval - interval of sampling across time (seconds)
% OUTPUTS:
%   freqbands - a cell containing all the validate frequency bands
% AUTHOR:
%   Xi-Nian Zuo, Ph.D. of Applied Mathematics
%   Institute of Psychology, Chinese Academy of Sciences.
%   Email: ZuoXN@psych.ac.cn
%   Website: zuolab.psych.ac.cn
% VERSION:
%   v1.0 released in 2017/12/30
%   v1.1 released in 2020/02/17
% REFERENCE:
%   [1] Markku Penttonen, Gyorgy Buzs¨¢ki (2003). Natural logarithmic relationship between 
%       brain oscillators. Thalamus & Related Systems 2: 145?152.
%   [2] Gyorgy Buzs¨¢ki, Andreas Draguhn (2004). Neuronal Oscillations in
%       Cortical Networks. Science 304: 1926-1929.
%   [3] M¨¹ller T, et al (2003). Detection of very low-frequency oscillations of cerebral 
%       haemodynamics is influenced by data detrending. Med Biol Eng Comput 41: 69-74.

%% Set up variables
N = samp_numbers; TR = samp_interval;
fmax = 1/(2*TR); fmin = 1/(N*TR/2);
if rem(N,2)==0 
    fnum = N/2; 
else
    fnum = (N+1)/2; 
end
freq = linspace(0,fmax,fnum+1);
tmpidx = find(freq<=fmin);
frmin = freq(tmpidx(end)+4); % minimal reliable frequency [3]

%% Determine the range of frequencies in natural log space
nlcfmin = round(log(frmin)); 
nlcfmax = round(log(fmax));
nlcf = nlcfmin:nlcfmax;
numbands = numel(nlcf);
freqbands = cell(numbands,1);
for nlcfID=1:numbands
    [~,idxfmin] = min(abs(freq-exp(nlcf(nlcfID)-0.5)));    
    [~,idxfmax] = min(abs(freq-exp(nlcf(nlcfID)+0.5)));
    freqbands{nlcfID} = [freq(idxfmin) freq(idxfmax)];
end
%modify the min band and max band
tmpf = freqbands{1};
if tmpf(1)<frmin
    tmpf(1) = frmin;
    freqbands{1} = tmpf;
end
tmpf = freqbands{end};
if tmpf(2)>fmax
    tmpf(2) = fmax;
    freqbands{end} = tmpf;
end

end