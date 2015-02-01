%% Check the surface geometry.
clear all ; clc
fs_dir = '/Optapplications/freesurfer/subjects'; fsaverage = 'fsaverage6';
%pial surface
avgSurf_pial = {[fs_dir '/' fsaverage '/surf/lh.pial'], ...
           [fs_dir '/' fsaverage '/surf/rh.pial']};
%Left Hemisphere
[vertices_pial_lh, faces] = freesurfer_read_surf(avgSurf_pial{1});
FV.vertices = vertices_pial_lh ; FV.faces = faces; edge_pial_lh = mesh_adjacency(FV);
%Searching nrbs
nVertices_pial_lh = size(vertices_pial_lh,1) ; lh_nbrs_pial = cell(nVertices_pial_lh,1);
for k=1:nVertices_pial_lh
    lh_nbrs_pial{k} = find(edge_pial_lh(k,:)>0);
end
%Right Hemisphere
[vertices_pial_rh, faces] = freesurfer_read_surf(avgSurf_pial{2});
FV.vertices = vertices_pial_rh ; FV.faces = faces; edge_pial_rh = mesh_adjacency(FV);
%Searching nrbs
nVertices_pial_rh = size(vertices_pial_rh,1) ; rh_nbrs_pial = cell(nVertices_pial_rh,1);
for k=1:nVertices_pial_rh
    rh_nbrs_pial{k} = find(edge_pial_rh(k,:)>0);
end
%white surface
avgSurf_white = {[fs_dir '/' fsaverage '/surf/lh.white'], ...
           [fs_dir '/' fsaverage '/surf/rh.white']};
%Left Hemisphere
[vertices_white_lh, faces] = freesurfer_read_surf(avgSurf_white{1});
FV.vertices = vertices_white_lh ; FV.faces = faces; edge_white_lh = mesh_adjacency(FV);
%Searching nrbs
nVertices_white_lh = size(vertices_white_lh,1) ; lh_nbrs_white = cell(nVertices_white_lh,1);
for k=1:nVertices_white_lh
    lh_nbrs_white{k} = find(edge_white_lh(k,:)>0);
end
%Right Hemisphere
[vertices_white_rh, faces] = freesurfer_read_surf(avgSurf_white{2});
FV.vertices = vertices_white_rh ; FV.faces = faces; edge_white_rh = mesh_adjacency(FV);
%Searching nrbs
nVertices_white_rh = size(vertices_white_rh,1) ; rh_nbrs_white = cell(nVertices_white_rh,1);
for k=1:nVertices_white_rh
    rh_nbrs_white{k} = find(edge_white_rh(k,:)>0);
end