function [ cReHo, zReHo ] = ccs_ReHo( tsmat, nbrs)
%CCS_REHO MATLAB version of ReHo Computation
%   tsmat -- time series across neighbors (TxN)
%   nbrs -- neighbors
%
% Author: Xi-Nian Zuo at IPCAS, Dec., 18, 2016.
% Modified by Xi-Nian Zuo at IPCAS, Dec., 18, 2016.

[ntp, nsp] = size(tsmat); %num of time points, num of spatial points
cReHo = zeros(nsp,1); zReHo = zeros(nsp,1);
for ii=1:nsp
   if ~mod(ii,500) 
    disp(['Completing ' num2str(ii/nsp*100) ...
        ' percent units processed ...'])
   end
   tmp_ts = squeeze(tsmat(:,ii));
   if std(tmp_ts) > 0
       tmp_nbrs = nbrs{ii};
       nbrs_ts = squeeze(tsmat(:,tmp_nbrs));% total 7/20 or 6/19 neighbor vertices
       ts = [tmp_ts nbrs_ts(:,std(nbrs_ts,1,1)>0)]; 
       m = size(ts, 2); [~,I]=sort(ts); [~,R]=sort(I);
       S=sum(sum(R,2).^2)-ntp*mean(sum(R,2)).^2;
       F=m*m*(ntp*ntp*ntp-ntp); 
       W=12*S/F;
       if W ~= 1
           cReHo(ii) = W;
           zReHo(ii) = (m-1)*W/(1-W); %Fisher Z transform
       end
   end
end

