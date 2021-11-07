%% dir settings (may not usable for you and you have to change them...)
clear all; clc
data_dir = '/Volumes/EAGETZUO/CCS/courses/2016/CCBD/sample/subj01';
ana_dir = '/Users/mac/Projects/testDCM';
ccs_dir = '/Users/mac/Projects/CCS';
ccs_matlab = [ccs_dir '/matlab'];
ccs_vistool = [ccs_dir '/vistool'];
fs_home = '/opt/freesurfer51';
age_predict = 5:0.5:90;
colorset_hot = [0 0 0; 255 255 255; 255 0 0; 255 0 0]/255;
colorset_cold = [0 0 0; 255 255 255; 0 0 255; 0 0 255]/255;
cifti_matlab = [ccs_dir '/extool/cifti'];
atlas_dir = [ccs_dir '/extool/hcpworkbench/resources/32k_ConteAtlas_v2'];
%Set up the path to matlab function in Freesurfer release
addpath(genpath(ccs_matlab)) %ccs matlab scripts
addpath(genpath(ccs_vistool)) %ccs matlab scripts
addpath(genpath(cifti_matlab)) %cifti paths
addpath(genpath([fs_home '/matlab'])) %freesurfer matlab scripts

%% building yeo7network parcels
fsaverage = 'fsaverage5';
%YEO_lh
fwhite = [fs_home '/subjects/' fsaverage '/surf/lh.white'];
wmsurf_lh = SurfStatReadSurf(fwhite);
numlhROI_YEO = 26;
fannot = [ccs_dir '/parcellation/ParcelsYeo2011/' fsaverage ...
    '/lh.Yeo2011_7Networks_N1000.split_components.annot'];
[vertices_lh,label_lh,colortable_lh] = read_annotation(fannot);
nVertices_lh = numel(vertices_lh); 
tmpStructNames = colortable_lh.struct_names;
parcel_names_lh = cell(numlhROI_YEO,1);
parcel_xyz_lh = cell(numlhROI_YEO,1);
parcel_vtxid_lh = cell(numlhROI_YEO,1);
parcel_color_lh = zeros(numlhROI_YEO,3);
for k=1:numlhROI_YEO
    tmpStr = tmpStructNames{k+1};
    parcel_names_lh{k} = tmpStr(11:end);
    parcel_color_lh(k,:) = colortable_lh.table(k+1,1:3);
    tmpvtxid = find(label_lh==colortable_lh.table(k+1,5));
    parcel_vtxid_lh{k} = tmpvtxid;
    parcel_xyz_lh{k} = wmsurf_lh.coord(:,tmpvtxid);
end
%YEO_rh
fwhite = [fs_home '/subjects/' fsaverage '/surf/rh.white'];
wmsurf_rh = SurfStatReadSurf(fwhite);
numrhROI_YEO = 25;
fannot = [ccs_dir '/parcellation/ParcelsYeo2011/' fsaverage ...
    '/rh.Yeo2011_7Networks_N1000.split_components.annot'];
[vertices_rh,label_rh,colortable_rh] = read_annotation(fannot);
nVertices_rh = numel(vertices_rh);
tmpStuctNames = colortable_rh.struct_names;
parcel_names_rh = cell(numrhROI_YEO,1);
parcel_xyz_rh = cell(numrhROI_YEO,1);
parcel_vtxid_rh = cell(numrhROI_YEO,1);
parcel_color_rh = zeros(numrhROI_YEO,3);
for k=1:numrhROI_YEO
    tmpStr = tmpStructNames{k+27};
    parcel_names_rh{k} = tmpStr(11:end);
    parcel_color_rh(k,:) = colortable_rh.table(k+27,1:3);
    tmpvtxid = find(label_rh==colortable_rh.table(k+27,5));
    parcel_vtxid_rh{k} = tmpvtxid;
    parcel_xyz_rh{k} = wmsurf_rh.coord(:,tmpvtxid);
end
%build up the brain parcellation structure
Yeo7RSN.names_lh = parcel_names_lh;
Yeo7RSN.names_rh = parcel_names_rh;
Yeo7RSN.colors_lh = parcel_color_lh;
Yeo7RSN.colors_rh = parcel_color_rh;
Yeo7RSN.xyz_lh = parcel_xyz_lh;
Yeo7RSN.xyz_rh = parcel_xyz_rh;
Yeo7RSN.vtxid_lh = parcel_vtxid_lh;
Yeo7RSN.vtxid_rh = parcel_vtxid_rh;
save('Yeo7RSN.mat','Yeo7RSN')