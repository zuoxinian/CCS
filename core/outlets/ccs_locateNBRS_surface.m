function [edge_lh, edge_rh, edge2_lh, edge2_rh, lh_nbrs, rh_nbrs, lh_nbrs2, rh_nbrs2] = ...
    ccs_locateNBRS_surface(fs_dir, fsaverage)
%% NOTES

avgSurf = {[fs_dir '/subjects/' fsaverage '/surf/lh.pial'], ...
           [fs_dir '/subjects/' fsaverage '/surf/rh.pial']};
addpath([fs_dir '/matlab'])

%% Left Hemisphere
[vertices, faces] = freesurfer_read_surf(avgSurf{1});
FV.vertices = vertices ; FV.faces = faces; 
edge_lh = mesh_adjacency(FV); 
edge2_lh = edge_lh^2; %length-two paths
edge12_lh = edge_lh + edge2_lh;
%Searching length-one nrbs
nVertices_lh = size(vertices,1) ; nFaces_lh = size(faces,1); 
lh_nbrs = cell(nVertices_lh,1) ; lh_nbrs2 = cell(nVertices_lh,1);
for k=1:nVertices_lh
    lh_nbrs{k} = find(edge_lh(k,:)>0);
    lh_nbrs2{k} = find(edge12_lh(k,:)>0);
end
%Right Hemisphere
[vertices, faces] = freesurfer_read_surf(avgSurf{2});
FV.vertices = vertices ; FV.faces = faces; 
edge_rh = mesh_adjacency(FV);
edge2_rh = edge_rh^2; %length-two paths
edge12_rh = edge_rh + edge2_rh;
%Searching nrbs
nVertices_rh = size(vertices,1) ; nFaces_rh = size(faces,1); 
rh_nbrs = cell(nVertices_rh,1) ; rh_nbrs2 = cell(nVertices_rh,1);
for k=1:nVertices_rh
    rh_nbrs{k} = find(edge_rh(k,:)>0);
    rh_nbrs2{k} = find(edge12_rh(k,:)>0);
end
clear vertices faces