HC_NeuroPsychData = readtable(fullfile('Data', 'QSVR_Demographics_Neuropsychology_Battery.csv'));
HC_NeuroPsychData = HC_NeuroPsychData(strcmp(HC_NeuroPsychData.Status, 'HC'), :);

% Create a table for all three trial types
AlloData_Elderly_4MT = cell2table(cell(0,7));
AlloData_Elderly_4MT.Properties.VariableNames = {'ParticipantID', 'ParticipantGroup', 'MeanADE_SameView','MeanADE_ShiftedWalk','MeanADE_ShiftedTeleport','MeanRT','FourMT'};
uniqueID = unique(AlloData_SPSS_Cond_Conf.ParticipantID(AlloData_SPSS_Cond_Conf.ParticipantGroup == 2));

% Extracting only the ade for the Shifted Viewpoint Condition 
for i = 1:size(uniqueID,1)
    currOriginalId = uniqueID(i) - maxID;
    tempTable = array2table(zeros(1,7));
    tempTable.Properties.VariableNames = {'ParticipantID', 'ParticipantGroup', 'MeanADE_SameView','MeanADE_ShiftedWalk','MeanADE_ShiftedTeleport','MeanRT','FourMT'};
    tempTable.ParticipantID = currOriginalId;
    tempTable.ParticipantGroup(1) = 2;

    tempTable.MeanADE_SameView(1) = mean(AlloData_SPSS_Cond_Conf.MeanADE(AlloData_SPSS_Cond_Conf.ParticipantID == uniqueID(i) & (AlloData_SPSS_Cond_Conf.TrialType == 1)));
    tempTable.MeanADE_ShiftedWalk(1) = mean(AlloData_SPSS_Cond_Conf.MeanADE(AlloData_SPSS_Cond_Conf.ParticipantID == uniqueID(i) & (AlloData_SPSS_Cond_Conf.TrialType == 2)));
    tempTable.MeanADE_ShiftedTeleport(1) = mean(AlloData_SPSS_Cond_Conf.MeanADE(AlloData_SPSS_Cond_Conf.ParticipantID == uniqueID(i) & (AlloData_SPSS_Cond_Conf.TrialType == 3)));
  
    currFourMT = HC_NeuroPsychData.IV_MT(HC_NeuroPsychData.ID == currOriginalId);
    
    if isempty(currFourMT)
        tempTable.FourMT(1) = nan;
    else
        tempTable.FourMT(1) = currFourMT;
    end
    
    AlloData_Elderly_4MT = [AlloData_Elderly_4MT; tempTable];
end

% Also load young controls data for sex information
YC_NeuroPsychData = readtable(fullfile('Data', 'QSVR_Demographics_Neuropsychology_Battery.csv'));
YC_NeuroPsychData = YC_NeuroPsychData(strcmp(YC_NeuroPsychData.Status, 'YC'), :);

% Add Sex column to the SPSS tables if they don't already have it
if ~ismember('Sex', AlloData_SPSS_Cond_Conf.Properties.VariableNames)
    AlloData_SPSS_Cond_Conf.Sex = cell(height(AlloData_SPSS_Cond_Conf), 1);
end

if ~ismember('Sex', AlloData_SPSS_Cond_Conf_Block.Properties.VariableNames)
    AlloData_SPSS_Cond_Conf_Block.Sex = cell(height(AlloData_SPSS_Cond_Conf_Block), 1);
end

% Add sex information for each participant in both tables
for i = 1:height(AlloData_SPSS_Cond_Conf)
    participantID = AlloData_SPSS_Cond_Conf.ParticipantID(i);
    participantGroup = AlloData_SPSS_Cond_Conf.ParticipantGroup(i);
    
    % For young controls (group 1)
    if participantGroup == 1
        % Find the original ID in YC data
        originalID = participantID;
        idx = find(YC_NeuroPsychData.ID == originalID);
        if ~isempty(idx)
            AlloData_SPSS_Cond_Conf.Sex{i} = YC_NeuroPsychData.Sex{idx(1)};
        else
            AlloData_SPSS_Cond_Conf.Sex{i} = 'Unknown';
        end
    % For healthy controls (group 2)
    elseif participantGroup == 2
        % Find the original ID in HC data (adjusted by maxID)
        originalID = participantID - maxID;
        idx = find(HC_NeuroPsychData.ID == originalID);
        if ~isempty(idx)
            AlloData_SPSS_Cond_Conf.Sex{i} = HC_NeuroPsychData.Sex{idx(1)};
        else
            AlloData_SPSS_Cond_Conf.Sex{i} = 'Unknown';
        end
    end
end

% Do the same for the Block table
for i = 1:height(AlloData_SPSS_Cond_Conf_Block)
    participantID = AlloData_SPSS_Cond_Conf_Block.ParticipantID(i);
    participantGroup = AlloData_SPSS_Cond_Conf_Block.ParticipantGroup(i);
    
    % For young controls (group 1)
    if participantGroup == 1
        % Find the original ID in YC data
        originalID = participantID;
        idx = find(YC_NeuroPsychData.ID == originalID);
        if ~isempty(idx)
            AlloData_SPSS_Cond_Conf_Block.Sex{i} = YC_NeuroPsychData.Sex{idx(1)};
        else
            AlloData_SPSS_Cond_Conf_Block.Sex{i} = 'Unknown';
        end
    % For healthy controls (group 2)
    elseif participantGroup == 2
        % Find the original ID in HC data (adjusted by maxID)
        originalID = participantID - maxID;
        idx = find(HC_NeuroPsychData.ID == originalID);
        if ~isempty(idx)
            AlloData_SPSS_Cond_Conf_Block.Sex{i} = HC_NeuroPsychData.Sex{idx(1)};
        else
            AlloData_SPSS_Cond_Conf_Block.Sex{i} = 'Unknown';
        end
    end
end

