clear all;

%% adjust the following variables: savepath, current folder and participant list!-----------

COLLIDER_FILE = fullfile("additional_Files", "building_collider_list.csv");
savepath= "D:\big-data\2025-westbrueck\preprocessing-pipeline\graph-saturation";
data_path = "D:\big-data\2025-westbrueck\preprocessing-pipeline\noises-vs-gazes";


% participants with VR training less than 30% data loss

PartList = { ...
    4003, 4005, 4006, 4007, 4008, 4009, 4010, 4012, ...
    4013, 4014, 4015, 4016, 4017, 4018, 4019, 4020, ...
    4021, 4022, 4023, 4024, 4026, 4029, 4031, 4034 ...
};
%-------------------------------------------------------------------------------

Number = length(PartList);
noFilePartList = [];
countMissingPart = 0;
bad_nodes = ["noData", "newSession"];



for ii = 1:Number
    G = get_full_graph(COLLIDER_FILE, true);
    currentPart = cell2mat(PartList(ii));
    
    
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

    elem_x = zeros(length(gaze_seq_order)-1, 1);
    elem_y = zeros(length(gaze_seq_order)-1, 1);
    cur = 0;
    for i = 1:(length(gaze_seq_order)-1)
        fi = gaze_seq_order(i);
        se = gaze_seq_order(i + 1);
        if ~any(strcmp(fi, bad_nodes)) && ~any(strcmp(se, bad_nodes)) && ~strcmp(fi, se)
            if findedge(G, fi, se) == 0
                cur = cur + 1;
            end
        end
        G = addedge(G, fi, se);
        elem_y(i) = cur / height(G.Edges);
        elem_x(i) = i;
        
    end
    

    elem_x = elem_x / length(elem_x);
    % elem_y = elem_y / height(G.Edges);
    G = simplify(G);
      
    %% remove node noData and newSession from graph
    G = rmnode(G, 'noData');
    G = rmnode(G, 'newSession');
    

    
    %% save graph
    save(fullfile(savepath, [num2str(currentPart) '_saturation_WB.mat']), 'currentPart', 'elem_x', 'elem_y');
    %%%

end


disp(strcat(num2str(Number), ' Participants analysed'));
disp(strcat(num2str(countMissingPart),' files were missing'));

csvwrite(fullfile(savepath, 'Missing_Participant_Files'),noFilePartList);
disp('saved missing participant file list');

disp('done');