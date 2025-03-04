%% Log Transformation ANOVA
% This script applies a log transformation to the data
% and then runs an ANOVA to test for interaction effects between age and condition

close all;

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

%% ------ Post Hoc Analysis for Log-Transformed Data ------
% Prepare data for plotting by grouping by TrialType and Age Group
% Each TrialType will have data for both age groups
y_data = cell(2, 3); % 2 Groups x 3 Movement Conditions

for ageGroup = 1:2
    for condType = 1:3
        if ageGroup == 1
            currentAgeGroup = 'Young';
        else
            currentAgeGroup = 'Elderly';
        end
        
        if condType == 1
            currentCondition = 'SameView';
        elseif condType == 2
            currentCondition = 'ShiftedWalk';
        else
            currentCondition = 'ShiftedTeleport';
        end
        
        y_data{ageGroup, condType} = anovaTable.TransformedError(...
            anovaTable.AgeGroup == categorical({currentAgeGroup}) & ...
            anovaTable.Condition == categorical({currentCondition}));
    end
end

% Initialize an empty array to store the flattened data
flattened_y_data = {};

% Flatten the data by concatenating across participant groups and trial types
for ageGroup = 1:2
    for condType = 1:3
        flattened_y_data{end+1} = y_data{ageGroup, condType};
    end
end

% Paired t-tests (post hoc analysis)
fprintf('\nPost-hoc comparison for Log-Transformed Data:\n');
fprintf('------------------------------------------------\n');

% Store all p-values for multiple comparison correction
all_pvalues = zeros(6, 1);
test_descriptions = cell(6, 1);
test_idx = 1;
significant_pairs = [];

% Young participants
fprintf('Young participants:\n');
fprintf('------------------\n');

fprintf('Same vs shifted-walking\n');
[h, p, ci, stats] = ttest(flattened_y_data{1}, flattened_y_data{2});
all_pvalues(test_idx) = p;
test_descriptions{test_idx} = 'Young: Same vs shifted-walking';
test_idx = test_idx + 1;
fprintf('t-Test Results: p-value = %.4f, CI = [%.4f, %.4f], t-stat = %.4f, df = %d\n\n', ...
        p, ci(1), ci(2), stats.tstat, stats.df);

fprintf('Shifted-walking vs shifted-teleport\n');
[h, p, ci, stats] = ttest(flattened_y_data{2}, flattened_y_data{3});
all_pvalues(test_idx) = p;
test_descriptions{test_idx} = 'Young: Shifted-walking vs shifted-teleport';
test_idx = test_idx + 1;
fprintf('t-Test Results: p-value = %.4f, CI = [%.4f, %.4f], t-stat = %.4f, df = %d\n\n', ...
        p, ci(1), ci(2), stats.tstat, stats.df);

fprintf('Same vs shifted-teleport\n');
[h, p, ci, stats] = ttest(flattened_y_data{1}, flattened_y_data{3});
all_pvalues(test_idx) = p;
test_descriptions{test_idx} = 'Young: Same vs shifted-teleport';
test_idx = test_idx + 1;
fprintf('t-Test Results: p-value = %.4f, CI = [%.4f, %.4f], t-stat = %.4f, df = %d\n\n', ...
        p, ci(1), ci(2), stats.tstat, stats.df);

% Elderly participants
fprintf('Elderly participants:\n');
fprintf('--------------------\n');

fprintf('Same vs shifted-walking\n');
[h, p, ci, stats] = ttest(flattened_y_data{4}, flattened_y_data{5});
all_pvalues(test_idx) = p;
test_descriptions{test_idx} = 'Elderly: Same vs shifted-walking';
test_idx = test_idx + 1;
fprintf('t-Test Results: p-value = %.4f, CI = [%.4f, %.4f], t-stat = %.4f, df = %d\n\n', ...
        p, ci(1), ci(2), stats.tstat, stats.df);

fprintf('Shifted-walking vs shifted-teleport\n');
[h, p, ci, stats] = ttest(flattened_y_data{5}, flattened_y_data{6});
all_pvalues(test_idx) = p;
test_descriptions{test_idx} = 'Elderly: Shifted-walking vs shifted-teleport';
test_idx = test_idx + 1;
fprintf('t-Test Results: p-value = %.4f, CI = [%.4f, %.4f], t-stat = %.4f, df = %d\n\n', ...
        p, ci(1), ci(2), stats.tstat, stats.df);

fprintf('Same vs shifted-teleport\n');
[h, p, ci, stats] = ttest(flattened_y_data{4}, flattened_y_data{6});
all_pvalues(test_idx) = p;
test_descriptions{test_idx} = 'Elderly: Same vs shifted-teleport';
fprintf('t-Test Results: p-value = %.4f, CI = [%.4f, %.4f], t-stat = %.4f, df = %d\n\n', ...
        p, ci(1), ci(2), stats.tstat, stats.df);

% Print mean values for reference
fprintf('Mean values (log-transformed):\n');
fprintf('Young - Same viewpoint: %.4f\n', mean(flattened_y_data{1}, 'omitnan'));
fprintf('Young - Shifted viewpoint (walk): %.4f\n', mean(flattened_y_data{2}, 'omitnan'));
fprintf('Young - Shifted viewpoint (teleport): %.4f\n', mean(flattened_y_data{3}, 'omitnan'));
fprintf('Elderly - Same viewpoint: %.4f\n', mean(flattened_y_data{4}, 'omitnan'));
fprintf('Elderly - Shifted viewpoint (walk): %.4f\n', mean(flattened_y_data{5}, 'omitnan'));
fprintf('Elderly - Shifted viewpoint (teleport): %.4f\n', mean(flattened_y_data{6}, 'omitnan'));

%% ------ Multiple Comparison Correction ------
% Apply Bonferroni correction
num_tests = length(all_pvalues);
alpha = 0.05;
bonferroni_threshold = alpha / num_tests;

fprintf('\nMultiple Comparison Correction:\n');
fprintf('------------------------------\n');
fprintf('Number of tests: %d\n', num_tests);
fprintf('Original alpha: %.3f\n', alpha);
fprintf('Bonferroni-corrected threshold: %.5f\n\n', bonferroni_threshold);

fprintf('Bonferroni-corrected results:\n');
significant_pairs = [];
for i = 1:num_tests
    significant = all_pvalues(i) < bonferroni_threshold;
    if significant
        sig_symbol = '***';
        % Store the significant pair for plotting
        if i == 1
            significant_pairs = [significant_pairs; 1, 2]; % Young: Same vs shifted-walking
        elseif i == 2
            significant_pairs = [significant_pairs; 2, 3]; % Young: Shifted-walking vs shifted-teleport
        elseif i == 3
            significant_pairs = [significant_pairs; 1, 3]; % Young: Same vs shifted-teleport
        elseif i == 4
            significant_pairs = [significant_pairs; 4, 5]; % Elderly: Same vs shifted-walking
        elseif i == 5
            significant_pairs = [significant_pairs; 5, 6]; % Elderly: Shifted-walking vs shifted-teleport
        elseif i == 6
            significant_pairs = [significant_pairs; 4, 6]; % Elderly: Same vs shifted-teleport
        end
    else
        sig_symbol = 'n.s.';
    end
    fprintf('%s: p = %.5f (%s)\n', test_descriptions{i}, all_pvalues(i), sig_symbol);
end

%% ------ Violin Plot for Log-Transformed Data ------
% Colors and configuration
colors = {config.colorPalette.same_viewpoint, config.colorPalette.shifted_viewpoint_walk, config.colorPalette.shifted_viewpoint_teleport};
mean_color = config.colorPalette.GrayScale(4,:);
x_label = 'age group';
y_label = 'log(absolute distance error)';
x_categories = {'young', 'older'};

% Horizontal lines for reference (optional)
hlines = [0.0]; % Reference line at log(1) = 0

% y-axis limits
ylims = [-2.0, 2.0];

% Desired figure size
plotWidthInches = 6.0;  % Width in inches
plotHeightInches = 2.5; % Height in inches

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

% Define the positions for the data: Each TrialType has three blocks, spaced closely
movement_condition_gap = 0.3; % Space between conditions within a group
group_gap = 1.2; % Space between groups

% Generate the base position for the first group
base_position = 1; % any starting point

positions_group1 = base_position + [0, movement_condition_gap, movement_condition_gap * 2]; 
positions_group2 = base_position + group_gap + [0, movement_condition_gap, movement_condition_gap * 2]; 

% Concatenate both sets of positions
actual_positions = [positions_group1, positions_group2];

% Add horizontal lines if any
if ~isempty(hlines)
    for i = 1:length(hlines)
        yline(hlines(i), '--', 'Color', [127, 127, 127] / 255, 'LineWidth', config.plotSettings.AxisLineWidth);
    end
end

% Violin plot (using kernel density estimation)
for i = 1:length(flattened_y_data)
    current_data = flattened_y_data{i};
    [f, xi] = kde(current_data, 'Bandwidth', 0.3);
    f = f / max(f); % Normalize the density values
    f = 0.1 * f;   % Adjust the width of the violin
    
    % Plot the violin
    fill([actual_positions(i) - f, fliplr(actual_positions(i) + f)], [xi, fliplr(xi)], 'k', ...
        'FaceAlpha', 0, 'EdgeColor', [40, 39, 36] / 255, 'LineWidth', config.plotSettings.LineViolinWidth);
end

% Box plots
for i = 1:length(flattened_y_data)
    current_data = flattened_y_data{i};
    current_color = colors{mod(i-1, length(colors)) + 1};
    box_handle = boxplot(current_data, 'Positions', actual_positions(i), 'Widths', 0.15, ...
                         'Colors', current_color * 0.75, 'MedianStyle', 'line', ...
                         'OutlierSize', 0.1, 'Symbol', '', 'BoxStyle', 'outline');
    set(box_handle,{'linew'},{2})
end

% Scatter points
jitter_amount = 0.05;
scatter_handles = gobjects(1, 3);
for i = 1:length(flattened_y_data)
    current_data = flattened_y_data{i};
    jittered_x = actual_positions(i) + jitter_amount * randn(size(current_data));
    scatter_handles(mod(i-1, 3) + 1) = scatter(jittered_x, current_data, 60, 'MarkerFaceColor', colors{mod(i-1, length(colors)) + 1}, ...
        'MarkerEdgeColor', colors{mod(i-1, length(colors)) + 1}, 'MarkerFaceAlpha', 0.4, 'MarkerEdgeAlpha', 0.5);
end

% Means
for i = 1:length(flattened_y_data)
    current_data = flattened_y_data{i};
    mean_val = mean(current_data, 'omitnan');
    scatter(actual_positions(i), mean_val, 100, 'MarkerFaceColor', mean_color, ...
        'MarkerEdgeColor', 'k', 'LineWidth', config.plotSettings.LineWidth);
end

% Add significance bars based on Bonferroni-corrected results
if ~isempty(significant_pairs)
    % Start at a reasonable height above the data
    base_height = 1.5;
    height_increment = 0.2;
    
    for i = 1:size(significant_pairs, 1)
        idx1 = significant_pairs(i, 1);
        idx2 = significant_pairs(i, 2);
        
        % Calculate height for this significance bar
        bar_height = base_height + (i-1) * height_increment;
        
        % Draw the significance bar
        line_x = [actual_positions(idx1), actual_positions(idx2)];
        plot(line_x, [bar_height, bar_height], 'k-', 'LineWidth', 1.5);
        text(mean(line_x), bar_height + 0.1, '***', 'FontSize', 9, 'HorizontalAlignment', 'center');
    end
end

% Set y-axis limits (adjust based on significance bars if needed)
if ~isempty(significant_pairs)
    max_bar_height = base_height + (size(significant_pairs, 1)-1) * height_increment + 0.2;
    ylim([ylims(1), max(ylims(2), max_bar_height)]);
else
    ylim(ylims);
end

ax = gca;
ax.XAxis.LineWidth = config.plotSettings.AxisLineWidth;
ax.YAxis.LineWidth = config.plotSettings.AxisLineWidth;
ax.Title.String = '';
ax.FontName = config.plotSettings.FontName;
ax.FontSize = config.plotSettings.FontSize;
ax.Box = 'off';  % Remove top and right axes
ax.XColor = 'black'; % Set color for bottom X-axis
ax.YColor = 'black'; % Set color for left Y-axis

% Set labels
set(gca, 'XTick', [mean(actual_positions(1:3)), mean(actual_positions(4:6))], ...
    'XTickLabel', x_categories, ...
    'XLabel', text('String', x_label, 'FontSize', config.plotSettings.FontLabelSize, 'FontName', config.plotSettings.FontName), ...
    'YLabel', text('String', y_label, 'FontSize', config.plotSettings.FontLabelSize, 'FontName', config.plotSettings.FontName));

legend(scatter_handles, {'same-view', 'shifted-view (walk)', 'shifted-view (teleport)'}, 'Location', 'northwest', 'Box','off');

% Ensure the Output folder exists
outputFolder = 'Output';
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Define the full paths for saving
pngFile = fullfile(outputFolder, 'log_transform_violin_plot.png');
svgFile = fullfile(outputFolder, 'log_transform_violin_plot.svg');
pdfFile = fullfile(outputFolder, 'log_transform_violin_plot.pdf');

% Save the figure as PNG with the specified DPI
print(pngFile, '-dpng', ['-r' num2str(dpi)]); % Save as PNG with specified resolution

% Save the figure as SVG with a tight layout
print(svgFile, '-dsvg'); % Save as SVG

% Save the figure as a PDF with high resolution (300 dpi)
print(pdfFile, '-dpdf', ['-r' num2str(dpi)]);

disp(['Figure saved as ' pngFile ' and ' svgFile ' and ' pdfFile]);

hold off;

%% Clearing the workspace
% clearvars -except AlloData AlloData_Elderly_4MT HCData YCData AlloData_SPSS_Cond_Conf AlloData_SPSS_Cond_Conf_Block AlloData_SPSS_Cond_Conf_VirtualBlock config RetrievalTime