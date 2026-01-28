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
