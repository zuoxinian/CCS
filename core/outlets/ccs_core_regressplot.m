function [hregress] = ccs_core_regressplot(x, y, x_predict, y_fit, yfitupCI, yfitbtmCI, ...
    fig_title, x_label, y_label, colorset, fig_prefix, plotCI, ...
    pvalue, p05_corrected, plotP)
%CCS_REGRESSPLOT Summary of this function goes here
%
%
%
%Programmer: Xi-Nian Zuo

%Start of codes.
    %setup figure window
    figure('Units', 'pixels', 'Position', [100 100 1000 1000]); hold on;
    %plot
    hPlot_raw = plot(x, y, 'o');
    if pvalue <= p05_corrected
        hPlot_fit = plot(x_predict, y_fit,'-');
    else
        hPlot_fit = plot(x_predict, y_fit,'--');
    end
    if strcmp(plotCI, 'true')
        hPlot_upCI = plot(x_predict, yfitupCI,'--');
        hPlot_btmCI = plot(x_predict, yfitbtmCI,'--');
        hregress.upCI = hPlot_upCI;
        hregress.btmCI = hPlot_btmCI;
    end
    hregress.raw = hPlot_raw;
    hregress.fit = hPlot_fit;
    %adjust line properties (Functional)
    set(hPlot_raw, 'LineWidth', 2, 'MarkerEdgeColor', colorset(1,:), ...
        'MarkerFaceColor', colorset(2,:), 'MarkerSize', 8);
    set(hPlot_fit, 'LineWidth', 8, 'Color', colorset(3,:));
    if strcmp(plotCI, 'true')
        set(hPlot_upCI, 'LineWidth', 4, 'Color', colorset(4,:));
        set(hPlot_btmCI, 'LineWidth', 4, 'Color', colorset(4,:));
    end
    %add legends and labels
    hXLabel = xlabel(x_label);
    hYLabel = ylabel(y_label);
    hTitle = title(fig_title);
    %hLegend = legend( ...
    %    [hPlot_raw, hPlot_fit, hPlot_upCI, hPlot_btmCI], ...
    %    'Raw Data' , ...
    %    'Fitted Model' , ...
    %    'Confidence Interval (Up)' , ...
    %    'Confidence Interval (Bottom)');
    hregress.xlabel = hXLabel;
    hregress.ylabel = hYLabel;
    hregress.title = hTitle;
    if strcmp(plotP, 'true')
        strsig = ['P < ' num2str(ceil(pvalue*1e10)/1e10)];
        hPText = text(0.75*max(x_predict),0.95*max(y), strsig);
        set(hPText, 'FontName', 'Times', 'FontSize', 40, 'FontWeight', 'bold');
        hregress.text = hPText;
    end
    %hregress.legend = hLegend;
    %adjust font and axes properties
    set( gca, 'FontName', 'Times', 'FontSize', 40 , 'FontWeight', 'bold');
    set([hXLabel, hYLabel, hTitle], 'FontName', 'Times');
    set([hXLabel, hYLabel, hTitle], 'FontSize', 40);
    set([hXLabel, hYLabel, hTitle], 'FontWeight', 'bold');
    %set(hLegend, 'FontName', 'Times', 'FontSize', 40, 'Location','NorthEast'); 
    set(gca, ...
        'Box'         , 'on'     , ...
        'TickDir'     , 'Out'      , ...
        'TickLength'  , [.01 .01] , ...
        'XMinorTick'  , 'on'      , ...
        'YMinorTick'  , 'on'      , ...
        'YGrid'       , 'off'      , ...
        'XColor'      , [0 0 0], ...
        'YColor'      , [0 0 0], ...
        'xLim'        , [0.99*min(x_predict) 1.01*max(x_predict)], ...
        'LineWidth'   , 2         );
    %export to EPS
    if nargin > 10
        set(gcf, 'PaperPositionMode', 'auto');
        print('-depsc2', [fig_prefix '.eps'])
        print('-dpng', [fig_prefix '.png'])
        close
    end
end


