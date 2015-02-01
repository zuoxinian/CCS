function [ MZ_r, DZ_r, H, Z ] = IPN_falH( MZ_t1, MZ_t2, DZ_t1, DZ_t2, MZ_covar, DZ_covar )
%IPN_FALH The program calculates the classical Falconer's method to
%   estimate the heritability of phenotype based on twins sample.
% Inputs:
%   MZ_t1    -- nx1 vector: the twin1 vector of MZ twins;
%   MZ_t2    -- nx1 vector: the twin2 vector of MZ twins;
%   DZ_t1    -- mx1 vector: the twin1 vector of DZ twins;
%   DZ_t2    -- mx1 vector: the twin2 vector of DZ twins;
%   MZ_covar -- px1 cell: p covariates for MZ twins, each cell includes nx2 matrix;
%   DZ_covar -- qx1 cell: q covariates for DZ twins, each cell includes mx2 matrix;
%
% Outputs:
%   MZ_r -- MZ twins correlation;
%   DZ_r -- DZ twins correlation;
%   H    -- Falconer's heritability up-bounded by MZ_r;
%   Z    -- Fisher's Z-test converts heritability to Z-statistics;
%
% Author:
%   Xi-Nian Zuo, Ph.D.
%   Associate Research Scientist
%   NYU Langone Medical Center
%   
    
% Getting number of covariates for both MZ and DZ twins.
    if nargin < 4
        disp('Need 4 inputs at least: MZ_t1, MZ_t2, DZ_t1 and DZ_t2 ...')
    else
        n_mz = length(MZ_t1); n_dz = length(DZ_t1);
        if nargin == 4
            MZ_t1_res = MZ_t1;
            MZ_t2_res = MZ_t2;
            DZ_t1_res = DZ_t1;
            DZ_t2_res = DZ_t2;
        end
        
        if nargin > 4
            ncovar1 = length(MZ_covar);
            covar_mz1 = zeros(n_mz, ncovar1); 
            covar_mz2 = zeros(n_mz, ncovar1); 
            %MZ covariates
            for k=1:ncovar1
                tmp = MZ_covar{k};
                covar_mz1(:,k) = tmp(:,1);
                covar_mz2(:,k) = tmp(:,2);
            end
            [~, ~, MZ_t1_res] = regress(MZ_t1, IPN_demean(covar_mz1));
            [~, ~, MZ_t2_res] = regress(MZ_t2, IPN_demean(covar_mz2));
            DZ_t1_res = DZ_t1; 
            DZ_t2_res = DZ_t2; 
        end
        
        if nargin > 5
            ncovar2 = length(DZ_covar);
            covar_dz1 = zeros(n_dz, ncovar2);
            covar_dz2 = zeros(n_dz, ncovar2);
            %DZ covariates
            for k=1:ncovar2
                tmp = DZ_covar{k};
                covar_dz1(:,k) = tmp(:,1);
                covar_dz2(:,k) = tmp(:,2);
            end
            [~, ~, DZ_t1_res] = regress(DZ_t1, IPN_demean(covar_dz1));
            [~, ~, DZ_t2_res] = regress(DZ_t2, IPN_demean(covar_dz2));
            clear b1 bint1 ; clear b2 bint2
        end
    end
    %Regressing out covariates
    
    %MZ
    MZ_r = corr(MZ_t1_res, MZ_t2_res);
    %DZ
    DZ_r = corr(DZ_t1_res, DZ_t2_res);
    %Heritability
    hrt = 2 * (MZ_r - DZ_r);
    H = min(MZ_r, hrt);
    if H == MZ_r
        Z = IPN_FisherZtest(MZ_r, 0, numel(MZ_t1), numel(DZ_t1));
    else
        Z = IPN_FisherZtest(MZ_r, DZ_r, numel(MZ_t1), numel(DZ_t1));
    end
    
end