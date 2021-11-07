function cellstr = ccs_concatCell(cellstr1,cellstr2)
nc1 = numel(cellstr1);
nc2 = numel(cellstr2);
cellstr = cell(nc1+nc2,1);
for k=1:nc1
    cellstr{k} = cellstr1{k};
end
for k=1:nc2
    cellstr{k+nc1} = cellstr2{k};
end

end