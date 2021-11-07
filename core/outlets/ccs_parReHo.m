function [ cReHo ] = ccs_parReHo( tsmat, nbrs, nlabs )
%CCS_PARREHO Parallel version of ReHo Computation
%   Detailed explanation goes here
if nargin < 3
    nlabs = 8;
end
[ntp, nsp] = size(tsmat); %num of time points, num of spatial points
matlabpool('open', nlabs)
parfor ii=1:nsp        
   tmp_ts = squeeze(tsmat(:,ii));
   tmp_nbrs = nbrs{ii};
   nbrs_ts = squeeze(tsmat(:,tmp_nbrs));% total 7/20 or 6/19 neighbor vertices
   ts = [tmp_ts nbrs_ts(:,std(nbrs_ts,1,1)>0)]; 
   m = size(ts, 2); [~,I]=sort(ts); [~,R]=sort(I);
   S=sum(sum(R,2).^2)-ntp*mean(sum(R,2)).^2;
   F=m*m*(ntp*ntp*ntp-ntp); cReHo(ii)=12*S/F;
end
matlabpool('close')
