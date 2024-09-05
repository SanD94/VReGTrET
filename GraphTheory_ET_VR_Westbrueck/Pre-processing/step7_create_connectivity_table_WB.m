%% adjust the following variables: savepath and participant list!-----------
data_path = fullfile("..", "Data", "preprocessing-pipeline", "graphs");


% participants with VR training less than 30% data loss
PartList = {2002, 2005, 2008, 2009, 2015, 2016, 2017, 2018, 2024, 2006, 2007, 2013, 2014, 2021, 2020, 2025};
Group = ["Control","Control","Control","Control","Control","Control","Control","Control","Control", ...
    "Glaucoma","Glaucoma","Glaucoma","Glaucoma","Glaucoma","Glaucoma", "Glaucoma"];

%-------------------------------------------------------------------------------

Number = length(PartList);
id = zeros(Number, 1);
group = strings(Number, 1);
inside_connectivity_mean = zeros(Number, 1);
outside_connectivity_mean = zeros(Number, 1);
xor_connectivity_mean = zeros(Number, 1);
g_connectivity_mean = zeros(Number, 1);

inside_connectivity_sd = zeros(Number, 1);
outside_connectivity_sd = zeros(Number, 1);
xor_connectivity_sd = zeros(Number, 1);
g_connectivity_sd = zeros(Number, 1);


for ii = 1:Number
    currentPart = cell2mat(PartList(ii));
    
    
    graph_file_name = fullfile(data_path, ...
        strcat(num2str(currentPart),'_Graph_WB.mat'));
    subgraph_file_name = fullfile(data_path, ...
        strcat(num2str(currentPart),'_subgraphs_WB.mat'));
    %%% main code
        
    % load data
    load(subgraph_file_name); % G, iG, oG, xG
    
    
    ic = centrality(iG, "degree");
    oc = centrality(oG, "degree");
    xc = centrality(xG, "degree");
    gc = centrality(G, "degree");

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
    g_connectivity_mean(ii) = mean(gc);

    inside_connectivity_sd(ii) = std(ic);
    outside_connectivity_sd(ii) = std(oc);
    xor_connectivity_sd(ii) = std(xc); % TODO : find proper definition
    g_connectivity_sd(ii) = std(gc);


    group(ii) = Group(ii);
end

connectivity_table = table;
connectivity_table.id = id;
connectivity_table.group = group;
connectivity_table.inside_connectivity_mean = inside_connectivity_mean;
connectivity_table.outside_connectivity_mean = outside_connectivity_mean;
connectivity_table.xor_connectivity_mean = xor_connectivity_mean;
connectivity_table.g_connectivity_mean = g_connectivity_mean;

connectivity_table.inside_connectivity_sd = inside_connectivity_sd;
connectivity_table.outside_connectivity_sd = inside_connectivity_sd;
connectivity_table.xor_connectivity_sd = xor_connectivity_sd;
connectivity_table.g_connectivity_std = g_connectivity_sd;

writetable(connectivity_table, fullfile(data_path, "connectivity.csv"));