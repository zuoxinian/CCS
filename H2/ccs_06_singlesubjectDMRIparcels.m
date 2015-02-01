function err = ccs_06_singlesubjectDMRIparcels( ana_dir, sub_list, dti_dir_name, ccs_dir, parc)
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
ccs_matlab_dir = [ccs_dir '/matlab'];
fsLUT = importdata([ccs_matlab_dir '/etc/FreeSurferColorLUT.part']);
LUTdat = fsLUT.textdata; LUTstr = LUTdat(:,2);
%1-74 cortical pacels; 75-81 subcortical parcels; 82 cerebelum; 83 brain stems
numSubcortParcels = 2*8+1;
%DA2010: all parcels
tmpParcelsDA2010 = importdata([ccs_matlab_dir '/etc/Destrieux2010.dat']);
numCortexParcels = numel(tmpParcelsDA2010)-((numSubcortParcels-1)/2+1);
%cortex
ParcelsROIa2009s = []; ParcelsROI = [];
for parcid=1:numCortexParcels
    ParcelsROIa2009s{parcid,1} = tmpParcelsDA2010{parcid}; %lh
    ParcelsROIa2009s{parcid+numCortexParcels+numSubcortParcels,1} = ...
    tmpParcelsDA2010{parcid}; %rh
end
%subcortex
for parcid=(1+numCortexParcels):(8+numCortexParcels)
    ParcelsROIa2009s{parcid,1} = tmpParcelsDA2010{parcid}; %lh
    ParcelsROIa2009s{parcid+((numSubcortParcels-1)/2+1),1} = tmpParcelsDA2010{parcid}; %rh
end
%brain-stem
bstm_idx = numCortexParcels+(numSubcortParcels-1)/2+1;
ParcelsROIa2009s{bstm_idx,1} = tmpParcelsDA2010{bstm_idx};
%only cortical parcels
tmpParcelsYeo2011 = importdata([ccs_matlab_dir '/etc/Yeo2011.dat']);
%define general parcels
switch parc
    case 'DA2010'
        clear ParcelsROI;
        ParcelsROI = ParcelsROIa2009s;
    case 'Yeo2011'
        clear ParcelsROI;
        numCortexParcels = numel(tmpParcelsYeo2011.textdata)/2;
        %cortex
        for parcid=1:numCortexParcels
            ParcelsROI{parcid,1} = tmpParcelsYeo2011.textdata{parcid}; %lh
            ParcelsROI{parcid+numCortexParcels+numSubcortParcels,1} = ...
                tmpParcelsYeo2011.textdata{parcid+numCortexParcels}; %rh
        end
        %subcortex
        for parcid=(1+numCortexParcels):(8+numCortexParcels)
            ParcelsROI{parcid,1} = tmpParcelsDA2010{parcid+17}; %lh
            ParcelsROI{parcid+((numSubcortParcels-1)/2+1),1} = ...
                tmpParcelsDA2010{parcid+17}; %rh
        end
        %brain-stem
        bstm_idx = numCortexParcels+(numSubcortParcels-1)/2+1;
        ParcelsROI{bstm_idx,1} = tmpParcelsDA2010{bstm_idx+17};
    otherwise
        disp('Please select an usable parcellation (e.g., DA2010 or Yeo2011)!')
        exit
end
numPARCEL = numel(ParcelsROI)

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
    %aparc+aseg: DA2010
    faparc_aseg = [seg_dir '/aparc.a2009s+aseg2diff.nii.gz'];
    aparchdr = load_nifti(faparc_aseg); aparcvol_da2010 = aparchdr.vol;
    masks_parcel = cell(numPARCEL, 1);
    for k=1:numPARCEL
    	label = ParcelsROI{k};
        switch parc
            case 'DA2010'
                if k < 83
                    if k < 75
                        %left hemi: cortex
                        tmp_id = ccs_strfind(LUTstr, ['ctx_lh_' label]);
                        label_val = str2double(LUTdat(tmp_id, 1));
                        tmpvol = zeros(size(maskvol));
                        tmpvol(aparcvol_da2010==label_val) = 1;
                        tmpvol = tmpvol.*maskvol;
                        maskhdr.vol = tmpvol;
                        if k < 10
                            mask_tmp = ['mask00' num2str(k) '_LH_' label '.nii.gz'];
                        else
                            mask_tmp = ['mask0' num2str(k) '_LH_' label '.nii.gz'];
                        end
                        masks_parcel{k,1} = mask_tmp;
                        fout = [parcel_dir '/' mask_tmp];
                        err = save_nifti(maskhdr, fout);
                    else
                        %left hemi: subcortex
                        tmp_id = ccs_strfind(LUTstr, ['Left-' label]);
                        label_val = str2double(LUTdat(tmp_id, 1));
                        tmpvol = zeros(size(maskvol));
                        tmpvol(aparcvol_da2010==label_val) = 1;
                        tmpvol = tmpvol.*maskvol;
                        maskhdr.vol = tmpvol;
                        mask_tmp = ['mask0' num2str(k) '_LH_' label '.nii.gz'];
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
                        tmpvol(aparcvol_da2010==label_val) = 1;
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
                            tmpvol(aparcvol_da2010==label_val) = 1;
                            tmpvol = tmpvol.*maskvol;
                            maskhdr.vol = tmpvol;
                            mask_tmp = ['mask0' num2str(k) '_RH_' label '.nii.gz'];
                            masks_parcel{k,1} = mask_tmp;
                            fout = [parcel_dir '/' mask_tmp];
                            err = save_nifti(maskhdr, fout);
                        %right hemi: cortex
                        else
                            tmp_id = ccs_strfind(LUTstr, ['ctx_rh_' label]);
                            label_val = str2double(LUTdat(tmp_id, 1));
                            tmpvol = zeros(size(maskvol));
                            tmpvol(aparcvol_da2010==label_val) = 1;
                            tmpvol = tmpvol.*maskvol;
                            maskhdr.vol = tmpvol;
                            if k < 100
                                mask_tmp = ['mask0' num2str(k) '_RH_' label '.nii.gz'];
                            else
                                mask_tmp = ['mask' num2str(k) '_RH_' label '.nii.gz'];
                            end
                            masks_parcel{k,1} = mask_tmp;
                            fout = [parcel_dir '/' mask_tmp];
                            err = save_nifti(maskhdr, fout);
                        end
                    end
                end
            case 'Yeo2011'
                %aparc+aseg: Yeo2011
                faparc_aseg = [seg_dir '/aparc.yeo2011.split114+aseg2diff.nii.gz'];
                aparchdr = load_nifti(faparc_aseg); aparcvol_yeo2011 = aparchdr.vol;
                if k < 66
                    if k < 58
                        %left hemi: cortex
                        label_val = tmpParcelsYeo2011.data(k);
                        tmpvol = zeros(size(maskvol));
                        tmpvol(aparcvol_yeo2011==label_val) = 1;
                        tmpvol = tmpvol.*maskvol;
                        maskhdr.vol = tmpvol;
                        if k < 10
                            mask_tmp = ['mask00' num2str(k) '_' ParcelsROI{k} '.nii.gz'];
                        else
                            mask_tmp = ['mask0' num2str(k) '_' ParcelsROI{k} '.nii.gz'];
                        end
                        masks_parcel{k,1} = mask_tmp;
                        fout = [parcel_dir '/' mask_tmp];
                        err = save_nifti(maskhdr, fout);
                    else
                        %left hemi: subcortex
                        tmp_id = ccs_strfind(LUTstr, ['Left-' label]);
                        label_val = str2double(LUTdat(tmp_id, 1));
                        tmpvol = zeros(size(maskvol));
                        tmpvol(aparcvol_da2010==label_val) = 1;
                        tmpvol = tmpvol.*maskvol;
                        maskhdr.vol = tmpvol;
                        mask_tmp = ['mask0' num2str(k) '_LH_' label '.nii.gz'];
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
                        tmpvol(aparcvol_da2010==label_val) = 1;
                        tmpvol = tmpvol.*maskvol;
                        maskhdr.vol = tmpvol;
                        mask_tmp = ['mask0' num2str(k) '_' label '.nii.gz'];
                        masks_parcel{k,1} = mask_tmp;
                        fout = [parcel_dir '/' mask_tmp];
                        err = save_nifti(maskhdr, fout);
                    else
                        %right hemi: subcortex
                        if k < 75
                            tmp_id = ccs_strfind(LUTstr, ['Right-' label]);
                            label_val = str2double(LUTdat(tmp_id, 1));
                            tmpvol = zeros(size(maskvol));
                            tmpvol(aparcvol_da2010==label_val) = 1;
                            tmpvol = tmpvol.*maskvol;
                            maskhdr.vol = tmpvol;
                            mask_tmp = ['mask0' num2str(k) '_RH_' label '.nii.gz'];
                            masks_parcel{k,1} = mask_tmp;
                            fout = [parcel_dir '/' mask_tmp];
                            err = save_nifti(maskhdr, fout);
                        else
                        %right hemi: cortex    
                        	label_val = tmpParcelsYeo2011.data(k-numSubcortParcels);
                            tmpvol = zeros(size(maskvol));
                            tmpvol(aparcvol_yeo2011==label_val) = 1;
                            tmpvol = tmpvol.*maskvol;
                            maskhdr.vol = tmpvol;
                            if k < 100
                                mask_tmp = ['mask0' num2str(k) '_' label '.nii.gz'];
                            else
                                mask_tmp = ['mask' num2str(k) '_' label '.nii.gz'];
                            end
                            masks_parcel{k,1} = mask_tmp;
                            fout = [parcel_dir '/' mask_tmp];
                            err = save_nifti(maskhdr, fout);
                        end
                    end
                end
            otherwise
                disp('Please select an usable parcellation (e.g., DA2010 or Yeo2011)!')
                exit
        end
    end
    %merge all parcels into a single parcellation file
    if isnumeric(subs{sid})
        disp(['Generate a single parcellation file for ' num2str(numPARCEL) ...
            ' parcels: ' num2str(subs{sid}) ' ...'])
    else
        disp(['Generate a single parcellation file for ' num2str(numPARCEL) ...
            ' parcels: ' subs{sid} ' ...'])
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
