%% dir settings (may not usable for you and you have to change them...)
clear all; clc
ana_dir = '/Users/mac/Projects/ABIT';
proj_dir = [ana_dir '/atlas_parcellation/'];
voldisk_dir = '/Volumes/SeagateBackupPlusDrive';
ccs_bakdir = [voldisk_dir '/macbook-bak20161223/Brain/CCS'];
ccs_dir = '/Users/mac/Projects/CCS';
spm_dir = [ccs_dir '/extool/spm12'];
ccs_vistool = [ccs_dir '/vistool'];
fs_home = '/Applications/freesurfer'; 
cifti_matlab = [ccs_dir '/extool/cifti'];
atlas_dir = [ccs_dir '/extool/hcpworkbench/resources/32k_ConteAtlas_v2'];
%Set up the path to matlab function in Freesurfer release
addpath(genpath(ccs_dir)) %ccs matlab scripts
addpath(genpath([fs_home '/matlab'])) %freesurfer matlab scripts

%% reading surface information of the white-gray boundary
fsaverage = 'fsaverage5';
%lh
fwhite = [fs_home '/subjects/' fsaverage '/surf/lh.white'];
wmsurf_lh = SurfStatReadSurf(fwhite);
%rh
fwhite = [fs_home '/subjects/' fsaverage '/surf/rh.white'];
wmsurf_rh = SurfStatReadSurf(fwhite);

%% load Yeo400 parcels on freesurfer surfaces
%lh
fannot_lh = [ccs_bakdir '/parcellation/ParcelsSchaefer2016/fsaverage5/' ...
    'lh.Schaefer2016_400Parcels_7Networks_colors_23_05_16.annot'];
[vertices_lh,label_lh,colortable_lh] = read_annotation(fannot_lh);
nVertices_lh = numel(vertices_lh); 
tmpStructNames = colortable_lh.struct_names;
numParcels_lh = numel(tmpStructNames) - 1;
parcel_names_lh = cell(numParcels_lh,1);
parcel_xyz_lh = cell(numParcels_lh,1);
parcel_vtxid_lh = cell(numParcels_lh,1);
parcel_color_lh = zeros(numParcels_lh,3);
for k=1:numParcels_lh
    tmpStr = tmpStructNames{k+1};
    parcel_names_lh{k} = tmpStr(11:end);
    parcel_color_lh(k,:) = colortable_lh.table(k+1,1:3);
    tmpvtxid = find(label_lh==colortable_lh.table(k+1,5));
    parcel_vtxid_lh{k} = tmpvtxid;
    parcel_xyz_lh{k} = wmsurf_lh.coord(:,tmpvtxid);
end
%rh
fannot_rh = [ccs_bakdir '/parcellation/ParcelsSchaefer2016/fsaverage5/' ...
    'rh.Schaefer2016_400Parcels_7Networks_colors_23_05_16.annot'];
[vertices_rh,label_rh,colortable_rh] = read_annotation(fannot_rh);
nVertices_rh = numel(vertices_rh);
tmpStructNames = colortable_rh.struct_names(202:end);
numParcels_rh = numel(tmpStructNames);
parcel_names_rh = cell(numParcels_rh,1);
parcel_xyz_rh = cell(numParcels_rh,1);
parcel_vtxid_rh = cell(numParcels_rh,1);
parcel_color_rh = zeros(numParcels_rh,3);
for k=1:numParcels_rh
    tmpStr = tmpStructNames{k};
    parcel_names_rh{k} = tmpStr(11:end);
    parcel_color_rh(k,:) = colortable_rh.table(k+201,1:3);
    tmpvtxid = find(label_rh==colortable_rh.table(k+201,5));
    parcel_vtxid_rh{k} = tmpvtxid;
    parcel_xyz_rh{k} = wmsurf_rh.coord(:,tmpvtxid);
end

%% save final matrix for seven yeo networks
Yeo7RSN400.names_lh = parcel_names_lh;
Yeo7RSN400.names_rh = parcel_names_rh;
Yeo7RSN400.colors_lh = parcel_color_lh;
Yeo7RSN400.colors_rh = parcel_color_rh;
Yeo7RSN400.xyz_lh = parcel_xyz_lh;
Yeo7RSN400.xyz_rh = parcel_xyz_rh;
Yeo7RSN400.vtxid_lh = parcel_vtxid_lh;
Yeo7RSN400.vtxid_rh = parcel_vtxid_rh;
save([ccs_dir '/parcellation/Yeo7RSN400.mat'],'Yeo7RSN400')

%% load Yeo400 parcels on freesurfer surfaces
%lh
fannot_lh = [ccs_bakdir '/parcellation/ParcelsSchaefer2016/fsaverage5/' ...
    'lh.Schaefer2016_400Parcels_17Networks_colors_23_05_16.annot'];
[vertices_lh,label_lh,colortable_lh] = read_annotation(fannot_lh);
nVertices_lh = numel(vertices_lh); 
tmpStructNames = colortable_lh.struct_names;
numParcels_lh = numel(tmpStructNames) - 1;
parcel_names_lh = cell(numParcels_lh,1);
parcel_xyz_lh = cell(numParcels_lh,1);
parcel_vtxid_lh = cell(numParcels_lh,1);
parcel_color_lh = zeros(numParcels_lh,3);
for k=1:numParcels_lh
    tmpStr = tmpStructNames{k+1};
    parcel_names_lh{k} = tmpStr(11:end);
    parcel_color_lh(k,:) = colortable_lh.table(k+1,1:3);
    tmpvtxid = find(label_lh==colortable_lh.table(k+1,5));
    parcel_vtxid_lh{k} = tmpvtxid;
    parcel_xyz_lh{k} = wmsurf_lh.coord(:,tmpvtxid);
end
%rh
fannot_rh = [ccs_bakdir '/parcellation/ParcelsSchaefer2016/fsaverage5/' ...
    'rh.Schaefer2016_400Parcels_17Networks_colors_23_05_16.annot'];
[vertices_rh,label_rh,colortable_rh] = read_annotation(fannot_rh);
nVertices_rh = numel(vertices_rh);
tmpStructNames = colortable_rh.struct_names(202:end);
numParcels_rh = numel(tmpStructNames);
parcel_names_rh = cell(numParcels_rh,1);
parcel_xyz_rh = cell(numParcels_rh,1);
parcel_vtxid_rh = cell(numParcels_rh,1);
parcel_color_rh = zeros(numParcels_rh,3);
for k=1:numParcels_rh
    tmpStr = tmpStructNames{k};
    parcel_names_rh{k} = tmpStr(11:end);
    parcel_color_rh(k,:) = colortable_rh.table(k+201,1:3);
    tmpvtxid = find(label_rh==colortable_rh.table(k+201,5));
    parcel_vtxid_rh{k} = tmpvtxid;
    parcel_xyz_rh{k} = wmsurf_rh.coord(:,tmpvtxid);
end

%% save final matrix for seven yeo networks
Yeo17RSN400.names_lh = parcel_names_lh;
Yeo17RSN400.names_rh = parcel_names_rh;
Yeo17RSN400.colors_lh = parcel_color_lh;
Yeo17RSN400.colors_rh = parcel_color_rh;
Yeo17RSN400.xyz_lh = parcel_xyz_lh;
Yeo17RSN400.xyz_rh = parcel_xyz_rh;
Yeo17RSN400.vtxid_lh = parcel_vtxid_lh;
Yeo17RSN400.vtxid_rh = parcel_vtxid_rh;
save([ccs_dir '/parcellation/Yeo17RSN400.mat'],'Yeo17RSN400')
