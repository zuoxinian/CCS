function [f,Matrix,Matrix_FA,Matrix_Length]=ccs_gpanda_FiberNumMatrix(trackfilepath,ROIfilepath,FAfilepath)
%trackfilepath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%SUMMARY OF G_FIBERNUMMATRIX
% 
% Extract the fiber which connected the ROIm and ROIn. ROI1 and ROI2 are 
% the label according to the aal.nii
%
% 
%___________________________________________________________________
% INPUTS:
%
% TRACKFILEPATH
%       (string)
%       the full path of fiber tracking file(.trk)
%
% ROIFILEPATH
%       (string)
%       the fullpath of the ROI label file in native space (.nii.gz or .nii file)
%
% FAFILEPATH
%       (string)
%       the full path of FA in native space (.nii.gz or .nii file)
%
% 
%__________________________________________________________________________
% OUTPUTS:
% MatrixM-N.mat
%        the f structure contain the fiber read from .trk file
%        the Fiber Number Matrix, The FA Matrix and the fiber average length Matrix.
%
%__________________________________________________________________________
% USAGE:
%
%        1) g_FiberNumMatrix(trackfilepath, ROIfilepath, FAfilepath)
%        2) g_FiberNumMatrix(trackfilepath, ROIfilepath)
%__________________________________________________________________________
% COMMENTS:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if nargin < 3
    FAMatrix_Index = 0;
else
    FAMatrix_Index = 1;
end

Fibers = {};
[f] = g_readTrack(trackfilepath);
Voxel_size=f.voxel_size;
XLim = f.dim(1);
YLim = f.dim(2);
ZLim = f.dim(3);
numFibers = size(f.fiber, 2);
disp(['There are total ' num2str(numFibers) ' fibers!'])

    for i = 1:numFibers
        Fibers{i} = f.fiber(i).xyzFiberCoord;
    end
    %read ROI
    AtlasHDR = load_nifti(ROIfilepath); Atlas = AtlasHDR.vol;
    %read FA
    if FAMatrix_Index == 1
        faHDR = load_nifti(FAfilepath);
        FA_Matrix = faHDR.vol;
    end
 
Num_node = max(Atlas(:));
Matrix = zeros(Num_node,Num_node);
Matrix_FA= zeros(Num_node,Num_node);
Matrix_Voxel=zeros(Num_node,Num_node);
Matrix_Length=zeros(Num_node,Num_node);

for i = 1:numFibers
    %if mod(i, 1000) == 1
    %    disp(['Completed ' num2str(i/numFibers*100) ' percentage of fibers ...'])
    %end
    pStart = floor(Fibers{i}(1, :) + 1);
    pEnd = floor(Fibers{i}(end, :) + 1);
    if pStart(1)>0 && pStart(1)<=XLim &&  pStart(2)>0 && pStart(2)<=YLim && pStart(3)>0 && pStart(3)<=ZLim && pEnd(1)>0 && pEnd(1)<=XLim && pEnd(2)>0 && pEnd(2)<=YLim && pEnd(3)>0 && pEnd(3)<=ZLim
        m = Atlas(pStart(1),(YLim-pStart(2)),pStart(3));
        n = Atlas(pEnd(1),(YLim-pEnd(2)),pEnd(3));
        if m > 0 && n > 0 && m~= n && m <= Num_node && n <= Num_node
            Matrix(m,n) = Matrix(m,n) + 1;
            Matrix(n,m) = Matrix(n,m) + 1;
            lengthFiber_i = size(Fibers{i},1);
            for j=1:lengthFiber_i
                 point(j,:) = floor(Fibers{i}(j,:)+1);
                 if point(j,1)>0 && point(j,1)<=XLim &&  point(j,2)>0 && point(j,2)<=YLim && point(j,3)>0 && point(j,3)<=ZLim
                    
                     Matrix_Voxel(m,n)=Matrix_Voxel(m,n)+1;
                     Matrix_Voxel(n,m)=Matrix_Voxel(n,m)+1;
                     if j>=2
                         Matrix_Length(m,n)=Matrix_Length(m,n)+sqrt(sum(((point(j,:)-point(j-1,:)).*Voxel_size(1,:)).^2));
                         Matrix_Length(n,m)=Matrix_Length(m,n);
                         
                     end
                     if FAMatrix_Index == 1
                         Matrix_FA(m,n)=Matrix_FA(m,n)+FA_Matrix(point(j,1),point(j,2),point(j,3));
                         Matrix_FA(n,m)=Matrix_FA(m,n);
                     end
                     
                 end
            end  
        end
        
    end
end 
for i=1:Num_node
    for j=1:Num_node
        if Matrix_Length(i,j)~=0
           Matrix_FA(i,j)=Matrix_FA(i,j)/Matrix_Voxel(i,j);
           Matrix_Length(i,j)=Matrix_Length(i,j)/Matrix(i,j);
       end
    end
end

function [f] =g_readTrack(filename)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This program will read in a "dti.trk" file created
%   within Trackvis. 
%   SYNTAX:
%   G_READTRACK(FILENAME)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   INPUTS
%   FILENAME
%      (string)the full path of the .trk file
%      For example:'/data/node2/suyu/001+/trackvis_2/test_sl_nsf.trk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   OUTPUTS:
%   f.mat file format 
%		     - f.id_string               - ID string for track file.The first 5 characters must be "TRACK".
%            - f.dim                     - Dimension of the image volume.
%	         - f.voxel_size              - Voxel size of the image volume.
%		     - f.orgin                   - Origin of the image volume. 
%                                     		   This field is not yet being used by TrackVis.
%                                        	   That means the origin is always (0, 0, 0).
%            - f.n_scalars               - Number of scalars saved at each track point (besides x, y and z coordinates).
%		     - f.scalar_name             - Name of each scalar. Can not be longer than 20 characters each. Can only store up to 10 names.
%		     - f.n_properties            - Number of properties saved at each track.
%		     - f.property_name           - Name of each property. 
%                                        	   Can not be longer than 20 characters each. Can only store up to 10 names.
%            - f.vox_to_ras              - A 4x4 matrix for voxel to RAS (crs to xyz) transformation. 
%                                        	   If vox_to_ras[3][3] is 0, it means the matrix is not recorded. 
%            - f.reserved                - Reserved space for future version.
%		     - f.voxel_order             - Storing order of the original image data. 
%		     - f.pad2                    - Paddings.
%		     - image_orientation_patient - Image orientation of the original image. 
%		     - f.pad1                    - Paddings.
%            - f.invert_x                - Inversion/rotation flags used to generate this track file. 
%            - f.invert_y                - As above
%            - f.invert_z                - As above
%            - f.swap_xy                 - As above.
%		     - f.swap_yz                 - As above.
%		     - f.swap_zx                 - As above.
%		     - f.nFiberNr                - Number of tracks stored in this track file. 0 means the number was NOT stored.
%            - f.version                 - Version number of the trackvis.
%            - f.hdr_size                - Size of the header. Used to determine byte swap. Should be 1000.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Author  Suyu Zhong 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fid=fopen(filename, 'rb', 'l');
f.id_string                 = fread(fid, 6, '*char')';% image dimenson
f.dim                       = fread(fid, 3, 'short')';% voxel size
f.voxel_size                = fread(fid, 3, 'float')';
f.origin                    = fread(fid, 3, 'float')';%Orign of the image volume.
f.n_scalars                 = fread(fid, 1, 'short')';
f.scalar_name               = fread(fid, [20,10], '*char')';
f.n_properties              = fread(fid, 1, 'short')';
f.property_name             = fread(fid, [20,10], '*char')';
f.vox_to_ras                = fread(fid, [4,4], 'float')';
f.reserved                  = fread(fid, 444, '*char');
f.voxel_order               = fread(fid, 4, '*char')';
f.pad2                      = fread(fid, 4, '*char')';
f.image_orientation_patient = fread(fid, 6, 'float')';
f.pad1                      = fread(fid, 2, '*char')';
f.invert_x                  = fread(fid, 1, 'uchar');
f.invert_y                  = fread(fid, 1, 'uchar');
f.invert_z                  = fread(fid, 1, 'uchar');
f.swap_xy                   = fread(fid, 1, 'uchar');
f.swap_yz                   = fread(fid, 1, 'uchar');
f.swap_zx                   = fread(fid, 1, 'uchar');
f.nFiberNr                   = fread(fid, 1, 'int')';
f.version                   = fread(fid, 1, 'int')';
f.hdr_size                  = fread(fid, 1, 'int')';% Preallocate 
f.fiber(1).nFiberLength = 0;
f.fiber(1).xyzFiberCoord = single(zeros(3, 100000));
ii=0;
 while feof(fid) == 0
    ii=ii+1;
	%each fiber is stored in following way:
	%int nFiberLength;	    // fiber length
     A= fread(fid, 1, 'int');
     if(A~=0)
        f.fiber(ii).nFiberLength=A; 

        % XYZ_TRIPLE    xyzFiberCoordinate[nFiberLength]; //x-y-x, 3 float data
        f.fiber(ii).xyzFiberCoord = fread(fid, [3+f.n_scalars f.fiber(ii).nFiberLength], 'float=>float')';
        if f.n_properties
            f.fiber(ii).props=fread(fid,f.n_properties,'float');
        end
        f.fiber(ii).xyzFiberCoord=double(f.fiber(ii).xyzFiberCoord./repmat(f.voxel_size,f.fiber(ii).nFiberLength,1));
        f.nFiberNr=ii;
    end
    
end

fclose(fid);

