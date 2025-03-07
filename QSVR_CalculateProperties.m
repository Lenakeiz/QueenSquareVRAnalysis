AlloData.AbsError = sqrt((AlloData.RegX - AlloData.X).^2 + (AlloData.RegZ - AlloData.Z).^2);
AlloData.Angles =  atan2((AlloData.RegZ-AlloData.Z),(AlloData.RegX-AlloData.X));


AlloData.RetrievalTime = AlloData.UnityEndTime - AlloData.UnityStartTime;
% Filtering out the nan reponses
AlloData.RetrievalTime(isnan(AlloData.RegX)) = nan;

AlloData.MeanAbsError = nan(size(AlloData,1),1);
AlloData.MeanRetrievalTime = nan(size(AlloData,1),1);
AlloData.FirstRetrievalTime = nan(size(AlloData,1),1);

uniqueID = unique(AlloData.ParticipantID);
uniqueTrials = unique(AlloData.TrialNumber);

for i = 1:size(uniqueID,1)
    for j = 1:size(uniqueTrials,1)        
        f = find(AlloData.ParticipantID == uniqueID(i) & AlloData.TrialNumber == uniqueTrials(j));
        AlloData.MeanAbsError(f(1)) = nanmean(AlloData.AbsError(f));
        AlloData.MeanRetrievalTime(f(1)) = nanmean(AlloData.RetrievalTime(f));
        
        % For the first retrieval time, we want the first valid retrieval time in the trial
        % This is especially important for 4-object configurations
        validRetrievalTimes = AlloData.RetrievalTime(f);
        validRetrievalTimes = validRetrievalTimes(~isnan(validRetrievalTimes));
        if ~isempty(validRetrievalTimes)
            AlloData.FirstRetrievalTime(f(1)) = validRetrievalTimes(1);
        end
    end
end

%Calculating mean for each participant
AlloData_SPSS_Cond_Conf = cell2table(cell(0,7));  % Added one column for FirstRT
AlloData_SPSS_Cond_Conf.Properties.VariableNames = {'ParticipantID', 'ParticipantGroup', 'ConfigurationType', 'TrialType', 'MeanADE', 'MeanRT', 'FirstRT'};
AlloData_SPSS_Cond_Conf_Block = cell2table(cell(0,8));  % Added one column for FirstRT
AlloData_SPSS_Cond_Conf_Block.Properties.VariableNames = {'ParticipantID', 'ParticipantGroup', 'ConfigurationType', 'TrialType', 'BlockNumber','MeanADE', 'MeanRT', 'FirstRT'};

ctype = [1; 4];
blockNumber = [1; 2; 3];
blockNumberCell = {[1,2] [3,4] [5]};

for i = 1:size(uniqueID,1)
    tempTable = array2table(zeros(6,7));  % Added one column for FirstRT
    tempTable_condconfblock = array2table(zeros(18,8));  % Added one column for FirstRT
    tempTable.Properties.VariableNames = {'ParticipantID', 'ParticipantGroup', 'ConfigurationType', 'TrialType', 'MeanADE', 'MeanRT', 'FirstRT'};
    tempTable_condconfblock.Properties.VariableNames = {'ParticipantID', 'ParticipantGroup', 'ConfigurationType', 'TrialType', 'BlockNumber', 'MeanADE', 'MeanRT', 'FirstRT'};

    tempTable.ParticipantID = ones(6,1).*uniqueID(i);
    tempTable_condconfblock.ParticipantID = ones(18,1).*uniqueID(i);
    f = find(AlloData.ParticipantID == uniqueID(i));
    tempTable.ParticipantGroup = ones(6,1).*AlloData.ParticipantGroup(f(1,1));
    tempTable_condconfblock.ParticipantGroup = ones(18,1).*AlloData.ParticipantGroup(f(1,1));
    
    tempTable_condconfblockVirtual = tempTable_condconfblock;
    
    for cti = 1:size(ctype,1)
        for j = 1:1:3
            f = find(AlloData.ParticipantID == uniqueID(i) & AlloData.TrialType == j & AlloData.ConfigurationType == ctype(cti) & ~isnan(AlloData.MeanAbsError));
            tempTable.ConfigurationType(j + 3*(cti-1)) = ctype(cti);
            tempTable.TrialType(j + 3*(cti-1)) = j;
            tempTable.MeanADE(j + 3*(cti-1)) = nanmean(AlloData.MeanAbsError(f));
            tempTable.MeanRT(j + 3*(cti-1)) = nanmean(AlloData.MeanRetrievalTime(f));
            tempTable.FirstRT(j + 3*(cti-1)) = nanmean(AlloData.FirstRetrievalTime(f));
            blockNumberCell = {[1,2] [3,4] [5]};
            if(size(f,1) == 6)
                blockNumberCell = {[1,2] [3,4] [5,6]};
            end
            if(size(f,1) == 7)
                blockNumberCell = {[1,2] [3,4,5] [6,7]};
            end
            if(size(f,1) == 8)
                blockNumberCell = {[1,2,3] [4,5,6] [7,8]};
            end
            if(size(f,1) < 5)
                blockNumberCell = {[1,2] [3] [4]};
            end
            if(size(f,1) < 4)
                blockNumberCell = {[1] [2] [3]};
            end
            if(size(f,1) < 3)
                blockNumberCell = {[1] [2] [2]};
            end
            if(size(f,1) < 2)
                blockNumberCell = {[1] [1] [1]};
            end
            for hh = 1:1:3
                %f = find(AlloData.ParticipantID == uniqueID(i) & AlloData.TrialType == j & AlloData.ConfigurationType == ctype(cti) & AlloData.TrialNumber > 10*(hh-1) & AlloData.TrialNumber < 10*hh + 1);
                tempTable_condconfblock.ConfigurationType(hh + 3*(j-1) + 9*(cti-1)) = ctype(cti);
                tempTable_condconfblock.TrialType(hh + 3*(j-1) + 9*(cti-1)) = j;
                tempTable_condconfblock.BlockNumber(hh + 3*(j-1) + 9*(cti-1)) = hh;
                tempTable_condconfblockVirtual.ConfigurationType(hh + 3*(j-1) + 9*(cti-1)) = ctype(cti);
                tempTable_condconfblockVirtual.TrialType(hh + 3*(j-1) + 9*(cti-1)) = j;
                tempTable_condconfblockVirtual.BlockNumber(hh + 3*(j-1) + 9*(cti-1)) = hh;
                tempTable_condconfblock.MeanADE(hh + 3*(j-1) + 9*(cti-1)) = nanmean(AlloData.MeanAbsError(f));
                tempTable_condconfblock.MeanRT(hh + 3*(j-1) + 9*(cti-1)) = nanmean(AlloData.MeanRetrievalTime(f));
                tempTable_condconfblock.FirstRT(hh + 3*(j-1) + 9*(cti-1)) = nanmean(AlloData.FirstRetrievalTime(f));
                tempTable_condconfblockVirtual.MeanADE(hh + 3*(j-1) + 9*(cti-1)) = nanmean(AlloData.MeanAbsError(f(cell2mat(blockNumberCell(hh)))));
                tempTable_condconfblockVirtual.MeanRT(hh + 3*(j-1) + 9*(cti-1)) = nanmean(AlloData.MeanRetrievalTime(f(cell2mat(blockNumberCell(hh)))));
                tempTable_condconfblockVirtual.FirstRT(hh + 3*(j-1) + 9*(cti-1)) = nanmean(AlloData.FirstRetrievalTime(f(cell2mat(blockNumberCell(hh)))));
            end
        end
    end    
    
    AlloData_SPSS_Cond_Conf       = [AlloData_SPSS_Cond_Conf; tempTable];
    AlloData_SPSS_Cond_Conf_Block = [AlloData_SPSS_Cond_Conf_Block; tempTable_condconfblock];
end

temMat = reshape(AlloData_SPSS_Cond_Conf_Block.MeanADE,18,44)';
a = [ones(21,1);ones(23,1)*2];
temMat = [a,temMat];
temMat = array2table(temMat);
temMat.Properties.VariableNames = {'Participant_Group' 'One_Ego_One' 'One_Ego_Two' 'One_Ego_Three' 'One_Walk_One' 'One_Walk_Two' 'One_Walk_Three' 'One_Tele_One' 'One_Tele_Two' 'One_Tele_Three' ...
                                   'Four_Ego_One' 'Four_Ego_Two' 'Four_Ego_Three' 'Four_Walk_One' 'Four_Walk_Two' 'Four_Walk_Three' 'Four_Tele_One' 'Four_Tele_Two' 'Four_Tele_Three'};

outputFolder = 'Output';
if ~exist(outputFolder, 'dir')
    mkdir(outputFolder);
end
writetable(temMat, fullfile(outputFolder, 'SPSS_Conf_Cond_Block.csv'), 'WriteVariableNames', true);

clear uniqueID uniqueTrials f i j hh ctype cti tempTable blockNumber tempTable_condconfblock temMat a blockNumberCell tempTable_condconfblockVirtual