function result_table = extract_table_data(file_path)
    % load the MAT file
    loaded_data = load(file_path);
    
    % Get field names of the loaded structure
    field_names = fieldnames(loaded_data);
    
    % Extract the first field which should be our struct
    struct_data = loaded_data.(field_names{1});
    result_table = struct2table(struct_data);
    
    % Keep only the required fields
    result_table = result_table(:, {'sampleNr', 'clusterDuration', 'hitObjectColliderName'});
    result_table.clusterID = (1:height(result_table))';

    % Reorder columns to make clusterID first
    result_table = result_table(:, {'clusterID', 'sampleNr', 'clusterDuration', 'hitObjectColliderName'});
end