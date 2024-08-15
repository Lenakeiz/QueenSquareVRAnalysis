% Analysing the retrieval time. Comparison between young and elderly
youngcolor = config.colorPalette.young;
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

hY = histogram(RetrievalTime.Young.Vector, 'FaceColor', youngcolor, 'EdgeColor', youngcolor * 0.8, 'Normalization', 'probability');
hE = histogram(RetrievalTime.Elderly.Vector, 'FaceColor', elderColor, 'EdgeColor', youngcolor * 0.8, 'Normalization', 'probability');

% Calculating the kernel density estimate
[f_young, xi_young] = kde(RetrievalTime.Young.Vector, 'Bandwidth', 0.1);
binWidthY = hY.BinWidth;
f_young = f_young * binWidthY;
plot(xi_young, f_young, 'Color',  youngcolor*0.6, 'LineWidth', 2);

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
legend('Young', 'Elderly', 'Location','best');

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
ax.YLabel.FontSize = fontSize + 2;

% Customize X axis label
ax.XLabel.Interpreter = 'tex';
ax.XLabel.String = {'bootstrapped mean retrieval time (s)'};
ax.XLabel.FontSize = fontSize + 2;

% Ensure the Output folder exists
outputFolder = 'Output';
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Define the full paths for saving
pngFile = fullfile(outputFolder, 'retrievaltimeageing.png');
svgFile = fullfile(outputFolder, 'retrievaltimeageing.svg');

% Save the figure as PNG with the specified DPI
print(pngFile, '-dpng',  ['-r' num2str(dpi)]); % Save as PNG with specified resolution

% Save the figure as SVG with a tight layout
print(svgFile, '-dsvg'); % Save as SVG

disp(['Figure saved as ' pngFile ' and ' svgFile]);

% Finalize and clear
hold off;

clearvars -except AlloData AlloData_Elderly_4MT HCData YCData AlloData_SPSS_Cond_Conf AlloData_SPSS_Cond_Conf_Block AlloData_SPSS_Cond_Conf_VirtualBlock config RetrievalTime

%% Plotting mean ade vs mean retrieval time
conftype = 4;
trialtype = 3;

RetrievalTime.Young.Mean_ade = AlloData_SPSS_Cond_Conf.MeanADE(AlloData_SPSS_Cond_Conf.ParticipantGroup == 1 & AlloData_SPSS_Cond_Conf.ConfigurationType == conftype & AlloData_SPSS_Cond_Conf.TrialType == trialtype );
Older.ADE.Sample = AlloData_SPSS_Cond_Conf.MeanADE(AlloData_SPSS_Cond_Conf.ParticipantGroup == 2 & AlloData_SPSS_Cond_Conf.ConfigurationType == conftype & AlloData_SPSS_Cond_Conf.TrialType == trialtype );
RetrievalTime.Young.Sample  = AlloData_SPSS_Cond_Conf.MeanRT(AlloData_SPSS_Cond_Conf.ParticipantGroup == 1 & AlloData_SPSS_Cond_Conf.ConfigurationType == conftype & AlloData_SPSS_Cond_Conf.TrialType == trialtype );
Elderly_RT.Sample  = AlloData_SPSS_Cond_Conf.MeanRT(AlloData_SPSS_Cond_Conf.ParticipantGroup == 2 & AlloData_SPSS_Cond_Conf.ConfigurationType == conftype & AlloData_SPSS_Cond_Conf.TrialType == trialtype );

CreateCustomFigure;
subplot(2,1,1)
%scatter(RetrievalTime.Young.Sample,Young.ADE.Sample);
hold on
tbl = table(RetrievalTime.Young.Sample, Young.ADE.Sample);
tbl.Properties.VariableNames = {'RT' 'ADE'};
mdl = fitlm(tbl,'linear')
plot(mdl);
hold off

subplot(2,1,2)
%scatter(Elderly_RT.Sample,Older.ADE.Sample);
hold on
tbl = table(Elderly_RT.Sample,Older.ADE.Sample);
tbl.Properties.VariableNames = {'RT' 'ADE'};
mdl = fitlm(tbl,'linear')
plot(mdl);
axis equal
hold off

clearvars -except AlloData AlloData_SPSS_Cond_Conf HCData YCData AlloData_SPSS_Cond_Conf AlloData_SPSS_Cond_Conf_Block AlloData_SPSS_Cond_Conf_VirtualBlock config

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
ax.FontName = config.plotSettings.FontName;
ax.FontSize = fontSize;
ax.Box = 'off';  % Remove top and right axes

xlabel('mean retrieval time (s)');
ylabel('mean absolute distance error (m)');
legend({'Young', 'Elderly'}, 'Location', 'best');

% Ensure the Output folder exists
outputFolder = 'Output';
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Define the full paths for saving
pngFile = fullfile(outputFolder, 'retrievaltimevsade.png');
svgFile = fullfile(outputFolder, 'retrievaltimevsade.svg');

% Save the figure as PNG with the specified DPI
print(pngFile, '-dpng',  ['-r' num2str(dpi)]); % Save as PNG with specified resolution

% Save the figure as SVG with a tight layout
print(svgFile, '-dsvg'); % Save as SVG

disp(['Figure saved as ' pngFile ' and ' svgFile]);


%
clearvars -except AlloData AlloData_Elderly_4MT HCData YCData AlloData_SPSS_Cond_Conf AlloData_SPSS_Cond_Conf_Block AlloData_SPSS_Cond_Conf_VirtualBlock config RetrievalTime
%%

Young.ADE.Sample = AlloData_SPSS_Cond_Conf.MeanADE(AlloData_SPSS_Cond_Conf.ParticipantGroup == 1 & AlloData_SPSS_Cond_Conf.ConfigurationType == young_conftype & AlloData_SPSS_Cond_Conf.TrialType == young_trialtype );
Older.ADE.Sample = AlloData_SPSS_Cond_Conf.MeanADE(AlloData_SPSS_Cond_Conf.ParticipantGroup == 2 & AlloData_SPSS_Cond_Conf.ConfigurationType == elder_conftype & AlloData_SPSS_Cond_Conf.TrialType == elder_trialtype );
Young_RT.Sample  = AlloData_SPSS_Cond_Conf.MeanRT(AlloData_SPSS_Cond_Conf.ParticipantGroup == 1 & AlloData_SPSS_Cond_Conf.ConfigurationType == young_conftype & AlloData_SPSS_Cond_Conf.TrialType == young_trialtype );
Elderly_RT.Sample  = AlloData_SPSS_Cond_Conf.MeanRT(AlloData_SPSS_Cond_Conf.ParticipantGroup == 2 & AlloData_SPSS_Cond_Conf.ConfigurationType == elder_conftype & AlloData_SPSS_Cond_Conf.TrialType == elder_trialtype );

Young.ADE.Sample(isoutlier(Young.ADE.Sample,'grubbs')) = nan;
Older.ADE.Sample(isoutlier(Older.ADE.Sample,'grubbs')) = nan;
Young_RT.Sample(isoutlier(Young_RT.Sample,'grubbs')) = nan;
Elderly_RT.Sample(isoutlier(Elderly_RT.Sample,'grubbs')) = nan;

groupColors = [config.colorPalette.elderly; config.colorPalette.young];

CreateCustomFigure;
subplot(1,2,1)
%scatter(Young_RT.Sample,Young.ADE.Sample);
hold on
tbl = table(Young_RT.Sample, Young.ADE.Sample);
tbl.Properties.VariableNames = {'RT' 'ADE'};
mdl = fitlm(tbl,'linear','RobustOpts','on')
p = plot(mdl);
data = p(1,1);
data.MarkerEdgeColor = 'none';
data.MarkerFaceColor = [groupColors(2,:)];
data.Marker = 'o';
data.MarkerSize = 10;
data.Color = [groupColors(2,:) 0.2];
fit = p(2,1);
fit.Color = [groupColors(2,:)*0.2 0.7];
fit.LineWidth = 2;
cb = p(3,1);
cb.Color = [groupColors(2,:) 0.6];
cb.LineWidth = 2;
%cb = p(4,1);
%cb.Color = [groupColors(2,:) 0.6];
%cb.LineWidth = 2;
legend('off');
l = legend([data], {'Young'});
hold off

ax = gca;
ax.Title.String = '';
ax.FontName = 'Times New Roman';
ax.FontSize = 20;
ax.YLabel.Interpreter = 'tex';
ax.YLabel.String = {'ADE({\mu})'};
ylim([0 5]);
ax.XLabel.Interpreter = 'tex';
ax.XLabel.String = {'RT({\mu})'};
xlim([0 12]);

subplot(1,2,2)
%scatter(Elderly_RT.Sample,Older.ADE.Sample);
hold on
tbl = table(Elderly_RT.Sample,Older.ADE.Sample + 1.4);
tbl.Properties.VariableNames = {'RT' 'ADE'};
mdl = fitlm(tbl,'linear','RobustOpts','on')

p = plot(mdl);
data = p(1,1);
data.MarkerEdgeColor = 'none';
data.MarkerFaceColor = [groupColors(1,:)];
data.Marker = 'o';
data.MarkerSize = 10;
data.Color = [groupColors(1,:) 0.2];
fit = p(2,1);
fit.Color = [groupColors(1,:)*0.5 0.7];
fit.LineWidth = 2;
cb = p(3,1);
cb.Color = [groupColors(1,:) 0.6];
cb.LineWidth = 2;
%cb = p(4,1);
%cb.Color = [groupColors(1,:) 0.6];
%cb.LineWidth = 2;
legend('off');
l = legend([data], {'Elderly'});
hold off
ax = gca;

ax.Title.String = '';
ax.FontName = 'Times New Roman';
ax.FontSize = 20;
ax.YLabel.Interpreter = 'tex';
ax.YLabel.String = {'ADE({\mu})'};
ylim([0 5]);
ax.XLabel.Interpreter = 'tex';
ax.XLabel.String = {'RT({\mu})'};
xlim([0 12]);

%%
clearvars -except AlloData AlloData_Elderly_4MT HCData YCData AlloData_SPSS_Cond_Conf AlloData_SPSS_Cond_Conf_Block AlloData_SPSS_Cond_Conf_VirtualBlock config RetrievalTime


