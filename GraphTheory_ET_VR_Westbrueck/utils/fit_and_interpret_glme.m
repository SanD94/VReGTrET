function [model_result, model_summary] = fit_and_interpret_glme(data, formula, distribution, varargin)
    % FIT_AND_INTERPRET_GLME Fits a generalized linear mixed-effects model and provides interpretation
    %
    % Inputs:
    %   data - table containing the variables in the model
    %   formula - string formula for the model (e.g., 'y ~ x1 + x2 + (1|group)')
    %   distribution - string specifying distribution ('normal', 'binomial', 'poisson', etc.)
    %   varargin - additional name-value pairs for fitglme
    %
    % Outputs:
    %   model_result - the fitted glme model object
    %   model_summary - struct with interpretation and key statistics
    
    % Set defaults for optional parameters
    p = inputParser;
    addParameter(p, 'link', '');
    addParameter(p, 'verbose', true);
    parse(p, varargin{:});
    
    link_function = p.Results.link;
    verbose_output = p.Results.verbose;
    
    % Determine link function if not specified
    if isempty(link_function)
        switch lower(distribution)
            case 'binomial'
                link_function = 'logit';
            case 'poisson'
                link_function = 'log';
            case 'normal'
                link_function = 'identity';
            case 'gamma'
                link_function = 'reciprocal';
            otherwise
                link_function = 'identity';
        end
    end
    
    % Fit the model
    model_result = fitglme(data, formula, 'Distribution', distribution, 'Link', link_function, varargin{:});
    
    % Collect key statistics
    fixed_effects = model_result.Coefficients;
    random_effects = randomEffects(model_result);
    
    % Calculate AIC, BIC
    aic_value = model_result.ModelCriterion.AIC;
    bic_value = model_result.ModelCriterion.BIC;
    
    % Collect p-values and confidence intervals
    p_values = fixed_effects.pValue;
    ci_lower = fixed_effects.Lower;
    ci_upper = fixed_effects.Upper;
    
    % Interpret coefficients based on distribution
    coef_names = fixed_effects.Name;
    coef_values = fixed_effects.Estimate;
    interpretations = cell(size(coef_names));
    
    for i = 1:length(coef_names)
        coef_name = coef_names{i};
        coef_value = coef_values(i);
        p_value = p_values(i);
        
        % Skip intercept for interpretation
        if strcmp(coef_name, '(Intercept)')
            interpretations{i} = 'Baseline value when all predictors are zero/reference level';
            continue;
        end
        
        % Create interpretation based on distribution and link
        switch lower(distribution)
            case 'binomial'
                if p_value < 0.05
                    if coef_value > 0
                        interpretations{i} = sprintf('One unit increase in %s is associated with %.2f increase in log odds (OR=%.2f, p=%.4f)', ...
                            coef_name, coef_value, exp(coef_value), p_value);
                    else
                        interpretations{i} = sprintf('One unit increase in %s is associated with %.2f decrease in log odds (OR=%.2f, p=%.4f)', ...
                            coef_name, abs(coef_value), exp(coef_value), p_value);
                    end
                else
                    interpretations{i} = sprintf('No significant association between %s and outcome (p=%.4f)', coef_name, p_value);
                end
                
            case 'poisson'
                if p_value < 0.05
                    if coef_value > 0
                        interpretations{i} = sprintf('One unit increase in %s is associated with %.2f%% increase in expected count (IRR=%.2f, p=%.4f)', ...
                            coef_name, (exp(coef_value)-1)*100, exp(coef_value), p_value);
                    else
                        interpretations{i} = sprintf('One unit increase in %s is associated with %.2f%% decrease in expected count (IRR=%.2f, p=%.4f)', ...
                            coef_name, (1-exp(coef_value))*100, exp(coef_value), p_value);
                    end
                else
                    interpretations{i} = sprintf('No significant association between %s and outcome (p=%.4f)', coef_name, p_value);
                end
                
            case {'normal', 'gaussian'}
                if p_value < 0.05
                    interpretations{i} = sprintf('One unit increase in %s is associated with %.2f unit change in outcome (p=%.4f)', ...
                        coef_name, coef_value, p_value);
                else
                    interpretations{i} = sprintf('No significant association between %s and outcome (p=%.4f)', coef_name, p_value);
                end
                
            otherwise
                interpretations{i} = sprintf('Coefficient = %.4f (p=%.4f). Interpret based on link function %s', ...
                    coef_value, p_value, link_function);
        end
    end
    
    % Prepare summary structure
    model_summary = struct();
    model_summary.formula = formula;
    model_summary.distribution = distribution;
    model_summary.link = link_function;
    model_summary.aic = aic_value;
    model_summary.bic = bic_value;
    model_summary.fixed_effects = fixed_effects;
    model_summary.random_effects = random_effects;
    model_summary.coefficient_interpretations = interpretations;
    model_summary.significant_predictors = coef_names(p_values < 0.05);
    
    % Display summary if verbose
    if verbose_output
        disp('=== Model Summary ===');
        disp(['Formula: ' formula]);
        disp(['Distribution: ' distribution ' with ' link_function ' link']);
        disp(['AIC: ' num2str(aic_value) ', BIC: ' num2str(bic_value)]);
        disp('');
        disp('=== Coefficient Interpretations ===');
        for i = 1:length(interpretations)
            disp([coef_names{i} ': ' interpretations{i}]);
        end
        
        % Display random effects summary
        if ~isempty(random_effects)
            disp('');
            disp('=== Random Effects ===');
            disp(random_effects);
        end
    end
end