function [modelfit, y_predict, y_predictupCI, y_predictbtmCI] = ...
    ccs_core_polyagecurvfit(age, sex, voi, age_predict)
%CCS_CORE_POLYAGECURVFIT Summary of this function goes here

tbl = table(age,sex,voi);
%models
mdl{1} = fitlm(tbl, 'interactions', 'ResponseVar', 'voi', ...
    'PredictorVars', {'age','sex'}, 'CategoricalVar', {'sex'});
mdl{2} = fitlm(tbl, 'quadratic', 'ResponseVar', 'voi', ...
    'CategoricalVar', {'sex'});
mdl{3} = fitlm(tbl, 'poly31', 'ResponseVar', 'voi', ...
    'CategoricalVar', {'sex'});
%model selection
AIC = zeros(3,1);
for mid=1:3
    AIC(mid) = mdl{mid}.ModelCriterion.AIC;
end
[~, idx_model] = min(BIC); modelfit = mdl{idx_model};
poly_coef = table2array(modelfit.Coefficients(end:-1:1,1));
poly_SE = table2array(modelfit.Coefficients(end:-1:1,2));
y_predict = polyval(poly_coef,x_predict);
poly_upCI = poly_coef + tinv(1-0.05/2,modelfit.DFE)* poly_SE;
poly_btmCI = poly_coef - tinv(1-0.05/2,modelfit.DFE)* poly_SE;
y_predictupCI = polyval(poly_upCI,age_predict);
y_predictbtmCI = polyval(poly_btmCI,age_predict);

end

