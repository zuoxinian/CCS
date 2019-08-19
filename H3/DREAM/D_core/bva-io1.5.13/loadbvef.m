% loadbvef() - Load BrainVision electrode location file
%
% Usage:
%   >> chanlocs = loadbvef( filename );
%
% Inputs:
%   filename  - filename incl. filepath
%
% Outputs:
%   chanlocs  - EEGLAB chanlocs structure
%
% References:
%   http://de.mathworks.com/help/matlab/import_export/importing-xml-documents.html
%
% Author: Andreas Widmann, University of Leipzig, 2015

%123456789012345678901234567890123456789012345678901234567890123456789012

% Copyright (C) 2015 Andreas Widmann, University of Leipzig, widmann@uni-leipzig.de
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

function [ chanlocs ] = loadbvef( filename )

% Import/export tag/field name mapping
fieldNames = { 'Name', 'labels', 1; 'Theta', 'sph_theta_besa', 0; 'Phi', 'sph_phi_besa', 0; 'Radius', 'sph_radius', 0 };

% Read file
xDoc = xmlread( filename );

% Loop over electrodes
allListitems = xDoc.getElementsByTagName( 'Electrode' );

for k = 0:allListitems.getLength - 1

    thisListitem = allListitems.item( k );

    % Loop over fields
    for iField = 1:size( fieldNames, 1 )

        thisList = thisListitem.getElementsByTagName( fieldNames{ iField, 1 } );
        thisElement = thisList.item( 0 );

        % String or numeric
        if fieldNames{ iField, 3 }
            chanlocs( k + 1 ).( fieldNames{ iField, 2 } ) = char( thisElement.getFirstChild.getData ); %#ok<AGROW>
        else
            chanlocs( k + 1 ).( fieldNames{ iField, 2 } ) = str2double( thisElement.getFirstChild.getData ); %#ok<AGROW>
        end

    end

end

% Convert from BESA
chanlocs = convertlocs( chanlocs, 'sphbesa2all' );
chanlocs = rmfield( chanlocs, { 'sph_phi_besa', 'sph_theta_besa' } );

end