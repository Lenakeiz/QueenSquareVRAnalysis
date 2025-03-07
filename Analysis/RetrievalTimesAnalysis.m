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

%% Mixed ANOVA for Retrieval Time Analysis
% This section performs a mixed ANOVA with movement condition and object configuration 
% as within-subject factors and participant group as a between-subject factor

% Prepare data for repeated measures ANOVA
fprintf('\n----- Mixed ANOVA for Retrieval Time -----\n');

% Get unique participants
uniqueParticipants = unique(AlloData_SPSS_Cond_Conf.ParticipantID);
numParticipants = length(uniqueParticipants);

% Create matrices to store data
% Format: rows = participants, columns = conditions (2 config types x 3 movement types)
rt_data = zeros(numParticipants, 6);
group_data = zeros(numParticipants, 1);

% Fill the matrices
for i = 1:numParticipants
    participantID = uniqueParticipants(i);
    participantData = AlloData_SPSS_Cond_Conf(AlloData_SPSS_Cond_Conf.ParticipantID == participantID, :);
    
    % Store group (1 = young, 2 = elderly)
    group_data(i) = participantData.ParticipantGroup(1);
    
    % Store retrieval times for each condition
    col = 1;
    for configType = [1, 4]  % 1-object and 4-object configurations
        for trialType = 1:3  % Same view, Shifted walk, Shifted teleport
            idx = find(participantData.ConfigurationType == configType & participantData.TrialType == trialType);
            if ~isempty(idx)
                rt_data(i, col) = participantData.MeanRT(idx);
            else
                rt_data(i, col) = NaN;  % Handle missing data
            end
            col = col + 1;
        end
    end
end

%% Outlier detection and removal
fprintf('\n----- Outlier Detection and Removal -----\n');

% Create a copy of the original data for reference
rt_data_original = rt_data;

% Detect and remove outliers for each condition and group separately
condition_names = {'OneObj_Same', 'OneObj_Walk', 'OneObj_Teleport', ...
                  'FourObj_Same', 'FourObj_Walk', 'FourObj_Teleport'};
group_names = {'Young', 'Elderly'};

for group = 1:2
    group_indices = (group_data == group);
    
    for col = 1:size(rt_data, 2)
        % Get data for current condition and group
        condition_data = rt_data(group_indices, col);
        
        % Skip if all values are NaN
        if all(isnan(condition_data))
            continue;
        end
        
        % Calculate quartiles and IQR (ignoring NaNs)
        Q1 = prctile(condition_data(~isnan(condition_data)), 25);
        Q3 = prctile(condition_data(~isnan(condition_data)), 75);
        IQR = Q3 - Q1;
        
        % Define bounds for outliers
        lowerBound = Q1 - 1.5 * IQR;
        upperBound = Q3 + 1.5 * IQR;
        
        % Identify outliers
        outliers = condition_data < lowerBound | condition_data > upperBound;
        outliers(isnan(condition_data)) = false;  % Don't count NaNs as outliers
        
        % Get indices of outliers in the original data matrix
        outlier_indices = find(group_indices);
        outlier_indices = outlier_indices(outliers);
        
        % Report outliers
        if sum(outliers) > 0
            fprintf('Group %s, Condition %s: %d outliers detected\n', ...
                    group_names{group}, condition_names{col}, sum(outliers));
            fprintf('  Outlier values: ');
            fprintf('%.2f ', condition_data(outliers));
            fprintf('\n');
            
            % Replace outliers with NaN
            rt_data(outlier_indices, col) = NaN;
        end
    end
end

% Report on overall data changes
fprintf('\nOutlier Summary:\n');
fprintf('  Original data range: %.2f to %.2f\n', min(rt_data_original(:)), max(rt_data_original(:)));
fprintf('  Cleaned data range: %.2f to %.2f\n', min(rt_data(:)), max(rt_data(:)));
fprintf('  Total outliers removed: %d out of %d values\n', ...
    sum(~isnan(rt_data_original(:)) & isnan(rt_data(:))), ...
    sum(~isnan(rt_data_original(:))));

% Convert group data to categorical
group_factor = categorical(group_data, [1, 2], {'Young', 'Elderly'});

% Define within-subject factors
config_factor = [ones(1,3), 2*ones(1,3)];  % 1 = one object, 2 = four objects
movement_factor = repmat(1:3, 1, 2);  % 1 = same view, 2 = shifted walk, 3 = shifted teleport

% Perform repeated measures ANOVA using fitrm
% First, create a table with the data
rt_table = array2table(rt_data_original, 'VariableNames', {'OneObj_Same', 'OneObj_Walk', 'OneObj_Teleport', ...
                                                 'FourObj_Same', 'FourObj_Walk', 'FourObj_Teleport'});
rt_table.Group = group_factor;

disp(head(rt_table));

% Define the repeated measures model
rm = fitrm(rt_table, 'OneObj_Same-FourObj_Teleport ~ Group', 'WithinDesign', table(config_factor', movement_factor', 'VariableNames', {'Config', 'Movement'}));

% Run the ANOVA
ranovatbl = ranova(rm, 'WithinModel', 'Config*Movement');

% Display ANOVA results
disp('Repeated Measures ANOVA Results:');
disp(ranovatbl);

% Test between-subjects effect (Group)
between_tbl = rm.BetweenDesign;
between_tbl.MeanRT = mean(rt_data, 2, 'omitnan');  % Calculate mean RT across all conditions for each participant
between_model = fitlm(between_tbl, 'MeanRT ~ Group');
disp('Between-Subjects Effect (Group):');
disp(anova(between_model));

% Calculate means for each condition
fprintf('\nMean Retrieval Times:\n');
fprintf('------------------\n');

% Group means
group_means = grpstats(rt_table, 'Group', {'mean'}, 'DataVars', {'OneObj_Same', 'OneObj_Walk', 'OneObj_Teleport', ...
                                                                'FourObj_Same', 'FourObj_Walk', 'FourObj_Teleport'});
fprintf('Young: %.4f s\n', mean(mean(rt_data(group_data == 1, :), 'omitnan')));
fprintf('Elderly: %.4f s\n', mean(mean(rt_data(group_data == 2, :), 'omitnan')));

% Configuration means
fprintf('One Object: %.4f s\n', mean(mean(rt_data(:, 1:3), 'omitnan')));
fprintf('Four Objects: %.4f s\n', mean(mean(rt_data(:, 4:6), 'omitnan')));

% Movement condition means
movement_means = [mean(mean(rt_data(:, [1, 4]), 'omitnan')), ...
                 mean(mean(rt_data(:, [2, 5]), 'omitnan')), ...
                 mean(mean(rt_data(:, [3, 6]), 'omitnan'))];
fprintf('Same View: %.4f s\n', movement_means(1));
fprintf('Shifted Walk: %.4f s\n', movement_means(2));
fprintf('Shifted Teleport: %.4f s\n', movement_means(3));

% Group x Movement condition means
fprintf('\nGroup x Movement Condition Means:\n');
young_movement_means = [mean(rt_data(group_data == 1, [1, 4]), 'omitnan'), ...
                       mean(rt_data(group_data == 1, [2, 5]), 'omitnan'), ...
                       mean(rt_data(group_data == 1, [3, 6]), 'omitnan')];
elderly_movement_means = [mean(rt_data(group_data == 2, [1, 4]), 'omitnan'), ...
                         mean(rt_data(group_data == 2, [2, 5]), 'omitnan'), ...
                         mean(rt_data(group_data == 2, [3, 6]), 'omitnan')];

fprintf('Young - Same View: %.4f s\n', young_movement_means(1));
fprintf('Young - Shifted Walk: %.4f s\n', young_movement_means(2));
fprintf('Young - Shifted Teleport: %.4f s\n', young_movement_means(3));
fprintf('Elderly - Same View: %.4f s\n', elderly_movement_means(1));
fprintf('Elderly - Shifted Walk: %.4f s\n', elderly_movement_means(2));
fprintf('Elderly - Shifted Teleport: %.4f s\n', elderly_movement_means(3));

%% Post-hoc analysis for movement conditions within each age group
fprintf('\n----- Post-hoc Analysis for Movement Conditions -----\n');

% Prepare data for post-hoc analysis
% Each age group will have data for all three movement conditions
y_data = cell(2, 3); % 2 Groups x 3 Movement Conditions

% Young participants
y_data{1, 1} = mean(rt_data(group_data == 1, [1, 4]), 2);  % Same view
y_data{1, 2} = mean(rt_data(group_data == 1, [2, 5]), 2);  % Shifted walk
y_data{1, 3} = mean(rt_data(group_data == 1, [3, 6]), 2);  % Shifted teleport

% Elderly participants
y_data{2, 1} = mean(rt_data(group_data == 2, [1, 4]), 2);  % Same view
y_data{2, 2} = mean(rt_data(group_data == 2, [2, 5]), 2);  % Shifted walk
y_data{2, 3} = mean(rt_data(group_data == 2, [3, 6]), 2);  % Shifted teleport

% Flatten the data for easier access in post-hoc tests
flattened_y_data = {};
for ageGroupIdx = 1:2
    for condTypeIdx = 1:3
        flattened_y_data{end+1} = y_data{ageGroupIdx, condTypeIdx};
    end
end

% Store all p-values for multiple comparison correction
all_pvalues = zeros(6, 1);
test_idx = 1;

% Perform post-hoc t-tests for young participants
fprintf('Young participants:\n');
fprintf('------------------\n');

fprintf('Same view vs shifted-walking\n');
[h, p, ci, stats] = ttest(flattened_y_data{1}, flattened_y_data{2});
all_pvalues(test_idx) = p;
test_idx = test_idx + 1;
fprintf('t-Test Results: p-value = %.4f, CI = [%.4f, %.4f], t-stat = %.4f, df = %d\n\n', ...
        p, ci(1), ci(2), stats.tstat, stats.df);

fprintf('Shifted-walking vs shifted-teleport\n');
[h, p, ci, stats] = ttest(flattened_y_data{2}, flattened_y_data{3});
all_pvalues(test_idx) = p;
test_idx = test_idx + 1;
fprintf('t-Test Results: p-value = %.4f, CI = [%.4f, %.4f], t-stat = %.4f, df = %d\n\n', ...
        p, ci(1), ci(2), stats.tstat, stats.df);

fprintf('Same view vs shifted-teleport\n');
[h, p, ci, stats] = ttest(flattened_y_data{1}, flattened_y_data{3});
all_pvalues(test_idx) = p;
test_idx = test_idx + 1;
fprintf('t-Test Results: p-value = %.4f, CI = [%.4f, %.4f], t-stat = %.4f, df = %d\n\n', ...
        p, ci(1), ci(2), stats.tstat, stats.df);

% Perform post-hoc t-tests for elderly participants
fprintf('Elderly participants:\n');
fprintf('------------------\n');

fprintf('Same view vs shifted-walking\n');
[h, p, ci, stats] = ttest(flattened_y_data{4}, flattened_y_data{5});
all_pvalues(test_idx) = p;
test_idx = test_idx + 1;
fprintf('t-Test Results: p-value = %.4f, CI = [%.4f, %.4f], t-stat = %.4f, df = %d\n\n', ...
        p, ci(1), ci(2), stats.tstat, stats.df);

fprintf('Shifted-walking vs shifted-teleport\n');
[h, p, ci, stats] = ttest(flattened_y_data{5}, flattened_y_data{6});
all_pvalues(test_idx) = p;
test_idx = test_idx + 1;
fprintf('t-Test Results: p-value = %.4f, CI = [%.4f, %.4f], t-stat = %.4f, df = %d\n\n', ...
        p, ci(1), ci(2), stats.tstat, stats.df);

fprintf('Same view vs shifted-teleport\n');
[h, p, ci, stats] = ttest(flattened_y_data{4}, flattened_y_data{6});
all_pvalues(test_idx) = p;
test_idx = test_idx + 1;
fprintf('t-Test Results: p-value = %.4f, CI = [%.4f, %.4f], t-stat = %.4f, df = %d\n\n', ...
        p, ci(1), ci(2), stats.tstat, stats.df);

% Apply Bonferroni correction for multiple comparisons
fprintf('\nMultiple Comparison Correction (Bonferroni):\n');
fprintf('------------------\n');
bonferroni_alpha = 0.05 / length(all_pvalues);
fprintf('Adjusted alpha level: %.5f\n\n', bonferroni_alpha);

% Alternative: Use multcompare for post-hoc tests based on the ANOVA model
fprintf('\nPost-hoc tests using multcompare (based on ANOVA model):\n');
fprintf('------------------\n');

% For movement condition effect
fprintf('Movement condition comparisons:\n');
movement_comparisons = multcompare(rm, 'Movement', 'By', 'Group', 'ComparisonType', 'tukey-kramer');
disp(movement_comparisons);

% For configuration effect
fprintf('\nConfiguration comparisons:\n');
config_comparisons = multcompare(rm, 'Config', 'By', 'Group', 'ComparisonType', 'tukey-kramer');
disp(config_comparisons);

%% Visualization of retrieval time by movement condition and age group

youngColor = config.colorPalette.young;
elderColor = config.colorPalette.elderly;
markerSize = config.plotSettings.MarkerSize;
lineWidth = config.plotSettings.LineWidth;
axisLineWidth = config.plotSettings.AxisLineWidth;
fontSize = config.plotSettings.FontSize;
scatterFaceAlpha = config.plotSettings.MarkerScatterFaceAlpha;
scatterEdgeAlpha = config.plotSettings.MarkerScatterEdgeAlpha;

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

% Define positions for the bars
movement_condition_gap = 0.3; % Space between conditions within a group
group_gap = 1.2; % Space between groups

% Generate the base position for the first group
base_position = 1; % any starting point

positions_group1 = base_position + [0, movement_condition_gap, movement_condition_gap * 2]; 
positions_group2 = base_position + group_gap + [0, movement_condition_gap, movement_condition_gap * 2]; 

% Concatenate both sets of positions
actual_positions = [positions_group1, positions_group2];

% Calculate means and standard errors for each condition
means = zeros(1, 6);
sems = zeros(1, 6);
for i = 1:6
    means(i) = mean(flattened_y_data{i});
    sems(i) = std(flattened_y_data{i}) / sqrt(length(flattened_y_data{i}));
end

% Plot bars for young participants
bar(positions_group1, means(1:3), 0.2, 'FaceColor', youngColor);
% Plot error bars
errorbar(positions_group1, means(1:3), sems(1:3), 'k', 'LineStyle', 'none', 'LineWidth', 1);

% Plot bars for elderly participants
bar(positions_group2, means(4:6), 0.2, 'FaceColor', elderColor);
% Plot error bars
errorbar(positions_group2, means(4:6), sems(4:6), 'k', 'LineStyle', 'none', 'LineWidth', 1);

% Add individual data points
for i = 1:3
    scatter(repmat(positions_group1(i), size(flattened_y_data{i})) + (rand(size(flattened_y_data{i}))-0.5)*0.1, ...
        flattened_y_data{i}, markerSize, 'o', ...
        'MarkerEdgeColor', youngColor, 'MarkerFaceColor', youngColor, ...
        'MarkerFaceAlpha', scatterFaceAlpha, 'MarkerEdgeAlpha', scatterEdgeAlpha);
    
    scatter(repmat(positions_group2(i), size(flattened_y_data{i+3})) + (rand(size(flattened_y_data{i+3}))-0.5)*0.1, ...
        flattened_y_data{i+3}, markerSize, 'o', ...
        'MarkerEdgeColor', elderColor, 'MarkerFaceColor', elderColor, ...
        'MarkerFaceAlpha', scatterFaceAlpha, 'MarkerEdgeAlpha', scatterEdgeAlpha);
end

% Add significance markers if needed
% Example: if p < 0.05 for young same vs shifted-walk
% Add more based on your t-test results
% text(mean([positions_group1(1), positions_group1(2)]), max(means) + 1, '*', 'FontSize', 14, 'HorizontalAlignment', 'center');

% Customize the plot
ax = gca;
ax.XAxis.LineWidth = axisLineWidth;
ax.YAxis.LineWidth = axisLineWidth;
ax.Title.String = '';
ax.FontName = config.plotSettings.FontName;
ax.FontSize = fontSize;

ax.Box = 'off';  % Remove top and right axes
ax.XColor = 'black'; % Set color for bottom X-axis
ax.YColor = 'black'; % Set color for left Y-axis

% Set x-axis ticks and labels
xticks([mean(positions_group1), mean(positions_group2)]);
xticklabels({'young', 'older'});

% Customize Y axis label
ax.YLabel.Interpreter = 'tex';
ax.YLabel.String = {'retrieval time (s)'};
ax.YLabel.FontSize = config.plotSettings.FontLabelSize;

% Add legend
legend({'same view', 'shifted view (walk)', 'shifted view (teleport)'}, 'Location', 'best');

% Ensure the Output folder exists
outputFolder = 'Output';
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Define the full paths for saving
pngFile = fullfile(outputFolder, 'retrievaltime_by_condition.png');
svgFile = fullfile(outputFolder, 'retrievaltime_by_condition.svg');
pdfFile = fullfile(outputFolder, 'retrievaltime_by_condition.pdf');

% Save the figure as PNG with the specified DPI
print(pngFile, '-dpng', ['-r' num2str(dpi)]); % Save as PNG with specified resolution
% Save the figure as SVG with a tight layout
print(svgFile, '-dsvg'); % Save as SVG
print(pdfFile, '-dpdf', ['-r' num2str(dpi)]);

disp(['Figure saved as ' pngFile ' and ' svgFile]);

% Finalize and clear
hold off;

%%

% Save both the original and cleaned data tables for further analysis
% Ensure the Output folder exists
outputFolder = 'Output';
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Create a table with the original data (before outlier removal)
rt_table_original = array2table(rt_data_original, 'VariableNames', {'OneObj_Same', 'OneObj_Walk', 'OneObj_Teleport', ...
                                                 'FourObj_Same', 'FourObj_Walk', 'FourObj_Teleport'});
rt_table_original.Group = group_factor;
rt_table_original.ParticipantID = uniqueParticipants;

% Reorder columns to put ParticipantID and Group first
rt_table_original = rt_table_original(:, {'ParticipantID', 'Group', ...
                        'OneObj_Same', 'OneObj_Walk', 'OneObj_Teleport', ...
                        'FourObj_Same', 'FourObj_Walk', 'FourObj_Teleport'});

% Save original data as CSV
csvFile_original = fullfile(outputFolder, 'SPSS_Conf_Cond_RetrievalTime_original.csv');
writetable(rt_table_original, csvFile_original);
fprintf('Original retrieval time data saved to: %s\n', csvFile_original);

% Add participant IDs to the cleaned data table
rt_table.ParticipantID = uniqueParticipants;

% Reorder columns to put ParticipantID and Group first
rt_table = rt_table(:, {'ParticipantID', 'Group', ...
                        'OneObj_Same', 'OneObj_Walk', 'OneObj_Teleport', ...
                        'FourObj_Same', 'FourObj_Walk', 'FourObj_Teleport'});

% Save cleaned data as CSV
csvFile = fullfile(outputFolder, 'SPSS_Conf_Cond_RetrievalTime.csv');
writetable(rt_table, csvFile);
fprintf('Cleaned retrieval time data saved to: %s\n', csvFile);

%% 
clearvars -except AlloData AlloData_Elderly_4MT HCData YCData AlloData_SPSS_Cond_Conf AlloData_SPSS_Cond_Conf_Block AlloData_SPSS_Cond_Conf_VirtualBlock config RetrievalTime


