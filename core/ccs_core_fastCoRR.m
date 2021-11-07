%% Compute Pair-correlation between two sample matrices.
function R = ccs_core_fastCoRR(X, Y)
% INPUTS:
%   X - nxp1 sample matrix, n is the number of samples and p1 is the number
%       of random variables;
%   Y - nxp2 sample matrix, n is the number of samples and p2 is the number
%       of random variables;
% OUTPUTS:
%   R - p1xp2 sample correlation matrix.
% AUTHOR:
%   Xi-Nian Zuo, Ph.D. of Applied Mathematics
%   Institute of Psychology, Chinese Academy of Sciences.
%   Email: ZuoXN@psych.ac.cn
%   Website: lfcd.psych.ac.cn

[numSamp1 ~] = size(X); % n*p1
[numSamp2 ~] = size(Y); % n*p2

if (numSamp1 ~= numSamp2)
    disp('The two matices must have the same size of rows!')
else
    X = (X - repmat(mean(X), numSamp1, 1))./repmat(std(X, 0, 1), numSamp1, 1);
    Y = (Y - repmat(mean(Y), numSamp1, 1))./repmat(std(Y, 0, 1), numSamp1, 1);
    R = X' * Y / (numSamp1 - 1);
    R(isnan(R)) = 0; R(abs(R)>=1)=1; %exclude some positions with round errors.
end
