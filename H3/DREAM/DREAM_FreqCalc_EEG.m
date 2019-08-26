function [freqbands] = DREAM_FreqCalc_EEG(TR,filepath,sub_list,func,filename)
sublist_all = importdata(sub_list)
files = cellstr(filename)
for tem = 1:length(sublist_all)
    subj = char(sublist_all(tem,1))
    savepath = [filepath,'/', subj,'/',func]
    savep = [savepath,'/DREAM.mat']
    save(savep)
    EEGpath = filepath
    for ii= 1:length(files)
        file = files{ii,1}
        eegvhdr = [EEGpath ,'/', subj , '/' file ]
        [subjpath,subjname] = fileparts(eegvhdr)
        
        [EEG, com] = AFD_pop_loadbv([EEGpath ,'/', subj] , file);
        
        N = size(EEG.data,2);
        % Set up variables
        % TR = 1/EEG.srate;
        fmax = 1/(2*TR); fmin = 1/(N*TR/2);
        if rem(N,2)==0
            fnum = N/2;
        else
            fnum = (N+1)/2;
        end
        freq = linspace(0,fmax,fnum+1);
        tmpidx = find(freq<=fmin);
        frmin = freq(tmpidx(end)+4); % minimal reliable frequency
        
        %% Determine the range of frequencies in natural log space
        
        nlcfmin = fix(log(frmin));
        nlcfmax = fix(log(fmax));
        nlcf = nlcfmin:nlcfmax;
        numbands = numel(nlcf);
        freqbands = cell(numbands,1);
        for nlcfID=1:numbands
            [~,idxfmin] = min(abs(freq-exp(nlcf(nlcfID)-0.5)));
            [~,idxfmax] = min(abs(freq-exp(nlcf(nlcfID)+0.5)));
            freqbands{nlcfID} = [freq(idxfmin) freq(idxfmax)];
        end
        %modify the min band and max band
        tmpf = freqbands{1};
        if tmpf(1)<frmin
            tmpf(1) = frmin;
            freqbands{1} = tmpf;
        end
        tmpf = freqbands{end};
        if tmpf(2)>fmax
            tmpf(2) = fmax;
            freqbands{end} = tmpf;
        end
        
        cd(subjpath);
        subjname = [subjname ,'FBs',];
        if ~exist(subjname, 'dir'); mkdir(subjname); end
        cd(subjname);
        csvwrite('freqbands.csv',freqbands);
        
        input_mtx = EEG.data';
           
        for i =1:length(freqbands)
            low_f = min(freqbands{i,1})
            high_f = max(freqbands{i,1})
            if (low_f >= high_f)
                error('ERROR: Bandstop is not allowed.')
            end
            
            % sample frequency
            Fs = 1/TR;
            
            % sample points
            L = size(input_mtx, 1);
            
            if (mod(L, 2) == 0)
                % If L is even
                f = [0:(L/2-1) L/2:-1:1]*Fs/L;  %frequency vector
            elseif (mod(L, 2) == 1)
                % If L is odd
                f = [0:(L-1)/2 (L-1)/2:-1:1]*Fs/L;
            end
            
            % index of frequency that you want to keep
            ind = ((low_f <= f) & (f <= high_f));
            
            % create a rectangle window according to the cutoff frequency
            rectangle = zeros(L, 1);
            rectangle(ind) = 1;
            
            % use fft to transform the time course into frequency domain
            fprintf('FFT each time course.\n')
            input_mtx_fft = fft(input_mtx);
            
            % apply the rectangle window and ifft the signal from frequency domain to time domain
            fprintf('Apply rectangle window and IFFT.\n')
            output_mtx{i,1} = ifft(bsxfun(@times, input_mtx_fft, rectangle));
            
            output_mtx{i,1} = output_mtx{i,1}';
            
            dat = output_mtx{i,1};
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