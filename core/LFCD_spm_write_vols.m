function [ V, P ] = LFCD_spm_write_vols( P_in, V_in, Y_in )
%LFCD_SPM_WRITE_VOLS Warp of spm_write_vol with an extension of writing 
%   out NIFTI_GZ volumes
%   Detailed explanation goes to spm_write_vol.m
% Author: Xi-Nian Zuo at Institute of Psychology, Chinese Academy of
% Sciences.

% Get the size of list of file names in cell P
n1 = length(P_in); n2 = length(V_in) ;
if n1 ~= n2
    disp('Numer of filenames are inconsistent with the number of volumes!')
else
    n = n1;
    % Read volume information
    P = cell(n,1); V = V_in;
    for k=1:n
        [pth,nm,xt] = fileparts(deblank(P_in{k}));
        if strcmp(xt, '.gz')
            P{k} = [pth '/' nm];
            V{k}.fname = P{k};
            V{k} = spm_write_vol(V{k}, Y_in{k});
            gzip(P{k});
            delete(P{k});
        else
            disp('This is not a gzipped nifti data.')
            P{k} = P_in{k};
            V{k}.fname = P{k};
            V{k} = spm_write_vol(V{k}, Y_in{k});
        end
    end
end

end

