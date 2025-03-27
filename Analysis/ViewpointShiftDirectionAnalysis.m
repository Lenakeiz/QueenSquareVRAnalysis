%% Viewpoint Projected Error Analysis - Triple Interaction Focus
% This script analyzes how spatial memory errors project onto the viewpoint shift direction,
% focusing on the triple interaction between shift direction, age group, and movement type.

% Turn off warnings temporarily
warning('off');

%% ------ Define viewpoint coordinates ------
% These are the relative coordinates of the two viewpoints
longSideViewpoint = [6.0, 0];   % Viewpoint on the long side of the L platform
shortSideViewpoint = [0, -4.5]; % Viewpoint on the short side of the L platform

fprintf('Defined viewpoint coordinates:\n');
fprintf('Long side viewpoint: (%.1f, %.1f)\n', longSideViewpoint);
fprintf('Short side viewpoint: (%.1f, %.1f)\n', shortSideViewpoint);

%% ------ Calculate viewpoint shift direction vectors ------
% For Right Shift (0): Direction from long side to short side
rightShiftVector = shortSideViewpoint - longSideViewpoint;  % (-6.0, -4.5)
rightShiftDirection = rightShiftVector / norm(rightShiftVector); % Normalize

% For Left Shift (1): Direction from short side to long side
leftShiftVector = longSideViewpoint - shortSideViewpoint;  % (6.0, 4.5)
leftShiftDirection = leftShiftVector / norm(leftShiftVector); % Normalize

fprintf('\nCalculated viewpoint shift direction vectors:\n');
fprintf('Right shift (0) direction: (%.4f, %.4f), magnitude: %.4f\n', ...
    rightShiftDirection(1), rightShiftDirection(2), norm(rightShiftDirection));
fprintf('Left shift (1) direction: (%.4f, %.4f), magnitude: %.4f\n', ...
    leftShiftDirection(1), leftShiftDirection(2), norm(leftShiftDirection));

%% ------ Load data ------
% Extract relevant columns from AlloData
AlloDataAnalysis = AlloData(:, {'ParticipantID', 'ParticipantGroup', 'TrialType', 'TrialNumber', ...
                              'ConfigurationType', 'X', 'Z', 'RegX', 'RegZ', 'SwitchSide'});

% Focus only on viewpoint shift conditions (TrialType 2 and 3)
% TrialType 2 = Shifted-viewpoint (walking)
% TrialType 3 = Shifted-viewpoint (teleport)
ShiftData = AlloDataAnalysis(AlloDataAnalysis.TrialType == 2 | AlloDataAnalysis.TrialType == 3, :);

%% ------ Calculate projected directional errors ------
% Create a new column for the projected error
ShiftData.ProjectedError = zeros(height(ShiftData), 1);

% For each row in ShiftData
for i = 1:height(ShiftData)
    % Calculate the raw error vector: (RegX, RegZ) - (X, Z)
    errorVector = [ShiftData.RegX(i) - ShiftData.X(i), ShiftData.RegZ(i) - ShiftData.Z(i)];
    
    % Determine which shift direction to use (0 = Right, 1 = Left)
    if ShiftData.SwitchSide(i) == 0  % Right shift
        directionVector = rightShiftDirection;
    else  % Left shift
        directionVector = leftShiftDirection;
    end
    
    % Project the error vector onto the shift direction
    % The projection is the dot product: errorVector · directionVector
    % Since directionVector is normalized, this gives us the scalar projection
    projectedError = dot(errorVector, directionVector);
    
    % Store the projected error
    ShiftData.ProjectedError(i) = projectedError;
end

fprintf('\nCalculated projected errors for %d observations.\n', height(ShiftData));

%% ------ Prepare data for LME analysis ------
% Create a copy of ShiftData for analysis
lmeData = ShiftData;

% Add categorical variables for LME analysis
lmeData.AgeGroup = categorical(lmeData.ParticipantGroup, [1 2], {'Young', 'Older'});
lmeData.ShiftDirection = categorical(lmeData.SwitchSide, [0 1], {'Right', 'Left'});
lmeData.MovementType = categorical(lmeData.TrialType, [2 3], {'Walking', 'Teleport'});
lmeData.Configuration = categorical(lmeData.ConfigurationType);

fprintf('\nLinear mixed effect model analysis\n');
fprintf('----------------------------------\n');

% Define full model with the triple interaction
modelFormula = 'ProjectedError ~ ShiftDirection*AgeGroup*MovementType + ConfigurationType + (1|ParticipantID)';
model = fitlme(lmeData, modelFormula);

% Display model summary
disp(model);
% Display ANOVA results for fixed effects
modelAnova = anova(model);
disp('ANOVA for Triple Interaction Model:');
disp(modelAnova);

% Define the expected terms for the model
modelTerms = {'(Intercept)', 'ConfigurationType', 'AgeGroup', 'ShiftDirection', ...
               'MovementType', 'AgeGroup:ShiftDirection', 'AgeGroup:MovementType', ...
               'ShiftDirection:MovementType', 'AgeGroup:ShiftDirection:MovementType'};

% Apply Benjamini-Hochberg FDR correction
fprintf('\nCalculating FDR correction using Benjamini-Hochberg procedure\n');

% Get all p-values from the ANOVA
allPValues = modelAnova.pValue;
[sortedP, indices] = sort(allPValues);
n = length(allPValues);

% Calculate FDR-adjusted p-values directly
adjustedP = zeros(size(sortedP));
for i = 1:n
    % Calculate adjusted p-value for this rank: p * (n/rank)
    adjustedP(i) = min(1, sortedP(i) * n / i);
end

% Ensure monotonicity (no adjusted value can be smaller than the previous one)
for i = n-1:-1:1
    adjustedP(i) = min(adjustedP(i), adjustedP(i+1));
end

% Map back to original order
fdrResults = zeros(size(allPValues));
fdrResults(indices) = adjustedP;

% Display results with FDR correction
fprintf('\nANOVA with FDR correction:\n');
fprintf('Term                                        F-Stat    DF1  DF2    p-value   FDR p\n');
fprintf('--------------------------------------------------------------------------------------------\n');
for i = 1:height(modelAnova)
    % Use the expected term name if available
    if i <= length(modelTerms)
        term = modelTerms{i};
    else
        term = sprintf('Term_%d', i);
    end
    
    fstat = modelAnova.FStat(i);
    df1 = modelAnova.DF1(i);
    df2 = modelAnova.DF2(i);
    pvalue = modelAnova.pValue(i);
    
    % Get FDR corrected p-value
    fdrP = fdrResults(i);
    
    % Determine significance level based on FDR
    if fdrP < 0.001
        sigLevel = '***';
    elseif fdrP < 0.01
        sigLevel = '**';
    elseif fdrP < 0.05
        sigLevel = '*';
    else
        sigLevel = '';
    end
    
    fprintf('%-42s %8.3f   %3d  %3d   %8.6f   %8.6f %s\n', ...
        term, fstat, df1, df2, pvalue, fdrP, sigLevel);
end


%% Plotting the triple interaction
% Add categorical variables
ShiftData.AgeGroup = categorical(ShiftData.ParticipantGroup, [1 2], {'Young', 'Older'});
ShiftData.ShiftDirection = categorical(ShiftData.SwitchSide, [0 1], {'Right', 'Left'});
ShiftData.MovementType = categorical(ShiftData.TrialType, [2 3], {'Walking', 'Teleport'});

% Average by trial for each participant
trialSummary = table();
row = 1;
participants = unique(ShiftData.ParticipantID);

% For each participant
for p = 1:length(participants)
    pid = participants(p);
    participantData = ShiftData(ShiftData.ParticipantID == pid, :);
    trialNumbers = unique(participantData.TrialNumber);
    
    % For each trial
    for t = 1:length(trialNumbers)
        trialNum = trialNumbers(t);
        trialData = participantData(participantData.TrialNumber == trialNum, :);
        
        % Get trial metadata
        pGroup = unique(trialData.ParticipantGroup);
        trialType = unique(trialData.TrialType);
        switchSide = unique(trialData.SwitchSide);
        
        % Calculate mean projected error for this trial
        meanProjectedError = mean(trialData.ProjectedError, 'omitnan');
        
        % Add to summary table
        trialSummary.ParticipantID(row) = pid;
        trialSummary.ParticipantGroup(row) = pGroup;
        trialSummary.TrialType(row) = trialType;
        trialSummary.SwitchSide(row) = switchSide;
        trialSummary.ProjectedError(row) = meanProjectedError;
        row = row + 1;
    end
end

% Add categorical variables for analysis
trialSummary.AgeGroup = categorical(trialSummary.ParticipantGroup, [1 2], {'Young', 'Older'});
trialSummary.ShiftDirection = categorical(trialSummary.SwitchSide, [0 1], {'Right', 'Left'});
trialSummary.MovementType = categorical(trialSummary.TrialType, [2 3], {'Walking', 'Teleport'});

% Analysis data
lmeData = trialSummary;

%% Calculate means and SEMs for visualization
uniqueGroups = {'young', 'older'};  % Changed to lowercase
uniqueDirections = {'Right', 'Left'};
uniqueMovements = {'Walking', 'Teleport'};

% Store means and SEMs
means = zeros(2, 2, 2); % [Age Group, Shift Direction, Movement Type]
sems = zeros(2, 2, 2);

for g = 1:length(uniqueGroups)
    % Convert to title case for matching (categorical variables maintain case)
    matchGroup = uniqueGroups{g};
    if strcmpi(matchGroup, 'young')
        matchGroup = 'Young';
    elseif strcmpi(matchGroup, 'older')
        matchGroup = 'Older';
    end
    
    for d = 1:length(uniqueDirections)
        for m = 1:length(uniqueMovements)
            % Filter data
            idx = lmeData.AgeGroup == matchGroup & ...
                  lmeData.ShiftDirection == uniqueDirections{d} & ...
                  lmeData.MovementType == uniqueMovements{m};
            
            % Calculate statistics
            means(g, d, m) = mean(lmeData.ProjectedError(idx), 'omitnan');
            sems(g, d, m) = std(lmeData.ProjectedError(idx), 'omitnan') / sqrt(sum(idx));
        end
    end
end

%% Visualization with fixed bar organization using the exact config colors
% Use the specific color palette entries for the two movement conditions
colorWalking = config.colorPalette.shifted_viewpoint_walk;     % For Walking
colorTeleport = config.colorPalette.shifted_viewpoint_teleport; % For Teleport

% Visualization parameters
vizParams.barAlpha = 0.7;          % Bar transparency
vizParams.scatterAlpha = 0.1;      % Scatter point transparency
vizParams.jitterAmount = 0.2;      % Jitter amount
vizParams.scatterSize = config.plotSettings.MarkerScatterSize; % Use config scatter size
vizParams.barWidth = config.plotSettings.LineWidth;  % Use config line width
vizParams.barPlotwidth = 1.0;      % Bar plot width
vizParams.ylimRange = [-2, 2];     % Y-axis limits

% Desired figure size
plotWidthInches = 8.0;  % Width in inches
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

% Create arrays to store bar handles for legend
hBars = zeros(2,1);

% Plot for each age group
for g = 1:2
    subplot(1, 2, g);
    hold on;
    
    % Set subplot title - all lowercase
    title([uniqueGroups{g}, ' adults'], 'FontWeight', 'normal');
    
    % Define x-positions for each bar
    xPositions = [1, 2, 4, 5]; % [Right+Walk, Right+Tele, Left+Walk, Left+Tele]
    
    % Convert group name to title case for matching
    matchGroup = uniqueGroups{g};
    if strcmpi(matchGroup, 'young')
        matchGroup = 'Young';
    elseif strcmpi(matchGroup, 'older')
        matchGroup = 'Older';
    end
    
    % First plot all scatter points
    % For Right Shift + Walking
    idx = lmeData.AgeGroup == matchGroup & lmeData.ShiftDirection == 'Right' & lmeData.MovementType == 'Walking';
    data = lmeData.ProjectedError(idx);
    jitter = vizParams.jitterAmount * (rand(size(data)) - 0.5);
    scatter(xPositions(1) + jitter, data, vizParams.scatterSize, colorWalking, 'filled', 'MarkerFaceAlpha', vizParams.scatterAlpha);
    
    % For Right Shift + Teleport
    idx = lmeData.AgeGroup == matchGroup & lmeData.ShiftDirection == 'Right' & lmeData.MovementType == 'Teleport';
    data = lmeData.ProjectedError(idx);
    jitter = vizParams.jitterAmount * (rand(size(data)) - 0.5);
    scatter(xPositions(2) + jitter, data, vizParams.scatterSize, colorTeleport, 'filled', 'MarkerFaceAlpha', vizParams.scatterAlpha);
    
    % For Left Shift + Walking
    idx = lmeData.AgeGroup == matchGroup & lmeData.ShiftDirection == 'Left' & lmeData.MovementType == 'Walking';
    data = lmeData.ProjectedError(idx);
    jitter = vizParams.jitterAmount * (rand(size(data)) - 0.5);
    scatter(xPositions(3) + jitter, data, vizParams.scatterSize, colorWalking, 'filled', 'MarkerFaceAlpha', vizParams.scatterAlpha);
    
    % For Left Shift + Teleport
    idx = lmeData.AgeGroup == matchGroup & lmeData.ShiftDirection == 'Left' & lmeData.MovementType == 'Teleport';
    data = lmeData.ProjectedError(idx);
    jitter = vizParams.jitterAmount * (rand(size(data)) - 0.5);
    scatter(xPositions(4) + jitter, data, vizParams.scatterSize, colorTeleport, 'filled', 'MarkerFaceAlpha', vizParams.scatterAlpha);
    
    % Add zero line
    plot([0.5, 5.5], [0, 0], 'k--', 'LineWidth', 1);
    
    if g == 1
        hBars(1) = bar(xPositions(1), means(g, 1, 1), 0.7, 'FaceColor', colorWalking, 'EdgeColor', 'k', 'FaceAlpha', vizParams.barAlpha, 'LineWidth', vizParams.barPlotwidth);
        hBars(2) = bar(xPositions(2), means(g, 1, 2), 0.7, 'FaceColor', colorTeleport, 'EdgeColor', 'k', 'FaceAlpha', vizParams.barAlpha, 'LineWidth', vizParams.barPlotwidth);
    else
        bar(xPositions(1), means(g, 1, 1), 0.7, 'FaceColor', colorWalking, 'EdgeColor', 'k', 'FaceAlpha', vizParams.barAlpha, 'LineWidth', vizParams.barPlotwidth);
        bar(xPositions(2), means(g, 1, 2), 0.7, 'FaceColor', colorTeleport, 'EdgeColor', 'k', 'FaceAlpha', vizParams.barAlpha, 'LineWidth', vizParams.barPlotwidth);
    end
    
    % Then, plot bars for Left Shift
    bar(xPositions(3), means(g, 2, 1), 0.7, 'FaceColor', colorWalking, 'EdgeColor', 'k', 'FaceAlpha', vizParams.barAlpha, 'LineWidth', vizParams.barPlotwidth);
    bar(xPositions(4), means(g, 2, 2), 0.7, 'FaceColor', colorTeleport, 'EdgeColor', 'k', 'FaceAlpha', vizParams.barAlpha, 'LineWidth', vizParams.barPlotwidth);
    
    % Add error bars last to ensure they're on top
    errorbar(xPositions(1), means(g, 1, 1), sems(g, 1, 1), 'k', 'LineStyle', 'none', 'LineWidth', vizParams.barWidth);
    errorbar(xPositions(2), means(g, 1, 2), sems(g, 1, 2), 'k', 'LineStyle', 'none', 'LineWidth', vizParams.barWidth);
    errorbar(xPositions(3), means(g, 2, 1), sems(g, 2, 1), 'k', 'LineStyle', 'none', 'LineWidth', vizParams.barWidth);
    errorbar(xPositions(4), means(g, 2, 2), sems(g, 2, 2), 'k', 'LineStyle', 'none', 'LineWidth', vizParams.barWidth);

    % Customize plot with lowercase labels
    set(gca, 'XTick', [1.5, 4.5], 'XTickLabel', {'right shift', 'left shift'});
    ylabel('projected error');
    ylim(vizParams.ylimRange);
    
    % Set only horizontal grid lines
    grid off;  % Turn off all grid lines first
    ax = gca;
    ax.YGrid = 'on';    % Turn on only horizontal grid lines
    ax.XGrid = 'off';   % Ensure vertical grid lines are off
    
    box off;
    
    % Apply config font settings
    ax.XAxis.LineWidth = config.plotSettings.AxisLineWidth;
    ax.YAxis.LineWidth = config.plotSettings.AxisLineWidth;
    ax.FontName = config.plotSettings.FontName;
    ax.FontSize = config.plotSettings.FontSize;
end

% Add legend at the bottom center of the figure
lgd = legend(hBars, {'walking', 'teleport'}, 'Orientation', 'horizontal');
lgd.Position = [0.5 - 0.15, 0.01, 0.3, 0.05]; % Centered at bottom
lgd.Box = 'off';

% Save the figure
if ~exist('Output', 'dir')
    mkdir('Output');
end

% Define the full paths for saving
pngFile = fullfile('Output', 'TripleInteractionProjectedErrors.png');
svgFile = fullfile('Output', 'TripleInteractionProjectedErrors.svg');
pdfFile = fullfile('Output', 'TripleInteractionProjectedErrors.pdf');

% Save in multiple formats
dpi = 300;
print(pngFile, '-dpng', ['-r' num2str(dpi)]); % Save as PNG with specified resolution
print(svgFile, '-dsvg'); % Save as SVG
print(pdfFile, '-dpdf', ['-r' num2str(dpi)]); % Save as PDF

disp(['Figure saved as ' pngFile ', ' svgFile, ' and ', pdfFile]);

%% Clean up
% Clear unused variables, keeping only the results for further analysis if needed
clearvars -except AlloData AlloData_Elderly_4MT HCData YCData AlloData_SPSS_Cond_Conf AlloData_SPSS_Cond_Conf_Block AlloData_SPSS_Cond_Conf_VirtualBlock config 

warning('on'); 