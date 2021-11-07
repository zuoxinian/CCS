clear all; clc
ana_dir = '/Users/mac/Downloads/2016NSFC_Xing/testproject';
ccs_dir = '/Volumes/RAID5/CCS';
ccs_matlab = [ccs_dir '/matlab'];
ccs_vistool = [ccs_dir '/vistool'];
cifti_matlab = [ana_dir '/matlab/cifti-matlab-master'];
subject_dir = [ana_dir '/100307'];
fs_home = '/opt/freesurfer51'; 
conte_home = [ana_dir '/32k_ConteAtlas_v2']; 
%Set up the path to matlab function in Freesurfer release
addpath(genpath(ccs_matlab)) %ccs matlab scripts
addpath(genpath(ccs_vistool)) %ccs matlab scripts
addpath(genpath(cifti_matlab)) %freesurfer matlab scripts
addpath(genpath([fs_home '/matlab'])) %freesurfer matlab scripts

%% load the geometry of the 32k_ConteAtlas
conte69_lh = gifti([ana_dir '/32k_ConteAtlas_v2/Conte69.L.midthickness.32k_fs_LR.surf.gii']);
conte69_rh = gifti([ana_dir '/32k_ConteAtlas_v2/Conte69.R.midthickness.32k_fs_LR.surf.gii']);
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
save('Conte69_surfgraph_nbrs.mat', 'lh_nbrs', 'rh_nbrs')
