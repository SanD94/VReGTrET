#' Visualization utilities for emmeans results
#' 
#' Functions for creating publication-ready plots of estimated marginal means
#' (Libraries loaded by 01_init.R: ggplot2, emmeans, ggpubr, patchwork)

#' Format contrast table for ggpubr significance plotting
#'
#' @param contrasts_tibble Contrast tibble from extract_contrasts()
#' @param y_positions Named numeric vector of y positions for brackets
#' @param sig_labels Optional character vector of significance labels (defaults to formatting p-values)
#'
#' @return tibble with columns: p, group1, group2, label, y.position (ready for add_pvalue)
#'
#' @details
#' Converts emmeans contrast output to format required by ggpubr::add_pvalue().
#' If sig_labels not provided, uses p-value formatting with asterisks.
#'
#' @examples
#' \dontrun{
#'   contrasts <- model %>% extract_emmeans(~ group) %>% extract_contrasts()
#'   contrast_table <- format_contrast_table(
#'     contrasts,
#'     y_positions = c(0.80, 0.75, 0.85),
#'     sig_labels = c("**", "P = 0.11", "***")
#'   )
#' }
format_contrast_table <- function(contrasts_tibble, y_positions = NULL, sig_labels = NULL) {
  
  # Auto-detect separator in contrast column (e.g., " - " for Gamma, " / " for Poisson)
  first_contrast <- as.character(contrasts_tibble$contrast[1])
  separator <- if (grepl(" - ", first_contrast, fixed = TRUE)) " - " else if (grepl(" / ", first_contrast, fixed = TRUE)) " / " else " - "
  
  # Extract group pairs from contrast column (e.g., "control - peripheral" -> c("control", "peripheral"))
  contrast_pairs <- strsplit(as.character(contrasts_tibble$contrast), separator, fixed = TRUE)
  group1 <- sapply(contrast_pairs, function(x) trimws(x[1]))
  group2 <- sapply(contrast_pairs, function(x) trimws(x[2]))
  
  # Create formatted table
  formatted <- contrasts_tibble %>%
    rename(p = p.value) %>%
    mutate(
      group1 = group1,
      group2 = group2,
      label = if (!is.null(sig_labels)) sig_labels else get_p_string(p)
    )
  
  # Add y positions if provided
  if (!is.null(y_positions)) {
    if (length(y_positions) != nrow(formatted)) {
      cli::cli_warn("y_positions length ({length(y_positions)}) != number of contrasts ({nrow(formatted)}). Skipping y.position assignment.")
    } else {
      formatted <- formatted %>% mutate(y.position = y_positions)
    }
  }
  
  formatted %>% select(p, group1, group2, label, everything())
}


#' Create dwell time EMM plot for building location (outside/inside)
#'
#' @param model_full_emm Fitted full emmeans object (already converted from model)
#' @param df Data frame for violin overlay
#' @param contrast_table Optional tibble with significance info
#'
#' @return ggplot object
#'
#' @examples
#' \dontrun{
#'   model_full_emm <- fit_model_full(df, median_clusterDuration)
#'   dwell_plot <- plot_dwell_time_by_location(model_full_emm, df)
#' }
plot_dwell_time_by_location <- function(model_full_emm, df, contrast_table = NULL) {
  
  ref_grid_emm <- ref_grid(model_full_emm)
  
  p <- ref_grid_emm %>% 
    emmip(~ building_location, CIs = TRUE, type = "response", style = "factor") +
    geom_violin(aes(y = median_clusterDuration, x = building_location), alpha = 0.2, data = df) +
    labs(
      title = "EMM(s) of Dwell Time",
      x = "Region",
      y = "Dwell Time (s)"
    ) +
    scale_x_discrete(expand = c(0, 0.5)) +
    scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
    theme_classic() +
    theme(legend.position = "none")
  
  if (!is.null(contrast_table)) {
    p <- p + add_pvalue(contrast_table, tip.length = 0)
  }
  
  p
}


#' Create NDC (node degree count) EMM plot
#'
#' @param node_model_full_emm Fitted Poisson emmeans object (already converted from model)
#' @param df_node Data frame with node-level data
#' @param contrast_table Optional tibble with significance info
#'
#' @return ggplot object
#'
#' @examples
#' \dontrun{
#'   node_model_full_emm <- fit_model_full(df_node, "mean_connections", family = poisson())
#'   ndc_plot <- plot_ndc_by_location(node_model_full_emm, df_node)
#' }
plot_ndc_by_location <- function(node_model_full_emm, df_node, contrast_table = NULL) {
  
  node_ref_grid_emm <- ref_grid(node_model_full_emm)
  
  p <- node_ref_grid_emm %>% 
    emmip(~ building_location, CIs = TRUE, type = "response", style = "factor") +
    geom_violin(aes(y = mean_connections, x = building_location), alpha = 0.2, data = df_node) +
    labs(
      title = "EMM(s) of NDC",
      x = "Region",
      y = "NDC"
    ) +
    scale_x_discrete(expand = c(0, 0.5)) +
    scale_y_continuous(limits = c(0, 20), expand = c(0, 0)) +
    theme_classic() +
    theme(legend.position = "none")
  
  if (!is.null(contrast_table)) {
    p <- p + add_pvalue(contrast_table, tip.length = 0)
  }
  
  p
}

#' Create EMM plot with violin overlay
#'
#' @param emm_object emmeans object from extract_emmeans()
#' @param data Original data frame for violin plot
#' @param response_col Character name of response variable column
#' @param group_col Character name of grouping variable (default: "group")
#' @param title Plot title
#' @param y_label Y-axis label
#' @param y_limits Y-axis limits as c(min, max)
#' @param contrast_table Optional tibble from format_contrast_table() for significance markers
#'
#' @return ggplot object
#'
#' @details
#' Creates a plot with:
#' - emmeans point estimates and confidence intervals
#' - Overlaid violin plot for raw data distribution
#' - Optional significance annotations
#'
#' @examples
#' \dontrun{
#'   emm <- extract_emmeans(model, ~ group)
#'   p <- plot_emmeans_with_violin(
#'     emm_object = emm,
#'     data = df,
#'     response_col = "median_clusterDuration",
#'     title = "Dwell Time",
#'     y_label = "Dwell Time (s)",
#'     y_limits = c(0, 1)
#'   )
#' }
plot_emmeans_with_violin <- function(emm_object, data, response_col, 
                                     group_col = "group", title = NULL, 
                                     y_label = NULL, y_limits = NULL,
                                     contrast_table = NULL) {
    
    # Get emmeans reference grid
    ref_grid_emm <- ref_grid(emm_object)
    
    # Create base emmip plot
    p <- ref_grid_emm %>% 
        emmip(~ group, CIs = TRUE, type = "response", style = "factor") +
        geom_violin(
            aes_string(y = response_col, x = group_col), 
            alpha = 0.2, 
            data = data
        )
    
    # Add labels
    if (!is.null(title)) {
        p <- p + labs(title = title)
    }
    if (!is.null(y_label)) {
        p <- p + labs(y = y_label)
    } else {
        p <- p + labs(y = response_col)
    }
    p <- p + labs(x = NULL)
    
    # Add significance markers if provided
    if (!is.null(contrast_table)) {
        p <- p + ggpubr::add_pvalue(contrast_table, tip.length = 0)
    }
    
    # Apply scale adjustments
    p <- p +
        scale_x_discrete(expand = c(0, 0.5)) +
        theme_classic() +
        theme(legend.position = "none")
    
    if (!is.null(y_limits)) {
        p <- p + scale_y_continuous(limits = y_limits, expand = c(0, 0))
    }
    
    p
}


#' Create dwell time EMM plot (scotoma)
#'
#' @param model_full_emm Fitted full emmeans object (already converted from model)
#' @param df Data frame for violin overlay
#' @param contrast_table Optional tibble with significance info
#'
#' @return ggplot object
#'
#' @details
#' Specialized wrapper for dwell time visualization.
#' Shows inverse-link Gamma model results.
#'
#' @examples
#' \dontrun{
#'   model_full_emm <- fit_model_full(df, median_clusterDuration, 
#'                                    group_levels = c("central", "control", "peripheral"))
#'   dwell_plot <- plot_dwell_time(model_full_emm, df)
#' }
plot_dwell_time <- function(model_full_emm, df, contrast_table = NULL) {
    
    ref_grid_emm <- ref_grid(model_full_emm)
    
    p <- ref_grid_emm %>% 
        emmip(~ group, CIs = TRUE, type = "response", style = "factor") +
        geom_violin(aes(y = median_clusterDuration, x = group), alpha = 0.2, data = df) +
        labs(
            title = "EMM(s) of Dwell Time",
            x = "Group",
            y = "Dwell Time (s)"
        ) +
        scale_x_discrete(expand = c(0, 0.5)) +
        scale_y_continuous(limits = c(0, 1), expand = c(0, 0)) +
        theme_classic() +
        theme(legend.position = "none")
    
    if (!is.null(contrast_table)) {
        p <- p + add_pvalue(contrast_table, tip.length = 0)
    }
    
    p
}


#' Create NDC (node degree count) EMM plot
#'
#' @param node_model_full_emm Fitted Poisson emmeans object (already converted from model)
#' @param df_node Data frame with node-level data
#'
#' @return ggplot object
#'
#' @details
#' Specialized wrapper for NDC visualization.
#' Shows log-link Poisson model results.
#'
#' @examples
#' \dontrun{
#'   node_model_full_emm <- fit_model_full(df_node, "mean_connections", 
#'                                         family = poisson(), 
#'                                         group_levels = c("central", "control", "peripheral"))
#'   ndc_plot <- plot_ndc(node_model_full_emm, df_node)
#' }
plot_ndc <- function(node_model_full_emm, df_node) {
    
    node_ref_grid_emm <- ref_grid(node_model_full_emm)
    
    node_ref_grid_emm %>% 
        emmip(~ group, CIs = TRUE, type = "response", style = "factor") +
        geom_violin(aes(y = mean_connections, x = group), alpha = 0.2, data = df_node) +
        labs(
            title = "EMM(s) of NDC",
            x = "Group",
            y = "NDC"
        ) +
        scale_x_discrete(expand = c(0, 0.5)) +
        scale_y_continuous(limits = c(0, 20), expand = c(0, 0)) +
        theme_classic() +
        theme(legend.position = "none")
}


#' Combine dwell time and NDC plots
#'
#' @param dwell_plot ggplot object from plot_dwell_time()
#' @param ndc_plot ggplot object from plot_ndc()
#'
#' @return patchwork object combining both plots
#'
#' @details
#' Creates a 2-panel figure with unified aesthetics:
#' - Shared x-axis labels for condition names
#' - Shared themes and legend settings
#' - Publication-ready layout
#'
#' @examples
#' \dontrun{
#'   combined_plot <- combine_dwell_ndc_plots(dwell_plot, ndc_plot)
#' }
combine_dwell_ndc_plots <- function(dwell_plot, ndc_plot) {
    (dwell_plot + ndc_plot + plot_layout(guides = "collect", axis_titles = "collect")) & 
        scale_x_discrete(
            labels = c(
                "central" = "central\nscotoma", 
                "control" = "control", 
                "peripheral" = "peripheral\nscotoma"
            )
        ) &
        xlab("Viewing Conditions") &
        (theme_classic() + theme(legend.position = "none"))
}


#' Combine dwell time and NDC plots by building location
#'
#' @param dwell_plot ggplot object from plot_dwell_time_by_location()
#' @param ndc_plot ggplot object from plot_ndc_by_location()
#'
#' @return patchwork object combining both plots
#'
#' @details
#' Creates a 2-panel figure for building location plots with unified aesthetics.
#' X-axis labels reflect outside/inside locations.
#'
#' @examples
#' \dontrun{
#'   combined_plot <- combine_dwell_ndc_plots_by_location(dwell_plot, ndc_plot)
#' }
combine_dwell_ndc_plots_by_location <- function(dwell_plot, ndc_plot) {
    (dwell_plot + ndc_plot + plot_layout(guides = "collect", axis_titles = "collect")) & 
        scale_x_discrete(
            labels = c(
                "outside" = "outside", 
                "inside" = "inside"
            )
        ) &
        xlab("Region") &
        (theme_classic() + theme(legend.position = "none"))
}
