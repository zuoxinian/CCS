function   r = IPN_centCommunicability(CIJ, type)
%Ross Ehmke, Xi-Nian Zuo edited in 09/09/2010.
%inputs
%           CIJ    connection matrix
%          
%
%outputs
%           r      communicability
%notes: diagonal 1/0s, no matters.
%=================================================
if nargin < 2
    type = 'b';
end

switch type
    case 'b'
        B = expm(CIJ) ; 
        r = sum(B')/length(CIJ) ;
    case 'w'
        B = sum(CIJ')' ;
        C = diag(B) ;
        D = C^(-(1/2)) ;
        E = D * CIJ * D ;
        F = expm(E) ;
        r = sum(F') ;
    otherwise
        disp('Please assign a correct type of networks ...')
end
