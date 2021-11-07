function [numVar] = ccs_core_double4cell(cellVar)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
numVar = zeros(numel(cellVar),1);
for varID=1:numel(cellVar)
    numVar(varID) = str2double(cellVar{varID,1});
end

end

