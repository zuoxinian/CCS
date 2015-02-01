function [ idx ] = LFCD_matchstrCell( strcell, pattern)
%UNTITLED5 Summary of this function goes here
%   Detailed explanation goes here
idx = [];
for k=1:numel(strcell)
    if strcmp(strcell{k}, pattern)
        idx = [idx k];
    end
end

