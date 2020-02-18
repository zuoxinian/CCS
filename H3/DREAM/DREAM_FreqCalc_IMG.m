function [freqbands,output_mtx] = DREAM_FreqCalc_IMG(TR,filepath,sub_list,func,filename)
sublist_all = importdata(sub_list)
files = cellstr(filename);

for tem = 1:length(sublist_all)
    cd (filepath);
    subj = char(sublist_all(tem,1));

    savepath = [filepath,'/', subj,'/',func];
    savep = [savepath,'/DREAM.mat'];
    save(savep);

    afdpath = [filepath '/' subj '/' func];
    
    for ii = 1:length(files)
        file = files{1,ii};
        
        subj_v=load_nifti([afdpath '/' file]);
        X= size(subj_v.vol,1);
        Y= size(subj_v.vol,2);
        Z = size(subj_v.vol,3);
        num_samples = size(subj_v.vol,4);
        
        subj_vol= reshape(subj_v.vol,X*Y*Z,num_samples);
        N = num_samples;
        
        freqbands = ccs_core_lfobands(N, TR);
        
        cd (afdpath);
        savefile = strrep(file,'.nii.gz','FBs');
        mkdir(savefile);
        dir_path = [afdpath '/' savefile];
        cd(dir_path);
        csvwrite(['freqbands.csv'],freqbands);
        
        input_mtx= subj_vol';
        
        for i =1:length(freqbands)
            low_f = min(freqbands{i,1});
            high_f = max(freqbands{i,1});
            
            output_mtx = CBIG_bandpass_matrix(input_mtx, low_f, high_f, TR);
                        
            subj_v_vol = output_mtx;
            subj_v_vol = subj_v_vol';
            subj_v.vol= reshape(subj_v_vol,X,Y,Z,N);
            
            cd (afdpath);
            savefile = strrep(file,'.nii.gz','FBs')
            mkdir(savefile);
            dir_path = [afdpath '/' savefile];
            p = ['save_nifti(subj_v ,''', dir_path ,'/',savefile , num2str(i), '.nii.gz', ''')'];
            eval(p);
            cd (dir_path);
            
        end
    end
end
