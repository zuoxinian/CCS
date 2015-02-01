function [ MZ_r, DZ_r, H, Z ] = IPN_falH( MZ_t1, MZ_t2, DZ_t1, DZ_t2 )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
    
    %MZ
    MZ_r = corr(MZ_t1, MZ_t2);
    %DZ
    DZ_r = corr(DZ_t1, DZ_t2);
    %Heritability
    hrt = 2 * (MZ_r - DZ_r);
    H = min(MZ_r, hrt);
    if H == MZ_r
        %Z = IPN_compR2Z(MZ_r, 0, numel(MZ_t1), numel(DZ_t1));
        Z = IPN_FisherZtest(MZ_r, 0, numel(MZ_t1), numel(DZ_t1));
    else
        %Z = IPN_compR2Z(MZ_r, DZ_r, numel(MZ_t1), numel(DZ_t1));
        Z = IPN_FisherZtest(MZ_r, DZ_r, numel(MZ_t1), numel(DZ_t1));
    end
    
end

