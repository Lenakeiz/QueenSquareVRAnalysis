%% Queen Square VR correlation with 4mt task
% Extracting plotting settings from config
elderColor = config.colorPalette.elderly;
markerSize = config.plotSettings.MarkerSize;
lineWidth = config.plotSettings.LineWidth;
axisLineWidth = config.plotSettings.AxisLineWidth;
fontSize = config.plotSettings.FontSize;
scatterFaceAlpha = config.plotSettings.MarkerScatterFaceAlpha;
scatterEdgeAlpha = config.plotSettings.MarkerScatterEdgeAlpha;

% Desired figure size
plotWidthInches = 2;  % Width in inches
plotHeightInches = 2.5; % Height in inches

dpi = 300;

% Define trial type names for plot titles and filenames
trialTypeNames = {'same-viewpoint', 'shifted-viewpoint (walk)', 'shifted-viewpoint (teleport)'};
trialTypeFields = {'MeanADE_SameView', 'MeanADE_ShiftedWalk', 'MeanADE_ShiftedTeleport'};

% Define colors for each trial type from config
trialTypeColors = {
    config.colorPalette.same_viewpoint,
    config.colorPalette.shifted_viewpoint_walk,
    config.colorPalette.shifted_viewpoint_teleport
};

% Bonferroni correction for multiple comparisons
bonferroni_alpha = 0.015;

% Create a plot for each trial type
for trialType = 1:3

    % Create figure and set the size and background color to white
    figure('Units', 'inches', 'Position', [1, 1, plotWidthInches, plotHeightInches], 'Color', 'white');
    
    % Set paper size for saving in inches
    set(gcf, 'PaperUnits', 'inches');
    set(gcf, 'PaperPosition', [0, 0, plotWidthInches, plotHeightInches]);
    set(gcf, 'PaperSize', [plotWidthInches, plotHeightInches]);
    set(gcf, 'PaperPositionMode', 'auto');  % Ensure that the saved figure matches the on-screen size
    
    % Prepare and fit linear model
    tbl = table(AlloData_Elderly_4MT.FourMT, AlloData_Elderly_4MT.(trialTypeFields{trialType}));
    tbl.Properties.VariableNames = {'4MT', 'ADE'};
    
    mdl = fitlm(tbl, 'linear', 'RobustOpts', 'bisquare')
    
    % Get the adjusted R² value
    R2_adjusted = mdl.Rsquared.Adjusted;
    p_value = mdl.Coefficients.pValue(2); % p-value for the slope
    
    % Define the range for x-axis
    x_fit = linspace(0, 15, 100)';  % Create x values from 0 to 15
    % Use predict to get the fitted values and confidence intervals
    [y_fit, y_ci] = predict(mdl, x_fit);
    
    currentColor = trialTypeColors{trialType};
    % Plot the data points
    scatter(AlloData_Elderly_4MT.FourMT, AlloData_Elderly_4MT.(trialTypeFields{trialType}), config.plotSettings.MarkerScatterSize, 'MarkerFaceColor',currentColor, MarkerFaceAlpha=scatterFaceAlpha, MarkerEdgeColor=currentColor, MarkerEdgeAlpha=scatterEdgeAlpha);
    
    hold on;
    
    % Plot the fitted line
    h_fit = plot(x_fit, y_fit, 'Color', [config.colorPalette.darkGray 0.9], 'LineWidth', lineWidth);
    
    % Plot the confidence intervals
    plot(x_fit, y_ci(:,1), 'Color', [config.colorPalette.lightGray 0.7], 'LineWidth', lineWidth, 'LineStyle', '--');
    plot(x_fit, y_ci(:,2), 'Color', [config.colorPalette.lightGray 0.7], 'LineWidth', lineWidth, 'LineStyle', '--');
    
    % Customize axes appearance
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
    ax.YLabel.String = {'average distance error (m)'};
    ax.YLabel.FontSize = fontSize + 2;
    ylim([0, 5]);
    
    % Customize X axis label
    ax.XLabel.Interpreter = 'tex';
    ax.XLabel.String = {'four mountain test score'};
    ax.XLabel.FontSize = fontSize + 2;
    xlim([0, 15]);
    
    % Add the legend with R²_adjusted value
    legend('off')
    
    if p_value < 0.001
        p_text = 'p < 0.001';
    else
        p_text = ['p = ' num2str(p_value, '%.3f')];
    end

    % Add asterisk if significant after Bonferroni correction
    if p_value < bonferroni_alpha
        p_text = [p_text '*'];
    end
    
    text(3.8, 5, [p_text ', R^{2}_{adj} = ' num2str(R2_adjusted, 2)], 'FontSize', fontSize, 'FontName', config.plotSettings.FontName);
    
    % Ensure the Output folder exists
    outputFolder = 'Output';
    if ~exist(outputFolder, 'dir')
        mkdir(outputFolder);
    end
    
    % Define the full paths for saving
    pngFile = fullfile(outputFolder, ['4mtvsade_' trialTypeNames{trialType} '.png']);
    svgFile = fullfile(outputFolder, ['4mtvsade_' trialTypeNames{trialType} '.svg']);
    pdfFile = fullfile(outputFolder, ['4mtvsade_' trialTypeNames{trialType} '.pdf']);
    
    % Save the figure as PNG with the specified DPI
    print(pngFile, '-dpng',  ['-r' num2str(dpi)]); % Save as PNG with specified resolution
    
    % Save the figure as SVG with a tight layout
    print(svgFile, '-dsvg'); % Save as SVG
    
    print(pdfFile, '-dpdf',  ['-r' num2str(dpi)]); % Save as PNG with specified resolution
    
    disp(['Figure saved as ' pngFile ' and ' svgFile]);
    
    % Finalize and clear
    hold off;
    
end
%%
clearvars -except AlloData AlloData_Elderly_4MT HCData YCData AlloData_SPSS_Cond_Conf AlloData_SPSS_Cond_Conf_Block AlloData_SPSS_Cond_Conf_VirtualBlock config RetrievalTime
