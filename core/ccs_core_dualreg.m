function [ network_maps, time_series] = ccs_core_dualreg( rfmrivol_masked, sp_regressors, type )
%CCS_CORE_DUALREG Perform dual regression of rfMRI images on the predefined
%   regressors.
%Input:
%   rfmrivol_masked -- the preprocessed resting state FMRI data (masked)
%   sp_regressors -- spatial regressiors for the first regression
%   type -- multiple regression or sigle map regression ('multiple' or
%   'single')

if nargin < 3
    type = 'single';
end
%get basic information
numTRs = size(rfmrivol_masked,2);
[numVertices, numSPs] = size(sp_regressors);
time_series = zeros(numTRs,numSPs);
network_maps = zeros(numVertices, numSPs);
tmpDesignDR1 = [ones(numVertices,1) sp_regressors];
if strcmp(type, 'multiple')
    for trID=1:numTRs %spatial regression
        tmpY = rfmrivol_masked(:,trID);
        tmpB = regress(tmpY, tmpDesignDR1);
        time_series(trID,:) = tmpB(2:end);
    end
    tmpDesignDR2 = [ones(numTRs,1) time_series];
    for vtxID=1:numVertices %temporal regression
        tmpY = rfmrivol_masked(vtxID,:);
        tmpB = regress(tmpY', tmpDesignDR2);
        network_maps(vtxID,:) = tmpB(2:end);
    end
else %one-by-one
    for trID=1:numTRs %spatial regression
        tmpY = rfmrivol_masked(:,trID);
        for cogID=1:numSPs
            tmpDesignDR1 = [ones(numVertices,1) sp_regressors(:,cogID)];
            tmpB = regress(tmpY, tmpDesignDR1);
            time_series(trID,cogID) = tmpB(2);
        end
    end
    for vtxID=1:numVertices %temporal regression
        tmpY = rfmrivol_masked(vtxID,:);
        for cogID=1:numSPs
            tmpDesignDR2 = [ones(numTRs,1) time_series(:,cogID)];
            tmpB = regress(tmpY', tmpDesignDR2);
            network_maps(vtxID,cogID) = tmpB(2);
        end
    end
end

end

