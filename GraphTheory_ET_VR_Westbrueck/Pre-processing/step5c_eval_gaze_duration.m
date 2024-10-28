%% ------------------ step5_optional_create_Graphs_WB----------------------

% --------------------script written by Jasmin L. Walter-------------------
% -----------------------jawalter@uni-osnabrueck.de------------------------

% Description: 
% 5th and last step of preprocessing pipeline.
% The script creates the gaze graphs from the gaze events
% The script creates unweighted and binary graph objects the gaze events. 
% To achieve this it removes all repetition and self references from graphs
% and removes noData node after creation of graph

% Input:  
% {PID}_gazes_data_WB.mat = a new data file containing all gazes

% Output:
% {PID}_Graph_WB.mat = the gaze graph object for every participant
% Missing_Participant_Files = contains all participant numbers where the
%                                  data file could not be loaded


clear all;

%% adjust the following variables: savepath, current folder and participant list!-----------

COLLIDER_FILE = fullfile("..", "additional_Files", "building_collider_list.csv");
savepath= "F:\big-data\vr_data\Data\preprocessing-pipeline\gaze-duration";
data_path = "F:\big-data\vr_data\Data\preprocessing-pipeline\noises-vs-gazes";


% participants with VR training less than 30% data loss
PartList = {2002, 2005, 2008, 2009, 2015, 2016, 2017, 2018, 2024, 2006, 2007, 2013, 2014, 2021, 2020, 2025};


%-------------------------------------------------------------------------------

Number = length(PartList);
noFilePartList = [];
countMissingPart = 0;



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
    gaze_duration_building = [gazesData.]
    
    % remove all NH and sky elements
    q_nohouse = strcmp(gaze_seq_order,"NH");
    gaze_seq_order(q_nohouse) = [];

    G = addedge(G, gaze_seq_order(1:end-1), gaze_seq_order(2:end));
    G = simplify(G);
    
    
    %% remove node noData and newSession from graph
    G = rmnode(G, 'noData');
    G = rmnode(G, 'newSession');
    
    %% save graph
    save(fullfile(savepath, [num2str(currentPart) '_Graph_WB.mat']),'G');
    %%%

end


disp(strcat(num2str(Number), ' Participants analysed'));
disp(strcat(num2str(countMissingPart),' files were missing'));

csvwrite(fullfile(savepath, 'Missing_Participant_Files'),noFilePartList);
disp('saved missing participant file list');

disp('done');