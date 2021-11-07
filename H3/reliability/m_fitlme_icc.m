function icc = m_fitlme_icc(tbl, model, type)
% Intra-Class Correlation Testing
% Ting Xu Feb 21, 2019
%
% Ref: Koo & Li 2016,
% A guideline of selecting and reporting intraclass correlation coefficients for reliability research

% Model: One-way random, Two-way random, Two-way mixed
% Type?single measurement, mean of k measurements as the basis of the actual measurement
% Definition: Absolute Agreement, or Consistency

% Input matrix
% tbl: table (variables includes y, subID, rater)
% example: 25 subjects x 2 sessions 
%% demo data
% fname = 'demo_data_m_fitlme_icc.mat';
% load(fname);
%
% icc = m_fitlme_icc(tbl, 'one-way-random', 'consistency');
% icc = m_fitlme_icc(tbl, 'two-way-random', 'agreement');
% icc = m_fitlme_icc(tbl, 'two-way-random', 'consistency');
% icc = m_fitlme_icc(tbl, 'two-way-mixed',  'consistency');
% 
% Result: One-way random model ICC = 0.530
% Result: Two-way random model ICC(agreement)   = 0.531
% Result: Two-way random model ICC(consistency) = 0.534
% Result: Two-way mixed model  ICC(consistency) = 0.534

%% coding the input data

%%
switch model
    case "one-way-random" 
        %% one-way random
        lme_1wayR = fitlme(tbl,'y ~ 1 + (1|subID)', 'FitMethod','REML');
        [psi,mse, ~] = covarianceParameters(lme_1wayR);
        sigma_res = mse;
        sigma_sub = psi{1};
        icc_agreement = sigma_sub / (sigma_sub + sigma_res);
        switch lower(type)
            case "consistency"
                fprintf('One-way random model\nICC(agreement) = %0.3f\n ', icc_agreement)
                icc = icc_agreement;
            otherwise
                error('Choose Type (One-way random model): agreement')
        end
    case "two-way-random" 
        %% two-way random
        lme_2wayR = fitlme(tbl,'y ~ 1  + (1|subID) + (1|rater)', 'FitMethod','REML');
        [psi,mse,~] = covarianceParameters(lme_2wayR);
        sigma_res = mse;
        sigma_sub = psi{1};
        sigma_rat = psi{2};
        icc_consistency = sigma_sub / (sigma_sub + sigma_res);
        icc_agreement   = sigma_sub / (sigma_sub + sigma_rat + sigma_res);
        switch lower(type)
            case "agreement"
                fprintf('Two-way random model\nICC(agreement)   = %0.3f\n ', icc_agreement)
                icc = icc_agreement;
            case "consistency"
                fprintf('Two-way random model\nICC(consistency) = %0.3f\n ', icc_consistency)
                icc = icc_consistency;
            otherwise
                error('Choose type (Two-way random model): agreement or consistency')
        end
    case "two-way-mixed" 
        %% two-way mixed
        lme_2wayM = fitlme(tbl,'y ~ 1 + rater + (1|subID)', 'FitMethod','REML');
        [psi,mse,~] = covarianceParameters(lme_2wayM);
        sigma_res = mse;
        sigma_sub = psi{1};
        icc_consistency = sigma_sub / (sigma_sub + sigma_res);
        switch lower(type)
            case "consistency"
                fprintf('Two-way mixed model\nICC(consistency) = %0.3f\n ', icc_consistency)
                icc = icc_consistency;
            otherwise
                error('Choose Type (Two-way Mixed model): consistency')
        end
    otherwise
        error('Error: Choose Model: one-way-random, two-way-random, two-way-mixed\n      Choose Type:  agreement or consistency')
end

%% Need to polish this function
