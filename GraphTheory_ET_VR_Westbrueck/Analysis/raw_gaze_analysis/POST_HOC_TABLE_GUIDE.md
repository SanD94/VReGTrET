# Post-Hoc Results Table Functions

## Overview

Two new functions in `R/06_tables.R` create publication-ready tables combining estimated marginal means (EMM) and pairwise contrasts for both dwell time and NDC outcomes in a single, structured HTML table.

## Function Signatures

### `build_posthoc_table()`

**Arguments:**
- `emm_dwell` - emmeans object for dwell time (from `extract_emmeans(model_full, ~ group)`)
- `contrasts_dwell` - Contrasts tibble for dwell time (from `extract_contrasts(emm_dwell)`)
- `emm_ndc` - emmeans object for NDC/node connections (from `extract_emmeans(node_model_full, ~ group)`)
- `contrasts_ndc` - Contrasts tibble for NDC (from `extract_contrasts(emm_ndc)`)
- `factor_name` - Character: `"group"` or `"building_location"` (used in export title)

**Returns:** Tibble with columns:
- `Variable` - Group/location level or contrast name
- `Dwell Time EMM [95% CI]` - Either formatted EMM with CI (for group rows) or z-test results (for contrast rows)
- `NDC EMM [95% CI]` - Either formatted EMM with CI (for group rows) or z-test results (for contrast rows)

**Structure:**
1. **Group levels** (3 rows for group factor: control, peripheral, central) - shows EMM and 95% CI
2. **Separator row** (dashes)
3. **Pairwise contrasts** (3 rows: control-peripheral, control-central, peripheral-central) - shows z-ratio and formatted p-value

### `export_posthoc_table()`

**Arguments:**
- `posthoc_table` - Tibble from `build_posthoc_table()`
- `output_path` - Character file path for HTML output
- `factor_name` - Character: `"group"` or `"building_location"` (determines table title)

**Returns:** Invisibly returns the gt table object

**Side Effects:** Saves publication-ready HTML file with:
- Title and subtitle
- Formatted column headers with markdown
- Separator line with borders between EMM and contrast sections
- 280px column widths for readability

## Example Usage

```r
# For group factor (control, peripheral, central)
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

# For building location factor
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

## Table Format Example

| Condition | Dwell Time | NDC |
|-----------|-----------|-----|
| control | 0.523 [0.412, 0.634] | 12.456 [10.234, 14.678] |
| peripheral | 0.612 [0.501, 0.723] | 15.234 [13.012, 17.456] |
| central | 0.687 [0.576, 0.798] | 18.901 [16.679, 21.123] |
| — | — | — |
| control-peripheral | z = -1.23, *p* < .05* | z = -1.45, *p* < .05* |
| control-central | z = -2.34, *p* < .01** | z = -2.56, *p* < .01** |
| peripheral-central | z = -0.98, *p* = 0.328 | z = -1.12, *p* = 0.262 |

## Design Notes

- **Column structure**: Uses same column names for both EMM and contrast rows for simplicity
- **p-value formatting**: Uses `get_p_string()` utility for consistent significance markers
- **Z-ratios**: Rounds to 2 decimal places for publication
- **Tukey adjustment**: Uses default Tukey adjustment for pairwise comparisons (from `extract_contrasts()`)
- **Symmetric layout**: Both dwell time and NDC displayed side-by-side for easy comparison
- **CI formatting**: Always 3 decimal places for consistency

## Dependencies

- `dplyr`, `purrr` for tibble manipulation
- `emmeans` for EMM extraction (provides `summary()` method)
- `gt` for table formatting and HTML export
- `get_p_string()` from `R/04_formatting.R` for p-value formatting
