%% Computes the Kendall's W.
function [W,p,Fdist]=IPN_kendallW(X,tied)
% X is a n*k ratings matrix.
% n is the number of objects and k is the number of judges.

[n,k]=size(X);
if tied
    [R,T]=tiedrank(X);
    T=sum(logical(repmat([1:n]',1,k)-sort(round(R))))+1;
    RS=sum(R,2);
    S=sum(RS.^2)-n*mean(RS).^2;
    F=k*k*(n*n*n-n)-k*sum(T.^3-T);
    W=12*S/F;
else
    [Y,I]=sort(X);
    [Y,R]=sort(I);
    RS=sum(R,2);
    S=sum(RS.^2)-n*mean(RS).^2;
    F=k*k*(n*n*n-n);
    W=12*S/F;
end
%Chi=k*(n-1)*W;
%p=chi2pdf(Chi,n-1);
Fdist=W*(k-1)./(1-W);
nu1 = n-1-(2/k);
nu2 = nu1*(k-1);
p=fpdf(Fdist,nu1,nu2);
