close all;

% Analysing the retrieval time. Comparison between young and elderly
youngColor = config.colorPalette.young;
elderColor = config.colorPalette.elderly;
markerSize = config.plotSettings.MarkerSize;
lineWidth = config.plotSettings.LineWidth;
axisLineWidth = config.plotSettings.AxisLineWidth;
fontSize = config.plotSettings.FontSize;
scatterFaceAlpha = config.plotSettings.MarkerScatterFaceAlpha;
scatterEdgeAlpha = config.plotSettings.MarkerScatterEdgeAlpha;

RetrievalTime.Young.Rt = AlloData.MeanRetrievalTime(AlloData.ParticipantGroup == 1 & ~isnan(AlloData.MeanRetrievalTime));
RetrievalTime.Elderly.Rt = AlloData.MeanRetrievalTime(AlloData.ParticipantGroup == 2 & ~isnan(AlloData.MeanRetrievalTime));

N = 1000;
%Bootstrapping
RetrievalTime.Young.Vector = bootstrp(N,@nanmean,RetrievalTime.Young.Rt);
RetrievalTime.Young.Mean = nanmean(RetrievalTime.Young.Vector);
RetrievalTime.Young.Sd = std(RetrievalTime.Young.Vector);
RetrievalTime.Young.CI = bootci(N,@nanmean,RetrievalTime.Young.Rt);
%Bootstrapping
RetrievalTime.Elderly.Vector = bootstrp(N,@nanmean,RetrievalTime.Elderly.Rt);
RetrievalTime.Elderly.Mean = nanmean(RetrievalTime.Elderly.Vector);
RetrievalTime.Elderly.Sd = std(RetrievalTime.Elderly.Vector);
RetrievalTime.Elderly.CI = bootci(N,@nanmean,RetrievalTime.Elderly.Rt);

% Perform two-Rt t-test
[h, p, ci, stats] = ttest2(RetrievalTime.Young.Vector, RetrievalTime.Elderly.Vector);

% Display the t-test result

disp(['Bootstrapped means:']);
disp(['young: ' num2str(RetrievalTime.Young.Mean) ' +- ' num2str(RetrievalTime.Young.Sd)])
disp(['elderly: ' num2str(RetrievalTime.Elderly.Mean) ' +- ' num2str(RetrievalTime.Elderly.Sd)])

disp(['t-test result:']);
disp(['t-statistic = ' num2str(stats.tstat)]);
disp(['p-value = ' num2str(p)]);
disp(['Degrees of freedom = ' num2str(stats.df)]);
disp(['95% Confidence Interval of the difference = [' num2str(ci(1)) ', ' num2str(ci(2)) ']']);

% Desired figure size
plotWidthInches = 3;  % Width in inches
plotHeightInches = 2.5; % Height in inches

dpi = 300;

% Create figure and set the size and background color to white
figure('Units', 'inches', 'Position', [1, 1, plotWidthInches, plotHeightInches], 'Color', 'white');
hold on

% Set paper size for saving in inches
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperPosition', [0, 0, plotWidthInches, plotHeightInches]);
set(gcf, 'PaperSize', [plotWidthInches, plotHeightInches]);
set(gcf, 'PaperPositionMode', 'auto');  % Ensure that the saved figure matches the on-screen size

hY = histogram(RetrievalTime.Young.Vector, 'FaceColor', youngColor, 'EdgeColor', youngColor * 0.8, 'Normalization', 'probability');
hE = histogram(RetrievalTime.Elderly.Vector, 'FaceColor', elderColor, 'EdgeColor', youngColor * 0.8, 'Normalization', 'probability');

% Calculating the kernel density estimate
[f_young, xi_young] = kde(RetrievalTime.Young.Vector, 'Bandwidth', 0.1);
binWidthY = hY.BinWidth;
f_young = f_young * binWidthY;
plot(xi_young, f_young, 'Color',  youngColor*0.6, 'LineWidth', 2);

% Calculating the kernel density estimate
[f_elderly, xi_elderly] = kde(RetrievalTime.Elderly.Vector, 'Bandwidth', 0.1);
binWidthE = hE.BinWidth;
f_elderly = f_elderly * binWidthE;
plot(xi_elderly, f_elderly, 'Color',  elderColor*0.6, 'LineWidth', 2);

% Adding stats line
yMax = max([max(hY.Values), max(hE.Values)]);  % Get the maximum y value from histograms
starY = yMax + 0.02;  % Position for stars
lineY = yMax + 0.01;  % Position for the line

plot([RetrievalTime.Young.Mean, RetrievalTime.Elderly.Mean], [lineY, lineY], 'k-', 'LineWidth', 1.5);
text(mean([RetrievalTime.Young.Mean, RetrievalTime.Elderly.Mean]), starY, '***', 'FontSize', 18, 'HorizontalAlignment', 'center');

ylim([0, starY + 0.05]);  % Adjust y-limits to fit the significance stars
legend('young', 'older', 'Location','best');

ax = gca;
ax.XAxis.LineWidth = axisLineWidth;
ax.YAxis.LineWidth = axisLineWidth;
ax.Title.String = '';
ax.FontName = config.plotSettings.FontName;
ax.FontSize = fontSize;

ax.Box = 'off';  % Remove top and right axes
ax.XColor = 'black'; % Set color for bottom X-axis
ax.YColor = 'black'; % Set color for left Y-axis

% Customize Y axis label
ax.YLabel.Interpreter = 'tex';
ax.YLabel.String = {'probability'};
ax.YLabel.FontSize = config.plotSettings.FontLabelSize;

% Customize X axis label
ax.XLabel.Interpreter = 'tex';
ax.XLabel.String = {'bootstrapped retrieval time (s)'};
ax.XLabel.FontSize = config.plotSettings.FontLabelSize;

% Ensure the Output folder exists
outputFolder = 'Output';
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Define the full paths for saving
pngFile = fullfile(outputFolder, 'retrievaltimeageing.png');
svgFile = fullfile(outputFolder, 'retrievaltimeageing.svg');
pdfFile = fullfile(outputFolder, 'retrievaltimeageing.pdf');


% Save the figure as PNG with the specified DPI
print(pngFile, '-dpng',  ['-r' num2str(dpi)]); % Save as PNG with specified resolution
% Save the figure as SVG with a tight layout
print(svgFile, '-dsvg'); % Save as SVG

print(pdfFile, '-dpdf',  ['-r' num2str(dpi)]); 


disp(['Figure saved as ' pngFile ' and ' svgFile]);

% Finalize and clear
hold off;

clearvars -except AlloData AlloData_Elderly_4MT HCData YCData AlloData_SPSS_Cond_Conf AlloData_SPSS_Cond_Conf_Block AlloData_SPSS_Cond_Conf_VirtualBlock config RetrievalTime

%% Analysis of ade vs retrieval time

youngColor = config.colorPalette.young;
elderColor = config.colorPalette.elderly;
markerSize = config.plotSettings.MarkerSize;
lineWidth = config.plotSettings.LineWidth;
axisLineWidth = config.plotSettings.AxisLineWidth;
fontSize = config.plotSettings.FontSize;
scatterFaceAlpha = config.plotSettings.MarkerScatterFaceAlpha;
scatterEdgeAlpha = config.plotSettings.MarkerScatterEdgeAlpha;
markerScatterSize = config.plotSettings.MarkerScatterSize;

youngData = AlloData_SPSS_Cond_Conf(AlloData_SPSS_Cond_Conf.ParticipantGroup == 1, :);
elderlyData = AlloData_SPSS_Cond_Conf(AlloData_SPSS_Cond_Conf.ParticipantGroup == 2, :);

youngMeans = varfun(@mean, youngData, 'InputVariables', {'MeanADE', 'MeanRT'}, 'GroupingVariables', 'ParticipantID');
elderlyMeans = varfun(@mean, elderlyData, 'InputVariables', {'MeanADE', 'MeanRT'}, 'GroupingVariables', 'ParticipantID');

youngModel = fitlm(youngMeans.mean_MeanRT, youngMeans.mean_MeanADE) 
elderlyModel = fitlm(elderlyMeans.mean_MeanRT, elderlyMeans.mean_MeanADE)

xRange = linspace(0, max([youngMeans.mean_MeanRT; elderlyMeans.mean_MeanRT]), 100)';
[youngFit, youngCI] = predict(youngModel, xRange);
[elderlyFit, elderlyCI] = predict(elderlyModel, xRange);

% Desired figure size
plotWidthInches = 3;  % Width in inches
plotHeightInches = 2.5; % Height in inches

dpi = 300;

% Create figure and set the size and background color to white
figure('Units', 'inches', 'Position', [1, 1, plotWidthInches, plotHeightInches], 'Color', 'white');
hold on

% Set paper size for saving in inches
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperPosition', [0, 0, plotWidthInches, plotHeightInches]);
set(gcf, 'PaperSize', [plotWidthInches, plotHeightInches]);
set(gcf, 'PaperPositionMode', 'auto');  % Ensure that the saved figure matches the on-screen size

scatter(youngMeans.mean_MeanRT, youngMeans.mean_MeanADE, markerScatterSize, 'o', ...
    'MarkerEdgeColor', youngColor, 'MarkerFaceColor', youngColor, ...
    'MarkerFaceAlpha', scatterFaceAlpha, 'MarkerEdgeAlpha', scatterEdgeAlpha);

scatter(elderlyMeans.mean_MeanRT, elderlyMeans.mean_MeanADE, markerScatterSize, 'o', ...
    'MarkerEdgeColor', elderColor, 'MarkerFaceColor', elderColor, ...
    'MarkerFaceAlpha', scatterFaceAlpha, 'MarkerEdgeAlpha', scatterEdgeAlpha);

plot(xRange, youngFit, 'Color', [youngColor * 0.6, 0.7], 'LineWidth', lineWidth);
plot(xRange, youngCI(:,1), '--', 'Color', [youngColor * 0.8, 0.5], 'LineWidth', lineWidth);
plot(xRange, youngCI(:,2), '--', 'Color', [youngColor * 0.8, 0.5], 'LineWidth', lineWidth);

plot(xRange, elderlyFit, 'Color', [elderColor * 0.6, 0.7], 'LineWidth', lineWidth);
plot(xRange, elderlyCI(:,1), '--', 'Color', [elderColor * 0.8, 0.5], 'LineWidth', lineWidth);
plot(xRange, elderlyCI(:,2), '--', 'Color', [elderColor * 0.8 0.5], 'LineWidth', lineWidth);

ax = gca;
ax.XAxis.LineWidth = axisLineWidth;
ax.YAxis.LineWidth = axisLineWidth;
ax.Title.String = '';
ax.FontName = config.plotSettings.FontName;
ax.FontSize = fontSize;

ax.Box = 'off';  % Remove top and right axes
ax.XColor = 'black'; % Set color for bottom X-axis
ax.YColor = 'black'; % Set color for left Y-axis

xlabel('retrieval time (s)');
ax.YLabel.FontSize = config.plotSettings.FontLabelSize;
ylabel('absolute distance error (m)');
ax.YLabel.FontSize = config.plotSettings.FontLabelSize;
legend({'young', 'older'}, 'Location', 'best');

% Ensure the Output folder exists
outputFolder = 'Output';
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Define the full paths for saving
pngFile = fullfile(outputFolder, 'retrievaltimevsade.png');
svgFile = fullfile(outputFolder, 'retrievaltimevsade.svg');
pdffile = fullfile(outputFolder, 'retrievaltimevsade.pdf');

% Save the figure as PNG with the specified DPI
print(pngFile, '-dpng',  ['-r' num2str(dpi)]); % Save as PNG with specified resolution

% Save the figure as SVG with a tight layout
print(svgFile, '-dsvg'); % Save as SVG

print(pdffile, '-dpdf',  ['-r' num2str(dpi)]);

disp(['Figure saved as ' pngFile ' and ' svgFile]);

%%
clearvars -except AlloData AlloData_Elderly_4MT HCData YCData AlloData_SPSS_Cond_Conf AlloData_SPSS_Cond_Conf_Block AlloData_SPSS_Cond_Conf_VirtualBlock config RetrievalTime