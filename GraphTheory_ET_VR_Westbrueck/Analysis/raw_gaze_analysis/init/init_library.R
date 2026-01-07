init_library <- function() {
    library(repr)
    library(tidyverse)
    library(gtsummary)
    library(broom)
    library(broom.mixed)
    library(gt)
    library(ggprism)
    library(marginaleffects)
    library(ggeffects)
    library(scales)
    library(cli)
    library(here)

    cli_alert_success("Libraries are loaded")
}
