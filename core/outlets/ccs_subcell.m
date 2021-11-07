function subcell = ccs_subcell(cellstr,idx)
subcell = cell(numel(idx), 1);
for k=1:numel(idx)
    subcell{k} = cellstr{idx(k)};
end