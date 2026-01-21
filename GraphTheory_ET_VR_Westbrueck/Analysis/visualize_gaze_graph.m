%% visualize_gaze_graph - Generate gaze-based graph visualization per participant
%
% DESCRIPTION:
%   Creates a figure for each participant showing the gaze-based graph
%   (nodes represent gazed buildings, edges represent gaze transitions)
%   superimposed on the experimental map.
%
% AUTHOR: ampcode
% DATE: 2026

function visualize_gaze_graph(varargin)
    % Default configuration
    config = get_default_config();
    
    % Parse optional arguments
    config = parse_arguments(config, varargin);
    
    % Setup and validation
    setup_paths(config);
    validate_paths(config);
    
    % Load map and building data
    map = load_map(config);
    house_list = load_building_list(config);
    
    % Load gaze data and process
    [valid_participants, gaze_data_list] = load_gaze_data(config);
    
    % Generate visualization for each participant
    for participant_idx = 1:length(valid_participants)
        participant_id = valid_participants(participant_idx);
        gaze_data = gaze_data_list{participant_idx};
        
        % Build graph from gaze data
        [graph_obj, node_table] = build_gaze_graph(gaze_data);
        
        % Create and save figure
        fig = create_gaze_graph_figure(map, graph_obj, house_list, node_table, participant_id, config);
        
        if config.save_figure
            save_figure_per_participant(fig, participant_id, config);
        end
        
        close(fig);
    end
    
    disp(['Gaze graph visualization created successfully.']);
    disp(['Participants analyzed: ', num2str(length(valid_participants))]);
end


%% Helper Functions

function config = get_default_config()
    % Returns default configuration structure
    config = struct();
    
    % Paths (adjust for your system)
    config.data_dir = 'D:\big-data\2025-westbrueck\preprocessing-pipeline\noises-vs-gazes';
    config.image_dir = 'D:\big-data\additional_Files';
    config.collider_dir = 'D:\big-data\additional_Files';
    config.output_dir = 'D:\big-data\2025-westbrueck\preprocessing-pipeline\graph-images';
    
    % Participant list
    ids = [4003, 4004, 4005, 4006, 4007, 4008, 4009, 4010, 4011, 4012, 4013, 4014, 4015, 4016, 4017, 4018, 4019, 4020, ...
        4021, 4022, 4023, 4024, 4025, 4026, 4028, 4029, 4031, 4034];
    config.participants = ids;
    
    % Map configuration
    config.map_filename = 'map_natural_white_flipped.png';
    config.map_alpha = 0.3;
    
    % Coordinate transformation
    config.coord_scale = 4.2;
    config.coord_offset_x = 2050;
    config.coord_offset_z = 2050;
    
    % Figure configuration
    config.node_marker_size = 100;
    config.edge_color = 'black';
    config.edge_width = 1;
    config.node_color = 'black';
    config.save_figure = true;
    config.output_format = 'png';
    config.dpi = 140;
end


function config = parse_arguments(config, args)
    % Parse input arguments as name-value pairs
    for ii = 1:2:length(args)
        if ii + 1 <= length(args)
            config.(args{ii}) = args{ii + 1};
        end
    end
end


function setup_paths(config)
    % Create output directory if it doesn't exist
    if ~isfolder(config.output_dir)
        mkdir(config.output_dir);
    end
end


function validate_paths(config)
    % Validate that required directories exist
    if ~isfolder(config.data_dir)
        error(['Data directory not found: ', config.data_dir]);
    end
    if ~isfolder(config.image_dir)
        error(['Image directory not found: ', config.image_dir]);
    end
    if ~isfolder(config.collider_dir)
        error(['Collider list directory not found: ', config.collider_dir]);
    end
end


function map = load_map(config)
    % Load the experimental environment map image
    map_path = fullfile(config.image_dir, 'map_natural_white_flipped.png');
    map = imread(map_path);
end


function house_list = load_building_list(config)
    % Load building/house list with coordinates
    list_path = fullfile(config.collider_dir, 'building_collider_list.csv');
    full_list = readtable(list_path);
    
    % Get unique houses
    [~, unique_idx, ~] = unique(full_list.target_collider_name);
    house_list = full_list(unique_idx, :);
end


function [valid_participants, gaze_data_list] = load_gaze_data(config)
    % Load gaze data for all participants
    
    num_participants = length(config.participants);
    gaze_data_list = cell(num_participants, 1);
    valid_participants = [];
    valid_idx = 0;
    
    missing_participants = [];
    
    for ii = 1:num_participants
        participant_id = config.participants(ii);
        filename = fullfile(config.data_dir, sprintf('%d_gazes_data_WB.mat', participant_id));
        
        if ~isfile(filename)
            missing_participants = [missing_participants; participant_id];
            warning(['File not found: ', filename]);
            continue;
        end
        
        % Load gaze data
        valid_idx = valid_idx + 1;
        data = load(filename).gazes_data;
        gaze_data_list{valid_idx} = data;
        valid_participants = [valid_participants, participant_id];
    end
    
    % Trim cell array
    if valid_idx < num_participants
        gaze_data_list = gaze_data_list(1:valid_idx);
    end
    
    if ~isempty(missing_participants)
        disp(['Missing files for participants: ', num2str(missing_participants)]);
    end
end


function [graph_obj, node_table] = build_gaze_graph(gaze_data)
    % Build graph from gaze data
    %
    % RETURNS:
    %   graph_obj: MATLAB graph object
    %   node_table: Table of nodes in the graph
    
    % Remove NH (no house) and newSession entries
    nohouse = strcmp([gaze_data.hitObjectColliderName], {'NH'});
    newsess = strcmp([gaze_data.hitObjectColliderName], {'newSession'});
    remove_mask = nohouse | newsess;
    clean_data = gaze_data;
    clean_data(remove_mask) = [];
    
    % Create node table (unique houses)
    unique_houses = unique([clean_data.hitObjectColliderName])';
    node_table = cell2table(unique_houses, 'VariableNames', {'Name'});
    
    % Create edge table (gaze transitions)
    gaze_sequence = [clean_data.hitObjectColliderName]';
    
    % Build edges: each consecutive pair of gazes
    edge_source = gaze_sequence(1:end-1);
    edge_target = gaze_sequence(2:end);
    
    % Create EndNodes array (two-column cell array)
    end_nodes = [edge_source, edge_target];
    
    % Create edge table with EndNodes variable
    edge_table = table(end_nodes, 'VariableNames', {'EndNodes'});
    
    % Create graph object
    graph_obj = graph(edge_table, node_table);
    
    % Remove self-loops and duplicate edges
    graph_obj = simplify(graph_obj);
    
    % Remove 'noData' node if it exists
    if ismember('noData', graph_obj.Nodes.Name)
        graph_obj = rmnode(graph_obj, 'noData');
    end
end


function fig = create_gaze_graph_figure(map, graph_obj, house_list, node_table, participant_id, config)
    % Create figure showing gaze graph overlaid on map
    %
    % PARAMETERS:
    %   graph_obj: MATLAB graph object
    %   house_list: Table with building coordinates
    %   node_table: Table of nodes in the graph
    %   participant_id: ID of the participant
    
    fig_title = sprintf('Gaze Graph - Participant %d', participant_id);
    fig = figure('Name', fig_title, 'NumberTitle', 'off');
    fig.Position = [100, 100, 1200, 900];
    
    % Display map
    imshow(map);
    alpha(config.map_alpha);
    hold on;
    
    % Get node positions from building list
    node_names = node_table.Name;
    node_indices = ismember(house_list.target_collider_name, node_names);
    node_x = house_list.transformed_collidercenter_x(node_indices);
    node_y = house_list.transformed_collidercenter_y(node_indices);
    
    % Plot edges
    edge_cell = graph_obj.Edges.EndNodes;
    for ee = 1:height(edge_cell)
        source_node = edge_cell{ee, 1};
        target_node = edge_cell{ee, 2};
        
        % Find indices in building list
        source_idx = find(strcmp(house_list.target_collider_name, source_node));
        target_idx = find(strcmp(house_list.target_collider_name, target_node));
        
        if ~isempty(source_idx) && ~isempty(target_idx)
            x1 = house_list.transformed_collidercenter_x(source_idx);
            y1 = house_list.transformed_collidercenter_y(source_idx);
            
            x2 = house_list.transformed_collidercenter_x(target_idx);
            y2 = house_list.transformed_collidercenter_y(target_idx);
            
            line([x1, x2], [y1, y2], 'Color', config.edge_color, 'LineWidth', config.edge_width);
        end
    end
    
    % Plot nodes
    scatter(node_x, node_y, config.node_marker_size, config.node_color, 'filled');
    
    % Set coordinate system
    set(gca, 'xdir', 'normal', 'ydir', 'normal');
    
    % Labels and formatting
    xlabel('X Position');
    ylabel('Z Position');
    title(fig_title);
    grid on;
    
    hold off;
end


function save_figure_per_participant(fig, participant_id, config)
    % Save individual participant figure to disk
    
    output_path = fullfile(config.output_dir, ...
                          sprintf('gaze_graph_participant_%d.%s', participant_id, config.output_format));
    
    exportgraphics(fig, output_path, 'Resolution', config.dpi);
    disp(['Figure saved to: ', output_path]);
end
