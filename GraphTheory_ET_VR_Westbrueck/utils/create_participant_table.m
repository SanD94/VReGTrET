% Currently supports participant IDs in 4Ks
function participant_table = create_participant_table(folder_path)
    % Creates a table of participant IDs and categories from filenames
    %
    % Parameters:
    %   folder_path - Path to the folder containing data files (optional)
    %
    % Returns:
    %   participant_table - Table with ParticipantID and Category columns
    
    % Get all .mat files in the specified directory
    files = dir(fullfile(folder_path, '*_gazes_data_WB.mat'));
    
    % Extract participant IDs (first 4 characters of each filename)
    participant_ids = str2double(cellfun(@(x) x(1:4), {files.name}, 'UniformOutput', false));
    
    % Filter out invalid participant IDs (outside the range [4000, 4999])
    valid_ids = participant_ids >= 4000 & participant_ids < 5000;
    participant_ids = participant_ids(valid_ids);
    
    % Determine categories based on the participant ID
    categories = get_category(participant_ids);
    
    % Create a table with the data
    participant_table = table(participant_ids', categories', 'VariableNames', {'PID', 'category'});
end

% Helper function to determine the category based on the participant ID
function category = get_category(participant_ids)
    groups = ["central", "peripheral", "control"];
    remainder = mod(participant_ids, 3) + 1;

    category = groups(remainder);
end