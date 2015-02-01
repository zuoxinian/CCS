%% Remove Mean from each column of matrix D
function dm = IPN_demean(D)

nr = size(D,1);
m = repmat(mean(D), nr, 1);
dm = D - m;