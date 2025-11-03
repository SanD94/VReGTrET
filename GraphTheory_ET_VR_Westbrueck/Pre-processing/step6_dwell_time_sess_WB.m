clear all;

%% adjust the following variables: savepath, current folder and participant list!-----------

COLLIDER_FILE = fullfile("additional_Files", "building_collider_list.csv");
savepath= [ 
    "D:\big-data\2025-westbrueck\preprocessing-pipeline\dwell-time\sess1", ...
    "D:\big-data\2025-westbrueck\preprocessing-pipeline\dwell-time\sess2", ...
    "D:\big-data\2025-westbrueck\preprocessing-pipeline\dwell-time\sess3"
];
data_path = "D:\big-data\2025-westbrueck\preprocessing-pipeline\noises-vs-gazes";


% participants with VR training less than 30% data loss

PartList = { ...
    4003, 4005, 4006, 4007, 4008, 4009, 4010, 4012, ...
    4013, 4014, 4015, 4016, 4017, 4018, 4019, 4020, ...
    4021, 4022, 4023, 4024, 4026, 4029, 4031, 4034 ...
};
%-------------------------------------------------------------------------------
% it's written by hand by checking the raw data.
sess_list = { ... // same order with partlist
    [1, 1, 2, 3], [1, 2, 3], [1, 2, 3], [1, 2, 3], ...
    [1, 2, 3], [1, 2, 3], [1, 2, 2, 3, 3], [1, 1, 2, 3], ...
    [1, 2, 3], [1, 2, 2, 3], [1, 2, 2, 3], [1, 2, 3], ...
    [1, 2, 3], [1, 2, 2, 3, 3], [1, 2, 3], [1, 2, 2, 3], ...
    [1, 2, 3], [1, 2, 3], [1, 2, 3], [1, 2, 3], ...
    [1, 2, 3], [1, 2, 3], [1, 1, 1, 2, 3], [1, 2, 3] ...
};


Number = length(PartList);
noFilePartList = [];
countMissingPart = 0;
bad_nodes = ["noData", "newSession"];



for ii = 1:Number
    currentPart = cell2mat(PartList(ii));
    cur_sessions = sess_list{ii};
    
    
    file = fullfile(data_path, ...
        strcat(num2str(currentPart),'_gazes_data_WB.mat'));
 
    % check for missing files
    if exist(file) == 0
        countMissingPart = countMissingPart+1;
        
        noFilePartList = [noFilePartList;currentPart];
        disp(strcat(file,' does not exist in folder'));
        continue;
    end
    %%% main code
        
    % load data
    gazesData = load(file);
    gaze_seq_order = string([gazesData.gazes_data.hitObjectColliderName]);
    gaze_dwell_time = [gazesData.gazes_data.clusterDuration];
    
    % remove all NH and sky elements
    q_nohouse = strcmp(gaze_seq_order,"NH");
    gaze_seq_order(q_nohouse) = [];
    gaze_dwell_time(q_nohouse) = [];

    sess_idx = 1;

    dwell_table = table('Size', [0 2], ...
          'VariableTypes', {'string', 'double'}, ...
          'VariableNames', {'hitObjectColliderName', 'dwellTime'});
    for i = 1:length(gaze_seq_order)
        fi = gaze_seq_order(i);
        fi_t = gaze_dwell_time(i);
        if strcmp(fi, "newSession")
            disp(cur_sessions(sess_idx));
            query = ismember(dwell_table.hitObjectColliderName, bad_nodes);
            dwell_table = dwell_table(~query, :);

            save(fullfile(savepath(cur_sessions(sess_idx)), [num2str(currentPart) '_Dwell_WB.mat']), 'dwell_table');
            sess_idx = sess_idx + 1;
            continue;
        end
        cur_row = table(fi, fi_t, ...
            'VariableNames', {'hitObjectColliderName', 'dwellTime'});
        dwell_table = [dwell_table; cur_row];
    end

end


disp(strcat(num2str(Number), ' Participants analysed'));
disp(strcat(num2str(countMissingPart),' files were missing'));

disp('done');