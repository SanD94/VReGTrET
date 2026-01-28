#' Formatting and output utilities
#' 
#' Functions for converting statistical results to publication-ready formats

#' Convert p-values to formatted strings with significance markers
#'
#' @param p_val Numeric p-value
#'
#' @return Character string formatted for reporting
#'   Format: "$p$ < .001***" for highly significant, "$p$ = 0.052" otherwise
#'
#' @examples
#' \dontrun{
#'   get_p_string(0.001)  # returns "$p$ < .001***"
#'   get_p_string(0.052)  # returns "$p$ = .05"
#' }
get_p_string <- function(p_val) {
    dplyr::case_when(
        p_val < 0.001 ~ "$p$ < .001***",
        p_val < 0.01  ~ "$p$ < .01**",
        p_val < 0.05  ~ "$p$ < .05*",
        TRUE          ~ sprintf("$p$ = %.3f", round(p_val, 3))
    )
}


#' Format coefficient with standard error and confidence interval
#'
#' @param estimate Point estimate
#' @param std_error Standard error
#' @param z_critical Critical z-value for CI (default: 1.96 for 95% CI)
#' @param digits Number of decimal places (default: 3)
#'
#' @return Character string formatted as "estimate [lower, upper]"
#'
#' @examples
#' \dontrun{
#'   format_coef(0.523, 0.098)  # returns "0.523 [0.331, 0.715]"
#' }
format_coef <- function(estimate, std_error, z_critical = 1.96, digits = 3) {
    lower <- estimate - z_critical * std_error
    upper <- estimate + z_critical * std_error
    sprintf(
        "%.*f [%.*f, %.*f]",
        digits, round(estimate, digits),
        digits, round(lower, digits),
        digits, round(upper, digits)
    )
}


#' Format contrast results table
#'
#' @param contrasts Data frame from extract_contrasts()
#' @param round_digits Decimal places for rounding (default: 3)
#'
#' @return Formatted tibble with p-value strings and CI formatting
#'
#' @details
#' Accepts output from emmeans::pairs() and formats for presentation.
#' Adds formatted p-value column and cleans column names.
#'
#' @examples
#' \dontrun{
#'   emm <- extract_emmeans(model, ~ group)
#'   contrasts <- extract_contrasts(emm)
#'   formatted <- format_contrasts_table(contrasts)
#' }
format_contrasts_table <- function(contrasts, round_digits = 3) {
    contrasts %>%
        mutate(
            estimate = round(estimate, round_digits),
            SE = round(SE, round_digits),
            p_formatted = get_p_string(p.value),
            t.ratio = round(t.ratio, 2),
            contrast = as.character(contrast)
        ) %>%
        select(contrast, estimate, SE, t.ratio, p.value, p_formatted) %>%
        rename(
            Contrast = contrast,
            Estimate = estimate,
            "Std. Error" = SE,
            "t-ratio" = t.ratio,
            "p (raw)" = p.value,
            "p (formatted)" = p_formatted
        ) %>%
        as_tibble()
}


#' Format emmeans summary table
#'
#' @param emm_summary emmeans summary object (or tibble)
#' @param round_digits Decimal places for rounding (default: 3)
#' @param include_ci Include confidence interval columns (default: TRUE)
#'
#' @return Formatted tibble with cleaned column names
#'
#' @examples
#' \dontrun{
#'   emm <- extract_emmeans(model, ~ group)
#'   formatted <- format_emmeans_table(summary(emm))
#' }
format_emmeans_table <- function(emm_summary, round_digits = 3, include_ci = TRUE) {
    tbl <- as_tibble(emm_summary) %>%
        mutate(
            across(where(is.numeric), ~round(., round_digits))
        )
    
    # Standardize column names if present
    tbl <- tbl %>%
        rename_with(~gsub("asymp\\.", "asymp_", .x))
    
    if (!include_ci) {
        tbl <- tbl %>%
            select(-starts_with("asymp_"))
    }
    
    tbl
}


#' Format model coefficients table from summary
#'
#' @param model Fitted model
#' @param round_digits Decimal places (default: 3)
#'
#' @return Formatted tibble of fixed effects
#'
#' @examples
#' \dontrun{
#'   model <- fit_model_full(df, median_clusterDuration)
#'   coef_table <- format_model_coefficients(model)
#' }
format_model_coefficients <- function(model, round_digits = 3) {
    broom.mixed::tidy(model, effects = "fixed") %>%
        mutate(
            estimate = round(estimate, round_digits),
            std.error = round(std.error, round_digits),
            statistic = round(statistic, round_digits),
            p.value_formatted = get_p_string(p.value)
        ) %>%
        select(term, estimate, std.error, statistic, p.value, p.value_formatted) %>%
        rename(
            Term = term,
            Estimate = estimate,
            "Std. Error" = std.error,
            Statistic = statistic,
            "p (raw)" = p.value,
            "p (formatted)" = p.value_formatted
        ) %>%
        as_tibble()
}


#' Format R² and fit statistics
#'
#' @param r2_list List from extract_r2()
#' @param icc_list List from extract_icc() (optional)
#'
#' @return Tibble with formatted fit statistics
#'
#' @examples
#' \dontrun{
#'   r2_results <- extract_r2(model)
#'   icc_results <- extract_icc(model)
#'   fit_table <- format_model_fit(r2_results, icc_results)
#' }
format_model_fit <- function(r2_list, icc_list = NULL) {
    fit_tbl <- tibble(
        Metric = c("Marginal R²", "Conditional R²"),
        Value = c(r2_list$marginal, r2_list$conditional)
    )
    
    if (!is.null(icc_list)) {
        icc_tbl <- tibble(
            Metric = c("ICC (adjusted)", "ICC (conditional)"),
            Value = c(icc_list$icc_adjusted, icc_list$icc_conditional)
        )
        fit_tbl <- bind_rows(fit_tbl, icc_tbl)
    }
    
    fit_tbl
}


#' Create publication-ready comparison table
#'
#' @param model_comparison List from compare_models()
#' @param model_names Character vector of model names (default: c("Null vs. Intermediate", "Intermediate vs. Full"))
#'
#' @return Formatted tibble suitable for publication
#'
#' @examples
#' \dontrun{
#'   models <- fit_model_sequence(df, median_clusterDuration)
#'   comp_results <- compare_models(models)
#'   comp_table <- format_model_comparison(comp_results)
#' }
format_model_comparison <- function(model_comparison, 
                                     model_names = c("Null vs. Intermediate", "Intermediate vs. Full")) {
    tibble(
        Comparison = model_names,
        "χ²" = c(
            model_comparison$null_vs_inter$chi_sq,
            model_comparison$inter_vs_full$chi_sq
        ),
        "p-value" = c(
            round(model_comparison$null_vs_inter$p_val, 4),
            round(model_comparison$inter_vs_full$p_val, 4)
        ),
        Significance = c(
            model_comparison$null_vs_inter$p_string,
            model_comparison$inter_vs_full$p_string
        )
    )
}


#' Format variance component table
#'
#' @param model Fitted glmer model
#' @param round_digits Decimal places (default: 3)
#'
#' @return Tibble of random effect variances
#'
#' @examples
#' \dontrun{
#'   model <- fit_model_full(df, median_clusterDuration)
#'   var_table <- format_variance_components(model)
#' }
format_variance_components <- function(model, round_digits = 3) {
    var_corr <- VarCorr(model)
    
    as_tibble(var_corr) %>%
        mutate(
            sdcor = round(sdcor, round_digits),
            var = round(sdcor^2, round_digits)
        ) %>%
        select(grp, var1, sdcor, var) %>%
        rename(
            "Group" = grp,
            "Variable" = var1,
            "Std. Dev." = sdcor,
            "Variance" = var
        ) %>%
        as_tibble()
}
