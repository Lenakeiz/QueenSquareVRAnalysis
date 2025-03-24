%% Viewpoint Shift Direction Analysis
% This script analyzes the effect of viewpoint shift direction (left vs. right)
% on spatial memory performance, as identified by the SwitchSide variable.
%
% Responds to reviewer comment about whether shift direction affects error patterns
% and if participants make errors aligned with the perspective shift.

close all;

%% ------ Load data ------
% Extract relevant columns from AlloData
AlloDataAnalysis = AlloData(:, {'ParticipantID', 'ParticipantGroup', 'TrialType', 'TrialNumber', 'ConfigurationType', 'X', 'Z', 'RegX', 'RegZ', 'SwitchSide'});

% Focus only on viewpoint shift conditions (TrialType 2 and 3)
% TrialType 2 = Shifted-viewpoint (walking)
% TrialType 3 = Shifted-viewpoint (teleport)
ShiftData = AlloDataAnalysis(AlloDataAnalysis.TrialType == 2 | AlloDataAnalysis.TrialType == 3, :);

% Create directional error measures that align with the shift direction
% For X errors:
% - For left shifts (SwitchSide = true), positive X errors align with shift direction
% - For right shifts (SwitchSide = false), negative X errors align with shift direction
ShiftData.DirectionalErrorX = ShiftData.RegX - ShiftData.X;
ShiftData.DirectionalErrorX(ShiftData.SwitchSide == 0) = -ShiftData.DirectionalErrorX(ShiftData.SwitchSide == 0);

% For Z errors:
% - For left shifts (SwitchSide = true), positive Z errors align with shift direction
% - For right shifts (SwitchSide = false), negative Z errors align with shift direction
ShiftData.DirectionalErrorZ = ShiftData.RegZ - ShiftData.Z;
ShiftData.DirectionalErrorZ(ShiftData.SwitchSide == 0) = -ShiftData.DirectionalErrorZ(ShiftData.SwitchSide == 0);

% Create labels for shift direction
ShiftData.ShiftDirection = categorical(ShiftData.SwitchSide, [0 1], {'Right', 'Left'});

%% ------ First, average errors within each trial ------
% This is especially important for configuration type 4 (four objects)

% Create a table to store trial-level summary data
trialSummary = table();
row = 1;

% Get unique participants
participants = unique(ShiftData.ParticipantID);

% For each participant
for p = 1:length(participants)
    pid = participants(p);
    
    % Get all data for this participant
    participantData = ShiftData(ShiftData.ParticipantID == pid, :);
    
    % Get unique trial numbers for this participant
    trialNumbers = unique(participantData.TrialNumber);
    
    % For each trial
    for t = 1:length(trialNumbers)
        trialNum = trialNumbers(t);
        
        % Get all data for this trial
        trialData = participantData(participantData.TrialNumber == trialNum, :);
        
        % Get trial metadata (should be the same for all rows with this trial number)
        pGroup = unique(trialData.ParticipantGroup);
        trialType = unique(trialData.TrialType);
        confType = unique(trialData.ConfigurationType);
        switchSide = unique(trialData.SwitchSide);
        
        % Sanity check - these should all be single values
        if length(pGroup) ~= 1 || length(trialType) ~= 1 || length(confType) ~= 1 || length(switchSide) ~= 1
            warning('Inconsistent metadata for Participant %d, Trial %d', pid, trialNum);
            continue;
        end
        
        % Calculate mean directional errors for this trial
        meanDirErrorX = mean(trialData.DirectionalErrorX, 'omitnan');
        meanDirErrorZ = mean(trialData.DirectionalErrorZ, 'omitnan');
        
        % Add to summary table
        trialSummary.ParticipantID(row) = pid;
        trialSummary.ParticipantGroup(row) = pGroup;
        trialSummary.TrialNumber(row) = trialNum;
        trialSummary.ConfigurationType(row) = confType;
        trialSummary.TrialType(row) = trialType;
        trialSummary.SwitchSide(row) = switchSide;
        trialSummary.MeanDirectionalErrorX(row) = meanDirErrorX;
        trialSummary.MeanDirectionalErrorZ(row) = meanDirErrorZ;
        
        row = row + 1;
    end
end

% Verify the trial summary has the expected number of trials
fprintf('Created trial summary with %d trials\n', height(trialSummary));

%% ------ Create participant-level summary ------
% For each participant, calculate mean errors by shift direction and trial type
participantSummary = table();

row = 1;
for p = 1:length(participants)
    pid = participants(p);
    pGroup = unique(trialSummary.ParticipantGroup(trialSummary.ParticipantID == pid));
    
    % For each shift direction
    for sd = [0, 1] % 0 = Right, 1 = Left
        % For each trial type (walking shift vs teleport shift)
        for tt = [2, 3]
            % Get this participant's data for this combination
            pData = trialSummary(trialSummary.ParticipantID == pid & ...
                              trialSummary.SwitchSide == sd & ...
                              trialSummary.TrialType == tt, :);
            
            if ~isempty(pData)
                % Calculate mean values across trials
                meanDirErrorX = mean(pData.MeanDirectionalErrorX, 'omitnan');
                meanDirErrorZ = mean(pData.MeanDirectionalErrorZ, 'omitnan');
                
                % Add to summary table
                participantSummary.ParticipantID(row) = pid;
                participantSummary.ParticipantGroup(row) = pGroup;
                participantSummary.SwitchSide(row) = sd;
                participantSummary.TrialType(row) = tt;
                participantSummary.MeanDirectionalErrorX(row) = meanDirErrorX;
                participantSummary.MeanDirectionalErrorZ(row) = meanDirErrorZ;
                
                row = row + 1;
            end
        end
    end
end

% Add categorical variables for easier analysis
participantSummary.AgeGroup = categorical(participantSummary.ParticipantGroup, [1 2], {'Young', 'Elderly'});
participantSummary.ShiftDirection = categorical(participantSummary.SwitchSide, [0 1], {'Right', 'Left'});
participantSummary.MovementType = categorical(participantSummary.TrialType, [2 3], {'Walking', 'Teleport'});

%% ------ Analysis 1: X-Axis Directional Error Alignment with Shift Direction ------
fprintf('\n1. X-Axis Directional Error Alignment with Shift Direction\n');
fprintf('------------------------------------------------------\n');

% Test if X directional errors are significantly different from zero
[h, p, ci, stats] = ttest(participantSummary.MeanDirectionalErrorX);
fprintf('One-sample t-test (H0: mean X directional error = 0):\n');
fprintf('t(%d) = %.2f, p = %.4f\n', stats.df, stats.tstat, p);
fprintf('Mean X directional error: %.4f, 95%% CI [%.4f, %.4f]\n', ...
    mean(participantSummary.MeanDirectionalErrorX, 'omitnan'), ci(1), ci(2));

if p < 0.05
    fprintf('Significant tendency of shifted error along the X shifted direction.\n');
else
    fprintf('Non significant tendency of shifted error along the X shifted direction.\n');
end

% Test if the effect differs by age group
young_dir_error_x = participantSummary.MeanDirectionalErrorX(participantSummary.AgeGroup == 'Young');
elderly_dir_error_x = participantSummary.MeanDirectionalErrorX(participantSummary.AgeGroup == 'Elderly');

fprintf('\nX Directional Error by Age Group:\n');
[h_young, p_young, ci_young, stats_young] = ttest(young_dir_error_x);
fprintf('Young: Mean = %.4f, t(%d) = %.2f, p = %.4f\n', ...
    mean(young_dir_error_x, 'omitnan'), stats_young.df, stats_young.tstat, p_young);

[h_elderly, p_elderly, ci_elderly, stats_elderly] = ttest(elderly_dir_error_x);
fprintf('Elderly: Mean = %.4f, t(%d) = %.2f, p = %.4f\n', ...
    mean(elderly_dir_error_x, 'omitnan'), stats_elderly.df, stats_elderly.tstat, p_elderly);

% Compare age groups directly
[h_age, p_age, ci_age, stats_age] = ttest2(young_dir_error_x, elderly_dir_error_x);
fprintf('\nComparison between age groups for X directional error:\n');
fprintf('t(%d) = %.2f, p = %.4f\n', stats_age.df, stats_age.tstat, p_age);

%% ------ Analysis 2: Z-Axis Directional Error Alignment with Shift Direction ------
fprintf('\n2. Z-Axis Directional Error Alignment with Shift Direction\n');
fprintf('------------------------------------------------------\n');

% Test if Z directional errors are significantly different from zero
[h, p, ci, stats] = ttest(participantSummary.MeanDirectionalErrorZ);
fprintf('One-sample t-test (H0: mean Z directional error = 0):\n');
fprintf('t(%d) = %.2f, p = %.4f\n', stats.df, stats.tstat, p);
fprintf('Mean Z directional error: %.4f, 95%% CI [%.4f, %.4f]\n', ...
    mean(participantSummary.MeanDirectionalErrorZ, 'omitnan'), ci(1), ci(2));

if p < 0.05
    fprintf('Significant tendency of shifted error along the Z shifted direction.\n');
else
    fprintf('No Significant tendency of shifted error along the Z shifted direction.\n');
end

% Test if the effect differs by age group
young_dir_error_z = participantSummary.MeanDirectionalErrorZ(participantSummary.AgeGroup == 'Young');
elderly_dir_error_z = participantSummary.MeanDirectionalErrorZ(participantSummary.AgeGroup == 'Elderly');

fprintf('\nZ Directional Error by Age Group:\n');
[h_young, p_young, ci_young, stats_young] = ttest(young_dir_error_z);
fprintf('Young: Mean = %.4f, t(%d) = %.2f, p = %.4f\n', ...
    mean(young_dir_error_z, 'omitnan'), stats_young.df, stats_young.tstat, p_young);

[h_elderly, p_elderly, ci_elderly, stats_elderly] = ttest(elderly_dir_error_z);
fprintf('Elderly: Mean = %.4f, t(%d) = %.2f, p = %.4f\n', ...
    mean(elderly_dir_error_z, 'omitnan'), stats_elderly.df, stats_elderly.tstat, p_elderly);

% Compare age groups directly
[h_age, p_age, ci_age, stats_age] = ttest2(young_dir_error_z, elderly_dir_error_z);
fprintf('\nComparison between age groups for Z directional error:\n');
fprintf('t(%d) = %.2f, p = %.4f\n', stats_age.df, stats_age.tstat, p_age);

%% ------ Analysis 3: Linear Mixed Effects Models for Directional Errors ------
fprintf('\n3. Linear Mixed Effects Models for Directional Errors\n');
fprintf('----------------------------------------------------\n');

% Create a long-format table for analysis that includes both X and Z errors
lmeData = participantSummary(:, {'ParticipantID', 'AgeGroup', 'ShiftDirection', 'MovementType', 'MeanDirectionalErrorX', 'MeanDirectionalErrorZ'});

% 3A: Linear Mixed Effects Model for X-Axis Directional Errors
fprintf('\n3A. LME Model for X-Axis Directional Errors\n');
fprintf('------------------------------------------\n');

% Define the model formula with all main effects and interactions
% Include participant ID as a random effect
xFormula = 'MeanDirectionalErrorX ~ AgeGroup*ShiftDirection*MovementType + (1|ParticipantID)';

% Fit the model
xModel = fitlme(lmeData, xFormula);

% Display model summary
disp(xModel);

% Display ANOVA results for fixed effects
xAnova = anova(xModel);
disp('ANOVA for X-Axis Directional Error:');
disp(xAnova);

% Calculate and display means for significant effects
% Let's look at the main effect of age group
xAgeGroupMeans = grpstats(lmeData, 'AgeGroup', {'mean', 'sem'}, 'DataVars', 'MeanDirectionalErrorX');
fprintf('\nX-Axis Directional Error by Age Group:\n');
fprintf('Young: %.4f (SEM: %.4f)\n', ...
    xAgeGroupMeans.mean_MeanDirectionalErrorX(1), ...
    xAgeGroupMeans.sem_MeanDirectionalErrorX(1));
fprintf('Elderly: %.4f (SEM: %.4f)\n', ...
    xAgeGroupMeans.mean_MeanDirectionalErrorX(2), ...
    xAgeGroupMeans.sem_MeanDirectionalErrorX(2));

% Movement type means
xMovementMeans = grpstats(lmeData, 'MovementType', {'mean', 'sem'}, 'DataVars', 'MeanDirectionalErrorX');
fprintf('\nX-Axis Directional Error by Movement Type:\n');
fprintf('Walking: %.4f (SEM: %.4f)\n', ...
    xMovementMeans.mean_MeanDirectionalErrorX(1), ...
    xMovementMeans.sem_MeanDirectionalErrorX(1));
fprintf('Teleport: %.4f (SEM: %.4f)\n', ...
    xMovementMeans.mean_MeanDirectionalErrorX(2), ...
    xMovementMeans.sem_MeanDirectionalErrorX(2));

% Shift direction means
xShiftMeans = grpstats(lmeData, 'ShiftDirection', {'mean', 'sem'}, 'DataVars', 'MeanDirectionalErrorX');
fprintf('\nX-Axis Directional Error by Shift Direction:\n');
fprintf('Right: %.4f (SEM: %.4f)\n', ...
    xShiftMeans.mean_MeanDirectionalErrorX(1), ...
    xShiftMeans.sem_MeanDirectionalErrorX(1));
fprintf('Left: %.4f (SEM: %.4f)\n', ...
    xShiftMeans.mean_MeanDirectionalErrorX(2), ...
    xShiftMeans.sem_MeanDirectionalErrorX(2));

% 3B: Linear Mixed Effects Model for Z-Axis Directional Errors
fprintf('\n3B. LME Model for Z-Axis Directional Errors\n');
fprintf('------------------------------------------\n');

% Define the model formula for Z errors
zFormula = 'MeanDirectionalErrorZ ~ AgeGroup*ShiftDirection*MovementType + (1|ParticipantID)';

% Fit the model
zModel = fitlme(lmeData, zFormula);

% Display model summary
disp(zModel);

% Display ANOVA results for fixed effects
zAnova = anova(zModel);
disp('ANOVA for Z-Axis Directional Error:');
disp(zAnova);

% Calculate and display means for significant effects
zAgeGroupMeans = grpstats(lmeData, 'AgeGroup', {'mean', 'sem'}, 'DataVars', 'MeanDirectionalErrorZ');
fprintf('\nZ-Axis Directional Error by Age Group:\n');
fprintf('Young: %.4f (SEM: %.4f)\n', ...
    zAgeGroupMeans.mean_MeanDirectionalErrorZ(1), ...
    zAgeGroupMeans.sem_MeanDirectionalErrorZ(1));
fprintf('Elderly: %.4f (SEM: %.4f)\n', ...
    zAgeGroupMeans.mean_MeanDirectionalErrorZ(2), ...
    zAgeGroupMeans.sem_MeanDirectionalErrorZ(2));

% Movement type means
zMovementMeans = grpstats(lmeData, 'MovementType', {'mean', 'sem'}, 'DataVars', 'MeanDirectionalErrorZ');
fprintf('\nZ-Axis Directional Error by Movement Type:\n');
fprintf('Walking: %.4f (SEM: %.4f)\n', ...
    zMovementMeans.mean_MeanDirectionalErrorZ(1), ...
    zMovementMeans.sem_MeanDirectionalErrorZ(1));
fprintf('Teleport: %.4f (SEM: %.4f)\n', ...
    zMovementMeans.mean_MeanDirectionalErrorZ(2), ...
    zMovementMeans.sem_MeanDirectionalErrorZ(2));

% Shift direction means
zShiftMeans = grpstats(lmeData, 'ShiftDirection', {'mean', 'sem'}, 'DataVars', 'MeanDirectionalErrorZ');
fprintf('\nZ-Axis Directional Error by Shift Direction:\n');
fprintf('Right: %.4f (SEM: %.4f)\n', ...
    zShiftMeans.mean_MeanDirectionalErrorZ(1), ...
    zShiftMeans.sem_MeanDirectionalErrorZ(1));
fprintf('Left: %.4f (SEM: %.4f)\n', ...
    zShiftMeans.mean_MeanDirectionalErrorZ(2), ...
    zShiftMeans.sem_MeanDirectionalErrorZ(2));

% If there are any significant interactions, display those as well
zAgeMovementMeans = grpstats(lmeData, {'AgeGroup', 'MovementType'}, {'mean', 'sem'}, 'DataVars', 'MeanDirectionalErrorZ');
fprintf('\nZ-Axis Directional Error by Age Group and Movement Type:\n');
for i = 1:height(zAgeMovementMeans)
    fprintf('%s, %s: %.4f (SEM: %.4f)\n', ...
        char(zAgeMovementMeans.AgeGroup(i)), ...
        char(zAgeMovementMeans.MovementType(i)), ...
        zAgeMovementMeans.mean_MeanDirectionalErrorZ(i), ...
        zAgeMovementMeans.sem_MeanDirectionalErrorZ(i));
end

% For age group × shift direction interaction
zAgeShiftMeans = grpstats(lmeData, {'AgeGroup', 'ShiftDirection'}, {'mean', 'sem'}, 'DataVars', 'MeanDirectionalErrorZ');
fprintf('\nZ-Axis Directional Error by Age Group and Shift Direction:\n');
for i = 1:height(zAgeShiftMeans)
    fprintf('%s, %s: %.4f (SEM: %.4f)\n', ...
        char(zAgeShiftMeans.AgeGroup(i)), ...
        char(zAgeShiftMeans.ShiftDirection(i)), ...
        zAgeShiftMeans.mean_MeanDirectionalErrorZ(i), ...
        zAgeShiftMeans.sem_MeanDirectionalErrorZ(i));
end

%% ------ Visualizations ------
% Define visualization parameters
vizParams.barAlpha = 0.7;          % Transparency of bars
vizParams.scatterAlpha = 0.1;      % Transparency of scatter points
vizParams.jitterAmount = 0.45;      % Amount of jitter for scatter points
vizParams.scatterSize = config.plotSettings.MarkerScatterSize;        % Size of scatter points
vizParams.ylimRange = [-2, 2];     % Y-axis limits
vizParams.barWidth = config.plotSettings.LineWidth;
vizParams.barPlotwidth = 1.0;

% Desired figure size
plotWidthInches = 4.0;  % Width in inches
plotHeightInches = 3.25; % Height in inches

dpi = 300;

% Create figure and set the size and background color to white
figure('Units', 'inches', 'Position', [1, 1, plotWidthInches, plotHeightInches], 'Color', 'white');

% Set paper size for saving in inches
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperPosition', [0, 0, plotWidthInches, plotHeightInches]);
set(gcf, 'PaperSize', [plotWidthInches, plotHeightInches]);
set(gcf, 'PaperPositionMode', 'auto');  % Ensure that the saved figure matches the on-screen size
hold on;

% Background color
set(gcf, 'Color', 'white');
set(gca, 'Color', 'white');

% Prepare data
ageGroups = {'Young', 'Older'};
xData = zeros(1, 2);
zData = zeros(1, 2);
xSEM = zeros(1, 2);
zSEM = zeros(1, 2);

for a = 1:2
    indices = participantSummary.AgeGroup == ageGroups{a};
    xData(a) = mean(participantSummary.MeanDirectionalErrorX(indices), 'omitnan');
    zData(a) = mean(participantSummary.MeanDirectionalErrorZ(indices), 'omitnan');
    xSEM(a) = std(participantSummary.MeanDirectionalErrorX(indices), 'omitnan') / sqrt(sum(indices));
    zSEM(a) = std(participantSummary.MeanDirectionalErrorZ(indices), 'omitnan') / sqrt(sum(indices));
end

% Create subplot for X errors
subplot(1, 2, 1);
b1 = bar(xData, 'FaceColor', config.colorPalette.GrayScaleThreePoints(1,:), 'FaceAlpha', vizParams.barAlpha, LineWidth=vizParams.barPlotwidth);
hold on;
errorbar(1:2, xData, xSEM, 'k', 'linestyle', 'none', 'linewidth', vizParams.barWidth);

% Add scatter points for X errors
for a = 1:2
    indices = participantSummary.AgeGroup == ageGroups{a};
    individualData = participantSummary.MeanDirectionalErrorX(indices);
    xJitter = (rand(size(individualData)) - 0.5) * vizParams.jitterAmount;
    scatter(a + xJitter, individualData, vizParams.scatterSize, 'k', 'filled', 'MarkerFaceAlpha', vizParams.scatterAlpha);
end

% refline(0, 0);
set(gca, 'XTickLabel', lower(ageGroups));
ylabel('x-axis directional error');
xlabel('age group');
grid on;
ylim(vizParams.ylimRange);
box off;

ax = gca;
ax.XAxis.LineWidth = config.plotSettings.AxisLineWidth;
ax.YAxis.LineWidth = config.plotSettings.AxisLineWidth;
ax.FontName = config.plotSettings.FontName;
ax.FontSize = config.plotSettings.FontSize;

% Create subplot for Z errors
subplot(1, 2, 2);
b2 = bar(zData, 'FaceColor', config.colorPalette.GrayScaleThreePoints(3,:), 'FaceAlpha', vizParams.barAlpha, LineWidth=vizParams.barPlotwidth);
hold on;
errorbar(1:2, zData, zSEM, 'k', 'linestyle', 'none', 'linewidth', vizParams.barWidth);

% Add scatter points for Z errors
for a = 1:2
    indices = participantSummary.AgeGroup == ageGroups{a};
    individualData = participantSummary.MeanDirectionalErrorZ(indices);
    xJitter = (rand(size(individualData)) - 0.5) * vizParams.jitterAmount;
    scatter(a + xJitter, individualData, vizParams.scatterSize, 'k', 'filled', 'MarkerFaceAlpha', vizParams.scatterAlpha);
end

% refline(0, 0);
set(gca, 'XTickLabel', lower(ageGroups));
ylabel('z-axis directional error');
xlabel('age group');
grid on;
ylim(vizParams.ylimRange);
box off;

ax = gca;
ax.XAxis.LineWidth = config.plotSettings.AxisLineWidth;
ax.YAxis.LineWidth = config.plotSettings.AxisLineWidth;
ax.FontName = config.plotSettings.FontName;
ax.FontSize = config.plotSettings.FontSize;

% Ensure the Output folder exists
outputFolder = 'Output';
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Define the full paths for saving
pngFile = fullfile(outputFolder, 'shifdirectionbyagegroups.png');
svgFile = fullfile(outputFolder, 'shifdirectionbyagegroups.svg');
pdfFile = fullfile(outputFolder, 'shifdirectionbyagegroups.pdf');

% Save the figure as PNG with the specified DPI
print(pngFile, '-dpng',  ['-r' num2str(dpi)]); % Save as PNG with specified resolution

% Save the figure as SVG with a tight layout
print(svgFile, '-dsvg'); % Save as SVG

% Save the figure as a PDF with high resolution (300 dpi)
print(pdfFile, '-dpdf', ['-r' num2str(dpi)]);

disp(['Figure saved as ' pngFile ', ' svgFile, ' and ', pdfFile]);

hold off;

% Figure 2: X-Axis and Z-Axis Directional Errors by Shift Direction
dpi = 300;

% Create figure and set the size and background color to white
figure('Units', 'inches', 'Position', [1, 1, plotWidthInches, plotHeightInches], 'Color', 'white');

% Set paper size for saving in inches
set(gcf, 'PaperUnits', 'inches');
set(gcf, 'PaperPosition', [0, 0, plotWidthInches, plotHeightInches]);
set(gcf, 'PaperSize', [plotWidthInches, plotHeightInches]);
set(gcf, 'PaperPositionMode', 'auto');  % Ensure that the saved figure matches the on-screen size
hold on;

% Background color
set(gcf, 'Color', 'white');
set(gca, 'Color', 'white');

% Prepare data
shiftDirections = {'Right', 'Left'};
xDataByShift = zeros(1, 2);
zDataByShift = zeros(1, 2);
xSEMByShift = zeros(1, 2);
zSEMByShift = zeros(1, 2);

for s = 1:2
    indices = participantSummary.ShiftDirection == shiftDirections{s};
    xDataByShift(s) = mean(participantSummary.MeanDirectionalErrorX(indices), 'omitnan');
    zDataByShift(s) = mean(participantSummary.MeanDirectionalErrorZ(indices), 'omitnan');
    xSEMByShift(s) = std(participantSummary.MeanDirectionalErrorX(indices), 'omitnan') / sqrt(sum(indices));
    zSEMByShift(s) = std(participantSummary.MeanDirectionalErrorZ(indices), 'omitnan') / sqrt(sum(indices));
end

% Create subplot for X errors by shift direction
subplot(1, 2, 1);
b3 = bar(xDataByShift, 'FaceColor', config.colorPalette.GrayScaleThreePoints(1,:), 'FaceAlpha', vizParams.barAlpha, LineWidth=vizParams.barPlotwidth);
hold on;
errorbar(1:2, xDataByShift, xSEMByShift, 'k', 'linestyle', 'none', 'linewidth', vizParams.barWidth);

% Add scatter points for X errors by shift direction
for s = 1:2
    indices = participantSummary.ShiftDirection == shiftDirections{s};
    individualData = participantSummary.MeanDirectionalErrorX(indices);
    xJitter = (rand(size(individualData)) - 0.5) * vizParams.jitterAmount;
    scatter(s + xJitter, individualData, vizParams.scatterSize, 'k', 'filled', 'MarkerFaceAlpha', vizParams.scatterAlpha);
end

% refline(0, 0);
set(gca, 'XTickLabel', lower(shiftDirections));
ylabel('x-axis directional error');
xlabel('shift direction');
grid on;
ylim(vizParams.ylimRange);
box off;

ax = gca;
ax.XAxis.LineWidth = config.plotSettings.AxisLineWidth;
ax.YAxis.LineWidth = config.plotSettings.AxisLineWidth;
ax.FontName = config.plotSettings.FontName;
ax.FontSize = config.plotSettings.FontSize;

% Create subplot for Z errors by shift direction
subplot(1, 2, 2);
b4 = bar(zDataByShift, 'FaceColor', config.colorPalette.GrayScaleThreePoints(3,:), 'FaceAlpha', vizParams.barAlpha, LineWidth=vizParams.barPlotwidth);
hold on;
errorbar(1:2, zDataByShift, zSEMByShift, 'k', 'linestyle', 'none', 'linewidth', vizParams.barWidth);

% Add scatter points for Z errors by shift direction
for s = 1:2
    indices = participantSummary.ShiftDirection == shiftDirections{s};
    individualData = participantSummary.MeanDirectionalErrorZ(indices);
    xJitter = (rand(size(individualData)) - 0.5) * vizParams.jitterAmount;
    scatter(s + xJitter, individualData, vizParams.scatterSize, 'k', 'filled', 'MarkerFaceAlpha', vizParams.scatterAlpha);
end

% refline(0, 0);
set(gca, 'XTickLabel', lower(shiftDirections));
ylabel('z-axis directional error');
xlabel('shift direction');
grid on;
ylim(vizParams.ylimRange);
box off;

ax = gca;
ax.XAxis.LineWidth = config.plotSettings.AxisLineWidth;
ax.YAxis.LineWidth = config.plotSettings.AxisLineWidth;
ax.FontName = config.plotSettings.FontName;
ax.FontSize = config.plotSettings.FontSize;

% Add significance bar
hold on;
% Calculate position for significance bar
yOffset = 0.2; % Offset from the maximum value point
barHeight = max(max(zDataByShift) + max(zSEMByShift)) + yOffset;
xStart = 1;
xEnd = 2;

% Draw the significance bar (just the horizontal line)
plot([xStart xEnd], [barHeight barHeight], 'k-', 'LineWidth', vizParams.barWidth);

% Add text for p-value
text(mean([xStart xEnd]), barHeight + 0.1, 'p < 0.05', ...
    'HorizontalAlignment', 'center', ...
    'FontSize', config.plotSettings.FontSize, ...
    'FontName', config.plotSettings.FontName);

% Adjust y-axis limit to accommodate the significance bar
currentYLim = get(gca, 'YLim');
set(gca, 'YLim', [currentYLim(1) barHeight + 0.3]);

% Ensure the Output folder exists
outputFolder = 'Output';
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Define the full paths for saving
pngFile = fullfile(outputFolder, 'shifdirectionbydirectioncomponents.png');
svgFile = fullfile(outputFolder, 'shifdirectionbydirectioncomponents.svg');
pdfFile = fullfile(outputFolder, 'shifdirectionbydirectioncomponents.pdf');

% Save the figure as PNG with the specified DPI
print(pngFile, '-dpng',  ['-r' num2str(dpi)]); % Save as PNG with specified resolution

% Save the figure as SVG with a tight layout
print(svgFile, '-dsvg'); % Save as SVG

% Save the figure as a PDF with high resolution (300 dpi)
print(pdfFile, '-dpdf', ['-r' num2str(dpi)]);

disp(['Figure saved as ' pngFile ', ' svgFile, ' and ', pdfFile]);

hold off;

%% Clean up
% Clear unused variables, keeping only the results for further analysis if needed
 clearvars -except AlloData AlloData_Elderly_4MT HCData YCData AlloData_SPSS_Cond_Conf AlloData_SPSS_Cond_Conf_Block AlloData_SPSS_Cond_Conf_VirtualBlock config 