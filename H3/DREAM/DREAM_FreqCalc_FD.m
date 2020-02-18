function  [freqbands,output_mtx] = DREAM_FreqCalc_FD(TR,filepath,sub_list,func,filename)
sublist_all = importdata(sub_list);
files = cellstr(filename);

for tem = 1:length(sublist_all)
    subj = char(sublist_all(tem,1));
    
    savepath = [filepath,'/', subj,'/',func];
    savep = [savepath,'DREAM.mat'];
    save(savep);

    FDpath = [filepath ,'/', subj ,'/', func];
    for ii = 1:length(files)
        
        file = files{1,ii};
        
        data = importdata([FDpath,'/',file]);
        num_sample = length(data);
        N = num_sample;
        
        freqbands = ccs_core_lfobands(N, TR);
       
        cd(FDpath);
        
        input_mtx = data;
        
        for i =1:length(freqbands)
            low_f = min(freqbands{i,1});
            high_f = max(freqbands{i,1});
            
            output_mtx = CBIG_bandpass_matrix(input_mtx, low_f, high_f, TR);
            
            savefile = strrep(file,'.1D','FBs');
            if ~exist(savefile, 'dir'); mkdir(savefile); end
            cd([FDpath,savefile]);
            csvwrite([FDpath,savefile,'/freqbands.csv'],freqbands);
            savefile = strrep(file,'.1D','FBs');
            AFD = [FDpath,'/',savefile,'/',savefile, num2str(i), '.1D'];
            dlmwrite(AFD, output_mtx, '\t');
        end
    end
end
