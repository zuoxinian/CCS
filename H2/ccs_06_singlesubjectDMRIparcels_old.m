function err = ccs_06_singlesubjectDMRIparcels_old( ana_dir, sub_list, dti_dir_name, ccs_dir, parc)
%CCS_06_SINGLESUBJECTDMRIPARCELS Computing the 165 parcels for each subject.
%   ana_dir -- full path of the analysis directory.
%   sub_list -- full path of the list of subjects.
%   dti_dir_name -- the name of functional directory.
%   ccs_dir -- the name of ccs scripts directory (full path).
%   parc -- the type of brain parcellation (DA2010 or Yeo2011).
%
% Author: Xi-Nian Zuo at IPCAS, Dec., 08, 2012.
% Modified by Xi-Nian Zuo at IPCAS, Oct., 18, 2013.
% Modified by Xi-Nian Zuo at IPCAS, Dec., 21, 2014.

if nargin < 4
    disp('Usage: lfcd_06_singlesubjectDMRIparcels( ana_dir, sub_list, dti_dir_name, ccs_dir, parc)')
    exit
end

if nargin < 5
    parc = 'DA2010';
end

%% Parcellation Info
fsaverage = 'fsaverage5';
ccs_matlab_dir = [ccs_dir '/matlab'];
fsLUT = importdata([ccs_matlab_dir '/etc/FreeSurferColorLUT.part']);
LUTdat = fsLUT.textdata; LUTstr = LUTdat(:,2);
%1-74 cortical pacels; 75-81 subcortical parcels; 82 cerebelum; 83 brain stems
tmpParcels = importdata([ccs_matlab_dir '/etc/Destrieux2010.dat']);
%yeo2011
fannot = [ccs_dir '/parcellation/ParcelsYeo2011/' fsaverage ...
	'/lh.Yeo2011_17Networks_N1000.split_components.annot'];
[~, ~, colortable_lh] = read_annotation(fannot); 
tmpStructNames = colortable_lh.struct_names;
parcel_names_lh = cell(57,1);
for parcid=1:57
    tmpStr = tmpStructNames{parcid+1};
    parcel_names_lh{parcid} = tmpStr(15:end);
end
fannot = [ccs_dir '/parcellation/ParcelsYeo2011/' fsaverage ...
	'/rh.Yeo2011_17Networks_N1000.split_components.annot'];
[~, ~, colortable_rh] = read_annotation(fannot);
tmpStructNames = colortable_rh.struct_names;
parcel_names_rh = cell(57,1);
for parcid=1:57
	tmpStr = tmpStructNames{parcid+1+57};
    parcel_names_rh{parcid} = tmpStr(15:end);
end
%define generale parcels
switch parc
    case 'DA2010'
        clear ParcelsROI;
        %cortex
        for parcid=1:74
            ParcelsROI{parcid,1} = tmpParcels{parcid}; %lh
            ParcelsROI{parcid+91,1} = tmpParcels{parcid}; %rh
        end
        %subcortex
        for parcid=75:82
            ParcelsROI{parcid,1} = tmpParcels{parcid}; %lh
            ParcelsROI{parcid+9,1} = tmpParcels{parcid}; %rh
        end
        %brain-stem
        ParcelsROI{83,1} = tmpParcels{83};
        %mask list
        %fParcels = importdata([ccs_matlab_dir '/etc/parcels165.list']);
    case 'Yeo2011'
        clear ParcelsROI;
        %cortex
        for parcid=1:57
            ParcelsROI{parcid,1} = parcel_names_lh{parcid}; %lh
            ParcelsROI{parcid+74,1} = parcel_names_rh{parcid}; %rh
        end
        %subcortex
        for parcid=58:65
            ParcelsROI{parcid,1} = tmpParcels{parcid+17}; %lh
            ParcelsROI{parcid+9,1} = tmpParcels{parcid+17}; %rh
        end
        %brain-stem
        ParcelsROI{66,1} = tmpParcels{83};
        %mask list
        %fParcels = importdata([ccs_matlab_dir '/etc/parcels131.list']);
    otherwise
        disp('Please select an usable parcellation (e.g., DA2010 or Yeo2011)!')
        exit
end
numPARCEL = numel(ParcelsROI);

%% LOOP SUBJECTS
% SUBINFO
fid = fopen(sub_list) ;
tmpcell = textscan(fid, '%s'); 
fclose(fid);
subs = tmpcell{1} ; nsubs = numel(subs);
for sid=1:nsubs
    if isnumeric(subs{sid})
    	disp(['Generate ' num2str(numPARCEL) ' parcels for ' num2str(subs{sid}) ' ...'])
        dti_dir = [ana_dir '/' num2str(subs{sid}) '/' dti_dir_name];
    else
    	disp(['Generate ' num2str(numPARCEL) ' parcels for ' subs{sid} ' ...'])
        dti_dir = [ana_dir '/' subs{sid} '/' dti_dir_name];
    end
    seg_dir = [dti_dir '/segment'];
    parcel_dir = [seg_dir '/parcels' num2str(numPARCEL)];
    if ~exist(parcel_dir, 'dir')
        mkdir(parcel_dir)
    end
    %mask
    fmask = [dti_dir '/b0_brain_mask.nii.gz'];
    maskhdr = load_nifti(fmask); 
    maskvol = maskhdr.vol;
    %aparc+aseg
    faparc_aseg = [seg_dir '/aparc.a2009s+aseg2diff.nii.gz'];
    aparchdr = load_nifti(faparc_aseg); aparcvol = aparchdr.vol;
    masks_parcel = cell(numPARCEL, 1);
    for k=1:numPARCEL
    	label = ParcelsROI{k};
        if strcmp(parc, 'DA2010')
            if k < 83
                if k < 75
                    %left hemi: cortex
                    tmp_id = ccs_strfind(LUTstr, ['ctx_lh_' label]);
                    label_val = str2double(LUTdat(tmp_id, 1));
                    tmpvol = zeros(size(maskvol));
                    tmpvol(aparcvol==label_val) = 1;
                    tmpvol = tmpvol.*maskvol;
                    maskhdr.vol = tmpvol;
                    if k < 10
                        mask_tmp = ['mask00' num2str(k) '_ctx_lh_' label '.nii.gz'];
                    else
                        mask_tmp = ['mask0' num2str(k) '_ctx_lh_' label '.nii.gz'];
                    end
                    masks_parcel{k,1} = mask_tmp;
                    fout = [parcel_dir '/' mask_tmp];
                    err = save_nifti(maskhdr, fout);
                else
                    %left hemi: subcortex
                    tmp_id = ccs_strfind(LUTstr, ['Left-' label]);
                    label_val = str2double(LUTdat(tmp_id, 1));
                    tmpvol = zeros(size(maskvol));
                    tmpvol(aparcvol==label_val) = 1;
                    tmpvol = tmpvol.*maskvol;
                    maskhdr.vol = tmpvol;
                    mask_tmp = ['mask0' num2str(k) '_Left-' label '.nii.gz'];
                    masks_parcel{k,1} = mask_tmp;
                    fout = [parcel_dir '/' mask_tmp];
                    err = save_nifti(maskhdr, fout);
                end
            else
                if k==83    
                    %brain-stem
                    tmp_id = ccs_strfind(LUTstr, label);
                    label_val = str2double(LUTdat(tmp_id, 1));
                    tmpvol = zeros(size(maskvol));
                    tmpvol(aparcvol==label_val) = 1;
                    tmpvol = tmpvol.*maskvol;
                    maskhdr.vol = tmpvol;
                    mask_tmp = ['mask0' num2str(k) '_' label '.nii.gz'];
                    masks_parcel{k,1} = mask_tmp;
                    fout = [parcel_dir '/' mask_tmp];
                    err = save_nifti(maskhdr, fout);
                else
                    %right hemi: subcortex
                    if k < 92
                        tmp_id = ccs_strfind(LUTstr, ['Right-' label]);
                        label_val = str2double(LUTdat(tmp_id, 1));
                        tmpvol = zeros(size(maskvol));
                        tmpvol(aparcvol==label_val) = 1;
                        tmpvol = tmpvol.*maskvol;
                        maskhdr.vol = tmpvol;
                        mask_tmp = ['mask0' num2str(k) '_Right-' label '.nii.gz'];
                        masks_parcel{k,1} = mask_tmp;
                        fout = [parcel_dir '/' mask_tmp];
                        err = save_nifti(maskhdr, fout);
                    else
                    %right hemi: cortex    
                        tmp_id = ccs_strfind(LUTstr, ['ctx_rh_' label]);
                        label_val = str2double(LUTdat(tmp_id, 1));
                        tmpvol = zeros(size(maskvol));
                        tmpvol(aparcvol==label_val) = 1;
                        tmpvol = tmpvol.*maskvol;
                        maskhdr.vol = tmpvol;
                        if k < 100
                            mask_tmp = ['mask0' num2str(k) '_ctx_rh_' label '.nii.gz'];
                        else
                            mask_tmp = ['mask' num2str(k) '_ctx_rh_' label '.nii.gz'];
                        end
                        masks_parcel{k,1} = mask_tmp;
                        fout = [parcel_dir '/' mask_tmp];
                        err = save_nifti(maskhdr, fout);
                    end
                end
            end
        end
        if strcmp(parc, 'Yeo2011')
            if k < 66
                if k < 58
                    %left hemi: cortex
                    masks_parcel{k,1} = ['lh.' label '.nii.gz'];
                else
                    %left hemi: subcortex
                    tmp_id = ccs_strfind(LUTstr, ['Left-' label]);
                    label_val = str2double(LUTdat(tmp_id, 1));
                    tmpvol = zeros(size(maskvol));
                    tmpvol(aparcvol==label_val) = 1;
                    tmpvol = tmpvol.*maskvol;
                    maskhdr.vol = tmpvol;
                    mask_tmp = ['lh.' label '.nii.gz'];
                    masks_parcel{k,1} = mask_tmp;
                    fout = [parcel_dir '/' mask_tmp];
                    err = save_nifti(maskhdr, fout);
                end
            else
                if k==66    
                    %brain-stem
                    tmp_id = ccs_strfind(LUTstr, label);
                    label_val = str2double(LUTdat(tmp_id, 1));
                    tmpvol = zeros(size(maskvol));
                    tmpvol(aparcvol==label_val) = 1;
                    tmpvol = tmpvol.*maskvol;
                    maskhdr.vol = tmpvol;
                    mask_tmp = [label '.nii.gz'];
                    masks_parcel{k,1} = mask_tmp;
                    fout = [parcel_dir '/' mask_tmp];
                    err = save_nifti(maskhdr, fout);
                else
                    %right hemi: subcortex
                    if k < 75
                        tmp_id = ccs_strfind(LUTstr, ['Right-' label]);
                        label_val = str2double(LUTdat(tmp_id, 1));
                        tmpvol = zeros(size(maskvol));
                        tmpvol(aparcvol==label_val) = 1;
                        tmpvol = tmpvol.*maskvol;
                        maskhdr.vol = tmpvol;
                        mask_tmp = ['rh.' label '.nii.gz'];
                        masks_parcel{k,1} = mask_tmp;
                        fout = [parcel_dir '/' mask_tmp];
                        err = save_nifti(maskhdr, fout);
                    else
                    %right hemi: cortex    
                        masks_parcel{k,1} = ['rh.' label '.nii.gz'];
                    end
                end
            end
        end
    end    
    %merge all parcels into a single parcellation file
    if isnumeric(subs{sid})
        disp(['Generate a single parcellation file for ' num2str(numPARCEL) ' parcels: ' ...
            num2str(subs{sid}) ' ...'])
    else
        disp(['Generate a single parcellation file for ' num2str(numPARCEL) ' parcels: ' ...
            subs{sid} ' ...'])
    end
    maskvol = maskvol.*0;
    for k=1:numPARCEL
    	fparcel = [parcel_dir '/' masks_parcel{k}];
        parcelhdr = load_nifti(fparcel);
        parcelvol = parcelhdr.vol;
        maskvol(parcelvol > 0) = k;
    end
    maskhdr.datatype = 4;
    maskhdr.vol = maskvol;
    fout = [seg_dir '/parcels' num2str(numPARCEL) '.nii.gz'];
	err = save_nifti(maskhdr, fout);
end