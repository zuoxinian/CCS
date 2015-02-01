%% IPN_subCell.m
function [Csub] = IPN_subCell(C, idx)
% Xi-Nian Zuo: xinian.zuo@nyumc.org.

for k=1:length(idx)
    Csub{k} = C{idx(k)};
end