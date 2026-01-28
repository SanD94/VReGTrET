#' Fit mixed-effects models for gaze metrics analysis
#' 
#' Functions to fit and manage nested models for statistical analysis
#' of gaze data with random intercepts by building location and participant.

#' Fit null model (intercept only)
#'
#' @param df Data frame with required columns
#' @param outcome_var Outcome variable (bare column name, e.g., median_clusterDuration)
#' @param family GLM family specification (default: Gamma with inverse link)
#' @return Fitted glmer model
#'
#' @details
#' Null model includes only random intercepts by building_location and PID.
#' Used as baseline for model comparison via LRT.
#'
#' @examples
#' \dontrun{
#'   fit_model_null(df, median_clusterDuration)
#' }
fit_model_null <- function(df, outcome_var, family = Gamma(link = "inverse")) {
    outcome_name <- rlang::as_name(rlang::enquo(outcome_var))
    formula <- reformulate(
        termlabels = c("(1 | PID)", "(1 | hitObjectColliderName)"),
        response = outcome_name
    )
    glmer(formula, data = df, family = family)
}


#' Fit intermediate model (adding building_location main effect)
#'
#' @param df Data frame with required columns
#' @param outcome_var Outcome variable (bare column name)
#' @param family GLM family specification (default: Gamma with inverse link)
#' @return Fitted glmer model
#'
#' @details
#' Intermediate model adds building_location main effect.
#' Tests whether location (inside/outside) affects outcome.
#'
#' @examples
#' \dontrun{
#'   fit_model_intermediate(df, median_clusterDuration)
#' }
fit_model_intermediate <- function(df, outcome_var, family = Gamma(link = "inverse")) {
    outcome_name <- rlang::as_name(rlang::enquo(outcome_var))
    formula <- reformulate(
        termlabels = c("building_location", "(1 | PID)", "(1 | hitObjectColliderName)"),
        response = outcome_name
    )
    glmer(formula, data = df, family = family)
}


#' Fit full model (adding group main effect)
#'
#' @param df Data frame with required columns
#' @param outcome_var Outcome variable (bare column name)
#' @param family GLM family specification (default: Gamma with inverse link)
#' @return Fitted glmer model
#'
#' @details
#' Full model adds group main effect (control, peripheral, central).
#' Tests whether visual field defect group affects outcome.
#'
#' @examples
#' \dontrun{
#'   fit_model_full(df, median_clusterDuration)
#' }
fit_model_full <- function(df, outcome_var, family = Gamma(link = "inverse")) {
    outcome_name <- rlang::as_name(rlang::enquo(outcome_var))
    formula <- reformulate(
        termlabels = c("building_location", "group", "(1 | PID)", "(1 | hitObjectColliderName)"),
        response = outcome_name
    )
    glmer(formula, data = df, family = family)
}


#' Fit nested model sequence for comparison
#'
#' @param df Data frame with required columns
#' @param outcome_var Outcome variable (bare column name)
#' @param family GLM family specification (default: Gamma with inverse link)
#' @return List with named elements: null, intermediate, full
#'
#' @details
#' Convenience function to fit all three nested models at once.
#' Returns a list suitable for model comparison workflows.
#'
#' @examples
#' \dontrun{
#'   models <- fit_model_sequence(df, median_clusterDuration)
#'   models$full
#' }
fit_model_sequence <- function(df, outcome_var, family = Gamma(link = "inverse")) {
    list(
        null = fit_model_null(df, outcome_var, family),
        intermediate = fit_model_intermediate(df, outcome_var, family),
        full = fit_model_full(df, outcome_var, family)
    )
}


#' Fit Poisson model for count data (e.g., connections)
#'
#' @param df Data frame with required columns
#' @param outcome_var Outcome variable (bare column name)
#' @return List with fitted glmer models (Poisson family)
#'
#' @details
#' Specialized for count outcomes like mean_connections.
#' Uses Poisson family instead of Gamma.
#'
#' @examples
#' \dontrun{
#'   models <- fit_poisson_sequence(df_node, mean_connections)
#' }
fit_poisson_sequence <- function(df, outcome_var) {
    list(
        null = fit_model_null(df, {{ outcome_var }}, family = poisson()),
        intermediate = fit_model_intermediate(df, {{ outcome_var }}, family = poisson()),
        full = fit_model_full(df, {{ outcome_var }}, family = poisson())
    )
}
