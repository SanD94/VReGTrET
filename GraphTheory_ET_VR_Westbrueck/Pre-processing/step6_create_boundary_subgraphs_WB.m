%% adjust the following variables: savepath and participant list!-----------
data_path = "F:\big-data\vr_data\Data\preprocessing-pipeline\graphs";


% participants with VR training less than 30% data loss
PartList = { 4003 4004 4005 4006 4007 4008 4009 4010 4011 4012 4013 4014 4015 4016 4017 4018 4019 4020 4021 4022 4023 4024 4025 4026 4028 4029 4031 4034 };

%-------------------------------------------------------------------------------

Number = length(PartList);

for ii = 1:Number
    currentPart = cell2mat(PartList(ii));
    
    
    file_name = fullfile(data_path, ...
        strcat(num2str(currentPart),'_Graph_WB.mat'));
 
    %%% main code
        
    % load graph
    load(file_name);
    inside_query = G.Nodes.inside == true;

    iG = subgraph(G, G.Nodes.Name(inside_query));
    oG = subgraph(G, G.Nodes.Name(~inside_query));
    % inside -- outside xor from edges to create subgraph
    fi_inside = get_connected_nodes(G.Edges.EndNodes(:, 1), G);
    se_inside = get_connected_nodes(G.Edges.EndNodes(:, 2), G);
    xor_inside = xor(fi_inside, se_inside);


    xor_edges = G.Edges(xor_inside, :);
    xor_nodes = get_nodes(unique(reshape(xor_edges.EndNodes, [], 1)), G);
    xG = graph(xor_edges, xor_nodes);
    
    %% save subgraphs
    save(fullfile(data_path, [num2str(currentPart) '_subgraphs_WB.mat']), 'G', 'iG', 'oG', 'xG');
    %%%

end


disp(strcat(num2str(Number), ' Participants analysed'));
disp('done');

% get only inside column of connected nodes
function connected = get_connected_nodes(names, G)
    [r, ~] = find(string(names)' == string(G.Nodes.Name));
    connected = G.Nodes.inside(r);
end

function nodes = get_nodes(names, G)
    [r, ~] = find(string(names)' == string(G.Nodes.Name));
    nodes = G.Nodes(r,:);
end