# AGENTS.md

## Build/Test/Run Commands

**Running Notebooks:**
- Open `.ipynb` files in Jupyter or VS Code Notebooks
- Execute cells individually or use "Run All" to process entire notebook
- Notebooks auto-load configuration via `R/init.R` which initializes libraries, constants, and fonts

## Architecture & Structure

**Project:** VR Gaze Analysis with Graph Theory (statistical analysis of eye-tracking data in VR environments)

**Directories:**
- `notebooks/results/` - Final analysis notebooks (results_scotoma.ipynb, results_glaucoma.ipynb)
- `notebooks/exploratory/` - Exploratory analyses and playgrounds
- `R/init.R` - Project initialization: loads config, libraries (tidyverse, lme4, emmeans, ggprism, etc.), configures 300dpi fonts
- `src/utils.R` - Shared utility functions for mixed-effects model summaries and statistical reporting
- `data/` - Input CSV files (gaze data, node data, connection graphs)
- `output/`, `playground_output/` - Generated plots and results

**Key Libraries:** tidyverse, lme4 (mixed models), emmeans (estimated marginal means), ggeffects, marginaleffects, performance (model diagnostics), broom/broom.mixed (tidy outputs)

**Data Files:** median_io_group_gaze.csv, glaucoma_io_group_gaze.csv, vr_navigation_westbrueck_vf_data.csv, graph_group_connections.csv

## Code Style & Conventions

**R Style:**
- Use tidyverse pipe syntax (`%>%`)
- Load config via `get_config()` in init.R; reference as `config$DATA_FOLDER`, etc.
- Helper functions return lists with named elements for model summaries
- P-value strings use `get_p_string()` utility (returns formatted strings with significance markers)
- Use `cli::cli_alert_*()` for console feedback

**Analysis Pattern:**
- Mixed models: `lmer()` for continuous outcomes with random intercepts by building/PID
- Model comparison: use `anova()` for likelihood ratio tests
- Effect estimation: use `emmeans::emmeans()` for estimated marginal means
- Model diagnostics: `performance::icc()`, `r2_nakagawa()`
- Rounding: 3 decimals for coefficients, 4 for ICC/R²

**Imports:** Always load needed tidyverse components explicitly; source utils.R for helper functions
