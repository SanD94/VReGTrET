#' Table generation and export functions
#' 
#' Functions for creating publication-ready tables and saving to HTML
#' (Libraries loaded by 01_init.R: gt, dplyr, tidyr, purrr, here)

#' Create model summary table
#'
#' @param dwell_summaries List from get_sim_model_summary() for dwell time models
#' @param node_summaries List from get_sim_model_summary() for NDC models
#'
#' @return Tibble with model comparison data ready for gt table
#'
#' @details
#' Builds a structured tibble with model parameters and statistics.
#' Rows contain: LRT statistics, fixed effects, random effects, diagnostics.
#' Columns contain: Model type (dwell vs NDC) x Model complexity (null, inter, full).
#'
#' @examples
#' \dontrun{
#'   dwell_summaries <- get_sim_model_summary(model_0, model_inter, model_full)
#'   node_summaries <- get_sim_model_summary(node_model_0, node_model_inter, node_model_full)
#'   tbl <- build_model_summary_table(dwell_summaries, node_summaries)
#' }
build_model_summary_table <- function(dwell_summaries, node_summaries) {
    
    tibble(
        model_name = c(
            "**LRT**",
            "***fixed effects***",
            "intercept",
            "region (inside)",
            "condition (peripheral)",
            "condition (central)",
            "***random effects***",
            "building",
            "participant",
            "observation-level<br>&nbsp;&nbsp;(distribution-specific)",
            "$R^2_{GLMM(m)}$ (%)",
            "$R^2_{GLMM(c)}$ (%)",
            "$ICC_{[Building]}$ (%)",
            "$ICC_{[Participant]}$ (%)",
            "$AIC$"
        ),
        # dwell time models
        dw_null_model = dwell_summaries$model_null,
        dw_inter_model = dwell_summaries$model_inter_summary,
        dw_full_model = dwell_summaries$model_full_summary,
        # node models
        node_null_model = node_summaries$model_null,
        node_inter_model = node_summaries$model_inter_summary,
        node_full_model = node_summaries$model_full_summary
    )
}


#' Format and save model summary table as HTML
#'
#' @param summary_table Tibble from build_model_summary_table()
#' @param output_path Character path for HTML output file
#'
#' @return Invisibly returns the gt object
#'
#' @details
#' Creates a publication-ready GT table with:
#' - Column spanners for model types (Dwell Time vs NDC)
#' - Bold borders between model type groups
#' - Markdown formatting support
#' - Fixed column widths for readability
#'
#' Saves directly to HTML file.
#'
#' @examples
#' \dontrun{
#'   tbl <- build_model_summary_table(dwell_summaries, node_summaries)
#'   export_model_summary_table(tbl, here("output", "model_summaries.html"))
#' }
export_model_summary_table <- function(summary_table, output_path) {
    
    gt_tbl <- summary_table %>% 
        gt() %>%
        tab_spanner(
            label = md("**Dwell Time Models (inverse-link)<br>Gamma Mixed Models**"),
            columns = starts_with("dw"),
            id = "dwell_time_models"
        ) %>%
        tab_spanner(
            label = md("**NDC Models (log-link)<br>Poisson Mixed Models**"),
            columns = starts_with("node")
        ) %>%
        cols_label(
            model_name = md("**Model Name**"),
            dw_null_model = md("**Null Model**"),
            dw_inter_model = md("**Intermediate Model**"),
            dw_full_model = md("**Full Model**"),
            node_null_model = md("**Null Model**"),
            node_inter_model = md("**Intermediate Model**"),
            node_full_model = md("**Full Model**")
        ) %>%
        # Right border of dwell time models group
        tab_style(
            style = cell_borders(
                sides = c("right", "left"),
                color = "black",
                weight = px(2)
            ),
            locations = cells_column_spanners(
                "dwell_time_models"
            )
        ) %>%
        # Right border of dwell time full model column
        tab_style(
            style = cell_borders(
                sides = "right",
                color = "black",
                weight = px(2)
            ),
            locations = cells_column_labels(
                "dw_full_model"
            )
        ) %>%
        tab_style(
            style = cell_borders(
                sides = "right",
                color = "black",
                weight = px(2)
            ),
            locations = cells_body(
                "dw_full_model"
            )
        ) %>%
        # Left border of dwell time null model column
        tab_style(
            style = cell_borders(
                sides = "left",
                color = "black",
                weight = px(2)
            ),
            locations = cells_column_labels(
                "dw_null_model"
            )
        ) %>%
        tab_style(
            style = cell_borders(
                sides = "left",
                color = "black",
                weight = px(2)
            ),
            locations = cells_body(
                "dw_null_model"
            )
        ) %>%
        cols_width(everything() ~ px(200)) %>%
        fmt_markdown() %>%
        gtsave(output_path)
    
    invisible(gt_tbl)
}


#' Build comparison statistics table (LRT results)
#'
#' @param lrt_results List output from compare_models()
#' @param add_p_string Logical, add formatted p-value column (default: TRUE)
#'
#' @return Tibble ready for display or export
#'
#' @details
#' Takes model comparison results and creates a clean comparison table
#' suitable for publication. Optionally adds formatted p-value strings.
#'
#' @examples
#' \dontrun{
#'   lrt <- compare_models(models)
#'   comp_tbl <- build_comparison_table(lrt)
#'   print(comp_tbl)
#' }
build_comparison_table <- function(lrt_results, add_p_string = TRUE) {
    
    tbl <- lrt_results %>% 
        tidy() %>%
        select(comparison, chi.squared, p.value)
    
    if (add_p_string) {
        tbl <- tbl %>%
            mutate(
                p.value = round(p.value, 4),
                p_string = map_chr(p.value, get_p_string),
                chi.squared = round(chi.squared, 2)
            ) %>%
            select(comparison, chi.squared, p.value, p_string)
    } else {
        tbl <- tbl %>%
            mutate(
                chi.squared = round(chi.squared, 2),
                p.value = round(p.value, 4)
            )
    }
    
    tbl
}


#' Format EMM contrast results for publication
#'
#' @param contrasts emmeans contrast tibble from extract_contrasts()
#' @param add_significance Logical, add significance marker column (default: TRUE)
#'
#' @return Formatted tibble ready for publication
#'
#' @details
#' Cleans and formats emmeans contrast output:
#' - Rounds estimates and SE to 3 decimal places
#' - Formats z/t-ratio to 2 decimals
#' - Optionally adds significance markers (*, **, ***)
#' - Renames columns for readability
#'
#' @examples
#' \dontrun{
#'   emm <- extract_emmeans(model, ~ group)
#'   contrasts <- extract_contrasts(emm)
#'   formatted_contrasts <- format_emm_contrasts(contrasts)
#' }
format_emm_contrasts <- function(contrasts, add_significance = TRUE) {
    
    tbl <- contrasts %>%
        mutate(
            estimate = round(estimate, 3),
            SE = round(SE, 3),
            p.value = round(p.value, 4),
            z.ratio = round(z.ratio, 2)
        )
    
    if (add_significance) {
        tbl <- tbl %>%
            mutate(
                significance = case_when(
                    p.value < 0.001 ~ "***",
                    p.value < 0.01 ~ "**",
                    p.value < 0.05 ~ "*",
                    TRUE ~ "ns"
                )
            )
    }
    
    tbl %>%
        select(contrast, estimate, SE, z.ratio, p.value, everything()) %>%
        rename(
            Contrast = contrast,
            Estimate = estimate,
            "Std. Error" = SE,
            "z-ratio" = z.ratio,
            "p-value" = p.value
        )
}


#' Export EMM contrasts table as HTML
#'
#' @param contrasts Formatted contrasts tibble from format_emm_contrasts()
#' @param output_path Character path for HTML output
#' @param table_title Character title for the table
#'
#' @return Invisibly returns the gt object
#'
#' @examples
#' \dontrun{
#'   formatted <- format_emm_contrasts(contrasts)
#'   export_contrasts_table(formatted, "output/contrasts.html", 
#'                         "Group Contrasts for Dwell Time")
#' }
export_contrasts_table <- function(contrasts, output_path, table_title = NULL) {
    
    gt_tbl <- contrasts %>%
        gt() %>%
        fmt_number(columns = c(Estimate, "Std. Error", "z-ratio"), decimals = 3) %>%
        fmt_number(columns = "p-value", decimals = 4)
    
    if (!is.null(table_title)) {
        gt_tbl <- gt_tbl %>%
            tab_header(title = md(table_title))
    }
    
    gt_tbl %>%
        gtsave(output_path)
    
    invisible(gt_tbl)
}


#' Build post-hoc results table (EMM + pairwise contrasts)
#'
#' @param emm_dwell emmeans object for dwell time (from extract_emmeans())
#' @param contrasts_dwell Contrasts tibble for dwell time (from extract_contrasts())
#' @param emm_ndc emmeans object for NDC (from extract_emmeans())
#' @param contrasts_ndc Contrasts tibble for NDC (from extract_contrasts())
#' @param factor_name Character name of factor being compared ("group" or "building_location")
#' @param filter_ndc_contrasts Logical, remove NDC contrasts with p >= 0.05 (default: FALSE)
#' @param relabel_groups Named character vector for relabeling group levels (e.g., c("peripheral" = "peripheral scotoma"))
#'
#' @return Tibble with structured post-hoc results: group levels with EMM/CI,
#'         then separator line, then pairwise comparisons with z/p values
#'
#' @details
#' Creates a publication-ready tibble with:
#' - Estimated marginal means and confidence intervals for each group level
#' - Separator row
#' - Pairwise comparisons with z-ratios and p-values
#' Structure is repeated for each outcome (dwell time and NDC)
#'
#' If filter_ndc_contrasts is TRUE, NDC contrast rows with non-significant p-values are removed
#' to avoid presenting misleading comparisons.
#'
#' @examples
#' \dontrun{
#'   emm_dwell <- extract_emmeans(model_full, ~ group)
#'   contrasts_dwell <- extract_contrasts(emm_dwell)
#'   emm_ndc <- extract_emmeans(node_model_full, ~ group)
#'   contrasts_ndc <- extract_contrasts(emm_ndc)
#'   
#'   posthoc_tbl <- build_posthoc_table(
#'     emm_dwell, contrasts_dwell,
#'     emm_ndc, contrasts_ndc,
#'     "group"
#'   )
#' }
build_posthoc_table <- function(emm_dwell, contrasts_dwell, emm_ndc, contrasts_ndc, factor_name, filter_ndc_contrasts = FALSE, relabel_groups = NULL) {
    
    # Convert emmeans summary to tibble
    emm_dwell_tbl <- summary(emm_dwell) %>% as_tibble()
    emm_ndc_tbl <- summary(emm_ndc) %>% as_tibble()
    
    # Get the factor variable name (first column in emm results)
    factor_col <- names(emm_dwell_tbl)[1]
    
    # Extract group/location labels and order from emmeans
    group_labels <- emm_dwell_tbl %>% pull(!!sym(factor_col)) %>% as.character()
    
    # Relabel groups if mapping provided (names are old labels, values are new labels)
    if (!is.null(relabel_groups)) {
        for (i in seq_along(relabel_groups)) {
            group_labels[group_labels == names(relabel_groups)[i]] <- relabel_groups[i]
        }
    }
    
    # Get estimate column names (varies by model type: "response" for Gamma, "rate" for Poisson, etc.)
    dwell_est_col <- if ("response" %in% names(emm_dwell_tbl)) "response" else names(emm_dwell_tbl)[2]
    ndc_est_col <- if ("rate" %in% names(emm_ndc_tbl)) "rate" else if ("response" %in% names(emm_ndc_tbl)) "response" else names(emm_ndc_tbl)[2]
    
    # Build combined EMM rows for each group
    emm_combined <- tibble(
        "Variable" = group_labels,
        "Dwell Time EMM [95% CI]" = sprintf(
            "%.3f [%.3f, %.3f]",
            emm_dwell_tbl[[dwell_est_col]],
            emm_dwell_tbl$asymp.LCL,
            emm_dwell_tbl$asymp.UCL
        ),
        "NDC EMM [95% CI]" = sprintf(
            "%.3f [%.3f, %.3f]",
            emm_ndc_tbl[[ndc_est_col]],
            emm_ndc_tbl$asymp.LCL,
            emm_ndc_tbl$asymp.UCL
        )
    )
    
    # Format contrasts with both dwell time and NDC z-values and p-values
    # Get contrast names from dwell time
    contrast_names <- contrasts_dwell %>% pull(contrast) %>% as.character()
    
    # Relabel contrasts if mapping provided (names are old labels, values are new labels)
    if (!is.null(relabel_groups)) {
        for (i in seq_along(relabel_groups)) {
            old_label <- names(relabel_groups)[i]
            new_label <- relabel_groups[i]
            contrast_names <- str_replace_all(contrast_names, fixed(old_label), new_label)
        }
    }
    
    # Format dwell time contrasts (always show)
    dwell_contrasts_text <- sprintf(
        "z = %.2f, %s",
        contrasts_dwell$z.ratio,
        map_chr(contrasts_dwell$p.value, get_p_string)
    )
    
    # Format NDC contrasts, replacing non-significant ones with dash if filtered
    if (filter_ndc_contrasts) {
        significant_idx <- contrasts_ndc$p.value < 0.05
        ndc_contrasts_text <- ifelse(
            significant_idx,
            sprintf(
                "z = %.2f, %s",
                contrasts_ndc$z.ratio,
                map_chr(contrasts_ndc$p.value, get_p_string)
            ),
            "—"
        )
    } else {
        ndc_contrasts_text <- sprintf(
            "z = %.2f, %s",
            contrasts_ndc$z.ratio,
            map_chr(contrasts_ndc$p.value, get_p_string)
        )
    }
    
    contrasts_combined <- tibble(
        "Variable" = contrast_names,
        "Dwell Time EMM [95% CI]" = dwell_contrasts_text,
        "NDC EMM [95% CI]" = ndc_contrasts_text
    )
    
    # Final table: EMM rows + contrast rows (no separator row; styled with double border in export)
    result <- bind_rows(
        emm_combined,
        contrasts_combined
    )
    
    # Attach metadata: number of EMM rows for styling
    attr(result, "n_emm_rows") <- nrow(emm_combined)
    
    result
}


#' Export post-hoc results table as HTML
#'
#' @param posthoc_table Tibble from build_posthoc_table()
#' @param output_path Character path for HTML output file
#' @param factor_name Character name of factor ("group" or "building_location")
#' @param combined_table Optional second tibble from build_posthoc_table() to combine with posthoc_table
#' @param combined_factor_name Character name of second factor (required if combined_table provided)
#'
#' @return Invisibly returns the gt object
#'
#' @details
#' If combined_table is provided, creates a single export with both factors separated by a section header.
#'
#' @examples
#' \dontrun{
#'   posthoc_tbl <- build_posthoc_table(...)
#'   export_posthoc_table(posthoc_tbl, "output/posthoc.html", "group")
#'   
#'   # Combine two factors
#'   posthoc_group <- build_posthoc_table(...)
#'   posthoc_loc <- build_posthoc_table(...)
#'   export_posthoc_table(posthoc_group, "output/posthoc_combined.html", "group",
#'                        combined_table = posthoc_loc, combined_factor_name = "building_location")
#' }
export_posthoc_table <- function(posthoc_table, output_path, factor_name, combined_table = NULL, combined_factor_name = NULL) {
    
    # Get factor titles
    factor_title <- case_when(
        factor_name == "group" ~ "Viewing Condition",
        factor_name == "building_location" ~ "Region",
        TRUE ~ factor_name
    )
    
    # Combine tables if provided
    if (!is.null(combined_table)) {
        if (is.null(combined_factor_name)) {
            stop("combined_factor_name must be provided when combined_table is specified")
        }
        
        combined_factor_title <- case_when(
            combined_factor_name == "group" ~ "Viewing Condition",
            combined_factor_name == "building_location" ~ "Region",
            TRUE ~ combined_factor_name
        )
        
        # Create section separator with bold factor name header
        factor_separator <- tibble(
            "Variable" = paste0("**", combined_factor_title, "**"),
            "Dwell Time EMM [95% CI]" = "",
            "NDC EMM [95% CI]" = ""
        )
        
        # Combine first table + separator + second table
        table_to_export <- bind_rows(
            posthoc_table,
            factor_separator,
            combined_table
        )
        
        # Update title to reflect both factors
        table_title <- paste0("**Post-Hoc Results: ", factor_title, " & ", combined_factor_title, "**")
    } else {
        table_to_export <- posthoc_table
        table_title <- paste0("**Post-Hoc Results: ", factor_title, "**")
    }
    
    # Get number of EMM rows (stored as attribute from build_posthoc_table)
    n_emm_posthoc <- attr(posthoc_table, "n_emm_rows")
    if (is.null(n_emm_posthoc)) n_emm_posthoc <- nrow(posthoc_table)
    
    gt_tbl <- table_to_export %>%
        gt() %>%
        tab_header(
            title = md(table_title),
            subtitle = md("*Estimated marginal means (top section) and pairwise contrasts (bottom section)*")
        ) %>%
        cols_label(
            Variable = md("**Viewing Condition**"),
            "Dwell Time EMM [95% CI]" = md("**Dwell Time**<br>*EMM [95% CI] or z-test*"),
            "NDC EMM [95% CI]" = md("**NDC**<br>*EMM [95% CI] or z-test*")
        ) %>%
        cols_width(everything() ~ px(280)) %>%
        fmt_markdown()
    
    # Style double border: last EMM row of first table
    gt_tbl <- gt_tbl %>%
        tab_style(
            style = cell_borders(
                sides = "bottom",
                color = "black",
                style = "double",
                weight = px(3)
            ),
            locations = cells_body(rows = seq(n_emm_posthoc, n_emm_posthoc))
        )
    
    # If combined table, add double border for second table's EMM section
    if (!is.null(combined_table)) {
        n_emm_combined <- attr(combined_table, "n_emm_rows")
        if (is.null(n_emm_combined)) n_emm_combined <- nrow(combined_table)
        
        # Row number of last EMM in second table = first EMM rows + header row + first table contrasts + second table EMMs
        # This is: n_emm_posthoc + 1 (header) + (nrow(posthoc_table) - n_emm_posthoc) + n_emm_combined
        row_num_second_emm_end <- nrow(table_to_export) - (nrow(combined_table) - n_emm_combined)
        
        gt_tbl <- gt_tbl %>%
            tab_style(
                style = cell_borders(
                    sides = "bottom",
                    color = "black",
                    style = "double",
                    weight = px(3)
                ),
                locations = cells_body(rows = seq(row_num_second_emm_end, row_num_second_emm_end))
            )
    }
    
    # Style factor header rows with bold text and top border
    gt_tbl <- gt_tbl %>%
        tab_style(
            style = cell_borders(
                sides = "top",
                color = "black",
                weight = px(2)
            ),
            locations = cells_body(rows = grepl("^\\*\\*", Variable))
        ) %>%
        gtsave(output_path)
    
    invisible(gt_tbl)
}
