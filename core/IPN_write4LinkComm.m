function IPN_write4LinkComm(CIJ, fname, labels)
%IPN_WRITE4LINKCOMM         Write to a TXT format used for Link Community
%                           detection
%
%   IPN_write4LinkComm(CIJ, fname);
%
%   This function writes a R LinkComm .txt file from a MATLAB matrix
%
%   Inputs:     CIJ,        adjacency matrix
%               fname,      filename minus .txt extension
%               labels,     name of nodes
%
%   Xi-Nian Zuo, LFCD@IPCAS, 2011.


N = size(CIJ,1);
fid = fopen(cat(2,fname,'.txt'), 'w');

%% HEADER
%hdl1 = '<?xml version="1.0" encoding="UTF-8"?>';
%fprintf(fid, '%s \r', hdl1);
%% NODES
%fprintf(fid, '  <nodes> \r');
%for i = 1:N
%	ndl = ['   <node id="' num2str(i-1) '" label="' labels{i} '" />'];
%    fprintf(fid, '%s \r', ndl);
%end
%fprintf(fid, '   </nodes> \r');
%% EDGES
k=1;
for ii = 1:N
    for jj = ii+1:N
        if CIJ(ii,jj) ~= 0
			edl = [labels{ii} ' ' labels{jj} ' ' num2str(CIJ(ii,jj))];
            fprintf(fid, '%s \r', edl);
			k = k + 1;
        end
    end
end
%% CLOSE
fclose(fid);
