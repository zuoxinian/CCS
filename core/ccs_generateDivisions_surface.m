%% Regional differences in ReHo.
clear all ; clc
fs_home = '/Optapplications/freesurfer'; 
fsaverage = 'fsaverage5';
data_dir = [work_dir '/data'];
fig_dir = [work_dir '/figures/jpeg'];
avgSurf = {[fs_home '/subjects/' fsaverage '/surf/lh.pial'], ...
           [fs_home '/subjects/' fsaverage '/surf/rh.pial']};
s = SurfStatReadSurf( avgSurf );

% DK areas
fDKLH = [fs_home '/subjects/' fsaverage '/label/lh.aparc.annot'];
[vertices_DK_lh,label_DK_lh,colortable_DK_lh] = read_annotation(fDKLH);
DK_names_lh = colortable_DK_lh.struct_names;
DK_labels_lh = colortable_DK_lh.table;
fDKRH = [fs_home '/subjects/' fsaverage '/label/rh.aparc.annot'];
[vertices_DK_rh,label_DK_rh,colortable_DK_rh] = read_annotation(fDKRH);
DK_names_rh = colortable_DK_rh.struct_names;
DK_labels_rh = colortable_DK_rh.table;

%% Lobes
frontal_lobe = {'caudalanteriorcingulate','caudalmiddlefrontal','lateralorbitofrontal','medialorbitofrontal',...
    'paracentral','parsopercularis','parsorbitalis','parstriangularis','precentral','rostralanteriorcingulate',...
    'rostralmiddlefrontal','superiorfrontal','frontalpole'};
parietal_lobe = {'inferiorparietal','isthmuscingulate','postcentral','posteriorcingulate',...
    'precuneus','superiorparietal','supramarginal'};
temporal_lobe = {'bankssts','entorhinal','fusiform','inferiortemporal','middletemporal','parahippocampal',...
    'superiortemporal','temporalpole','transversetemporal'};
occipital_lobe = {'cuneus','lateraloccipital','lingual','pericalcarine'};
insular_lobe = {'insula'}; lobe_lh = zeros(size(maskLH)); lobe_rh = zeros(size(maskRH));
for k=1:numel(frontal_lobe)
    %lh
    idx_label = ccs_strfind(DK_names_lh,frontal_lobe{k});
    DK_idx = find(label_DK_lh == DK_labels_lh(idx_label,5));
    lobe_lh(DK_idx) = 1.5;
    %rh
    idx_label = ccs_strfind(DK_names_rh,frontal_lobe{k});
    DK_idx = find(label_DK_rh == DK_labels_rh(idx_label,5));
    lobe_rh(DK_idx) = 1.5;
end
for k=1:numel(parietal_lobe)
    %lh
    idx_label = ccs_strfind(DK_names_lh,parietal_lobe{k});
    DK_idx = find(label_DK_lh == DK_labels_lh(idx_label,5));
    lobe_lh(DK_idx) = 2.5;
    %rh
    idx_label = ccs_strfind(DK_names_rh,parietal_lobe{k});
    DK_idx = find(label_DK_rh == DK_labels_rh(idx_label,5));
    lobe_rh(DK_idx) = 2.5;
end
for k=1:numel(temporal_lobe)
    %lh
    idx_label = ccs_strfind(DK_names_lh,temporal_lobe{k});
    DK_idx = find(label_DK_lh == DK_labels_lh(idx_label,5));
    lobe_lh(DK_idx) = 3.5;
    %rh
    idx_label = ccs_strfind(DK_names_rh,temporal_lobe{k});
    DK_idx = find(label_DK_rh == DK_labels_rh(idx_label,5));
    lobe_rh(DK_idx) = 3.5;
end
for k=1:numel(insular_lobe)
    %lh
    idx_label = ccs_strfind(DK_names_lh,insular_lobe{k});
    DK_idx = find(label_DK_lh == DK_labels_lh(idx_label,5));
    lobe_lh(DK_idx) = 4.5;
    %rh
    idx_label = ccs_strfind(DK_names_rh,insular_lobe{k});
    DK_idx = find(label_DK_rh == DK_labels_rh(idx_label,5));
    lobe_rh(DK_idx) = 4.5;
end
for k=1:numel(occipital_lobe)
    %lh
    idx_label = ccs_strfind(DK_names_lh,occipital_lobe{k});
    DK_idx = find(label_DK_lh == DK_labels_lh(idx_label,5));
    lobe_lh(DK_idx) = 5.5;
    %rh
    idx_label = ccs_strfind(DK_names_rh,occipital_lobe{k});
    DK_idx = find(label_DK_rh == DK_labels_rh(idx_label,5));
    lobe_rh(DK_idx) = 5.5;
end

%% Lobe surface
% cmap_lobe = [[128 128 128]; [255 211 65]; [119 166 66]; [216 76 121]; [236 144 93]; [56 212 214]]/255;% F/P/T/I/O
% figure('Units', 'pixels', 'Position', [100 100 800 800]); axis off
% SurfStatView([lobe_lh; lobe_rh], s, 'Cortical Lobes');
% colormap(cmap_lobe) ; SurfStatColLim( [0 6] )
% %Export to JPG
% set(gcf, 'PaperPositionMode', 'auto');
% print('-djpeg', '-r300', [work_dir '/data/masks/figures/lobes.jpg'])
% close;

%% Hierarchy
primary = {'postcentral','precentral','paracentral','cuneus','pericalcarine','transversetemporal'};
unimodal = {'lingual','lateraloccipital','precuneus','superiorparietal','fusiform','middletemporal',...
    'superiortemporal','bankssts','entorhinal','caudalmiddlefrontal','parsopercularis','parahippocampal'};
heteromodal = {'inferiorparietal','supramarginal','lateralorbitofrontal','medialorbitofrontal',...
    'parsorbitalis','parstriangularis','rostralmiddlefrontal','superiorfrontal','frontalpole',...
    'inferiortemporal'};
paralimbic = {'insula','caudalanteriorcingulate','rostralanteriorcingulate','isthmuscingulate',...
    'posteriorcingulate','temporalpole'}; 
hierarchy_lh = zeros(size(maskLH)); hierarchy_rh = zeros(size(maskRH));
for k=1:numel(primary)
    %lh
    idx_label = ccs_strfind(DK_names_lh,primary{k});
    DK_idx = find(label_DK_lh == DK_labels_lh(idx_label,5));
    hierarchy_lh(DK_idx) = 1.5;
    %rh
    idx_label = ccs_strfind(DK_names_rh,primary{k});
    DK_idx = find(label_DK_rh == DK_labels_rh(idx_label,5));
    hierarchy_rh(DK_idx) = 1.5;
end
for k=1:numel(unimodal)
    %lh
    idx_label = ccs_strfind(DK_names_lh,unimodal{k});
    DK_idx = find(label_DK_lh == DK_labels_lh(idx_label,5));
    hierarchy_lh(DK_idx) = 2.5;
    %rh
    idx_label = ccs_strfind(DK_names_rh,unimodal{k});
    DK_idx = find(label_DK_rh == DK_labels_rh(idx_label,5));
    hierarchy_rh(DK_idx) = 2.5;
end
for k=1:numel(heteromodal)
    %lh
    idx_label = ccs_strfind(DK_names_lh,heteromodal{k});
    DK_idx = find(label_DK_lh == DK_labels_lh(idx_label,5));
    hierarchy_lh(DK_idx) = 3.5;
    %rh
    idx_label = ccs_strfind(DK_names_rh,heteromodal{k});
    DK_idx = find(label_DK_rh == DK_labels_rh(idx_label,5));
    hierarchy_rh(DK_idx) = 3.5;
end
for k=1:numel(paralimbic)
    %lh
    idx_label = ccs_strfind(DK_names_lh,paralimbic{k});
    DK_idx = find(label_DK_lh == DK_labels_lh(idx_label,5));
    hierarchy_lh(DK_idx) = 4.5;
    %rh
    idx_label = ccs_strfind(DK_names_rh,paralimbic{k});
    DK_idx = find(label_DK_rh == DK_labels_rh(idx_label,5));
    hierarchy_rh(DK_idx) = 4.5;
end
%% Hierarchy surface
% cmap_hierarchy = [[128 128 128]; [0 255 0]; [0 0 255]; [155 37 166]; [243 84 151]]/255;% P/U/H/p
% figure('Units', 'pixels', 'Position', [100 100 800 800]); axis off
% SurfStatView([hierarchy_lh; hierarchy_rh], s, 'Cortical Hierarchies');
% colormap(cmap_hierarchy) ; SurfStatColLim( [0 5] )
% %Export to JPG
% set(gcf, 'PaperPositionMode', 'auto');
% print('-djpeg', '-r300', [work_dir '/data/masks/figures/hierarchies.jpg'])
% close;

%% Yeo 7Networks: you can find this parcellation by searching Yeo_JNeurophysiol11_FreeSurfer in Google :)
fYeoLH = [work_dir '/data/masks/networks/Yeo_JNeurophysiol11_FreeSurfer/' ...
    fsaverage '/label/lh.Yeo2011_7Networks_N1000.annot'];
[vertices_Yeo_lh,label_Yeo_lh,colortable_Yeo_lh] = read_annotation(fYeoLH);
Yeo_names_lh = colortable_Yeo_lh.struct_names;
Yeo_labels_lh = colortable_Yeo_lh.table;
fYeoRH = [work_dir '/data/masks/networks/Yeo_JNeurophysiol11_FreeSurfer/' ...
    fsaverage '/label/rh.Yeo2011_7Networks_N1000.annot'];
[vertices_Yeo_rh,label_Yeo_rh,colortable_Yeo_rh] = read_annotation(fYeoRH);
Yeo_names_rh = colortable_Yeo_rh.struct_names;
Yeo_labels_rh = colortable_Yeo_rh.table;
Yeo_lh = zeros(size(maskLH)); Yeo_rh = zeros(size(maskRH));
for k=2:numel(Yeo_names_lh)
    idx_label = ccs_strfind(Yeo_names_lh,Yeo_names_lh{k});
    Yeo_idx = find(label_Yeo_lh == Yeo_labels_lh(idx_label,5));
    Yeo_lh(Yeo_idx) = k-0.5;
end
for k=2:numel(Yeo_names_rh)
    idx_label = ccs_strfind(Yeo_names_rh,Yeo_names_rh{k});
    Yeo_idx = find(label_Yeo_rh == Yeo_labels_rh(idx_label,5));
    Yeo_rh(Yeo_idx) = k-0.5;
end

%% Yeo surface
% cmap_Yeo = Yeo_labels_rh(:,1:3)/255; cmap_Yeo(1,:) = 0.5;
% figure('Units', 'pixels', 'Position', [100 100 800 800]); axis off
% SurfStatView([Yeo_lh; Yeo_rh], s, 'Cortical Functional Networks');
% colormap(cmap_Yeo) ; SurfStatColLim( [0 8] )
% %Export to JPG
% set(gcf, 'PaperPositionMode', 'auto');
% print('-djpeg', '-r300', [work_dir '/data/masks/figures/Yeo.jpg'])
% close;

%% Settings of variables
subjects = importdata(sub_list);
numSubs = numel(subjects);
reho_lobe = zeros(numSubs, 3, 4, 2);
reho_hierarchy = zeros(numSubs, 3, 4, 2);
reho_7network = zeros(numSubs, 3, 7, 2);

%% Read in KCC-ReHo maps.
for k=1:numSubs
    subjects{k}
    for trt=1:3
        fname_lh = [data_dir '/NYU/ReHo_mc6/func_' num2str(trt) '/surf/' subjects{k} ...
            '.lh.reho.sm0.nii.gz'];
        ReHohdr_lh = load_nifti(fname_lh); tmpvol_lh = squeeze(ReHohdr_lh.vol);
        fname_rh = [data_dir '/NYU/ReHo_mc6/func_' num2str(trt) '/surf/' subjects{k} ...
            '.rh.reho.sm0.nii.gz'];
        ReHohdr_rh = load_nifti(fname_rh); tmpvol_rh = squeeze(ReHohdr_rh.vol);
        for lval=1:5
            %lobe_lh
            tmp = tmpvol_lh((maskLH .* lobe_lh) == (lval+0.5));
            reho_lobe(k,trt,lval,1) = mean(tmp(:));
            %lobe_rh
            tmp = tmpvol_rh((maskRH .* lobe_rh) == (lval+0.5));
            reho_lobe(k,trt,lval,2) = mean(tmp(:));
        end
        for lval=1:4
            %hierarchy_lh
            tmp = tmpvol_lh((maskLH .* hierarchy_lh) == (lval+0.5));
            reho_hierarchy(k,trt,lval,1) = mean(tmp(:));
            %hierarchy_rh
            tmp = tmpvol_rh((maskRH .* hierarchy_rh) == (lval+0.5));
            reho_hierarchy(k,trt,lval,2) = mean(tmp(:));
        end
        for lval=1:7
            %Yeo_lh
            tmp = tmpvol_lh((maskLH .* Yeo_lh) == (lval+0.5));
            reho_7network(k,trt,lval,1) = mean(tmp(:));
            %Yeo_rh
            tmp = tmpvol_rh((maskRH .* Yeo_rh) == (lval+0.5));
            reho_7network(k,trt,lval,2) = mean(tmp(:));
        end
    end
end