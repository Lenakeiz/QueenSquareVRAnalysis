function[AlloData] = XmlReader(folderpath,fileheader)
%% Function to extract VR object location task output from xml files
%  Andrea Castegnaro, UCL (2019)
%
%
%
%  **     **   ****     ****   **                                      
% //**   **   /**/**   **/**  /**                                      
%  //** **    /**//** ** /**  /**                                      
%   //***     /** //***  /**  /**                                      
%    **/**    /**  //*   /**  /**                                      
%   ** //**   /**   /    /**  /**                                      
%  **   //**  /**        /**  /********                                
% //     //   //         //   ////////    
%
%
%
%  *******     ********       **       *******     ********   *******  
% /**////**   /**/////       ****     /**////**   /**/////   /**////** 
% /**   /**   /**           **//**    /**    /**  /**        /**   /** 
% /*******    /*******     **  //**   /**    /**  /*******   /*******  
% /**///**    /**////     **********  /**    /**  /**////    /**///**  
% /**  //**   /**        /**//////**  /**    **   /**        /**  //** 
% /**   //**  /********  /**     /**  /*******    /********  /**   //**
% //     //   ////////   //      //   ///////     ////////   //     //
%
%
%
%  Requires xml2struct function from:
%  http://uk.mathworks.com/matlabcentral/fileexchange/28518-xml2struct
%
%  Inputs:
%  folderPath = currentFolder
%  fileHeader = currFileHeader
%
%  Outputs:
%  AlloData - complex structure containing all of the extracted data from
%  the xml.
%


disp(['%--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%     Processing ', fileheader, '     %--%--%--%--%--%--%--%--%--%--%--%--%--%--%--%']);

k = strfind(fileheader,'_');
participantGroupName = extractBetween(fileheader,1,k-1);
participantID = extractBetween(fileheader,k+1,strlength(fileheader));
participantID = str2num(participantID{1});
participantGroup = 0;

switch upper(participantGroupName{1,1})
    case 'YC'
        participantGroup = 1;
    case 'HC'
        participantGroup = 2;
    case 'MCI'
        participantGroup = 99;
end

AlloData = struct();
AlloData.Trials = {};
AlloData.Grouped = table();

% creating the groupingData
vNames = {'ParticipantID' 'ParticipantGroup' 'TrialNumber' 'TrialType' 'ConfigurationType' 'ObjectID' 'StartTime' 'UnityStartTime' 'X' 'Y' 'Z' 'RegX' 'RegY' 'RegZ' 'EndTime' 'UnityEndTime' 'SwitchSide'};
finalGroupingTable           = array2table(zeros(0,17), 'VariableNames', vNames);
finalGroupingTable.StartTime = datetime(zeros(0,3));
finalGroupingTable.EndTime   = datetime(zeros(0,3));
groupingCounter              = 1;

%
    for j = 1:3

        % Taking block
        xmlfile     = strcat(folderpath,strcat(fileheader,'_',num2str(j),'.xml'));

        rawData    	= xmlread(xmlfile);
        rawData     = xml2struct(rawData);
        trials      = size(rawData.Block.BlockTrials.Trial,2);

        AlloData.StartTime      = rawData.Block.ApplicationStartTime.Text;
        AlloData.UnityStartTime = rawData.Block.ApplicationUnityStartTime.Text;
        AlloData.ParticipantID  = rawData.Block.ParticipantID.Text;

% %     0 is the longer side of the L shape, 1 otherwise
% % 
% %     +-----------------+------+
% %     |                 |      |
% %     |               0 |      |
% %     |    +------------+      |
% %     |    |                   |
% %     |    |                   |
% %     |   1|                   |
% %     +----+                   X
% %     |                      XX
% %     |                   XXX  
% %     +--------------XXXXX
% %     CONDITIONS:
% %     WALKEGO = 1;
% %     WALKALLO = 2;
% %     TELEPORT = 3;

        % Store the SwitchSide information for this block
        AlloData.SwitchSide = strcmp(rawData.Block.SwitchSide.Text,'true');

        for t = 1 : trials
            
            AlloData.Trials{t + trials*(j-1)} = struct();

            AlloData.Trials{t + trials*(j-1)}.TrialNumber       = str2num(rawData.Block.BlockTrials.Trial{t}.TrialNumber.Text);
            AlloData.Trials{t + trials*(j-1)}.Condition         = extractCondition(rawData.Block.BlockTrials.Trial{t}.Condition.Text);
            AlloData.Trials{t + trials*(j-1)}.EncodeTime        = str2num(rawData.Block.BlockTrials.Trial{t}.Encode_Time.Text);
            AlloData.Trials{t + trials*(j-1)}.ConfigurationType = str2num(rawData.Block.BlockTrials.Trial{t}.ObjectNumber.Text);
            
            vNames = {'ObjectID' 'StartTime' 'UnityStartTime' 'X' 'Y' 'Z' 'RegX' 'RegY' 'RegZ' 'EndTime' 'UnityEndTime'};
            AlloData.Trials{t + trials*(j-1)}.Objects = array2table(zeros(0,11), 'VariableNames', vNames);
            AlloData.Trials{t + trials*(j-1)}.Objects.StartTime = datetime(zeros(0,3));
            AlloData.Trials{t + trials*(j-1)}.Objects.EndTime = datetime(zeros(0,3));
            
            for cInfo = 1:AlloData.Trials{t + trials*(j-1)}.ConfigurationType
                
                if(AlloData.Trials{t + trials*(j-1)}.ConfigurationType == 1)
                    currConf = rawData.Block.BlockTrials.Trial{t}.ConfigurationInfo.ObjectInfo;
                else
                    currConf = rawData.Block.BlockTrials.Trial{t}.ConfigurationInfo.ObjectInfo{1,cInfo};
                end
                
                %Object Id
                AlloData.Trials{t + trials*(j-1)}.Objects.ObjectID(cInfo) = str2num(currConf.Id.Text);
                
                %Locations
                AlloData.Trials{t + trials*(j-1)}.Objects.X(cInfo)        = str2num(currConf.Real_Position.x.Text);
                AlloData.Trials{t + trials*(j-1)}.Objects.Y(cInfo)        = str2num(currConf.Real_Position.y.Text);
                AlloData.Trials{t + trials*(j-1)}.Objects.Z(cInfo)        = str2num(currConf.Real_Position.z.Text);
                AlloData.Trials{t + trials*(j-1)}.Objects.RegX(cInfo)     = str2num(currConf.Placed_Position.x.Text);
                AlloData.Trials{t + trials*(j-1)}.Objects.RegY(cInfo)     = str2num(currConf.Placed_Position.y.Text);
                AlloData.Trials{t + trials*(j-1)}.Objects.RegZ(cInfo)     = str2num(currConf.Placed_Position.z.Text);
                
                %Time Stamps
                AlloData.Trials{t + trials*(j-1)}.Objects.StartTime(cInfo) = datetime(currConf.Start_Trial_TimeStamp.Text,'InputFormat', 'dd/MM/yyyy HH:mm:ss.SSS');
                AlloData.Trials{t + trials*(j-1)}.Objects.UnityStartTime(cInfo) = str2num(currConf.Start_TrialTrial_UnityTimeStamp.Text);
                AlloData.Trials{t + trials*(j-1)}.Objects.EndTime(cInfo) = datetime(currConf.End_Trial_TimeStamp.Text,'InputFormat', 'dd/MM/yyyy HH:mm:ss.SSS');
                AlloData.Trials{t + trials*(j-1)}.Objects.UnityEndTime(cInfo) = str2num(currConf.End_Trial_UnityTimeStamp.Text);
                            
                %% GROUPING TABLE
                % 'ParticipantID' 'ParticipantGroup'  'TrialNumber'    'TrialType'   'ConfigurationType' 
                % 'ObjectID'      'StartTime'     'UnityStartTime'     'X'           'Y'                    Z RegX RegY RegZ EndTime UnityEndTime

                finalGroupingTable.ParticipantID(groupingCounter)           = participantID;
                finalGroupingTable.ParticipantGroup(groupingCounter)        = participantGroup;
                finalGroupingTable.TrialNumber(groupingCounter)             = t + trials*(j-1); %= str2num(rawData.Block.BlockTrials.Trial{t}.TrialNumber.Text);
                finalGroupingTable.TrialType(groupingCounter)               = AlloData.Trials{t + trials*(j-1)}.Condition;
                finalGroupingTable.ConfigurationType(groupingCounter)       = AlloData.Trials{t + trials*(j-1)}.ConfigurationType;
                finalGroupingTable(groupingCounter, 6:1:16)                 = AlloData.Trials{t + trials*(j-1)}.Objects(cInfo,:);
                finalGroupingTable.SwitchSide(groupingCounter)              = AlloData.SwitchSide;
                
                groupingCounter = groupingCounter + 1;
                %incrementing grouping counter
            end                        
        end
    end

    AlloData.Grouped = finalGroupingTable;

   
end

function a = extractCondition(b)
    a = 0;
    switch upper(b)
        case 'WALKEGO'
            a = 1;
        case 'WALKALLO'
            a = 2;
        case 'TELEPORT'
            a = 3;
    end
end



