clear all; clc
ana_dir = '/Users/mac/Projects/HCP/7T';
work_dir = '/Volumes/extHD1/projects/hcp7T';
hcpdemo_dir = '/Users/mac/Downloads/Frontiers_LaTeX_Templates/hcpdemo';
ccs_dir = '/Users/mac/Projects/CCS';
spm_dir = [ccs_dir '/extool/spm12'];
ccs_matlab = [ccs_dir '/matlab'];
ccs_vistool = [ccs_dir '/vistool'];
fs_home = '/opt/freesurfer51'; 
cifti_matlab = [ccs_dir '/extool/cifti'];
atlas_dir = [ccs_dir '/extool/hcpworkbench/resources/32k_ConteAtlas_v2'];
%Set up the path to matlab function in Freesurfer release
addpath(hcpdemo_dir);
addpath(genpath(ccs_matlab)) %ccs matlab scripts
addpath(genpath(ccs_vistool)) %ccs matlab scripts
addpath(genpath(cifti_matlab)) %cifti paths
addpath(genpath([fs_home '/matlab'])) %freesurfer matlab scripts

%% load the geometry of the 59k_ConteAtlas
conte69_lh = gifti([work_dir '/100610/MNINonLinear/fsaverage_LR59k/' ...
    '100610.L.midthickness.59k_fs_LR.surf.gii']);
conte69_rh = gifti([work_dir '/100610/MNINonLinear/fsaverage_LR59k/' ...
    '100610.R.midthickness.59k_fs_LR.surf.gii']);
%Left Hemisphere
FV.vertices = conte69_lh.vertices ; FV.faces = conte69_lh.faces; 
nVertices_lh = size(conte69_lh.vertices,1); edge_lh = mesh_adjacency(FV); 
%Searching nrbs
lh_nbrs = cell(nVertices_lh,8);
for nstep=1:8
    if nstep > 1
        tmpedge = tmpedge*edge_lh;
    else
        tmpedge = edge_lh;
    end
    for k=1:nVertices_lh
        if mod(k,1000)==0
            disp(['Counting neighbours for ' num2str(nstep) '-step: ' ...
                num2str(round(100*k/nVertices_lh)) ' percentage vertices completed...'])
        end
        lh_nbrs{k,nstep} = find(tmpedge(k,:)>0);
    end
end
%Right Hemisphere
FV.vertices = conte69_rh.vertices ; FV.faces = conte69_rh.faces; 
nVertices_rh = size(conte69_rh.vertices,1); edge_rh = mesh_adjacency(FV); 
%Searching nrbs
rh_nbrs = cell(nVertices_rh,8);
for nstep=1:8
    if nstep > 1
        tmpedge = tmpedge*edge_rh;
    else
        tmpedge = edge_rh;
    end
    for k=1:nVertices_rh
        if mod(k,1000)==0
            disp(['Counting neighbours for ' num2str(nstep) '-step: ' ...
                num2str(round(100*k/nVertices_rh)) ' percentage vertices completed...'])
        end
        rh_nbrs{k,nstep} = find(tmpedge(k,:)>0);
    end
end

%Connection matrix
edge = [edge_lh sparse(nVertices_lh, nVertices_rh); ...
    sparse(nVertices_lh, nVertices_rh) edge_rh];
subplot(121), spy(edge); subplot(122), spy(edge_lh)

%Save neighbours
save([ana_dir '/HCP64_surf59kgraph_nbrs.mat'], 'lh_nbrs', 'rh_nbrs')
