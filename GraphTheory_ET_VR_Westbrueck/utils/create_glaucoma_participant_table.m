% Currently supports only glaucoma study with extensions
function participant_table = create_glaucoma_participant_table(folder_path)
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
    
    % Filter out invalid participant IDs
    valid_ids = [
        2002, 2005, 2008, 2009, 2015, 2016, 2017, 2018, 2024, ... % control
        2006, 2007, 2013, 2014, 2021, 2020, 2025, 5005, 5006 ... % glaucoma
        ];
    query = any(participant_ids == valid_ids', 1);
    participant_ids = participant_ids(query);
    
    % Determine categories based on the participant ID
    categories = [repmat("control", 1, 9) repmat("glaucoma", 1, 9)];
    
    % Create a table with the data
    participant_table = table(participant_ids', categories', 'VariableNames', {'PID', 'category'});
end
