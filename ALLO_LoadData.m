%% Main script 
% % Loading data for the iVR
% % 
% % TrialType:
% %     WALKEGO = 1; % participants walk back and forth to the same
% viewpoint
% %     WALKALLO = 2; % participant walk to the shifted viewpoint
% %     TELEPORT = 3; % participant is teleported to the shifted viewpoint
% % 
% % ParticipantGroup:
% %     YC  = 1; Young controls
% %     HC  = 2; Healthy controls
% %     MCI = 99; Mild Cognitive Impairment, not used in this analysis
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
config.colorPalette.darkGray = [40/255, 40/255, 40/255]; % #474747
config.colorPalette.darkYoung = [20/255, 48/255, 62/255]; % #14303E
config.colorPalette.darkElderly = [75/255, 6/255, 6/255]; % #4B0606


config.plotSettings.MarkerSize = 6;       % Marker size
config.plotSettings.MarkerScatterSize = 40;       % Marker scatter size
config.plotSettings.MarkerScatterFaceAlpha = 0.7;       % Marker scatter size
config.plotSettings.MarkerScatterEdgeAlpha = 0.9;       % Marker scatter size
config.plotSettings.LineWidth = 2;        % Line width
config.plotSettings.AxisLineWidth = 1;    % Axis line width
config.plotSettings.FontSize = 9;        % Font size for axes labels
config.plotSettings.FontTitleSize = 11;
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
ALLO_CalculateProperties;

%%
% Add neuropsychological tests data to AlloData (elderly participant only)
ALLO_AddNeuroPsychTest;

%% Cleaning
% Turn on all warnings again
warning('on','all');

% Clear remaining temporary variables
% Andrea: original clear
% clear folderpath folderYoung folderHealthyControl files allNames allNamesUnique allNamesHeader currSize currHeader currTable currGroupedData i
clearvars -except AlloData AlloData_Elderly_4MT HCData YCData AlloData_SPSS_Cond_Conf AlloData_SPSS_Cond_Conf_Block AlloData_SPSS_Cond_Conf_VirtualBlock config



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
