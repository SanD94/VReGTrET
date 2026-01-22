%% visualize_walking_paths - Generate walking path visualization
%
% DESCRIPTION:
%   Creates a figure for each participant showing their walking paths
%   overlaid on the experimental map. Uses configuration from external
%   JSON files for paths and parameters.
%
% AUTHOR: Jasmin Walter
% DATE: 2024

function visualize_walking_paths(varargin)
    % Load configuration from file
    config = load_config(varargin{:});
    
    % Extract visualization-specific config
    vis_config = config.walking_paths_visualization;
    
    % Setup and validation
    setup_paths(config);
    
    % Load data
    [walking_paths_x, walking_paths_z, participants] = extract_walking_paths(config);
    
    % Load map
    map = load_map(config);
    
    % Generate visualization for each participant
    for participant_idx = 1:length(participants)
        fig = create_walking_path_figure_per_participant(map, walking_paths_x, walking_paths_z, ...
            participants(participant_idx), participant_idx, config, vis_config);
        
        % Save figure
        if vis_config.save_figure
            save_figure_per_participant(fig, participants(participant_idx), config, vis_config);
        end
        
        close(fig);
    end
    
    disp(['Walking path visualization created successfully.']);
    disp(['Participants analyzed: ', num2str(length(participants))]);
end


%% Helper Functions

function setup_paths(config)
    % Create output directory if it doesn't exist
    if ~isfolder(config.paths.output_walking_paths)
        mkdir(config.paths.output_walking_paths);
    end
end


function [walking_paths_x, walking_paths_z, valid_participants] = extract_walking_paths(config)
    % Extract walking paths from participant data files
    %
    % Uses actual trajectory length from each participant's data file
    % (participants may have different trajectory lengths)
    %
    % RETURNS:
    %   walking_paths_x: cell array of x coordinates per participant
    %   walking_paths_z: cell array of z coordinates per participant
    %   valid_participants: list of successfully loaded participant IDs
    
    num_participants = length(config.participants);
    walking_paths_x = cell(num_participants, 1);
    walking_paths_z = cell(num_participants, 1);
    
    missing_participants = [];
    valid_idx = 0;
    
    for ii = 1:num_participants
        participant_id = config.participants(ii);
        filename = fullfile(config.paths.walking_paths_data_dir, ...
                           sprintf('%d_interpolatedColliders_5Sessions_WB.mat', participant_id));
        
        if ~isfile(filename)
            missing_participants = [missing_participants; participant_id];
            warning(['File not found: ', filename]);
            continue;
        end
        
        % Load and extract data
        valid_idx = valid_idx + 1;
        data = load(filename).interpolatedData;
        
        % Extract coordinates for all timepoints from struct array
        x_trajectory = [data.playerBodyPosition_x]';
        z_trajectory = [data.playerBodyPosition_z]';
        
        % Store in cell arrays
        walking_paths_x{valid_idx} = x_trajectory;
        walking_paths_z{valid_idx} = z_trajectory;
    end
    
    % Trim cell arrays to valid participants only
    if valid_idx < num_participants
        walking_paths_x = walking_paths_x(1:valid_idx);
        walking_paths_z = walking_paths_z(1:valid_idx);
    end
    
    valid_participants = config.participants(1:valid_idx);
    
    if ~isempty(missing_participants)
        disp(['Missing files for participants: ', num2str(missing_participants)]);
    end
end


function map = load_map(config)
    % Load the experimental environment map image
    map_path = fullfile(config.paths.image_dir, config.map.filename);
    map = imread(map_path);
end


function fig = create_walking_path_figure_per_participant(map, walking_paths_x, walking_paths_z, ...
                                                          participant_id, participant_idx, config, vis_config)
    % Create figure showing walking path for a single participant overlaid on map
    %
    % PARAMETERS:
    %   participant_id: ID of the participant
    %   participant_idx: Index of the participant in the data cell arrays
    
    fig_title = sprintf('Walking Path - Participant %d', participant_id);
    fig = figure('Name', fig_title, 'NumberTitle', 'off');
    fig.Position = [100, 100, 1200, 900];
    
    % Display map
    imshow(map);
    alpha(config.map.alpha);
    hold on;
    
    % Extract trajectory for this participant (variable length)
    x_trajectory = walking_paths_x{participant_idx};
    z_trajectory = walking_paths_z{participant_idx};
    
    % Transform coordinates
    x_coords = x_trajectory * config.coordinate_transform.scale + config.coordinate_transform.offset_x;
    z_coords = z_trajectory * config.coordinate_transform.scale + config.coordinate_transform.offset_z;
    
    % Use marker color from config
    scatter(x_coords, z_coords, vis_config.marker_size, vis_config.marker_color, 'filled');
    
    % Set coordinate system
    set(gca, 'xdir', 'normal', 'ydir', 'normal');
    
    % Labels and formatting
    xlabel('X Position');
    ylabel('Z Position');
    title(fig_title);
    grid on;
    
    hold off;
end


function save_figure_per_participant(fig, participant_id, config, vis_config)
    % Save individual participant figure to disk
    
    output_path = fullfile(config.paths.output_walking_paths, ...
                          sprintf('walking_path_participant_%d.%s', participant_id, vis_config.output_format));
    
    exportgraphics(fig, output_path, 'Resolution', vis_config.dpi);
    disp(['Figure saved to: ', output_path]);
end
