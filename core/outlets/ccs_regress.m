function [ res_dt ] = ccs_regress( tsmat, X)
%CCS_REGRESS Matrix version of regress function.
%   Detailed explanation goes here

[ntp, nsp] = size(tsmat); %num of time points, num of spatial points
res_tsmat = zeros(ntp, nsp);
for ii=1:nsp        
   tmp_ts = squeeze(tsmat(:,ii));
   if std(tmp_ts) > 0
      [~, ~, res_tmpts] = regress(tmp_ts, X);
      res_tsmat(:,ii) = res_tmpts;
   end
end
% detrend
res_dt = detrend(res_tsmat);

