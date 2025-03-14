function graph_table = create_graph_table(folder_path)
% create_graph_table - Analyzes graph data from multiple user .mat files
%
% Inputs:
% folder_path - String containing the folder path with user graph files
%
% Outputs:
% result_table - Table with columns PID, nodes, and connection counts


% Get list of mat files with the required format
file_pattern = fullfile(folder_path, '*_Graph_WB.mat');
files = dir(file_pattern);

% Initialize variables to store results
all_pids = [];
all_nodes = [];
all_connections = [];

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
    g = user_data.(field_names{1});
    

    % Get node IDs and their degrees (number of connections)
    node_ids = g.Nodes.Name;
    degrees = degree(g, node_ids);
    
    % Store results
    user_id = repmat(pid, length(node_ids), 1);
    all_pids = [all_pids; user_id];
    all_nodes = [all_nodes; node_ids];
    all_connections = [all_connections; degrees];
end

% Create the output table
graph_table = table(all_pids, all_nodes, all_connections, ...
    'VariableNames', {'PID', 'nodes', 'connections'});
end
