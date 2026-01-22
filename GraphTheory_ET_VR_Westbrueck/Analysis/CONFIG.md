# Configuration Management

This project uses JSON-based configuration files for all paths and parameters. This approach separates configuration from code and allows different users to have different local settings without modifying code.

## Configuration Structure

```
Analysis/
├── config/
│   ├── default_config.json          # Default configuration (tracked in git)
│   ├── local_config.json            # User-specific overrides (gitignored)
│   ├── local_config.example.json    # Template for local_config.json
│   └── .gitignore
├── functions/
│   ├── load_config.m                # Configuration loader
│   ├── visualize_walking_paths.m    # Walking path visualization
│   └── visualize_gaze_graph.m       # Gaze graph visualization
└── ...
```

## Setup

### First Time Setup

1. Copy the example local configuration:
   ```bash
   cp config/local_config.example.json config/local_config.json
   ```

2. Edit `config/local_config.json` with your local paths:
   ```json
   {
     "paths": {
       "walking_paths_data_dir": "/your/local/path/to/data",
       "gaze_data_dir": "/your/local/path/to/data",
       "image_dir": "/your/local/path/to/images",
       "collider_dir": "/your/local/path/to/colliders",
       "output_walking_paths": "/your/local/path/to/output",
       "output_gaze_graph": "/your/local/path/to/output"
     }
   }
   ```

### Adding New Users

Each user should:
1. Create their own `local_config.json` (never commit this file)
2. The file is automatically gitignored
3. The config loader will merge their local settings with defaults

## Configuration Priority

Settings are loaded in this order (later overrides earlier):
1. `default_config.json` (checked into git)
2. `local_config.json` (user-specific, gitignored)
3. Command-line arguments (highest priority)

## Usage

### With Defaults and Local Config
```matlab
% Uses config/default_config.json merged with config/local_config.json
visualize_walking_paths()
visualize_gaze_graph()
```

### Override Specific Parameters
```matlab
% Override DPI for this run only
visualize_walking_paths('walking_paths_visualization.dpi', 300)

% Override multiple parameters
visualize_gaze_graph('gaze_graph_visualization.node_marker_size', 200, 'participants', [1004 1005])
```

## Configuration Files

### default_config.json

Contains default values for all parameters. Check into git for team collaboration.

**Sections:**
- `paths`: File and directory paths
- `participants`: List of participant IDs to process
- `map`: Map image configuration (filename, transparency)
- `coordinate_transform`: Coordinate scaling and offset
- `walking_paths_visualization`: Marker size, colors, DPI
- `gaze_graph_visualization`: Node/edge styling, DPI

### local_config.json

User-specific configuration. **Never commit this file.**

Only include fields you want to override. Other fields use defaults.

**Example:**
```json
{
  "paths": {
    "walking_paths_data_dir": "/home/user/data/walking_paths"
  },
  "walking_paths_visualization": {
    "dpi": 200
  }
}
```

## Adding New Configuration Options

1. Add to `default_config.json` with sensible defaults
2. Users can override in `local_config.json`
3. Access in code via the nested struct:
   ```matlab
   config.paths.output_walking_paths
   config.walking_paths_visualization.dpi
   ```

## Troubleshooting

### Missing Configuration File
If you see an error about default_config.json not found:
- Ensure you're running from the Analysis directory
- Check that `config/default_config.json` exists

### Paths Not Being Resolved Correctly
- Verify JSON syntax in `local_config.json` (use JSON validator)
- Check that paths use double backslashes on Windows: `C:\\Users\\...`
- Ensure user-specific paths exist on your system

### Configuration Not Taking Effect
- Command-line arguments have highest priority (they override everything)
- Restart MATLAB to reload configuration
- Check if `local_config.json` exists and is being used
