#' Statistics extraction and model comparison functions
#' 
#' Functions for emmeans, contrasts, and effect size calculations
#' on fitted mixed-effects models

#' Extract and format model comparison results via likelihood ratio tests
#'
#' @param models List of nested models with names: null, intermediate, full
#' @return Named list with chi-square, p-value, and formatted p-string for each comparison
#'
#' @details
#' Performs likelihood ratio tests comparing nested models:
#' - null vs. intermediate
#' - intermediate vs. full
#'
#' @examples
#' \dontrun{
#'   models <- fit_model_sequence(df, median_clusterDuration)
#'   comp_results <- compare_models(models)
#' }
compare_models <- function(models) {
    cli::cli_alert_info("Performing LRT comparisons...")
    
    # Comparison 1: null vs intermediate
    comp_1 <- anova(models$null, models$intermediate)
    result_1 <- list(
        comparison = "null vs intermediate",
        chi_sq = comp_1$Chisq[2],
        df = comp_1$Chi.Df[2],
        p_val = comp_1$`Pr(>Chisq)`[2],
        p_string = get_p_string(comp_1$`Pr(>Chisq)`[2])
    )
    
    # Comparison 2: intermediate vs full
    comp_2 <- anova(models$intermediate, models$full)
    result_2 <- list(
        comparison = "intermediate vs full",
        chi_sq = comp_2$Chisq[2],
        df = comp_2$Chi.Df[2],
        p_val = comp_2$`Pr(>Chisq)`[2],
        p_string = get_p_string(comp_2$`Pr(>Chisq)`[2])
    )
    
    # Create object with anova results for broom methods
    results <- list(null_vs_inter = result_1, inter_vs_full = result_2)
    class(results) <- c("compare_models", "list")
    results
}


#' Tidy method for compare_models results
#'
#' @param x compare_models object
#' @param ... Additional arguments (unused)
#'
#' @return Tibble with columns: comparison, chi_sq, df, p.value, p_string
#'
#' @export
tidy.compare_models <- function(x, ...) {
    bind_rows(!!! x) %>%
        select(comparison, chi_sq, p_val, p_string) %>%
        rename(
            chi.squared = chi_sq,
            p.value = p_val
        ) %>%
        mutate(
            chi.squared = round(chi.squared, 2),
            p.value = round(p.value, 4)
        )
}


#' Glance method for compare_models results
#'
#' @param x compare_models object
#' @param ... Additional arguments (unused)
#'
#' @return Tibble with summary of all comparisons
#'
#' @export
glance.compare_models <- function(x, ...) {
    tidy(x) %>%
        summarize(
            n_comparisons = n(),
            min_p.value = min(p.value),
            max_chi.squared = max(chi.squared),
            any_significant = any(p.value < 0.05),
            .groups = "drop"
        )
}


#' Extract estimated marginal means with confidence intervals
#'
#' @param model Fitted glmer model
#' @param specs Formula specification for emmeans (e.g., ~ group)
#' @param transform Transform for backtransformation (default: "response")
#'
#' @return emmeans object with summary
#'
#' @examples
#' \dontrun{
#'   model <- fit_model_full(df, median_clusterDuration)
#'   emm <- extract_emmeans(model, ~ group)
#' }
extract_emmeans <- function(model, specs, transform = "response") {
    ref_grid_obj <- ref_grid(model)
    new_grid <- regrid(ref_grid_obj, transform = transform)
    emmeans(new_grid, specs)
}


#' Extract pairwise contrasts with adjusted p-values
#'
#' @param emm emmeans object
#' @param adjust Adjustment method (default: "tukey")
#' @param infer Confidence interval specification (c(TRUE, TRUE) for both CI and tests)
#'
#' @return Data frame of pairwise contrasts
#'
#' @examples
#' \dontrun{
#'   emm <- extract_emmeans(model, ~ group)
#'   contrasts_df <- extract_contrasts(emm)
#' }
extract_contrasts <- function(emm, adjust = "tukey", infer = c(TRUE, TRUE)) {
    pairs(emm, adjust = adjust, infer = infer) %>%
        summary() %>%
        as_tibble()
}


#' Calculate effect sizes from model
#'
#' @param model Fitted glmer model
#' @param emm emmeans object
#' @return List with effect size statistics
#'
#' @examples
#' \dontrun{
#'   model <- fit_model_full(df, median_clusterDuration)
#'   emm <- extract_emmeans(model, ~ group)
#'   eff_sizes <- extract_effect_sizes(model, emm)
#' }
extract_effect_sizes <- function(model, emm) {
    # Extract random effect standard deviations
    var_corr <- VarCorr(model)
    full_var <- as_tibble(var_corr) %>% pull(sdcor)
    full_sd <- sqrt(sum(full_var^2))
    
    # Get degrees of freedom from model
    edf <- nobs(model) - 1
    
    # Calculate effect sizes
    list(
        sigma = full_sd,
        edf = edf,
        effect_sizes = eff_size(emm, sigma = full_sd, edf = edf)
    )
}


#' Extract R² (variance explained) for mixed models
#'
#' @param model Fitted glmer model
#' @param digits Number of decimal places (default: 3)
#'
#' @return Named list with marginal and conditional R²
#'
#' @examples
#' \dontrun{
#'   model <- fit_model_full(df, median_clusterDuration)
#'   r2_results <- extract_r2(model)
#' }
extract_r2 <- function(model, digits = 3) {
    r2_stats <- r2_nakagawa(model)
    
    list(
        marginal = round(r2_stats$R2_marginal, digits),
        conditional = round(r2_stats$R2_conditional, digits),
        full_output = r2_stats
    )
}


#' Extract intraclass correlation (ICC) for random intercepts
#'
#' @param model Fitted glmer model
#' @param digits Number of decimal places (default: 3)
#'
#' @return Named list with ICC values
#'
#' @examples
#' \dontrun{
#'   model <- fit_model_full(df, median_clusterDuration)
#'   icc_results <- extract_icc(model)
#' }
extract_icc <- function(model, digits = 3) {
    icc_stats <- performance::icc(model)
    
    list(
        icc_adjusted = round(icc_stats$ICC_adjusted, digits),
        icc_conditional = round(icc_stats$ICC_conditional, digits),
        full_output = icc_stats
    )
}


#' Create comprehensive model summary
#'
#' @param model Fitted glmer model
#' @param outcome_name Name of outcome variable (for labeling)
#' @param specs Formula specification for emmeans (e.g., ~ group)
#'
#' @return List containing all key statistical results
#'
#' @examples
#' \dontrun{
#'   model <- fit_model_full(df, median_clusterDuration)
#'   summary_results <- create_model_summary(model, "Dwell Time", ~ group)
#' }
create_model_summary <- function(model, outcome_name, specs) {
    cli::cli_h3("Summarizing model: {outcome_name}")
    
    # Extract EMM and contrasts
    emm <- extract_emmeans(model, specs)
    contrasts <- extract_contrasts(emm)
    
    # Effect sizes and model fit
    eff_results <- extract_effect_sizes(model, emm)
    r2_results <- extract_r2(model)
    icc_results <- extract_icc(model)
    
    list(
        outcome = outcome_name,
        model = model,
        emmeans = emm,
        contrasts = contrasts,
        effect_sizes = eff_results$effect_sizes,
        r2 = r2_results,
        icc = icc_results,
        sigma = eff_results$sigma,
        edf = eff_results$edf
    )
}
