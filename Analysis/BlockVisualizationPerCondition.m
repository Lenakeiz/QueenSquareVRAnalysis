AlloDataBlock = AlloData(:, {'ParticipantID', 'ParticipantGroup', 'TrialNumber', 'TrialType', 'ConfigurationType', 'MeanAbsError'});

% Remove rows with NaNs in MeanAbsError - this will automatically filter
% out the trials with 4 objects where the abs error has been already
% averaged for that column
AlloDataBlock = AlloDataBlock(~isnan(AlloDataBlock.MeanAbsError), :);

% Create the block column
AlloDataBlock.Block = arrayfun(@(x) floor((x - 1) / 10) + 1, AlloDataBlock.TrialNumber);

% Calculating the block-wise mean for each participant
funcOmitNan = @(x) mean(x,"omitnan"); 
groupedMeans = varfun(funcOmitNan, AlloDataBlock, 'InputVariables', 'MeanAbsError', ...
                        'GroupingVariables', {'ParticipantID', 'TrialType', 'Block'});

% Identify the specific block that is missing data points
% Assuming from your observation that it's the 3rd block for the 2nd TrialType
trialType = 2;
block = 3;

% Get the participant IDs for this block
participants_block = groupedMeans.ParticipantID(...
    groupedMeans.TrialType == trialType & groupedMeans.Block == block);

% Get participant IDs for another block for comparison (e.g., the first block of the same TrialType)
participants_comparison_block = groupedMeans.ParticipantID(...
    groupedMeans.TrialType == trialType & groupedMeans.Block == 1);

% Identify the missing participant(s)
missing_participants = setdiff(participants_comparison_block, participants_block);

disp('Missing participant(s) in TrialType 2, Block 3:');
disp(missing_participants);

%%

% Prepare data for plotting by grouping by TrialType and Block
% Each TrialType will have three blocks of data
y_data = cell(3, 3); % 3 TrialTypes x 3 Blocks

for trialType = 1:3
    for block = 1:3
        y_data{trialType, block} = groupedMeans.Fun_MeanAbsError(...
            groupedMeans.TrialType == trialType & groupedMeans.Block == block);
    end
end

% Flatten the data to plot
flattened_y_data = [y_data{1, :}, y_data{2, :}, y_data{3, :}];

% Colors and configuration
colors = {config.colorPalette.GrayScale(2,:), config.colorPalette.GrayScale(2,:), config.colorPalette.GrayScale(2,:)};
mean_color = config.colorPalette.GrayScale(4,:);
x_label = 'movement condition';
y_label = 'mean absolute error distance (m)';
x_categories = {'1-Block1', '1-Block2', '1-Block3', '2-Block1', '2-Block2', '2-Block3', '3-Block1', '3-Block2', '3-Block3'};

% Horizontal lines for reference (optional)
hlines = [1.0, 2.0, 3.0, 4.0];

% y-axis limits
ylims = [0, 5.0];

%% ------ Plotting section ------ 
% Desired figure size
plotWidthInches = 3.0;  % Width in inches
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
positions = 1:9;
block_gap = 0.5; % Space between blocks
trialtype_gap = 2; % Space between TrialTypes

% Calculate the actual positions with gaps
actual_positions = [positions(1:3) + (0 * (block_gap + trialtype_gap)), ...
                    positions(4:6) + (1 * (block_gap + trialtype_gap)), ...
                    positions(7:9) + (2 * (block_gap + trialtype_gap))];


% Add horizontal lines if any
if ~isempty(hlines)
    for i = 1:length(hlines)
        yline(hlines(i), '--', 'Color', [127, 127, 127] / 255, 'LineWidth', config.plotSettings.AxisLineWidth);
    end
end

% Violin plot (using kernel density estimation)
for i = 1:length(flattened_y_data)
    [f, xi] = kde(flattened_y_data{i}, 'Bandwidth', 0.3, Support="nonnegative");
    f = f / max(f); % Normalize the density values
    f = 0.25 * f;   % Adjust the width of the violin
    
    % Plot the violin
    fill([actual_positions(i) - f, fliplr(actual_positions(i) + f)], [xi, fliplr(xi)], 'k', ...
        'FaceAlpha', 0, 'EdgeColor', [40, 39, 36] / 255, 'LineWidth',  config.plotSettings.LineViolinWidth);
end

% Box plots
for i = 1:length(flattened_y_data)
    box_handle = boxplot(flattened_y_data{i}, 'Positions', actual_positions(i), 'Widths', 0.3, ...
                         'Colors', [116, 116, 115] / 255, 'MedianStyle', 'line', ...
                         'OutlierSize', 0.1, 'Symbol', '', 'BoxStyle', 'outline');
    set(box_handle,{'linew'},{2})
end

% Scatter points
jitter_amount = 0.075;
for i = 1:length(flattened_y_data)
    jittered_x = actual_positions(i) + jitter_amount * randn(size(flattened_y_data{i}));
    scatter(jittered_x, flattened_y_data{i}, 100, 'MarkerFaceColor', colors{mod(i-1,3)+1}, ...
        'MarkerEdgeColor', 'none', 'MarkerFaceAlpha', 0.3, 'MarkerEdgeAlpha', 0.6);
end

% % Connect data points for the same participant
% unique_participants = unique([participant_ids{:}]);
% for i = 1:length(unique_participants)
%     participant_id = unique_participants(i);
%     participant_data = nan(1, length(y_data));
%     participant_positions = nan(1, length(y_data));
% 
%     for j = 1:length(y_data)
%         idx = participant_ids{j} == participant_id;
%         if any(idx)
%             participant_data(j) = y_data{j}(idx);
%             participant_positions(j) = positions(j);
%         end
%     end
% 
%     if all(~isnan(participant_data))
%         % Plot a line connecting the data points for this participant
%         plot(participant_positions, participant_data, '-o', 'Color', [0.5 0.5 0.5 0.2], 'LineWidth', 1.2);
%     end
% end

% Means
for i = 1:length(flattened_y_data)
    mean_val = mean(flattened_y_data{i});
    scatter(positions(i), mean_val, 100, 'MarkerFaceColor', mean_color, ...
        'MarkerEdgeColor', 'k', 'LineWidth', config.plotSettings.LineWidth);
    % plot([positions(i), positions(i) + 0.25], [mean_val, mean_val], ...
    %     'k-.', 'LineWidth', 1.2);
    % text(positions(i) + 0.25, mean_val, sprintf('\\mu_{mean} = %.2f', mean_val), ...
    %     'FontSize', 13, 'VerticalAlignment', 'middle', ...
    %     'BackgroundColor', 'w', 'EdgeColor', 'k', 'Margin', 1);
end

% Set y-axis limits
ylim(ylims);

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
set(gca, 'XTick', positions, 'XTickLabel', x_categories, ...
    'XLabel', text('String', x_label, 'FontSize', config.plotSettings.FontLabelSize), ...
    'YLabel', text('String', y_label, 'FontSize', config.plotSettings.FontLabelSize));

% Ensure the Output folder exists
outputFolder = 'Output';
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end

% Define the full paths for saving
pngFile = fullfile(outputFolder, 'block_visualization.png');
svgFile = fullfile(outputFolder, 'block_visualization.svg');

% Save the figure as PNG with the specified DPI
print(pngFile, '-dpng',  ['-r' num2str(dpi)]); % Save as PNG with specified resolution

% Save the figure as SVG with a tight layout
print(svgFile, '-dsvg'); % Save as SVG

disp(['Figure saved as ' pngFile ' and ' svgFile]);

hold off;