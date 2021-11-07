function zstat = ccs_icc2zstat( rho, N, d )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

zstat = sqrt((N-2)*(d-1)/2*d)*log((1+(d-1)*rho)./(1-rho));

end

