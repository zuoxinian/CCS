function [seedvertex, seedhemi] = ccshcp_seedvertex_conte69(mnicoord, conte69_home)
% CCSHCP_SEEDVERTEX_CONTE69 Locate the nearest seed vertex of interests on the standard surface.
%
%   Detailed explanation:
%    INPUT:
%       mnicoord -- [x,y,z] coordinates in the MNI brain space
%       conte69_home -- home directory of the Conte69 standard surfaces
% Credits:
%      Xi-Nian Zuo, PhD of Applied Mathematics
%      Institue of Psychology, Chinese Academy of Sciences.
%      Email: zuoxn@psych.ac.cn or zuoxinian@gmail.com
%      Website: http://lfcd.psych.ac.cn

%% load the geometry of the 32k_ConteAtlas
conte69_lh = gifti([conte69_home '/Conte69.L.midthickness.32k_fs_LR.surf.gii']);
coords_lh = conte69_lh.vertices;
conte69_rh = gifti([conte69_home '/Conte69.R.midthickness.32k_fs_LR.surf.gii']);
coords_rh = conte69_rh.vertices;
%Searching for seed vertex
numseeds = size(mnicoord,1); seedvertex = zeros(numseeds,1);
for idxseed=1:numseeds
    tmpseed = mnicoord(idxseed,:);
    if tmpseed(1) < 0
        seedhemi{idxseed} = 'lh';
        tmpvec = coords_lh - repmat(tmpseed, size(coords_lh,1), 1);
        seed_dist = tmpvec(:,1).^2 + tmpvec(:,2).^2 + tmpvec(:,3).^2;
        [~, seedvertex(idxseed)] = min(seed_dist);
    end
    if tmpseed(1) > 0
        seedhemi{idxseed} = 'rh';
        tmpvec = coords_rh - repmat(tmpseed, size(coords_rh,1), 1);
        seed_dist = tmpvec(:,1).^2 + tmpvec(:,2).^2 + tmpvec(:,3).^2;
        [~, seedvertex(idxseed)] = min(seed_dist);
    end
end
