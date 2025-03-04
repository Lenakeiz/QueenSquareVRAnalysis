%% Log Transformation ANOVA
% This script applies a log transformation to the data
% and then runs an ANOVA to test for interaction effects between age and condition

%% ------ Load data ------
AlloDataBlock = AlloData(:, {'ParticipantID', 'ParticipantGroup', 'TrialNumber', 'TrialType', 'ConfigurationType', 'MeanAbsError'});

% Remove rows with NaNs in MeanAbsError
AlloDataBlock = AlloDataBlock(~isnan(AlloDataBlock.MeanAbsError), :);

% Calculate participant-wise means for each condition
funcOmitNan = @(x) mean(x,"omitnan"); 
groupedMeans = varfun(funcOmitNan, AlloDataBlock, 'InputVariables', 'MeanAbsError', ...
                        'GroupingVariables', {'ParticipantID', 'ParticipantGroup', 'TrialType'});

clear funcOmitNan

%% ------ Prepare data for ANOVA ------
% Extract data into a format suitable for ANOVA
anovaTable = table();

% Create a row for each participant and condition combination
rows = 1;
for i = 1:height(groupedMeans)
    anovaTable.ParticipantID(rows) = groupedMeans.ParticipantID(i);
    
    % Get the correct group label from the original data
    if groupedMeans.ParticipantGroup(i) == 1
        anovaTable.AgeGroup(rows) = categorical({'Young'});
    else
        anovaTable.AgeGroup(rows) = categorical({'Elderly'});
    end
    
    % Get the condition
    switch groupedMeans.TrialType(i)
        case 1
            anovaTable.Condition(rows) = categorical({'SameView'});
        case 2
            anovaTable.Condition(rows) = categorical({'ShiftedWalk'});
        case 3
            anovaTable.Condition(rows) = categorical({'ShiftedTeleport'});
    end
    
    % Get the error value
    anovaTable.Error(rows) = groupedMeans.Fun_MeanAbsError(i);
    
    rows = rows + 1;
end

%% ------ Apply Log Transformation ------
% Apply log transformation to error values
% Note: We use natural log (ln) transformation

% First, check if we have any zeros or very small values
minError = min(anovaTable.Error(~isnan(anovaTable.Error)));
disp(['Minimum error value before transformation: ', num2str(minError)]);

% Apply transformation: log(x)
% Add a small constant if needed to avoid log(0)
epsilon = 0.001; % Small constant to avoid log(0) if needed
if minError <= epsilon
    anovaTable.TransformedError = log(anovaTable.Error + epsilon);
    disp(['Added epsilon of ', num2str(epsilon), ' before log transformation']);
else
    anovaTable.TransformedError = log(anovaTable.Error);
    disp('Applied natural log transformation without adjustment');
end

% Display the first few rows to verify correct grouping
disp('First few rows of ANOVA table:');
disp(head(anovaTable, 10));

%% ------ Run ANOVA on Original Data ------
% For comparison, run ANOVA on the original data first
disp('ANOVA on Original Data:');
disp('---------------------');

% Remove any rows with NaN values
validRows = ~isnan(anovaTable.Error);
anovaTableValid = anovaTable(validRows, :);

% Run the ANOVA
[p, tbl, stats] = anovan(anovaTableValid.Error, {anovaTableValid.AgeGroup, anovaTableValid.Condition}, ...
    'model', 'full', ...
    'varnames', {'AgeGroup', 'Condition'}, ...
    'display', 'off');

% Display results
disp('ANOVA Results (Original Data):');
disp(tbl);

% Calculate effect sizes (partial eta-squared)
% Extract the sum of squares for each effect and the total
SS_AgeGroup = tbl{2,2};
SS_Condition = tbl{3,2};
SS_Interaction = tbl{4,2};
SS_Error = tbl{5,2};

disp('Effect Sizes (Partial Eta-Squared):');
disp(['Age Group: ', num2str(SS_AgeGroup/(SS_AgeGroup + SS_Error))]);
disp(['Condition: ', num2str(SS_Condition/(SS_Condition + SS_Error))]);
disp(['Interaction: ', num2str(SS_Interaction/(SS_Interaction + SS_Error))]);

%% ------ Run ANOVA on Transformed Data ------
disp('ANOVA on Log-Transformed Data:');
disp('---------------------');

% Remove any rows with NaN values
validRows = ~isnan(anovaTable.TransformedError);
anovaTableValid = anovaTable(validRows, :);

% Run the ANOVA
[p_trans, tbl_trans, stats_trans] = anovan(anovaTableValid.TransformedError, {anovaTableValid.AgeGroup, anovaTableValid.Condition}, ...
    'model', 'full', ...
    'varnames', {'AgeGroup', 'Condition'}, ...
    'display', 'off');

% Display results
disp('ANOVA Results (Log-Transformed Data):');
disp(tbl_trans);

% Calculate effect sizes (partial eta-squared)
% Extract the sum of squares for each effect and the total
SS_AgeGroup_trans = tbl_trans{2,2};
SS_Condition_trans = tbl_trans{3,2};
SS_Interaction_trans = tbl_trans{4,2};
SS_Error_trans = tbl_trans{5,2};

disp('Effect Sizes (Partial Eta-Squared):');
disp(['Age Group: ', num2str(SS_AgeGroup_trans/(SS_AgeGroup_trans + SS_Error_trans))]);
disp(['Condition: ', num2str(SS_Condition_trans/(SS_Condition_trans + SS_Error_trans))]);
disp(['Interaction: ', num2str(SS_Interaction_trans/(SS_Interaction_trans + SS_Error_trans))]);

%% ------ Visualize Original vs Transformed Data ------
% Create a figure to compare distributions before and after transformation
figure('Position', [100, 100, 1200, 600]);

% Plot original data
subplot(1, 2, 1);
boxplot(anovaTable.Error, {anovaTable.AgeGroup, anovaTable.Condition}, 'factorgap', [10, 0], 'labelverbosity', 'major');
title('Original Data');
ylabel('Absolute Distance Error (m)');
grid on;

% Plot transformed data
subplot(1, 2, 2);
boxplot(anovaTable.TransformedError, {anovaTable.AgeGroup, anovaTable.Condition}, 'factorgap', [10, 0], 'labelverbosity', 'major');
title('Log-Transformed Data');
ylabel('Log(Error)');
grid on;

% Add overall title
sgtitle('Comparison of Original vs Log-Transformed Data', 'FontSize', 16);

% Save the figure
outputFolder = 'Output';
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end
print(gcf, fullfile(outputFolder, 'log_transform_comparison.png'), '-dpng', '-r300');

%% ------ Interaction Plot ------
% Create interaction plots for both original and transformed data
figure('Position', [100, 100, 1200, 600]);

% Calculate means for each group and condition
ageGroups = unique(anovaTable.AgeGroup);
conditions = unique(anovaTable.Condition);
numAgeGroups = length(ageGroups);
numConditions = length(conditions);

originalMeans = zeros(numAgeGroups, numConditions);
transformedMeans = zeros(numAgeGroups, numConditions);

for i = 1:numAgeGroups
    for j = 1:numConditions
        originalMeans(i,j) = mean(anovaTable.Error(anovaTable.AgeGroup == ageGroups(i) & ...
                                                 anovaTable.Condition == conditions(j)), 'omitnan');
        transformedMeans(i,j) = mean(anovaTable.TransformedError(anovaTable.AgeGroup == ageGroups(i) & ...
                                                              anovaTable.Condition == conditions(j)), 'omitnan');
    end
end

% Plot original data interaction
subplot(1, 2, 1);
plot(1:numConditions, originalMeans(1,:), 'b-o', 'LineWidth', 2, 'MarkerSize', 8);
hold on;
plot(1:numConditions, originalMeans(2,:), 'r-s', 'LineWidth', 2, 'MarkerSize', 8);
xticks(1:numConditions);
xticklabels({'Same View', 'Shifted Walk', 'Shifted Teleport'});
legend(cellstr(ageGroups), 'Location', 'northwest');
title('Interaction Plot - Original Data');
ylabel('Absolute Distance Error (m)');
grid on;

% Plot transformed data interaction
subplot(1, 2, 2);
plot(1:numConditions, transformedMeans(1,:), 'b-o', 'LineWidth', 2, 'MarkerSize', 8);
hold on;
plot(1:numConditions, transformedMeans(2,:), 'r-s', 'LineWidth', 2, 'MarkerSize', 8);
xticks(1:numConditions);
xticklabels({'Same View', 'Shifted Walk', 'Shifted Teleport'});
legend(cellstr(ageGroups), 'Location', 'northwest');
title('Interaction Plot - Log-Transformed Data');
ylabel('Log(Error)');
grid on;

% Add overall title
sgtitle('Interaction Between Age Group and Condition', 'FontSize', 16);

% Save the figure
print(gcf, fullfile(outputFolder, 'log_transform_interaction.png'), '-dpng', '-r300');

%% Clearing the workspace
% clearvars -except AlloData AlloData_Elderly_4MT HCData YCData AlloData_SPSS_Cond_Conf AlloData_SPSS_Cond_Conf_Block AlloData_SPSS_Cond_Conf_VirtualBlock config RetrievalTime