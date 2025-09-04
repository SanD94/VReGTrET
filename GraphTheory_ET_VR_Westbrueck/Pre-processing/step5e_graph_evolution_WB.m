clear all;

%% adjust the following variables: savepath, current folder and participant list!-----------

COLLIDER_FILE = fullfile("additional_Files", "building_collider_list.csv");
savepath= [ 
    "D:\big-data\2025-westbrueck\preprocessing-pipeline\graphs\sess1", ...
    "D:\big-data\2025-westbrueck\preprocessing-pipeline\graphs\sess2", ...
    "D:\big-data\2025-westbrueck\preprocessing-pipeline\graphs\sess3"
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
    G = get_full_graph(COLLIDER_FILE, true);
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
    
    % remove all NH and sky elements
    q_nohouse = strcmp(gaze_seq_order,"NH");
    gaze_seq_order(q_nohouse) = [];

    sess_idx = 1;
    
    for i = 1:(length(gaze_seq_order)-1)
        fi = gaze_seq_order(i);
        se = gaze_seq_order(i + 1);
        if strcmp(se, "newSession")
            disp(cur_sessions(sess_idx));
            cur_G = G;
            cur_G = simplify(cur_G);
            cur_G = rmnode(cur_G, bad_nodes(1));
            cur_G = rmnode(cur_G, bad_nodes(2));
            save(fullfile(savepath(cur_sessions(sess_idx)), [num2str(currentPart) '_Graph_WB.mat']), 'cur_G');
            sess_idx = sess_idx + 1;
        end
        
        G = addedge(G, fi, se);
    end

end


disp(strcat(num2str(Number), ' Participants analysed'));
disp(strcat(num2str(countMissingPart),' files were missing'));

disp('done');