%% visualize_walking_paths - Generate walking path visualization
%
% DESCRIPTION:
%   Creates a figure showing all participants' walking paths overlaid on
%   the experimental map. Extracts walking paths from participant data
%   and visualizes them with distinct colors.
%
% AUTHOR: ampcode
% DATE: 2026

function visualize_walking_paths(varargin)
% Default configuration
config = get_default_config();

% Parse optional arguments
config = parse_arguments(config, varargin);

% Setup and validation
setup_paths(config);
validate_paths(config);

% Load data
[walking_paths_x, walking_paths_z, participants] = extract_walking_paths(config);

% Load map
map = load_map(config);

% Generate visualization for each participant
for participant_idx = 1:length(participants)
    fig = create_walking_path_figure_per_participant(map, walking_paths_x, walking_paths_z, ...
        participants(participant_idx), participant_idx, config);

    % Save figure
    if config.save_figure
        save_figure_per_participant(fig, participants(participant_idx), config);
    end

    close(fig);
end

disp(['Walking path visualization created successfully.']);
disp(['Participants analyzed: ', num2str(length(participants))]);
end


%% Helper Functions

function config = get_default_config()
% Returns default configuration structure
config = struct();

% Paths (adjust for your system)
config.data_dir = 'D:\big-data\2025-westbrueck\preprocessing-pipeline\interpolated-colliders';
config.image_dir = 'D:\big-data\additional_Files';
config.collider_dir = 'D:\big-data\additional_Files';
config.output_dir = 'D:\big-data\2025-westbrueck\preprocessing-pipeline\path-images';

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
config.marker_size = 15;
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
        filename = fullfile(config.data_dir, ...
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
        disp(['Missing files: ', num2str(missing_participants)]);
    end
end


function map = load_map(config)
% Load the experimental environment map image
%
% NOTE: The map is flipped on vertical axis to match MATLAB coordinate system

map_path = fullfile(config.image_dir, config.map_filename);
map = imread(map_path);
end


function fig = create_walking_path_figure_per_participant(map, walking_paths_x, walking_paths_z, ...
                                                          participant_id, participant_idx, config)
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
    alpha(config.map_alpha);
    hold on;
    
    % Extract trajectory for this participant (variable length)
    x_trajectory = walking_paths_x{participant_idx};
    z_trajectory = walking_paths_z{participant_idx};
    
    % Transform coordinates
    x_coords = x_trajectory * config.coord_scale + config.coord_offset_x;
    z_coords = z_trajectory * config.coord_scale + config.coord_offset_z;
    
    % Use a distinct color (e.g., blue)
    scatter(x_coords, z_coords, config.marker_size, [0.2 0.4 0.8], 'filled');
    
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
%
% PARAMETERS:
%   participant_id: ID of the participant

output_path = fullfile(config.output_dir, ...
    sprintf('walking_path_participant_%d.%s', participant_id, config.output_format));

exportgraphics(fig, output_path, 'Resolution', config.dpi);
disp(['Figure saved to: ', output_path]);
end
