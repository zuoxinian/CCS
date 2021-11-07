function err = ccs_06_singlesubjectRFMRIparcels( ana_dir, sub_list, func_dir_name, rest_name, ccs_dir, gs_removal, fsaverage, fgmask_surf, fgmask_vol)
%CCS_06_SINGLESUBJECTDMRIPARCELS Computing the 165 parcels for each subject.
%   ana_dir -- full path of the analysis directory
%   sub_list -- full path of the list of subjects
%   func_dir_name -- the name of functional directory
%   rest_name -- the name of REST images
%   ccs_dir -- the name of ccs scripts directory (full path)
%   gs_removal -- if remove global signal
%   fsaverage -- the surface of freesurfer.
%   fgmask_surf -- full path of the global surface mask (cell {lh_mask, rh_mask})
%   fgmask_vol -- full path of the global volume mask
%
% Author: Xi-Nian Zuo at IPCAS, 
%   Start: Dec. 09, 2012.
%   Modified: May 29, 2013.

if nargin < 7
    disp('Usage: ccs_06_singlesubjectRMRIparcels( ana_dir, sub_list, func_dir_name, rest_name, ccs_dir, gs_removal, fsaverage, fgmask_surf, fgmask_vol)')
    exit
end
ccs_matlab_dir = [ccs_dir '/matlab'];
%% load basic information about the parcellation
%DA
Destrieux83ROI = importdata([ccs_matlab_dir '/etc/Destrieux2010.dat']); %1-74 cortical pacels; 75-81 subcortical parcels; 82 cerebelum; 83 brain stem
Destrieux165parcels = importdata([ccs_matlab_dir '/etc/parcels165.list']);
fsLUT = importdata([ccs_matlab_dir '/etc/FreeSurferColorLUT.part']);
LUTdat = fsLUT.textdata; LUTstr = LUTdat(:,2); 
numROI_DA = numel(Destrieux83ROI);
numPARCEL_DA = numel(Destrieux165parcels);
%YEO_lh
numROI_YEO = 57;
fannot = [ccs_dir '/parcellation/ParcelsYeo2011/' fsaverage ...
    '/lh.Yeo2011_17Networks_N1000.split_components.annot'];
[vertices_lh,label_lh,colortable_lh] = read_annotation(fannot);
nVertices_lh = numel(vertices_lh); 
tmpStructNames = colortable_lh.struct_names;
parcel_names_lh = cell(numROI_YEO,1);
for k=1:numROI_YEO
    tmpStr = tmpStructNames{k+1};
    parcel_names_lh{k} = tmpStr(12:end);
end
%YEO_rh
fannot = [ccs_dir '/parcellation/ParcelsYeo2011/' fsaverage ...
    '/rh.Yeo2011_17Networks_N1000.split_components.annot'];
[vertices_rh,label_rh,colortable_rh] = read_annotation(fannot);
nVertices_rh = numel(vertices_rh);
tmpStuctNames = colortable_rh.struct_names;
parcel_names_rh = cell(numROI_YEO,1);
for k=1:numROI_YEO
    tmpStr = tmpStructNames{k+58};
    parcel_names_rh{k} = tmpStr(12:end);
end
% subcortical parcels
subcort_list = ccs_subcell(Destrieux165parcels, [75:82 165 157:164]);
numSubcortROI = numel(subcort_list);

%% group mask loading
if nargin == 8
        %mask_lh
        maskhdr = load_nifti(fgmask_surf{1}); 
        maskvol = maskhdr.vol; maskvec_lh = squeeze(maskvol);
        %mask_rh
        maskhdr = load_nifti(fgmask_surf{2}); 
        maskvol = maskhdr.vol; maskvec_rh = squeeze(maskvol);
end
if nargin == 9
        %mask_lh
        maskhdr = load_nifti(fgmask_surf{1}); 
        maskvol = maskhdr.vol; maskvec_lh = squeeze(maskvol);
        %mask_rh
        maskhdr = load_nifti(fgmask_surf{2}); 
        maskvol = maskhdr.vol; maskvec_rh = squeeze(maskvol);
        %mask vol
        maskhdr = load_nifti(fgmask_vol); 
        maskvol = maskhdr.vol; 
        maskvec = reshape(maskvol,numel(maskvol),1);
end

%% SUBINFO
fid = fopen(sub_list) ;
tmpcell = textscan(fid, '%s'); 
fclose(fid);
subs = tmpcell{1} ; nsubs = numel(subs);

%% LOOP SUBJECTS
for sid=1:nsubs
    %stage-1: building up the DA parcels
    if isnumeric(subs{sid})
        disp(['Generate 165 parcels for ' num2str(subs{sid}) ' ...'])
        func_dir = [ana_dir '/' num2str(subs{sid}) '/' func_dir_name];
    else
        disp(['Generate 165 parcels for ' subs{sid} ' ...'])
        func_dir = [ana_dir '/' subs{sid} '/' func_dir_name];
    end
    mkdir([func_dir '/segment'], '/parcels165')
    %aparc+aseg
    faparc_aseg = [func_dir '/segment/aparc.a2009s+aseg2func.nii.gz'];
    aparchdr = load_nifti(faparc_aseg); aparcvol = aparchdr.vol;
    %vol mask
    if nargin < 9
        fmask = [func_dir '/segment/global_mask.nii.gz'];
        maskhdr = load_nifti(fmask); 
        maskvol = maskhdr.vol; 
        maskvec = reshape(maskvol,numel(maskvol),1);
    end
    for k=1:numROI_DA
    	label = Destrieux83ROI{k};
        if k < 75
        	%left hemi
            tmp_id = ccs_strfind(LUTstr, ['ctx_lh_' label]);
            label_val = str2double(LUTdat(tmp_id, 1));
            tmpvol = zeros(size(maskvol));
            tmpvol(aparcvol==label_val) = 1;
            tmpvol = tmpvol.*maskvol;
            maskhdr.vol = tmpvol;
            if k < 10
            	fout = [func_dir '/segment/parcels165/mask00' num2str(k) '_ctx_lh_' label '.nii.gz'];
            else
            	fout = [func_dir '/segment/parcels165/mask0' num2str(k) '_ctx_lh_' label '.nii.gz'];
            end
            err = save_nifti(maskhdr, fout);
            %right hemi
            tmp_id = ccs_strfind(LUTstr, ['ctx_rh_' label]);
            label_val = str2double(LUTdat(tmp_id, 1));
            tmpvol = zeros(size(maskvol));
            tmpvol(aparcvol==label_val) = 1;
            tmpvol = tmpvol.*maskvol;
            maskhdr.vol = tmpvol;
            if k < 18
            	fout = [func_dir '/segment/parcels165/mask0' num2str(k+82) '_ctx_rh_' label '.nii.gz'];
            else
            	fout = [func_dir '/segment/parcels165/mask' num2str(k+82) '_ctx_rh_' label '.nii.gz'];
            end
            err = save_nifti(maskhdr, fout);
        else
        	if k < 83
                %left hemi
                tmp_id = ccs_strfind(LUTstr, ['Left-' label]);
                label_val = str2double(LUTdat(tmp_id, 1));
                tmpvol = zeros(size(maskvol));
                tmpvol(aparcvol==label_val) = 1;
                tmpvol = tmpvol.*maskvol;
                maskhdr.vol = tmpvol;
                fout = [func_dir '/segment/parcels165/mask0' num2str(k) '_Left-' label '.nii.gz'];
                err = save_nifti(maskhdr, fout);
                %right hemi
                tmp_id = ccs_strfind(LUTstr, ['Right-' label]);
                label_val = str2double(LUTdat(tmp_id, 1));
                tmpvol = zeros(size(maskvol));
                tmpvol(aparcvol==label_val) = 1;
                tmpvol = tmpvol.*maskvol;
                maskhdr.vol = tmpvol;
                fout = [func_dir '/segment/parcels165/mask' num2str(k+82) '_Right-' label '.nii.gz'];
                err = save_nifti(maskhdr, fout);
            else
            	% brain-stem
                tmp_id = ccs_strfind(LUTstr, label);
                label_val = str2double(LUTdat(tmp_id, 1));
                tmpvol = zeros(size(maskvol));
                tmpvol(aparcvol==label_val) = 1;
                tmpvol = tmpvol.*maskvol;
                maskhdr.vol = tmpvol;
                fout = [func_dir '/segment/parcels165/mask' num2str(k+82) '_' label '.nii.gz'];
                err = save_nifti(maskhdr, fout);
            end
        end
    end
    %merge all parcels into a single parcellation file
    if isnumeric(subs{sid})
        disp(['Generate a single parcellation file for 165 parcels: ' num2str(subs{sid}) ' ...'])
    else
        disp(['Generate a single parcellation file for 165 parcels: ' subs{sid} ' ...'])
    end
    maskvol = maskvol.*0;
    for k=1:numPARCEL_DA
    	fparcel = [func_dir '/segment/parcels165/' Destrieux165parcels{k}];
        parcelhdr = load_nifti(fparcel);
        parcelvol = parcelhdr.vol;
        maskvol(parcelvol > 0) = k;
    end
    maskhdr.datatype = 4;
    maskhdr.vol = maskvol;
    fout = [func_dir '/segment/parcels165.nii.gz'];
	err = save_nifti(maskhdr, fout);
    %stage-2: extract the TS for each parcel in DA165 or YEO131
    %set up the gs tag
    if strcmp(gs_removal, 'true')
        pp_dir = [func_dir '/gs-removal'];
        graph_dir = [func_dir '/graph-gs'];
    else
        pp_dir = func_dir;
        graph_dir = [func_dir '/graph'];
    end
    if nargin < 8
        %mask_lh
        fmask_lh = [func_dir '/mask/brain.' fsaverage '.lh.nii.gz'];
        maskhdr = load_nifti(fmask_lh); 
        maskvol = maskhdr.vol; maskvec_lh = squeeze(maskvol);
        %mask_rh
        fmask_rh = [func_dir '/mask/brain.' fsaverage '.rh.nii.gz'];
        maskhdr = load_nifti(fmask_rh); 
        maskvol = maskhdr.vol; maskvec_rh = squeeze(maskvol);
    end
    %rfmri data lh
    frfmri = [pp_dir '/' rest_name '.pp.sm0.' fsaverage '.lh.nii.gz'];
    rfmrihdr = load_nifti(frfmri); 
    rfmrivec_lh = squeeze(rfmrihdr.vol);
    %rfmri data rh
    frfmri = [pp_dir '/' rest_name '.pp.sm0.' fsaverage '.rh.nii.gz'];
    rfmrihdr = load_nifti(frfmri); 
    rfmrivec_rh = squeeze(rfmrihdr.vol);
    %define tmpTS
    tmpTS = zeros(size(rfmrivec_lh,2), (numROI_YEO*2+numSubcortROI));
    if ~exist(graph_dir, 'dir'); mkdir(func_dir, '/graph-gs'); end
    if ~exist([graph_dir '/YEO131'], 'dir'); mkdir(graph_dir, 'YEO131'); end
    for ii=1:numROI_YEO
    	%lh
        idx_vertex = find((maskvec_lh > 0) & (label_lh == colortable_lh.table(ii+1,5)));
        tmpts = mean(rfmrivec_lh(idx_vertex,:))';
        f1D = [graph_dir '/YEO131/' parcel_names_lh{ii} '.1D'];
        save(f1D, 'tmpts', '-ASCII') ; tmpTS(:,ii) = tmpts;
        %rh
        idx_vertex = find((maskvec_rh > 0) & (label_rh == colortable_rh.table(ii+58,5)));
        tmpts = mean(rfmrivec_rh(idx_vertex,:))';
        f1D = [graph_dir '/YEO131/' parcel_names_rh{ii} '.1D'];
        save(f1D, 'tmpts', '-ASCII') ; tmpTS(:,ii+74) = tmpts;
    end
    %rfmri vol data
    frfmri = [pp_dir '/rest_pp_sm0.nii.gz'];
    rfmrihdr = load_nifti(frfmri); 
    rfmrivol = squeeze(rfmrihdr.vol);
    %numel(maskvol), size(rfmrivol)
    rfmrivec = reshape(rfmrivol,numel(maskvec),size(rfmrivol,4));
    if ~exist([graph_dir '/DA165'], 'dir'); mkdir(graph_dir, 'DA165'); end
    tmpTS2 = zeros(size(rfmrivec_lh,2), numPARCEL_DA);
    for ii=1:numPARCEL_DA
    	fii = [func_dir '/segment/parcels165/' Destrieux165parcels{ii}];
        iihdr = load_nifti(fii); 
        iivol = iihdr.vol; iivec = reshape(iivol,numel(maskvec),1);
        tmpts = mean(rfmrivec(iivec.*maskvec>0,:))'; tmpTS2(:,ii) = tmpts;
        tmpstring = Destrieux165parcels{ii};
        f1D = [graph_dir '/DA165/' tmpstring(9:end-7) '.1D'];
        save(f1D, 'tmpts', '-ASCII') ; 
    end
    %save data
    tmpTS(:,58:74) = tmpTS2(:, [75:82 165 157:164]);
    fmat = [graph_dir '/YEO131_timeseries.mat'];
    save(fmat, 'tmpTS')
    fmat = [graph_dir '/DA165_timeseries.mat'];
    save(fmat, 'tmpTS2')
end