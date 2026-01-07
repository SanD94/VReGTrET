init_library <- function() {
    library(repr)
    library(tidyverse)
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

    cli_alert_success("Libraries are loaded")
}
