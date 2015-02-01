function [ modelfit, y_predict, y_predictupCI, y_predictbtmCI] = ccs_core_polyfit( table, x_predict)
%UNTITLED2 Summary of this function goes here
%   Detailed explanation goes here

%linear
model{1} = fitlm(table,'linear');
%quad
model{2} = fitlm(table,'quadratic');
%cubic
model{3} = fitlm(table,'poly3');
%model selection
BIC = zeros(3,1);
for mid=1:3
    BIC(mid) = model{mid}.ModelCriterion.BIC;
end
[~, idx_model] = min(BIC); modelfit = model{idx_model};
poly_coef = table2array(model{idx_model}.Coefficients(end:-1:1,1));
poly_SE = table2array(model{idx_model}.Coefficients(end:-1:1,2));
y_predict = polyval(poly_coef,x_predict);
poly_upCI = poly_coef + tinv(1-0.05/2,model{idx_model}.DFE)* poly_SE;
poly_btmCI = poly_coef - tinv(1-0.05/2,model{idx_model}.DFE)* poly_SE;
y_predictupCI = polyval(poly_upCI,x_predict);
y_predictbtmCI = polyval(poly_btmCI,x_predict);

end

