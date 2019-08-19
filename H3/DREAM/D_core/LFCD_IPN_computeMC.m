function [FD1, FD2, mc_metrics, covariates] = LFCD_IPN_computeMC(fileMC, time_window)
%% Compute the motion correction nuisances from preprocessed data.
% Inputs:
%   fileMC - file name of 1D motion correction parameters output by
%            3dvolreg commands in AFNI, which includes 6 columns:
%                   roll pitch yaw dS  dL  dP
%            roll  = rotation about the I-S axis }
%            pitch = rotation about the R-L axis } degrees CCW
%            yaw   = rotation about the A-P axis }
%            zdS  = displacement in the Superior direction  }
%            xdL  = displacement in the Left direction      } mm
%            ydP  = displacement in the Posterior direction }
% Outputs:
%   FD1/FD2 - Framewise displacement proposed in Power et al., 2012 with L1 and L2 norm.
%   mc_metrics - all 23 metrics for summarying head motion.
%   covariates - RMS-based head motion measures.
% References:
%   [1]. Van Dijk KR, Sabuncu MR, Buckner RL. 2011. The influence of head 
%       motion on intrinsic functional connectivity MRI. Neuroimage. 59(1):431-438.
%   [2]. Satterthwaite TD, Wolf DH, Loughead J, Ruparel K, Elliott MA, 
%       Hakonarson H, Gur RC, Gur RE. 2012. Impact of in-scanner head motion on 
%       multiple measures of functional connectivity: Relevance for studies
%       of neurodevelopment in youth. Neuroimage. 60(1):623-632.
%   [3]. Power JD, Barnes KA, Snyder AZ, Schlaggar BL, Petersen SE. 2012. 
%       Spurious but systematic correlations in functional connectivity MRI
%       networks arise from subject motion. Neuroimage. 59(3):2142-2154.
% Author:
%   Xi-Nian Zuo, IPCAS
%   email: zuoxn@psych.ac.cn
%   website: lfcd.psych.ac.cn
%   date: 2012/02/01; revised 2012/04/18

%% read the parameters estimated
mc_f = load(fileMC); 
if nargin < 2
    mc_f1 = mc_f;
else
    mc_f1 = mc_f(time_window,:);
end
%% Absolute head motion
mc_dS = mc_f1(:,4); mc_dL = mc_f1(:,5); mc_dP = mc_f1(:,6); 
mc_roll = mc_f1(:,1); mc_pitch = mc_f1(:,2); mc_yaw = mc_f1(:,3);
% Summary
mcDsp = sqrt(mc_dS.^2 + mc_dL.^2 + mc_dP.^2);
mcRot = acos((cos(mc_roll*pi/180).*cos(mc_pitch*pi/180) + ...
    cos(mc_roll*pi/180).*cos(mc_yaw*pi/180) + ...
    cos(mc_yaw*pi/180).*cos(mc_pitch*pi/180) + ...
    sin(mc_roll*pi/180).*sin(mc_pitch*pi/180).*sin(mc_yaw*pi/180) - 1)/2);

%% Relative head motion
% rmc_dS = [mc_dS(1)-mc_dS(1) ; diff(mc_dS)]; 
% rmc_dL = [mc_dL(1)-mc_dL(1) ; diff(mc_dL)]; 
% rmc_dP = [mc_dP(1)-mc_dP(1) ; diff(mc_dP)];
% rmc_roll = [mc_roll(1)-mc_roll(1) ; diff(mc_roll)]; 
% rmc_pitch = [mc_pitch(1)-mc_pitch(1) ; diff(mc_pitch)]; 
% rmc_yaw = [mc_yaw(1)-mc_yaw(1) ; diff(mc_yaw)];
rmc_dS = diff(mc_dS); 
rmc_dL = diff(mc_dL); 
rmc_dP = diff(mc_dP);
rmc_roll = diff(mc_roll); 
rmc_pitch = diff(mc_pitch); 
rmc_yaw = diff(mc_yaw);
% Summary
rmcDsp = sqrt(rmc_dS.^2 + rmc_dL.^2 + rmc_dP.^2);
rmcRot = acos((cos(rmc_roll*pi/180).*cos(rmc_pitch*pi/180) + ...
    cos(rmc_roll*pi/180).*cos(rmc_yaw*pi/180) + ...
    cos(rmc_yaw*pi/180).*cos(rmc_pitch*pi/180) + ...
    sin(rmc_roll*pi/180).*sin(rmc_pitch*pi/180).*sin(rmc_yaw*pi/180) - 1)/2);

%% Absolute head motion
% Mean & Std
mc_meanDsp = mean(mcDsp);
mc_meanRot = mean(abs(mcRot));
mc_stdDsp = std(mcDsp);
mc_stdRot = std(abs(mcRot));
% RMS - very similar to the mean
mc_rmsDsp = IPN_rms(mcDsp);
mc_rmsRot = IPN_rms(mcRot);
% Max
mc_matDsp = abs(mc_f1(:,4:6));
mc_maxDsp = max(mc_matDsp(:));
mc_matRot = abs(mc_f1(:,1:3));
mc_maxRot = max(mc_matRot(:));
% Number 
mc_numDsp = nnz(mcDsp > 0.1);

%% Relative head motion
% Mean & Std
rmc_meanDsp = mean(rmcDsp);
rmc_meanRot = mean(abs(rmcRot));
rmc_stdDsp = std(rmcDsp);
rmc_stdRot = std(abs(rmcRot));
% RMS - very similar to the mean
rmc_rmsDsp = IPN_rms(rmcDsp);
rmc_rmsRot = IPN_rms(rmcRot);
% Max
rmc_maxDsp = max(abs(rmcDsp));
rmc_maxRot = max(abs(rmcRot));
% Number 
rmc_numDsp = nnz(rmcDsp > 0.1);

%% Framewise displacement: FD
FD2 = sqrt((rmc_dS).^2 + (rmc_dL).^2 + (rmc_dP).^2 + ...
    2500*(rmc_roll*pi/180).^2 + 2500*(rmc_pitch*pi/180).^2 + 2500*(rmc_yaw*pi/180).^2);
FD1 = abs(rmc_dS) + abs(rmc_dL) + abs(rmc_dP) + ...
    50*abs(rmc_roll*pi/180) + 50*abs(rmc_pitch*pi/180) + 50*abs(rmc_yaw*pi/180);
% Mean & Std
rmc_meanFD = mean(FD2);
rmc_stdFD = std(FD2);
% RMS
rmc_rmsFD = IPN_rms(FD2);
% Max
rmc_maxFD = max(FD2);
% Number
rmc_numFD = nnz(FD2 > 0.2);

%% Output
mc_metrics = [mc_meanDsp mc_stdDsp mc_rmsDsp mc_maxDsp mc_numDsp ...
    rmc_meanDsp rmc_stdDsp rmc_rmsDsp rmc_maxDsp rmc_numDsp ...
    mc_meanRot mc_stdRot mc_rmsRot mc_maxRot ...
    rmc_meanRot rmc_stdRot rmc_rmsRot rmc_maxRot ...
    rmc_meanFD rmc_stdFD rmc_rmsFD rmc_maxFD rmc_numFD ];
covariates = [rmc_rmsDsp rmc_rmsRot rmc_rmsFD];