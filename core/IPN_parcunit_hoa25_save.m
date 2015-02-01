function IPN_parcunit_hoa25_save( vec, template,outfname )
%
%   XiNian.Zuo@nyumc.org
template_list = importdata(template);
[nii, dims] = read_avw(template_list{1});
parc_vol = zeros(dims(1), dims(2), dims(3));
numRegions = length(vec);
%vec = vec/max(vec);
parc_vol(nii>0) = vec(1);
for k=2:numRegions
    nii = read_avw(template_list{k});
    parc_vol(nii>0) = vec(k);
end

save_avw(parc_vol, outfname, 'f', [dims(1) dims(2) dims(3) 1])
