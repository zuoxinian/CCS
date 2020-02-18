function [freqbands] = DREAM_FreqCalc_EEG(TR,filepath,sub_list,func,filename)
sublist_all = importdata(sub_list);
files = cellstr(filename);
for tem = 1:length(sublist_all)
    subj = char(sublist_all(tem,1));
    savepath = [filepath,'/', subj,'/',func];
    savep = [savepath,'/DREAM.mat'];
    save(savep);
    EEGpath = filepath;
    for ii= 1:length(files)
        file = files{1,ii};
        eegvhdr = [EEGpath ,'/', subj , '/' file ];
        [subjpath,subjname] = fileparts(eegvhdr);
        
        [EEG, com] = AFD_pop_loadbv([EEGpath ,'/', subj] , file);
        
        N = size(EEG.data,2);
        
        freqbands = ccs_core_lfobands(N, TR);
        
        cd(subjpath);
        subjname = [subjname ,'FBs',];
        if ~exist(subjname, 'dir'); mkdir(subjname); end
        cd(subjname);
        csvwrite('freqbands.csv',freqbands);
        
        input_mtx = EEG.data';
           
        for i =1:length(freqbands)
            low_f = min(freqbands{i,1});
            high_f = max(freqbands{i,1});
            
            output_mtx = CBIG_bandpass_matrix(input_mtx, low_f, high_f, TR);
           
            output_mtx = output_mtx';
            
            dat = output_mtx;
            ntrl = size(EEG.data,1);
            
            %save eeg data
            datafile = [subjname,'FBs',num2str(i),'.eeg'];
            fid = fopen(datafile,'w');
            if length(size(dat))>2
                ft_warning('writing segmented data as if it were continuous');
                for i=1:ntrl
                    fwrite(fid, dat,'int16');
                end
            else
                fwrite(fid, dat,'int16');
            end
            fclose(fid);
            
            [p, f, x] = fileparts(eegvhdr);
            vmrkfile = fullfile(p, [f '.vmrk']);
            
            dataname = [subjname,'FBs',num2str(i)];
            
            %%vhdrfile
            vhdrtext = fileread(eegvhdr);
            %modify datafile and makerfile
            exprdf = '[^\n]*DataFile[^\n]*';
            matches = regexp(vhdrtext,exprdf,'match');
            ndatafile = strrep(vhdrtext,matches{1},['DataFile=', dataname ,'.eeg']);
            exprmf = '[^\n]*MarkerFile[^\n]*';
            matches = regexp(vhdrtext,exprmf,'match');
            ndatafile = strrep(ndatafile,matches{1},['MarkerFile=', dataname ,'.vmrk']);
            %change \
            expr = '\';
            matches = regexp(ndatafile,expr,'match');
            ndatafile = strrep(ndatafile,matches{1},'\\');
            fid = fopen([dataname,'.vhdr'],'w');
            fprintf(fid,ndatafile);
            fclose(fid);
            
            %%vmrkfile
            vmrktext = fileread(vmrkfile);
            exprdf = '[^\n]*DataFile[^\n]*';
            matches = regexp(vmrktext,exprdf,'match');
            ndatafile = strrep(vmrktext,matches{1},['DataFile=', dataname ,'.eeg']);
            %change \
            expr = '\';
            matches = regexp(ndatafile,expr,'match');
            ndatafile = strrep(ndatafile,matches{1},'\\');
            fid = fopen([dataname,'.vmrk'],'w');
            fprintf(fid,ndatafile);
            fclose(fid);
            
        end
        
    end
end
end
