function [ gmetric_lh, gmetric_rh, hemiweights] = ccs_core_gparcmetric( metric_lh, ...
    metric_rh, fannot_lh, fannot_rh, sumparcel)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

%read fannot for a brain parcellation: lh
[vertices_lh,label_lh,colortable_lh] = read_annotation(fannot_lh);
numVertices_lh = numel(vertices_lh);
aparc_names_lh = colortable_lh.struct_names;
aparc_labels_lh = colortable_lh.table;
gmetric_lh = 0; numParcels_lh = numel(aparc_names_lh)-1;
if numel(metric_lh)==numParcels_lh
    for parcelid=1:numParcels_lh
        if strcmp(sumparcel, 'true')
            gmetric_lh = gmetric_lh + metric_lh(parcelid);
        else
            idx_parcel = aparc_labels_lh(parcelid+1,5);
            num_vertices_parcel = nnz(find(label_lh==idx_parcel));
            weight_parcel = num_vertices_parcel/numVertices_lh;
            gmetric_lh = gmetric_lh + metric_lh(parcelid)*weight_parcel;
        end
    end
else
    disp(['The number of metric elements must be identical ' ...
        'to that of parcels in the left hemisphere!'])
end
%read fannot for a brain parcellation: rh
[vertices_rh,label_rh,colortable_rh] = read_annotation(fannot_rh);
numVertices_rh = numel(vertices_rh);
aparc_names_rh = colortable_rh.struct_names;
aparc_labels_rh = colortable_rh.table;
gmetric_rh = 0; numParcels_rh = numel(aparc_names_rh)-1;
if numel(metric_rh)==numParcels_rh
    for parcelid=1:numParcels_rh
        if strcmp(sumparcel, 'true')
            gmetric_rh = gmetric_rh + metric_rh(parcelid);
        else
            idx_parcel = aparc_labels_rh(parcelid+1,5);
            num_vertices_parcel = nnz(find(label_rh==idx_parcel));
            weight_parcel = num_vertices_parcel/numVertices_rh;
            gmetric_rh = gmetric_rh + metric_rh(parcelid)*weight_parcel;
        end
    end
else
    disp(['The number of metric elements must be identical ' ...
        'to that of parcels in the right hemisphere!'])
end
%hemi weights
hemiweights = [numVertices_lh numVertices_rh]/(numVertices_lh+numVertices_rh);
%lh
end

