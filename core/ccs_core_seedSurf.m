function [seedROI, seed_surfcoord, hemi] = ccs_core_seedSurf( seed_coord, fs_home, ...
    fsaverage, ccs_home, plot_seeds)
%CCS_CORE_SEEDSURF Computing the region of interests seeded by a vertex.
% INPUT --
%   seed_coord -- an N*3 array of MNI coordinates of N vertices (seeds)
%   fs_home -- the fullpath of FreeSurfer software
%   fsaverage -- the fsaverage file name (commonly fsaverage5)
%   ccs_home -- the fullpath of CCS pipeline
%   plot_seeds -- if plot seeds on cortical surfaces
% OUTPUT --
%   seedROI -- an N*1 cell containing N arrays of path-two neighbours
%   seed_surfcoord -- An N*3 array of seeds on the surface
%   hemi -- the hemisphere of the seed belonging to
%
% Author: Xi-Nian Zuo at IPCAS, Nov., 26, 2014.
% Updated: Xi-Nian Zuo at IPCAS, Dec., 16, 2014.

[numSeeds, dim] = size(seed_coord);
if dim~=3
    disp('The input seems not an array of 3D coordinates.')
    exit
end
%add paths
addpath(genpath([fs_home '/matlab']));
ccs_matlab_dir = [ccs_home '/matlab'];
addpath(genpath(ccs_matlab_dir));
%read neighbours
%load surface vertex-wise neighbours
fs_vertex_adj = [ccs_home '/misc/' fsaverage '_adj.mat'];
if ~exist(fs_vertex_adj,'file')
    disp('Please check if the neighbours mat file exist!')
    exit
else
    load(fs_vertex_adj);
end
%read hemi surfaces
FS_lh = SurfStatReadSurf({[fs_home '/subjects/' fsaverage ...
    '/surf/lh.inflated']} );
numVertex_lh = size(FS_lh.coord,2); seeds_lh = zeros(numVertex_lh,1);
FS_rh = SurfStatReadSurf({[fs_home '/subjects/' fsaverage ...
    '/surf/rh.inflated']} );
numVertex_rh = size(FS_rh.coord,2); seeds_rh = zeros(numVertex_rh,1);
%predefine variables
seedROI = cell(numSeeds,1); hemi = cell(numSeeds,1); 
seed_surfcoord = zeros(size(seed_coord));
for seedid=1:numSeeds
    tmpSeed = seed_coord(seedid,:);
    %load white surfaces
    fSurf_lh = [fs_home, '/subjects/' fsaverage '/surf/lh.white'];
    fSurf_rh = [fs_home, '/subjects/' fsaverage '/surf/rh.white'];
    [vertex_coords_lh, ~] = read_surf(fSurf_lh);
    [vertex_coords_rh, ~] = read_surf(fSurf_rh);
    vertex_coords = [vertex_coords_lh; vertex_coords_rh];
    %find the closest vertex to the seed
    diff = vertex_coords - repmat(tmpSeed,size(vertex_coords,1),1);
    dist_seed = sqrt(diff(:,1).^2 + diff(:,2).^2 + diff(:,3).^2);
    [~, idx_seed] = min(dist_seed); seed_surfcoord(seedid,:) = vertex_coords(idx_seed,:);
    if idx_seed <= numVertex_lh
        hemi{seedid} = 'lh';
    else
        hemi{seedid} = 'rh';
    end
    %load surface vertex-wise neighbours
    if strcmp(hemi{seedid}, 'lh')
    	seedROI{seedid} = lh_nbrs2{idx_seed};
        seeds_lh(lh_nbrs2{idx_seed}) = 1;
    else
    	seedROI{seedid} = rh_nbrs2{idx_seed-numVertex_lh};
        seeds_rh(rh_nbrs2{idx_seed-numVertex_lh}) = 1;
    end
end
%plot seeds
if strcmp(plot_seeds, 'true')
    %Visualization: lh
    figure('Units', 'pixels', 'Position', [100 100 800 800]); axis off
    SurfStatView(seeds_lh, FS_lh, 'Seeds Distribution');
    colormap([0.5 0.5 0.5; 1 0 0]) ; SurfStatColLim([-0.5 1.5]);
    %Export to JPG
    set(gcf, 'PaperPositionMode', 'auto');
    print('-djpeg', '-r300', 'seeds.inflated.lh.jpg')
    close;
    %Visualization: rh
    figure('Units', 'pixels', 'Position', [100 100 800 800]); axis off
    SurfStatView(seeds_rh, FS_rh, 'Seeds Distribution');
    colormap([0.5 0.5 0.5; 1 0 0]) ; SurfStatColLim([-0.5 1.5]);
    %Export to JPG
    set(gcf, 'PaperPositionMode', 'auto');
    print('-djpeg', '-r300', 'seeds.inflated.rh.jpg')
    close;
end
