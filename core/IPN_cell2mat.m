function [mat, nr, nc] = IPN_cell2mat( cel )
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

numArray = length(cel);
tmp = cel{1};
[nr, nc] = size(tmp);
mat = zeros(numArray, nr, nc);
for k=1:numArray
    mat(k,:,:) = cel{k};
end

end

