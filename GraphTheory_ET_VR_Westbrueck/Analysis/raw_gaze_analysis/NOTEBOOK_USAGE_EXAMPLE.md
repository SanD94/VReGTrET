# Using the New Visualization and Table Functions in Notebooks

This guide shows how to update result notebooks to use the refactored visualization and table functions.

## Visualization Functions

### Creating Individual Plots

#### Dwell Time Plot
```r
# Create the emmeans object (from 02_models.R)
model_full_emm <- fit_model_full(df, median_clusterDuration, 
                                 group_levels = c("central", "control", "peripheral"))

# Create the plot
dwell_plot <- plot_dwell_time(model_full_emm, df)
dwell_plot  # Display it
```

#### NDC Plot  
```r
# Create the emmeans object
node_model_full_emm <- fit_model_full(df_node, "mean_connections", 
                                      family = poisson(), 
                                      group_levels = c("central", "control", "peripheral"))

# Create the plot
ndc_plot <- plot_ndc(node_model_full_emm, df_node)
ndc_plot  # Display it
```

### Combining Both Plots

```r
# After creating both individual plots:
combined_fig <- combine_dwell_ndc_plots(dwell_plot, ndc_plot)
combined_fig  # Publication-ready 2-panel figure
```

### Generic EMM Plot with Violin (advanced)

For custom visualizations, use the generic function:

```r
# Custom plot with different response variable
emm_custom <- extract_emmeans(my_model, ~ some_factor)

custom_plot <- plot_emmeans_with_violin(
    emm_object = emm_custom,
    data = my_df,
    response_col = "my_response_var",
    title = "Custom Analysis",
    y_label = "Response (units)",
    y_limits = c(0, 100)
)
```

## Table Functions

### Model Summary Table

```r
# Fit the model sequences (from 02_models.R)
models <- fit_model_sequence(df, median_clusterDuration)
model_0 <- models$null
model_inter <- models$intermediate
model_full <- models$full

node_models <- fit_poisson_sequence(df_node, mean_connections)
node_model_0 <- node_models$null
node_model_inter <- node_models$intermediate
node_model_full <- node_models$full

# Get summary data (from utils.R)
dwell_summaries <- get_sim_model_summary(model_0, model_inter, model_full)
node_summaries <- get_sim_model_summary(node_model_0, node_model_inter, node_model_full)

# Build and export the table
summary_table <- build_model_summary_table(dwell_summaries, node_summaries)
export_model_summary_table(
    summary_table, 
    here(config$OUTPUT_FOLDER, config$SCOTOMA_MODEL_SUMMARIES_HTML)
)
```

### LRT Comparison Table

```r
# From 03_statistics.R
lrt_dwell <- compare_models(models)
lrt_node <- compare_models(node_models)

# Format for display
lrt_table_dwell <- build_comparison_table(lrt_dwell, add_p_string = TRUE)
lrt_table_node <- build_comparison_table(lrt_node, add_p_string = TRUE)

lrt_table_dwell  # Display dwell time comparisons
lrt_table_node   # Display node comparisons
```

### Contrasts Table

```r
# Extract contrasts (from 03_statistics.R)
emm_group <- extract_emmeans(model_full, ~ group)
contrasts_group <- extract_contrasts(emm_group)

# Format for publication
formatted_contrasts <- format_emm_contrasts(contrasts_group, add_significance = TRUE)

# Optional: Export to HTML
export_contrasts_table(
    formatted_contrasts,
    here(config$OUTPUT_FOLDER, "contrasts.html"),
    table_title = "Group Contrasts for Dwell Time"
)

# Or display in notebook
formatted_contrasts
```

## Notebook Structure Example

Here's how a typical results notebook should be organized:

```r
# Cell 1: Initialize
source(here::here("R/01_init.R"))

# Cell 2: Load data
df <- read_csv(here(config$DATA_FOLDER, config$SCOTOMA_DATA_FILE))
df <- df %>% mutate(...)  # Prepare data
df_node <- read_csv(here(config$DATA_FOLDER, config$SCOTOMA_NODE_FILE))
df_node <- df_node %>% mutate(...)

# Cell 3: Fit models
models <- fit_model_sequence(df, median_clusterDuration)
node_models <- fit_poisson_sequence(df_node, mean_connections)

# Cell 4: Model comparisons
lrt_dwell <- compare_models(models)
lrt_node <- compare_models(node_models)

# Cell 5: RESULTS - Visualization
# Create EMM objects
dwell_emm <- fit_model_full(df, median_clusterDuration, group_levels = c("central", "control", "peripheral"))
ndc_emm <- fit_model_full(df_node, "mean_connections", family = poisson(), group_levels = c("central", "control", "peripheral"))

# Create and display combined plot
dwell_plot <- plot_dwell_time(dwell_emm, df)
ndc_plot <- plot_ndc(ndc_emm, df_node)
combined_fig <- combine_dwell_ndc_plots(dwell_plot, ndc_plot)
combined_fig

# Cell 6: RESULTS - Model Summary Table
dwell_summaries <- get_sim_model_summary(models$null, models$intermediate, models$full)
node_summaries <- get_sim_model_summary(node_models$null, node_models$intermediate, node_models$full)
summary_table <- build_model_summary_table(dwell_summaries, node_summaries)
export_model_summary_table(summary_table, here(config$OUTPUT_FOLDER, "model_summaries.html"))

# Cell 7: RESULTS - Contrasts
emm_group <- extract_emmeans(models$full, ~ group)
contrasts <- extract_contrasts(emm_group)
format_emm_contrasts(contrasts)
```

## Key Points

1. **Separation of Concerns**: 
   - Fitting happens in one cell
   - Visualization happens in separate cells
   - Tables are built and exported separately

2. **No Mixed Logic**: 
   - Notebooks don't contain visualization or table logic
   - All logic is in `R/05_visualization.R` and `R/06_tables.R`
   - Notebooks are now truly "result notebooks" (draft of paper results)

3. **Reusable Across Datasets**:
   - Same functions work for both scotoma and glaucoma analyses
   - Just change the data and model fitting step

4. **Future Changes**:
   - To change plot aesthetics: edit `05_visualization.R`
   - To change table formatting: edit `06_tables.R`
   - Notebooks stay clean and readable
