%% Main script 
% % Loading data for the iVR
% % 
% % TrialType:
% %     Same-viewpoint = 1; % participants walk back and forth to the same
% viewpoint
% %     Shifted-viewpoint (walking) = 2; % participant walk to the shifted viewpoint
% %     Shifted-viewpoint (teleport) = 3; % participant is teleported to the shifted viewpoint
% % 
% % ParticipantGroup:
% %     YC  = 1; Young controls
% %     HC  = 2; Healthy controls
% % 
% % 

% Clear the command window, workspace, and close all figures. Turn off all
% warnings.
clc; clear all; close all; warning('off','all');

% Initializing variables
AlloData = table();
YCData = {};
HCData = {};

% Define the path to the data folders
folderpath = pwd;
folderpath = strcat(folderpath,'\Data');

folderYoung          = strcat(folderpath,'\YC\');
folderHealthyControl = strcat(folderpath,'\HC\');

% Defining properties used in plotting
config.colorPalette.young = [45/255, 114/255, 143/255]; % #2D728F
config.colorPalette.elderly = [243/255, 63/255, 63/255]; % #F33F3F
config.colorPalette.lightGray = [75/255, 75/255, 75/255]; % #474747
config.colorPalette.one_object = [140/255, 216/255, 103/255]; % #8CD867
config.colorPalette.four_object = [47/255, 191/255, 113/255]; % #2FBF71
config.colorPalette.same_viewpoint = [253/255, 231/255, 76/255]; % #FDE74C;
config.colorPalette.shifted_viewpoint_walk = [99/255, 83/255, 91/255];     % #63535B;
config.colorPalette.shifted_viewpoint_teleport = [150/255, 52/255, 132/255];   % #963484;
config.colorPalette.darkGray = [40/255, 40/255, 40/255]; % #474747
config.colorPalette.darkYoung = [20/255, 48/255, 62/255]; % #14303E
config.colorPalette.darkElderly = [75/255, 6/255, 6/255]; % #4B0606
config.colorPalette.GrayScale =  [
    211/255, 211/255, 211/255;  % #d3d3d3
    153/255, 153/255, 153/255;  % #999999
    105/255, 105/255, 105/255;  % #696969
    28/255, 28/255, 28/255      % #1c1c1c
];
config.colorPalette.GrayScaleThreePoints =  [
    222/255, 222/255, 222/255;
    148/255, 148/255, 148/255;     
    74/255, 74/255, 74/255
];

config.plotSettings.MarkerSize = 6;       % Marker size
config.plotSettings.MarkerScatterSize = 40;       % Marker scatter size
config.plotSettings.MarkerScatterFaceAlpha = 0.7;       % Marker scatter size
config.plotSettings.MarkerScatterEdgeAlpha = 0.9;       % Marker scatter size
config.plotSettings.LineWidth = 2;        % Line width
config.plotSettings.LineViolinWidth = 1.5; 
config.plotSettings.AxisLineWidth = 1;    % Axis line width
config.plotSettings.FontSize = 9;        % Font size for axes
config.plotSettings.FontLabelSize = 11;        % Font size for labels
config.plotSettings.FontTitleSize = 12;
config.plotSettings.Width = 600;          % Width of the figure
config.plotSettings.Height = 400;         % Height of the figure
config.plotSettings.FontName = 'Arial';

%% Processing Young Data
% Extract data from the Young Control group folder and append it to
% AlloData
[YCData currGroupedData] = ExtractDataFromFolder(folderYoung,'YC');
AlloData = [AlloData;currGroupedData];

% Eliminating incorrect trials from the AlloData table
% Incorrect trials are those where the VR system lost tracking, resulting
% in misplaced position data (e.g., recorded at the position for the
% pooling game objects). 
excludedData     = AlloData(AlloData.RegY > 99,:);
excludedData     = excludedData(:,[1 2 3 5]);
excludedData     = unique(excludedData);
if( isempty(excludedData) == 0)
    sizeU = size(excludedData,1);
    for i = 1:sizeU
        % Replace the data for excluded trials with NaNs
        AlloData(AlloData.ParticipantID == excludedData.ParticipantID(i) & AlloData.TrialNumber == excludedData.TrialNumber(i),[12:1:14]) =  array2table(NaN(excludedData.ConfigurationType(i),3));
    end
end

disp('%%%%%% -------------------------------------- %%%%%%');
disp(['# Removed void trials: ' num2str(size(excludedData,1))]);
clear excludedData sizeU 

%% Processing Healthy Control Data
[HCData currGroupedData] = ExtractDataFromFolder(folderHealthyControl,'HC');
AlloData = [AlloData;currGroupedData];

%% Assigning unique ID for participants
%  ID for Healthy Control will be starting from max(Young) + 1

maxID = max(unique(AlloData.ParticipantID(AlloData.ParticipantGroup == 1)));
adjustedID = AlloData.ParticipantID(AlloData.ParticipantGroup == 2);
adjustedID = adjustedID + ones(size(adjustedID,1),1) * maxID; 
AlloData.ParticipantID(AlloData.ParticipantGroup == 2) = adjustedID;

% Do not remove maxID as it is used later in ALLO_AddNeuroPsychTest
clear adjustedID

% Eliminate incorrect trials again (from the combined AlloData)
excludedData     = AlloData(AlloData.RegY > 99,:);
excludedData     = excludedData(:,[1 2 3 5]);
excludedData     = unique(excludedData);
if( isempty(excludedData) == 0)
    sizeU = size(excludedData,1);
    for i = 1:sizeU
        AlloData(AlloData.ParticipantID == excludedData.ParticipantID(i) & AlloData.TrialNumber == excludedData.TrialNumber(i),[12:1:14]) =  array2table(NaN(excludedData.ConfigurationType(i),3));
    end
end

disp('%%%%%% -------------------------------------- %%%%%%');
disp(['# Removed trials ' num2str(size(excludedData,1))]);
clear excludedData sizeU 

%%
% Calculate basic properties based on the cleaned AlloData
QSVR_CalculateProperties;

%%
% Add neuropsychological tests data to AlloData (elderly participant only)
QSVR_AddNeuroPsychTest;

%% Cleaning
% Turn on all warnings again
warning('on','all');

% Clear remaining temporary variables
% Andrea: original clear
% clear folderpath folderYoung folderHealthyControl files allNames allNamesUnique allNamesHeader currSize currHeader currTable currGroupedData i
clearvars -except AlloData AlloData_Elderly_4MT HCData YCData AlloData_SPSS_Cond_Conf AlloData_SPSS_Cond_Conf_Block AlloData_SPSS_Cond_Conf_VirtualBlock config

%%
function a = extractHeader(x)
    k = strfind(x,'_3.xml');
    a = extractBetween(x,1,k-1);
end

%%
% Function to extract data from the specified folder
function [data groupedData] = ExtractDataFromFolder(folderName, groupName)
%% Extracts data from all the single XML files in a folder.
%  The VR data is saved in 3 XML files for each block (one per block).
%
%  Outputs:
%
%  data - Cell structure where each cell contains data from a single
%  participant 
%  groupedData - Table where each row represents a single trial for
%  replacing one object 

    data = {};
    groupedData = table();
    
    % Reading all files in the directory
    files = dir(folderName);
    allNames = {files.name};

    % Exclude current and parent folder names ('.', '..') and filter by
    % groupName 
    allNames = allNames(~cellfun('isempty',strfind(allNames,groupName)));
    % Extract unique headers (portion of the name before any
    % '_blocktrialnumber') 
    allNamesUnique = allNames(cell2mat(cellfun(@(x) endsWith(x,'_3.xml'),allNames,'UniformOutput',false)));
    allNamesHeader = cellfun(@extractHeader, allNamesUnique);

    currSize = size(allNamesHeader,2);
    
    % Reading each participant at once using the header
    for i = 1:currSize
        currHeader = allNamesHeader{i};
        currData = XmlReader(folderName,currHeader);
        data{i,1} = currData;
        groupedData = [groupedData;currData.Grouped];
    end
    
end
