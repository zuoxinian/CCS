function metric_norm = ccs_circos_normalize( metric_raw )
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
min_raw = min(metric_raw(:));
max_raw = max(metric_raw(:));
metric_norm = (metric_raw - min_raw)/(max_raw - min_raw);

end

