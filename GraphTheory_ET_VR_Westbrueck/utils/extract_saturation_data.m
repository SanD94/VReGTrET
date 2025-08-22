function result_table = extract_saturation_data(file_path)
    % load the MAT file
    loaded_data = load(file_path);
    
    time = loaded_data.elem_x;
    graph_saturation = loaded_data.elem_y;
    

    result_table = table(time, graph_saturation);
end

