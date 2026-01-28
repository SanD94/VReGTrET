library(lme4)
library(broom.mixed)
library(dplyr)
library(stringr)
library(performance)


get_model_summary <- function(model_0, model_inter, model_full, null_model = NULL) {
    # Use model_0 as null_model if not provided
    if (is.null(null_model)) {
        null_model <- model_0
    }

    ## model 0 summary
    model_0_mean_summary <- model_0 %>% tidy() %>% pull(estimate)
    model_0_std_summary <- model_0 %>% tidy() %>% pull(std.error)

    model_0_intercept <- c(
        model_0_mean_summary[1] %>% round(3),
        (model_0_mean_summary[1] - 1.96 * model_0_std_summary[1]) %>% round(3),
        (model_0_mean_summary[1] + 1.96 * model_0_std_summary[1]) %>% round(3)
    )

    model_0_corr_var <- model_0 %>% VarCorr() %>% as_tibble() %>% pull()
    model_0_building_var <- model_0_corr_var[1]^2 %>% round(3)
    model_0_PID_var <- model_0_corr_var[2]^2 %>% round(3)
    model_0_res_var <- model_0_corr_var[3]^2 %>% round(3)
    if (is.na(model_0_res_var)) {
        model_0_res_var <- "—"
    }
    model_0_intercept_mean <- model_0_intercept[1]
    model_0_intercept_lowCL <- model_0_intercept[2]
    model_0_intercept_highCL <- model_0_intercept[3]
    model_0_icc <- model_0 %>% icc(by_group = TRUE, null_model = null_model) %>% pull(ICC)
    model_0_icc_building <- model_0_icc[1] %>% round(4) * 100
    model_0_icc_PID <- model_0_icc[2] %>% round(4) * 100
    model_0_AIC <- model_0 %>% AIC() %>% round(1)

    model_null <- list(
        "—",
        "*b* [95% CI]",
        str_interp(
            "${model_0_intercept_mean} [${model_0_intercept_lowCL}, ${model_0_intercept_highCL}]"
        ),
        "—",
        "—",
        "$\\sigma^2$",
        model_0_building_var,
        model_0_PID_var,
        model_0_res_var,
        "—", "—",
        model_0_icc_building, model_0_icc_PID, 
        model_0_AIC
    )

    ## model inter summary
    model_inter_anova_table <- anova(model_0, model_inter)
    model_inter_chi_sq <- model_inter_anova_table$Chisq[2] %>% round(2)
    

    model_inter_mean_summary <- model_inter %>% tidy() %>% pull(estimate)
    model_inter_std_summary <- model_inter %>% tidy() %>% pull(std.error)

    model_inter_intercept <- c(
        model_inter_mean_summary[1] %>% round(3),
        (model_inter_mean_summary[1] - 1.96 * model_inter_std_summary[1]) %>% round(3),
        (model_inter_mean_summary[1] + 1.96 * model_inter_std_summary[1]) %>% round(3)
    )

    model_inter_building <- c(
        model_inter_mean_summary[2] %>% round(3),
        (model_inter_mean_summary[2] - 1.96 * model_inter_std_summary[2]) %>% round(3),
        (model_inter_mean_summary[2] + 1.96 * model_inter_std_summary[2]) %>% round(3)
    )

    model_inter_corr_var <- model_inter %>% VarCorr() %>% as_tibble() %>% pull()
    model_inter_building_var <- model_inter_corr_var[1]^2 %>% round(3)
    model_inter_PID_var <- model_inter_corr_var[2]^2 %>% round(3)
    model_inter_res_var <- model_inter_corr_var[3]^2 %>% round(3)
    if (is.na(model_inter_res_var)) {
        model_inter_res_var <- "—"
    }
    model_inter_icc <- model_inter %>% icc(by_group = TRUE, null_model = null_model) %>% pull(ICC)
    model_inter_icc_building <- model_inter_icc[1] %>% round(4) * 100
    model_inter_icc_PID <- model_inter_icc[2] %>% round(4) * 100
    model_inter_nakagawa <- model_inter %>% r2_nakagawa(null_model = null_model)
    model_inter_nakagawa_marginal <- model_inter_nakagawa$R2_marginal %>% unname() %>% round(4) * 100
    model_inter_nakagawa_conditional <- model_inter_nakagawa$R2_conditional %>% unname() %>% round(4) * 100
    model_inter_AIC <- model_inter %>% AIC() %>% round(1)


    model_inter_summary <- list(
        str_interp("*$\\chi^2$(1)$ = ${model_inter_chi_sq}, $p$ < .001*"),
        "*b* [95% CI]",
        str_interp(
            "${model_inter_intercept[1]} [${model_inter_intercept[2]}, ${model_inter_intercept[3]}]"
        ),
        str_interp(
            "${model_inter_building[1]} [${model_inter_building[2]}, ${model_inter_building[3]}]"
        ),
        "—",
        "$\\sigma^2$",
        model_inter_building_var,
        model_inter_PID_var,
        model_inter_res_var,
        model_inter_nakagawa_marginal, model_inter_nakagawa_conditional,
        model_inter_icc_building, model_inter_icc_PID, 
        model_inter_AIC
    )


    ## model full summary
    model_full_anova_table <- anova(model_inter, model_full)
    model_full_chi_sq <- model_full_anova_table$Chisq[2] %>% round(2)

    model_full_mean_summary <- model_full %>% tidy() %>% pull(estimate)
    model_full_std_summary <- model_full %>% tidy() %>% pull(std.error)

    model_full_intercept <- c(
        model_full_mean_summary[1] %>% round(3),
        (model_full_mean_summary[1] - 1.96 * model_full_std_summary[1]) %>% round(3),
        (model_full_mean_summary[1] + 1.96 * model_full_std_summary[1]) %>% round(3)
    )

    model_full_building <- c(
        model_full_mean_summary[2] %>% round(3),
        (model_full_mean_summary[2] - 1.96 * model_full_std_summary[2]) %>% round(3),
        (model_full_mean_summary[2] + 1.96 * model_full_std_summary[2]) %>% round(3)
    )

    model_full_peripheral <- c(
        model_full_mean_summary[3] %>% round(3),
        (model_full_mean_summary[3] - 1.96 * model_full_std_summary[3]) %>% round(3),
        (model_full_mean_summary[3] + 1.96 * model_full_std_summary[3]) %>% round(3)
    )

    model_full_central <- c(
        model_full_mean_summary[4] %>% round(3),
        (model_full_mean_summary[4] - 1.96 * model_full_std_summary[4]) %>% round(3),
        (model_full_mean_summary[4] + 1.96 * model_full_std_summary[4]) %>% round(3)
    )

    model_full_corr_var <- model_full %>% VarCorr() %>% as_tibble() %>% pull()
    model_full_building_var <- model_full_corr_var[1]^2 %>% round(3)
    model_full_PID_var <- model_full_corr_var[2]^2 %>% round(3)
    model_full_res_var <- model_full_corr_var[3]^2 %>% round(3)
    if (is.na(model_full_res_var)) {
        model_full_res_var <- "—"
    }
    model_full_icc <- model_full %>% icc(by_group = TRUE, null_model = null_model) %>% pull(ICC)
    model_full_icc_building <- model_full_icc[1] %>% round(4) * 100 
    model_full_icc_PID <- model_full_icc[2] %>% round(4) * 100
    model_full_nakagawa <- model_full %>% r2_nakagawa(null_model = null_model)
    model_full_nakagawa_marginal <- model_full_nakagawa$R2_marginal %>% unname() %>% round(4) * 100
    model_full_nakagawa_conditional <- model_full_nakagawa$R2_conditional %>% unname() %>% round(4) * 100
    model_full_AIC <- model_full %>% AIC() %>% round(1)


    model_full_summary <- list(
        str_interp("*$\\chi^2$(1)$ = ${model_full_chi_sq}, $p$ < .001*"),
        "*b* [95% CI]",
        str_interp(
            "${model_full_intercept[1]} [${model_full_intercept[2]}, ${model_full_intercept[3]}]"
        ),
        str_interp(
            "${model_full_building[1]} [${model_full_building[2]}, ${model_full_building[3]}]"
        ),
        str_interp(
            "${model_full_peripheral[1]} [${model_full_peripheral[2]}, ${model_full_peripheral[3]}]"
        ),
        "$\\sigma^2$",
        model_full_building_var,
        model_full_PID_var,
        model_full_res_var,
        model_full_nakagawa_marginal, model_full_nakagawa_conditional,
        model_full_icc_building, model_full_icc_PID, 
        model_full_AIC
    )


    list(
        model_null = model_null,
        model_inter_summary = model_inter_summary,
        model_full_summary = model_full_summary
    )
}


get_sim_model_summary <- function(model_0, model_inter, model_full, null_model = NULL) {
    # Use model_0 as null_model if not provided
    if (is.null(null_model)) {
        null_model <- model_0
    }

    ## model 0 summary
    model_0_mean_summary <- model_0 %>% tidy() %>% pull(estimate)
    model_0_std_summary <- model_0 %>% tidy() %>% pull(std.error)

    model_0_intercept <- c(
        model_0_mean_summary[1] %>% round(3),
        (model_0_mean_summary[1] - 1.96 * model_0_std_summary[1]) %>% round(3),
        (model_0_mean_summary[1] + 1.96 * model_0_std_summary[1]) %>% round(3)
    )

    model_0_corr_var <- model_0 %>% VarCorr() %>% as_tibble() %>% pull()
    model_0_building_var <- model_0_corr_var[1]^2 %>% round(3)
    model_0_PID_var <- model_0_corr_var[2]^2 %>% round(3)
    model_0_res_var <- model_0_corr_var[3]^2 %>% round(3)
    if (is.na(model_0_res_var)) {
        model_0_res_var <- "—"
    }
    model_0_intercept_mean <- model_0_intercept[1]
    model_0_intercept_lowCL <- model_0_intercept[2]
    model_0_intercept_highCL <- model_0_intercept[3]
    model_0_icc <- model_0 %>% icc(by_group = TRUE, null_model = null_model) %>% pull(ICC)
    model_0_icc_building <- model_0_icc[1] %>% round(4) * 100
    model_0_icc_PID <- model_0_icc[2] %>% round(4) * 100
    model_0_AIC <- model_0 %>% AIC() %>% round(1)

    model_null <- list(
        "—",
        "*b* [95% CI]",
        str_interp(
            "${model_0_intercept_mean} [${model_0_intercept_lowCL}, ${model_0_intercept_highCL}]"
        ),
        "—",
        "—",
        "—",
        "$\\sigma^2$",
        model_0_building_var,
        model_0_PID_var,
        model_0_res_var,
        "—", "—",
        model_0_icc_building, model_0_icc_PID, 
        model_0_AIC
    )

    ## model inter summary
    model_inter_anova_table <- anova(model_0, model_inter)
    model_inter_chi_sq <- model_inter_anova_table$Chisq[2] %>% round(2)
    model_inter_p_val <- model_inter_anova_table$`Pr(>Chisq)`[2] %>% round(4)
    model_inter_p_sig <- get_p_string(model_inter_p_val)

    model_inter_mean_summary <- model_inter %>% tidy() %>% pull(estimate)
    model_inter_std_summary <- model_inter %>% tidy() %>% pull(std.error)

    model_inter_intercept <- c(
        model_inter_mean_summary[1] %>% round(3),
        (model_inter_mean_summary[1] - 1.96 * model_inter_std_summary[1]) %>% round(3),
        (model_inter_mean_summary[1] + 1.96 * model_inter_std_summary[1]) %>% round(3)
    )

    model_inter_building <- c(
        model_inter_mean_summary[2] %>% round(3),
        (model_inter_mean_summary[2] - 1.96 * model_inter_std_summary[2]) %>% round(3),
        (model_inter_mean_summary[2] + 1.96 * model_inter_std_summary[2]) %>% round(3)
    )

    model_inter_corr_var <- model_inter %>% VarCorr() %>% as_tibble() %>% pull()
    model_inter_building_var <- model_inter_corr_var[1]^2 %>% round(3)
    model_inter_PID_var <- model_inter_corr_var[2]^2 %>% round(3)
    model_inter_res_var <- model_inter_corr_var[3]^2 %>% round(3)
    if (is.na(model_inter_res_var)) {
        model_inter_res_var <- "—"
    }
    model_inter_icc <- model_inter %>% icc(by_group = TRUE, null_model = null_model) %>% pull(ICC)
    model_inter_icc_building <- model_inter_icc[1] %>% round(4) * 100
    model_inter_icc_PID <- model_inter_icc[2] %>% round(4) * 100
    model_inter_nakagawa <- model_inter %>% r2_nakagawa(null_model = null_model)
    model_inter_nakagawa_marginal <- model_inter_nakagawa$R2_marginal %>% unname() %>% round(4) * 100
    model_inter_nakagawa_conditional <- model_inter_nakagawa$R2_conditional %>% unname() %>% round(4) * 100
    model_inter_AIC <- model_inter %>% AIC() %>% round(1)


    model_inter_summary <- list(
        str_interp("$\\chi^2(1)$ = ${model_inter_chi_sq}, ${model_inter_p_sig}"),
        "*b* [95% CI]",
        str_interp(
            "${model_inter_intercept[1]} [${model_inter_intercept[2]}, ${model_inter_intercept[3]}]"
        ),
        str_interp(
            "${model_inter_building[1]} [${model_inter_building[2]}, ${model_inter_building[3]}]"
        ),
        "—",
        "—",
        "$\\sigma^2$",
        model_inter_building_var,
        model_inter_PID_var,
        model_inter_res_var,
        model_inter_nakagawa_marginal, model_inter_nakagawa_conditional,
        model_inter_icc_building, model_inter_icc_PID, 
        model_inter_AIC
    )


    ## model full summary
    model_full_anova_table <- anova(model_inter, model_full)
    model_full_chi_sq <- model_full_anova_table$Chisq[2] %>% round(2)
    model_full_p_val <- model_full_anova_table$`Pr(>Chisq)`[2] %>% round(4)
    model_full_p_sig <- get_p_string(model_full_p_val)

    model_full_mean_summary <- model_full %>% tidy() %>% pull(estimate)
    model_full_std_summary <- model_full %>% tidy() %>% pull(std.error)

    model_full_intercept <- c(
        model_full_mean_summary[1] %>% round(3),
        (model_full_mean_summary[1] - 1.96 * model_full_std_summary[1]) %>% round(3),
        (model_full_mean_summary[1] + 1.96 * model_full_std_summary[1]) %>% round(3)
    )

    model_full_building <- c(
        model_full_mean_summary[2] %>% round(3),
        (model_full_mean_summary[2] - 1.96 * model_full_std_summary[2]) %>% round(3),
        (model_full_mean_summary[2] + 1.96 * model_full_std_summary[2]) %>% round(3)
    )

    model_full_peripheral <- c(
        model_full_mean_summary[3] %>% round(3),
        (model_full_mean_summary[3] - 1.96 * model_full_std_summary[3]) %>% round(3),
        (model_full_mean_summary[3] + 1.96 * model_full_std_summary[3]) %>% round(3)
    )

    model_full_central <- c(
        model_full_mean_summary[4] %>% round(3),
        (model_full_mean_summary[4] - 1.96 * model_full_std_summary[4]) %>% round(3),
        (model_full_mean_summary[4] + 1.96 * model_full_std_summary[4]) %>% round(3)
    )

    model_full_corr_var <- model_full %>% VarCorr() %>% as_tibble() %>% pull()
    model_full_building_var <- model_full_corr_var[1]^2 %>% round(3)
    model_full_PID_var <- model_full_corr_var[2]^2 %>% round(3)
    model_full_res_var <- model_full_corr_var[3]^2 %>% round(3)
    if (is.na(model_full_res_var)) {
        model_full_res_var <- "—"
    }
    model_full_icc <- model_full %>% icc(by_group = TRUE, null_model = null_model) %>% pull(ICC)
    model_full_icc_building <- model_full_icc[1] %>% round(4) * 100 
    model_full_icc_PID <- model_full_icc[2] %>% round(4) * 100
    model_full_nakagawa <- model_full %>% r2_nakagawa(null_model = null_model)
    model_full_nakagawa_marginal <- model_full_nakagawa$R2_marginal %>% unname() %>% round(4) * 100
    model_full_nakagawa_conditional <- model_full_nakagawa$R2_conditional %>% unname() %>% round(4) * 100
    model_full_AIC <- model_full %>% AIC() %>% round(1)


    model_full_summary <- list(
        str_interp("$\\chi^2(2)$ = ${model_full_chi_sq}, ${model_full_p_sig}"),
        "*b* [95% CI]",
        str_interp(
            "${model_full_intercept[1]} [${model_full_intercept[2]}, ${model_full_intercept[3]}]"
        ),
        str_interp(
            "${model_full_building[1]} [${model_full_building[2]}, ${model_full_building[3]}]"
        ),
        str_interp(
            "${model_full_peripheral[1]} [${model_full_peripheral[2]}, ${model_full_peripheral[3]}]"
        ),
        str_interp(
            "${model_full_central[1]} [${model_full_central[2]}, ${model_full_central[3]}]"
        ),
        "$\\sigma^2$",
        model_full_building_var,
        model_full_PID_var,
        model_full_res_var,
        model_full_nakagawa_marginal, model_full_nakagawa_conditional,
        model_full_icc_building, model_full_icc_PID, 
        model_full_AIC
    )


    list(
        model_null = model_null,
        model_inter_summary = model_inter_summary,
        model_full_summary = model_full_summary
    )
}


get_p_string <- function(p_val) {
    p_val_round <- round(p_val, 2)
    dplyr::case_when(
        p_val < 0.001 ~ "$p$ < .001***",
        p_val < 0.01 ~ "$p$ < .01**",
        p_val < 0.05 ~ "$p$ < .05*",
        TRUE ~ str_interp("$p$ = ${p_val_round}")
    )
}