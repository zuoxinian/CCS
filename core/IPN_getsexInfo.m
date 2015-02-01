function [ o_sex ] = IPN_getsexInfo( i_sex )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here
% Xi-Nian Zuo

num = length(i_sex);
o_sex = zeros(num,1);
for k=1:num
    if strcmp(i_sex{k}, 'm')
        o_sex(k) = 1;
    elseif strcmp(i_sex{k}, 'f')
        o_sex(k) = 0;
    end
end

