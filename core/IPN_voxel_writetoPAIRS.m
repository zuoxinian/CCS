function IPN_voxel_writetoPAIRS(CIJ, fname)
%IPN_VOXEL_WRITETOPAIRS         Write to .pairs format
%
%   IPN_voxel_writetoPAIRS(CIJ, fname);
%
%   This function writes a Gephi .gexf file from a MATLAB matrix
%
%   Inputs:     CIJ,        adjacency matrix
%               fname,      filename minus .gexf extension
%
%   Xi-Nian Zuo, New York University, 2010.


N = size(CIJ,1); 
[i, j, ~] = find(CIJ) ;
edge_list = [i, j];

%% List of pair edges
fid = fopen(cat(2,fname,'.pairs'), 'w');
fprintf(fid, '%d %d\n', edge_list');
fclose(fid);
