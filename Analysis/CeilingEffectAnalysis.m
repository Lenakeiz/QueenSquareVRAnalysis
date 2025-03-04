 %% Ceiling Effect Analysis
% This script analyzes potential floor effects in the data
% (since we're measuring error, where lower values are better)

%% ------ Load data ------
AlloDataBlock = AlloData(:, {'ParticipantID', 'ParticipantGroup', 'TrialNumber', 'TrialType', 'ConfigurationType', 'MeanAbsError'});

% Remove rows with NaNs in MeanAbsError
AlloDataBlock = AlloDataBlock(~isnan(AlloDataBlock.MeanAbsError), :);

funcOmitNan = @(x) mean(x,"omitnan"); 
groupedMeans = varfun(funcOmitNan, AlloDataBlock, 'InputVariables', 'MeanAbsError', ...
                        'GroupingVariables', {'ParticipantID', 'ParticipantGroup', 'TrialType'});

clear funcOmitNan

%% ------ Pre-processing ------ 
% Prepare data for plotting by grouping by TrialType and participant group
y_data = cell(2, 3); % 2 Groups x 3 Movement conditions

for participantGroup = 1:2
    for trialType = 1:3
        y_data{participantGroup, trialType} = groupedMeans.Fun_MeanAbsError(...
            groupedMeans.ParticipantGroup == participantGroup & groupedMeans.TrialType == trialType);
    end
end

% Flatten the data for easier access
flattened_y_data = {};
for participantGroup = 1:2
    for trialType = 1:3
        flattened_y_data{end+1} = y_data{participantGroup, trialType};
    end
end

numConditions = length(flattened_y_data);

%% ------ Normality Tests and Distribution Analysis ------
% Define condition names for output
conditionNames = {'Young - Same View', 'Young - Shifted Walk', 'Young - Shifted Teleport', ...
                  'Elderly - Same View', 'Elderly - Shifted Walk', 'Elderly - Shifted Teleport'};

% Initialize table to store results
resultsTable = table('Size', [numConditions, 8], ...
                    'VariableTypes', {'string', 'double', 'double', 'double', 'double', 'double', 'double', 'double'}, ...
                    'VariableNames', {'Condition', 'Mean', 'Median', 'SD', 'Skewness', 'Kurtosis', 'ShapiroP', 'MinValue'});

% Set condition names
resultsTable.Condition = conditionNames';

% Create figure for histograms
figure('Position', [100, 100, 1200, 800]);

for i = 1:numConditions
    currentData = flattened_y_data{i};

    % Calculate basic statistics
    resultsTable.Mean(i) = mean(currentData);
    resultsTable.Median(i) = median(currentData);
    resultsTable.SD(i) = std(currentData);
    resultsTable.Skewness(i) = skewness(currentData);
    resultsTable.Kurtosis(i) = kurtosis(currentData);
    resultsTable.MinValue(i) = min(currentData);

    % Shapiro-Wilk test for normality
    [~, p_shapiro] = swtest(currentData, 0.05);
    resultsTable.ShapiroP(i) = p_shapiro;

    % Plot histogram with normal fit
    subplot(2, 3, i);

    histogram(currentData, 'Normalization', 'probability', 'FaceAlpha', 0.7);
    hold on;

    % Add kernel density estimate
    [f, xi] = ksdensity(currentData);
    plot(xi, f, 'r-', 'LineWidth', 2);
    
    % Add vertical line for theoretical minimum (0)
    xline(0, 'g--', 'LineWidth', 2);
    
    % Add vertical line for mean
    xline(resultsTable.Mean(i), 'b-', 'LineWidth', 2);
    
    % Add title with key statistics
    title(sprintf('%s\nMean=%.2f, SD=%.2f, Skew=%.2f\nShapiro p=%.4f', ...
          conditionNames{i}, resultsTable.Mean(i), resultsTable.SD(i), ...
          resultsTable.Skewness(i), resultsTable.ShapiroP(i)));
    
    xlabel('Absolute Distance Error (m)');
    ylabel('Probability');
    grid on;
    
    % Set consistent x-axis limits for better comparison
    xlim([0, 5]);
end

% Add overall title
sgtitle('Distribution Analysis for Ceiling Effect Assessment', 'FontSize', 16);

%% ------ Floor Effect Assessment ------
% Calculate distance from theoretical minimum (0) in standard deviation units
resultsTable.DistanceFromFloor = resultsTable.Mean ./ resultsTable.SD;

% Calculate percentage of values within 1 SD of floor
percentNearFloor = zeros(numConditions, 1);
for i = 1:numConditions
    percentNearFloor(i) = 100 * sum(flattened_y_data{i} < resultsTable.SD(i)) / length(flattened_y_data{i});
end
resultsTable.PercentWithin1SD = percentNearFloor;

% Display results
disp('Distribution Analysis Results:');
disp(resultsTable);

%% ------ Floor Effect Visualization ------
figure('Position', [100, 100, 1000, 600]);

% Plot distance from floor in SD units
subplot(2, 1, 1);
bar(resultsTable.DistanceFromFloor);
hold on;
yline(1, 'r--', 'LineWidth', 2); % Reference line at 1 SD
grid on;
xticks(1:numConditions);
xticklabels(conditionNames);
xtickangle(45);
ylabel('Distance from Floor (in SD units)');
title('Distance of Mean from Theoretical Minimum (0)');

% Plot percentage of values within 1 SD of floor
subplot(2, 1, 2);
bar(resultsTable.PercentWithin1SD);
hold on;
yline(15, 'r--', 'LineWidth', 2); % Reference line at 15%
grid on;
xticks(1:numConditions);
xticklabels(conditionNames);
xtickangle(45);
ylabel('Percentage (%)');
title('Percentage of Values Within 1 SD of Floor (0)');

% Add overall title
sgtitle('Floor Effect Assessment Metrics', 'FontSize', 16);


%% ------ Save Results ------
% Ensure the Output folder exists
outputFolder = 'Output';
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Save figures
print(figure(1), fullfile(outputFolder, 'ceiling_effect_distributions.png'), '-dpng', '-r300');
print(figure(2), fullfile(outputFolder, 'ceiling_effect_metrics.png'), '-dpng', '-r300');

%% Clearing the workspace
clearvars -except AlloData AlloData_Elderly_4MT HCData YCData AlloData_SPSS_Cond_Conf AlloData_SPSS_Cond_Conf_Block AlloData_SPSS_Cond_Conf_VirtualBlock config RetrievalTime
    

