%% adjust the following variables: savepath and participant list!-----------
data_path = "data";


% participants with VR training less than 30% data loss
PartList = {1007};

%-------------------------------------------------------------------------------

Number = length(PartList);
id = zeros(1, Number);
group = strings(1, Number);
inside_connectivity_mean = zeros(1, Number);
outside_connectivity_mean = zeros(1, Number);
xor_connectivity_mean = zeros(1, Number);

inside_connectivity_sd = zeros(1, Number);
outside_connectivity_sd = zeros(1, Number);
xor_connectivity_sd = zeros(1, Number);


for ii = 1:Number
    currentPart = cell2mat(PartList(ii));
    
    
    graph_file_name = fullfile(data_path, ...
        strcat(num2str(currentPart),'_Graph_WB.mat'));
    subgraph_file_name = fullfile(data_path, ...
        strcat(num2str(currentPart),'_subgraphs_WB.mat'));
    %%% main code
        
    % load data
    load(subgraph_file_name); % iG, oG, xG
    
    
    ic = centrality(iG, "degree");
    oc = centrality(oG, "degree");
    xc = centrality(xG, "degree");

    id(ii) = PartList{ii};

    %% TODO: Discuss.
    % max_connected_no = max(height(iG.Nodes), height(oG.Nodes));
    % inside_connectivity_mean(ii) = sum(ic) / (length(ic) - 1);
    % outside_connectivity_mean(ii) = sum(oc) / (length(oc) - 1);
    % xor_connectivity_mean(ii) = sum(xc) / max_connected_no;
    %%
    inside_connectivity_mean(ii) = mean(ic);
    outside_connectivity_mean(ii) = mean(oc);
    xor_connectivity_mean(ii) = mean(xc);

    inside_connectivity_sd(ii) = std(ic);
    outside_connectivity_sd(ii) = std(oc);
    xor_connectivity_sd(ii) = std(xc); % TODO : find proper definition
    % TODO: Add group
end

connectivity_table = table;
connectivity_table.id = id;
connectivity_table.inside_connectivity_mean = inside_connectivity_mean;
connectivity_table.outside_connectivity_mean = outside_connectivity_mean;
connectivity_table.xor_connectivity_mean = xor_connectivity_mean;

connectivity_table.inside_connectivity_sd = inside_connectivity_sd;
connectivity_table.outside_connectivity_sd = inside_connectivity_sd;
connectivity_table.xor_connectivity_sd = xor_connectivity_sd;

writetable(connectivity_table, fullfile(data_path, "connectivity.csv"));