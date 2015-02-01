function [ V, P_out, Y ] = LFCD_spm_read_vols( P_in )
%LFCD_SPM_READ_VOLS Warp of spm_read_vols with an extension of reading 
%   NIFTI_GZ volumes
%   Detailed explanation goes to spm_read_vols.m
% Author: Xi-Nian Zuo at Institute of Psychology, Chinese Academy of
% Sciences.

% Get the size of list of file names in cell P
n = length(P_in);
% Unzip all data to the same directory
gunzip(P_in);
% Read volume information
P_out = cell(n,1); V = cell(n,1); Y = cell(n,1);
for k=1:n
    [pth,nm,xt] = fileparts(deblank(P_in{k}));
    if strcmp(xt, '.gz')
        P_out{k} = [pth '/' nm];
        V{k} = spm_vol(P_out{k});
        [Y{k},~] = spm_read_vols(V{k});
        delete(P_out{k});
    else
        disp('This is not a gzipped nifti data.')
        P_out{k} = P_in{k};
        V{k} = spm_vol(P_out{k});
        [Y{k},~] = spm_read_vol(V{k});
    end
end

end

