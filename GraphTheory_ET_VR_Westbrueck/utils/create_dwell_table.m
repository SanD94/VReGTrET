function dwell_table = create_dwell_table(folder_path)
% create_graph_table - Analyzes graph data from multiple user .mat files
%
% Inputs:
% folder_path - String containing the folder path with user graph files
%
% Outputs:
% result_table - Table with columns PID, nodes, and connection counts


% Get list of mat files with the required format
file_pattern = fullfile(folder_path, '4*_Dwell_WB.mat');
files = dir(file_pattern);

dwell_table = table('Size', [0 3], ...
          'VariableTypes', {'double', 'string', 'double'}, ...
          'VariableNames', {'PID', 'hitObjectColliderName', 'dwellTime'});

% Process each user file
for user_file = files'
    % Get full file path
    file_path = fullfile(folder_path, user_file.name);

    % Extract PID from filename
    [~, filename, ~] = fileparts(user_file.name);
    parts = strsplit(filename, '_');
    pid = str2double(parts{1});
    
    
    % Load the graph data
    user_data = load(file_path);

     % Get field names of the loaded structure
    field_names = fieldnames(user_data);
    
    % Extract graph object, assuming there is only one data
    cur_table = user_data.(field_names{1});
    


    % Store results
    user_id = repmat(pid, height(cur_table), 1);
    cur_table.PID = user_id;
    dwell_table = [dwell_table; cur_table];
    
end

end
