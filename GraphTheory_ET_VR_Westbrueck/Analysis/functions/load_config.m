function config = load_config(varargin)
    % Load configuration from JSON files
    %
    % DESCRIPTION:
    %   Loads default configuration from config/default_config.json
    %   and optionally merges with local_config.json if it exists.
    %   Command-line arguments override file settings.
    %
    % USAGE:
    %   config = load_config()
    %   config = load_config('participants', [1004 1005], 'dpi', 200)
    %
    % PARAMETERS:
    %   varargin: name-value pairs to override config values
    %
    % RETURNS:
    %   config: struct containing all configuration parameters
    
    % Get the script directory
    script_dir = fileparts(mfilename('fullpath'));
    config_dir = fullfile(script_dir, '..', 'config');
    
    % Load default config
    default_config_file = fullfile(config_dir, 'default_config.json');
    if ~isfile(default_config_file)
        error(['Default config file not found: ', default_config_file]);
    end
    
    config = read_json(default_config_file);
    
    % Load and merge local config if it exists
    local_config_file = fullfile(config_dir, 'local_config.json');
    if isfile(local_config_file)
        local_config = read_json(local_config_file);
        config = merge_configs(config, local_config);
    end
    
    % Override with command-line arguments
    config = parse_arguments(config, varargin);
    
    % Validate configuration
    validate_config(config);
end


function config = read_json(filepath)
    % Read JSON file into struct
    
    fid = fopen(filepath, 'r');
    if fid == -1
        error(['Cannot open file: ', filepath]);
    end
    
    raw_text = fread(fid, inf, 'char')';
    fclose(fid);
    
    % Use jsondecode (available in MATLAB R2016b+)
    config = jsondecode(raw_text);
end


function config = merge_configs(default_cfg, local_cfg)
    % Recursively merge local config into default config
    
    config = default_cfg;
    fields = fieldnames(local_cfg);
    
    for ii = 1:length(fields)
        field = fields{ii};
        
        if isstruct(local_cfg.(field)) && isstruct(default_cfg.(field))
            % Recursively merge nested structs
            config.(field) = merge_configs(default_cfg.(field), local_cfg.(field));
        else
            % Override with local value
            config.(field) = local_cfg.(field);
        end
    end
end


function config = parse_arguments(config, args)
    % Override config values with command-line arguments
    
    for ii = 1:2:length(args)
        if ii + 1 <= length(args)
            key = args{ii};
            value = args{ii + 1};
            
            % Handle nested keys with dot notation (e.g., 'paths.output_walking_paths')
            if contains(key, '.')
                parts = strsplit(key, '.');
                current = config;
                for jj = 1:length(parts)-1
                    if ~isfield(current, parts{jj})
                        current.(parts{jj}) = struct();
                    end
                    current = current.(parts{jj});
                end
                current.(parts{end}) = value;
            else
                config.(key) = value;
            end
        end
    end
end


function validate_config(config)
    % Validate that required config fields and paths exist
    
    % Check required top-level fields
    required_fields = {'paths', 'participants', 'map', 'coordinate_transform'};
    for ii = 1:length(required_fields)
        if ~isfield(config, required_fields{ii})
            error(['Missing required config field: ', required_fields{ii}]);
        end
    end
    
    % Check that participants is not empty
    if isempty(config.participants)
        error('Participants list is empty in config');
    end
    
    % Warn about non-existent paths (don't error, as some might be created)
    paths_to_check = {'image_dir', 'collider_dir'};
    for ii = 1:length(paths_to_check)
        if isfield(config.paths, paths_to_check{ii})
            path_value = config.paths.(paths_to_check{ii});
            if ~isfolder(path_value)
                warning(['Path does not exist: ', path_value]);
            end
        end
    end
end
