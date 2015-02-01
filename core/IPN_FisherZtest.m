function Z = IPN_FisherZtest(r1,r2, N1, N2)
%% Author: Xi-Nian Zuo

if ((abs(r1)-1)*(abs(r2)-1)) == 0
    Z = 0;
else
    fs_z1 = atanh(r1);
    fs_z2 = atanh(r2);
    Z = (fs_z1 - fs_z2)/ sqrt(1 / (N1 - 3) + 1 / (N2 - 3));
end

if isnan(Z)
    Z = 0;
end