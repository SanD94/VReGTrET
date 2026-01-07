function data_table = get_distance_graph(folder_path, participant_ids, file_format)
    data_table = table();
    
    % TODO: instead of a loop make it cell array and combine (vertcat)
    % Loop through each participant ID
    for pid = participant_ids
        file_name = fullfile(folder_path, [num2str(pid), file_format]);
        cur_table = table();
        
        g = extract_graph_data(file_name);

        cur_table.PID = pid;      
        dg = distances(g);
        dg(dg == Inf) = 0;
        cur_table.diameter = max(dg, [], 'all');
                
        % Append to the main table
        data_table = [data_table; cur_table]; 
    end
end