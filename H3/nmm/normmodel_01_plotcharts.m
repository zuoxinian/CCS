%% dir settings (may not usable for you and you have to change them...)
clear all; clc
meta_dir = '/Volumes/DJICopilot/REST-meta-PD';
ana_dir = [meta_dir '/nmm'];
fig_dir = [ana_dir '/group/figures'];
ccs_dir = '/Users/mac/Projects/CCS';
ccs_matlab = [ccs_dir '/matlab'];
ccs_vistool = [ccs_dir '/vistool'];
fs_home = '/Applications/freesurfer'; 
fsaverage = 'fsaverage5';

%% Set up the path to matlab function in Freesurfer release
addpath(genpath(ccs_matlab)) %ccs matlab scripts
addpath(genpath(ccs_vistool)) %ccs matlab scripts
addpath(genpath([fs_home '/matlab'])) %freesurfer matlab scripts

%% Normative charts plot: group-level ALFF
figure('Units', 'pixels', 'Position', [100 100 630 890]); 
ftable = [ana_dir '/data/alff/gamlss.predict.csv'];
if exist(ftable,'file')
    charts = readtable(ftable, 'Delimiter', ',');
    age = ccs_core_double4cell(charts.Var2(2:end));
    centile95 = ccs_core_double4cell(charts.Var7(2:end));
    centile75 = ccs_core_double4cell(charts.Var6(2:end));
    centile50 = ccs_core_double4cell(charts.Var5(2:end));
    centile25 = ccs_core_double4cell(charts.Var4(2:end));
    centile5 = ccs_core_double4cell(charts.Var3(2:end));
    %plot cent50 line
    hPlot_cent50 = plot(age, centile50);
    %adjust line properties (Functional)
    set(hPlot_cent50, 'LineWidth', 4, 'Color', 'k');
    hold on
    %plot cent25/75 line
    hPlot_cent25 = plot(age, centile25);
    hPlot_cent75 = plot(age, centile75);
    %adjust line properties (Functional)
    set(hPlot_cent25, 'LineWidth', 2, 'Color', 'k');
    set(hPlot_cent75, 'LineWidth', 2, 'Color', 'k');
    %plot cent5/95 line
    hPlot_cent5 = plot(age, centile5);
    hPlot_cent95 = plot(age, centile95);
    %adjust line properties (Functional)
    set(hPlot_cent5, 'LineWidth', 2, 'Color', 'k');
    set(hPlot_cent95, 'LineWidth', 2, 'Color', 'k');
end
hXLabel = xlabel('Age (years)');
hYLabel = ylabel('ALFF (z-score)');
%adjust font and axes properties
set(gca, 'FontName', 'Times', 'FontSize', 20 , 'FontWeight', 'bold');
set([hXLabel, hYLabel], 'FontName', 'Times', 'FontSize', 20, ...
    'FontWeight', 'bold');
set(gca, ...
        'Box'         , 'on'     , ...
        'TickDir'     , 'out'      , ...
        'TickLength'  , [.02 .02] , ...
        'XMinorTick'  , 'on'      , ...
        'YMinorTick'  , 'on'      , ...
        'XGrid'       , 'on'      , ...
        'YGrid'       , 'on'      , ...
        'XMinorGrid'  , 'on'      , ...
        'YMinorGrid'  , 'on'      , ...
        'GridAlpha'   , 0.75      , ...
        'Color'       , [1 1 1], ...
        'GridColor'   , [0 0 0], ...
        'XColor'      , [0 0 0], ...
        'YColor'      , [0 0 0], ...
        'xLim'        , [35 85]    , ...
        'LineWidth'   , 1         );
%export to PNG
set(gcf, 'PaperPositionMode', 'auto', 'Color', 'white', 'InvertHardCopy','off');
fig_dir = [ana_dir '/figures'];
print('-dpng','-r300', [fig_dir '/growthcharts_update.png'])
close;

%% Normative charts plot: group-level ALFF
figure('Units', 'pixels', 'Position', [100 100 630 890]); 
ftable = [ana_dir '/data/alff/gamlss.predict.females.csv'];
if exist(ftable,'file')
    charts = readtable(ftable, 'Delimiter', ',');
    age = ccs_core_double4cell(charts.Var2(2:end));
    centile95 = ccs_core_double4cell(charts.Var7(2:end));
    centile75 = ccs_core_double4cell(charts.Var6(2:end));
    centile50 = ccs_core_double4cell(charts.Var5(2:end));
    centile25 = ccs_core_double4cell(charts.Var4(2:end));
    centile5 = ccs_core_double4cell(charts.Var3(2:end));
    %plot cent50 line
    hPlot_cent50 = plot(age, centile50);
    %adjust line properties (Functional)
    set(hPlot_cent50, 'LineWidth', 4, 'Color', 'm');
    hold on
    %plot cent25/75 line
    hPlot_cent25 = plot(age, centile25);
    hPlot_cent75 = plot(age, centile75);
    %adjust line properties (Functional)
    set(hPlot_cent25, 'LineWidth', 2, 'Color', 'm');
    set(hPlot_cent75, 'LineWidth', 2, 'Color', 'm');
    %plot cent5/95 line
    hPlot_cent5 = plot(age, centile5);
    hPlot_cent95 = plot(age, centile95);
    %adjust line properties (Functional)
    set(hPlot_cent5, 'LineWidth', 2, 'Color', 'm');
    set(hPlot_cent95, 'LineWidth', 2, 'Color', 'm');
end
hXLabel = xlabel('Age (years)');
hYLabel = ylabel('ALFF (z-score)');
%adjust font and axes properties
set(gca, 'FontName', 'Times', 'FontSize', 20 , 'FontWeight', 'bold');
set([hXLabel, hYLabel], 'FontName', 'Times', 'FontSize', 20, ...
    'FontWeight', 'bold');
set(gca, ...
        'Box'         , 'on'     , ...
        'TickDir'     , 'Out'      , ...
        'TickLength'  , [.02 .02] , ...
        'XMinorTick'  , 'on'      , ...
        'YMinorTick'  , 'on'      , ...
        'XGrid'       , 'on'      , ...
        'YGrid'       , 'on'      , ...
        'XMinorGrid'  , 'on'      , ...
        'YMinorGrid'  , 'on'      , ...
        'GridAlpha'   , 0.75      , ...
        'Color'       , [1 1 1], ...
        'GridColor'   , [1 0 1], ...
        'XColor'      , [1 0 1], ...
        'YColor'      , [1 0 1], ...
        'xLim'        , [35 85]    , ...
        'LineWidth'   , 1         );
%export to PNG
set(gcf, 'PaperPositionMode', 'auto', 'Color', 'white', 'InvertHardCopy','off');
print('-dpng','-r300', [fig_dir '/growthcharts.females_update.png'])
close;

%% Normative charts plot: group-level ALFF
figure('Units', 'pixels', 'Position', [100 100 630 890]); 
ftable = [ana_dir '/data/alff/gamlss.predict.males.csv'];
if exist(ftable,'file')
    charts = readtable(ftable, 'Delimiter', ',');
    age = ccs_core_double4cell(charts.Var2(2:end));
    centile95 = ccs_core_double4cell(charts.Var7(2:end));
    centile75 = ccs_core_double4cell(charts.Var6(2:end));
    centile50 = ccs_core_double4cell(charts.Var5(2:end));
    centile25 = ccs_core_double4cell(charts.Var4(2:end));
    centile5 = ccs_core_double4cell(charts.Var3(2:end));
    %plot cent50 line
    hPlot_cent50 = plot(age, centile50);
    %adjust line properties (Functional)
    set(hPlot_cent50, 'LineWidth', 4, 'Color', 'b');
    hold on
    %plot cent25/75 line
    hPlot_cent25 = plot(age, centile25);
    hPlot_cent75 = plot(age, centile75);
    %adjust line properties (Functional)
    set(hPlot_cent25, 'LineWidth', 2, 'Color', 'b');
    set(hPlot_cent75, 'LineWidth', 2, 'Color', 'b');
    %plot cent5/95 line
    hPlot_cent5 = plot(age, centile5);
    hPlot_cent95 = plot(age, centile95);
    %adjust line properties (Functional)
    set(hPlot_cent5, 'LineWidth', 2, 'Color', 'b');
    set(hPlot_cent95, 'LineWidth', 2, 'Color', 'b');
end
hXLabel = xlabel('Age (years)');
hYLabel = ylabel('ALFF (z-score)');
%adjust font and axes properties
set(gca, 'FontName', 'Times', 'FontSize', 20 , 'FontWeight', 'bold');
set([hXLabel, hYLabel], 'FontName', 'Times', 'FontSize', 20, ...
    'FontWeight', 'bold');
set(gca, ...
        'Box'         , 'on'     , ...
        'TickDir'     , 'Out'      , ...
        'TickLength'  , [.02 .02] , ...
        'XMinorTick'  , 'on'      , ...
        'YMinorTick'  , 'on'      , ...
        'XGrid'       , 'on'      , ...
        'YGrid'       , 'on'      , ...
        'XMinorGrid'  , 'on'      , ...
        'YMinorGrid'  , 'on'      , ...
        'GridAlpha'   , 0.75      , ...
        'Color'       , [1 1 1], ...
        'GridColor'   , [0 0 1], ...
        'XColor'      , [0 0 1], ...
        'YColor'      , [0 0 1], ...
        'xLim'        , [35 85]    , ...
        'LineWidth'   , 1         );
%export to PNG
set(gcf, 'PaperPositionMode', 'auto', 'Color', 'white', 'InvertHardCopy','off');
print('-dpng','-r300', [fig_dir '/growthcharts.males_update.png'])
close;

