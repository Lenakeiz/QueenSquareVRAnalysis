% calculate_mean_task_duration.m
% Script to calculate the mean task duration across all participants
% by finding the difference between max UnityEndTime and min UnityStartTime
% for each participant, then averaging across participants

% Get unique participant IDs
uniqueParticipants = unique(AlloData.ParticipantID);

% Initialize array to store durations
participantDurations = zeros(length(uniqueParticipants), 1);

% Calculate duration for each participant
for i = 1:length(uniqueParticipants)
    participantID = uniqueParticipants(i);
    
    % Get data for this participant
    participantData = AlloData(AlloData.ParticipantID == participantID, :);
    
    % Calculate duration (max UnityEndTime - min UnityStartTime)
    minStartTime = min(participantData.UnityStartTime);
    maxEndTime = max(participantData.UnityEndTime);
    
    participantDurations(i) = maxEndTime - minStartTime;
end

% Calculate mean duration across all participants
meanTaskDuration = mean(participantDurations);

% Display results
fprintf('Mean task duration across all participants: %.2f seconds\n', meanTaskDuration);
fprintf('Mean task duration across all participants: %.2f minutes\n', meanTaskDuration/60);

% Optionally create a histogram of participant durations
figure;
histogram(participantDurations);
title('Distribution of Task Durations Across Participants');
xlabel('Duration (seconds)');
ylabel('Frequency');

%% Clean up
% Clear unused variables, keeping only the results for further analysis if needed
clearvars -except AlloData AlloData_Elderly_4MT HCData YCData AlloData_SPSS_Cond_Conf AlloData_SPSS_Cond_Conf_Block AlloData_SPSS_Cond_Conf_VirtualBlock config 
