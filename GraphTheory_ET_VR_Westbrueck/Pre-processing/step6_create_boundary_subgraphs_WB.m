%% adjust the following variables: savepath and participant list!-----------
data_path = "data";


% participants with VR training less than 30% data loss
PartList = {1007};

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
    save(fullfile(data_path, [num2str(currentPart) '_subgraphs_WB.mat']),'iG', 'oG', 'xG');
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