function data_table = get_saturation_data(folder_path, participant_ids, file_format)
         
    data_table = table();
    
    % TODO: instead of a loop make it cell array and combine (vertcat)
    % Loop through each participant ID
    for pid = participant_ids
        file_name = fullfile(folder_path, [num2str(pid), file_format]);
    
        data_values = extract_saturation_data(file_name);
        data_values.PID = repmat(pid, height(data_values), 1);
                
        % Append to the main table
        data_table = [data_table; data_values]; 
    end

end

