function graph = extract_graph_data(file_path)
    loaded_data = load(file_path);
    
    % Get field names of the loaded structure
    field_names = fieldnames(loaded_data);
    
    % Extract the first field which should be our struct
    struct_data = loaded_data.(field_names{1});

    

    graph = struct_data;
end

