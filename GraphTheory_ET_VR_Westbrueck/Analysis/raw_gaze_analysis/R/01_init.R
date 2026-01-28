# Initialize project: load libraries, set constants, configure fonts

# Project configuration
get_config <- function() {
  list(
    DATA_FOLDER = "data",
    OUTPUT_FOLDER = "output",
    PLAYGROUND_OUTPUT_FOLDER = "playground_output",
    SRC_FOLDER = "src",
    # Data file names
    SCOTOMA_DATA_FILE = "median_io_group_gaze.csv",
    GLAUCOMA_DATA_FILE = "glaucoma_io_group_gaze.csv",
    VF_DATA_FILE = "vr_navigation_westbrueck_vf_data.csv",
    GLAUCOMA_NODE_FILE = "glaucoma_io_building_node.csv",
    SCOTOMA_NODE_FILE = "io_node_group_gaze.csv",
    CONNECTIONS_FILE = "graph_group_connections.csv",
    # Output file names
    NAISU_LOCATION_PLOT = "naisu_only_location_node_filter.svg",
    GROUP_NODE_DEGREE_PLOT = "group_node_degree_ecdf.svg",
    SCOTOMA_MODEL_SUMMARIES_HTML = "model_summaries.html",
    POSTHOC_COMBINED_HTML = "posthoc_combined.html"
  )
}

config <- get_config()
cli::cli_alert_success("Constants initialized successfully")

# Load libraries
init_library <- function() {
    library(repr)
    library(tidyverse)
    library(purrr)
    library(gtsummary)
    library(broom)
    library(broom.mixed)
    library(gt)
    library(ggprism)
    library(patchwork)
    library(scales)
    library(cli)
    library(here)

    # stat analysis libraries
    library(marginaleffects)
    library(ggeffects)
    library(lme4)
    library(emmeans)
    library(performance)

    cli::cli_alert_success("Libraries are loaded")
}

# Configure fonts for publication-quality plots
init_font <- function() {
    options(repr.plot.width=8, repr.plot.height=6, repr.plot.res = 300)
    options(bitmapType = 'cairo')
    library(showtext)
    font_add_google("Lato", "lato")
    font_add_google(name = "Roboto", family = "roboto")
    showtext_opts(dpi = 300)
    showtext_auto()

    cli::cli_alert_success("Fonts are loaded while configuring repr for 300dpi")
}

# Run initialization functions
init_library()
init_font()

# Source analysis modules in order
source(here::here("R/utils.R"))
source(here::here("R/02_models.R"))
source(here::here("R/03_statistics.R"))
source(here::here("R/04_formatting.R"))
source(here::here("R/05_visualization.R"))
source(here::here("R/06_tables.R"))
