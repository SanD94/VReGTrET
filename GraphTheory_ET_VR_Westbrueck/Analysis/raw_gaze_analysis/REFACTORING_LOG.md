# Refactoring: Visualization and Table Generation

## Overview
Extracted visualization and table generation code from result notebooks into dedicated R modules, keeping notebooks lean and focused on reporting.

## Changes

### New Files Created

#### `R/05_visualization.R`
**Purpose**: Publication-ready visualization functions for emmeans results

**Key Functions**:
- `plot_emmeans_with_violin()` - Generic EMM plot with violin overlay
- `plot_dwell_time()` - Specialized plot for dwell time (inverse-link Gamma)
- `plot_ndc()` - Specialized plot for NDC/node connections (log-link Poisson)
- `combine_dwell_ndc_plots()` - Combine plots with unified aesthetics

**Design Notes**:
- Takes already-fitted emmeans objects (not raw models) to keep separation of concerns clear
- All scaling/theming configurable or uses sensible defaults
- Uses `patchwork` for combining multiple plots
- Supports significance marker annotations via `ggpubr::add_pvalue()`

#### `R/06_tables.R`
**Purpose**: Table generation and HTML export functions

**Key Functions**:
- `build_model_summary_table()` - Construct model comparison matrix
- `export_model_summary_table()` - GT table with formatting and column spanners
- `build_comparison_table()` - Format LRT comparison results
- `format_emm_contrasts()` - Clean up emmeans contrast output
- `export_contrasts_table()` - Export contrasts as publication-ready HTML
- `build_posthoc_table()` - **NEW** Build combined EMM + pairwise contrasts table
- `export_posthoc_table()` - **NEW** Export post-hoc results as publication-ready HTML

**Design Notes**:
- Deeply connected to `utils.R` (`get_sim_model_summary()`) as intended—don't refactor further
- Uses GT (Great Tables) for publication formatting
- All markdown formatting happens here, not in utils
- Exports to HTML files in output folder
- New post-hoc functions combine dwell time and NDC results in a single table

### Modified Files

#### `R/01_init.R`
- Added `ggpubr` to library imports
- Replaced source of `R/05_analysis.R` (which didn't exist) with:
  - `source(here::here("R/05_visualization.R"))`
  - `source(here::here("R/06_tables.R"))`

## Notebook Usage Pattern

### Before
```r
# Visualization code mixed in notebook
model_full_emm <- fit_model_full(df, median_clusterDuration, ...)
ref_grid_emm <- ref_grid(model_full_emm)
dwell_time_fig <- ref_grid_emm %>% emmip(...) + geom_violin(...) + ...

# Table code mixed in notebook  
dt <- tibble(model_name = ..., dw_null_model = ..., ...)
dt %>% gt() %>% tab_spanner(...) %>% ... %>% gtsave(...)
```

### After
```r
# In notebook: Clean calls to reusable functions
model_full_emm <- fit_model_full(df, median_clusterDuration, ...)
dwell_plot <- plot_dwell_time(model_full_emm, df)

# Or combine both plots
ndc_emm <- fit_model_full(df_node, "mean_connections", family = poisson(), ...)
ndc_plot <- plot_ndc(ndc_emm, df_node)
combined_plot <- combine_dwell_ndc_plots(dwell_plot, ndc_plot)

# For tables
dwell_summaries <- get_sim_model_summary(model_0, model_inter, model_full)
node_summaries <- get_sim_model_summary(node_model_0, node_model_inter, node_model_full)
summary_tbl <- build_model_summary_table(dwell_summaries, node_summaries)
export_model_summary_table(summary_tbl, here(config$OUTPUT_FOLDER, "model_summaries.html"))

# For post-hoc results (EMM + pairwise contrasts for both dwell time and NDC)
emm_dwell_group <- model_full %>% extract_emmeans(~ group)
contrasts_dwell_group <- emm_dwell_group %>% extract_contrasts()
emm_ndc_group <- node_model_full %>% extract_emmeans(~ group)
contrasts_ndc_group <- emm_ndc_group %>% extract_contrasts()

posthoc_group_tbl <- build_posthoc_table(
  emm_dwell_group, contrasts_dwell_group,
  emm_ndc_group, contrasts_ndc_group,
  "group"
)
export_posthoc_table(posthoc_group_tbl, here(config$OUTPUT_FOLDER, "posthoc_group.html"), "group")

# Repeat for building_location factor
emm_dwell_loc <- model_full %>% extract_emmeans(~ building_location)
contrasts_dwell_loc <- emm_dwell_loc %>% extract_contrasts()
emm_ndc_loc <- node_model_full %>% extract_emmeans(~ building_location)
contrasts_ndc_loc <- emm_ndc_loc %>% extract_contrasts()

posthoc_loc_tbl <- build_posthoc_table(
  emm_dwell_loc, contrasts_dwell_loc,
  emm_ndc_loc, contrasts_ndc_loc,
  "building_location"
)
export_posthoc_table(posthoc_loc_tbl, here(config$OUTPUT_FOLDER, "posthoc_location.html"), "building_location")
```

## Relationship to Other Modules

```
01_init.R (config + library loading)
    ↓
02_models.R (fit_model_sequence, fit_model_full)
    ↓
03_statistics.R (extract_emmeans, extract_contrasts, compare_models)
    ↓
04_formatting.R (get_p_string, format_coef, etc.)
    ↓
utils.R (get_sim_model_summary, model diagnostics & summaries)
    ↓
05_visualization.R (plot_dwell_time, plot_ndc, combine_plots)
06_tables.R (build_model_summary_table, export_*_table)
```

## Why Table Generation in 06_tables.R Rather Than 04_formatting.R?

- `04_formatting.R`: Low-level formatting functions (p-value strings, coefficient formatting)
- `06_tables.R`: High-level table construction and export (uses `gt`, saves HTML)
- The table functions are **composition** of lower-level functions, not just formatting
- They are **export operations** (writing to disk), not just data transformation
- Keeps concerns separated: formatting logic vs. table assembly logic

## Future Refactoring Opportunities

When refactoring tables further (as mentioned):
1. Consider extracting GT styling rules into separate function `apply_model_table_style()`
2. Could parameterize column spanners and borders for reusability
3. Currently tight coupling between `utils.R` output and `06_tables.R` input—this is intentional and OK for now
