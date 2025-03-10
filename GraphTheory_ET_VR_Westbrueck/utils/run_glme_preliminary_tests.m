% written by claude sonnet 3.7 concise
function test_results = run_glme_preliminary_tests(data, response_var, predictor_vars, grouping_var)
    % RUN_GLME_PRELIMINARY_TESTS Performs preliminary tests before fitting GLME models
    %
    % Inputs:
    %   data - table containing the variables for analysis
    %   response_var - string with name of response variable
    %   predictor_vars - cell array of strings with predictor variable names
    %   grouping_var - string with name of grouping variable for random effects
    %
    % Outputs:
    %   test_results - struct with test results and recommendations
    
    test_results = struct();
    
    % 1. Check for missing values
    missing_count = sum(ismissing(data(:,[response_var, predictor_vars, grouping_var])));
    test_results.missing_data = table(missing_count', 'RowNames', [response_var, predictor_vars, grouping_var], 'VariableNames', {'MissingCount'});
    test_results.has_missing = any(missing_count > 0);
    
    % 2. Check response variable distribution
    y = data.(response_var);
    test_results.response_stats = struct();
    test_results.response_stats.mean = mean(y, 'omitnan');
    test_results.response_stats.variance = var(y, 'omitnan');
    test_results.response_stats.min = min(y, [], 'omitnan');
    test_results.response_stats.max = max(y, [], 'omitnan');
    
    % Determine if binary
    unique_vals = unique(y);
    test_results.is_binary = (length(unique_vals) <= 2 && all(ismember(unique_vals, [0,1]))) || ...
                            (length(unique_vals) <= 2 && all(ismember(unique_vals, [1,2])));
    
    % Determine if count data
    test_results.is_count = all(y >= 0 & round(y) == y);
    
    % Check for overdispersion in count data
    if test_results.is_count
        test_results.overdispersion = test_results.response_stats.variance > test_results.response_stats.mean;
    end
    
    % 3. Check multicollinearity
    if length(predictor_vars) > 1
        X = data{:, predictor_vars};
        
        % Check for categorical variables and convert to dummy
        for i = 1:length(predictor_vars)
            if iscategorical(data.(predictor_vars{i})) || iscell(data.(predictor_vars{i})) || isstring(data.(predictor_vars{i}))
                % Convert to dummy variables for correlation calculation
                categories = unique(data.(predictor_vars{i}));
                dummy_matrix = zeros(height(data), length(categories)-1);
                for j = 1:length(categories)-1
                    dummy_matrix(:,j) = double(data.(predictor_vars{i}) == categories(j));
                end
                
                % Replace the column in X with dummy matrix
                if i == 1
                    X = [dummy_matrix, X(:,2:end)];
                elseif i == length(predictor_vars)
                    X = [X(:,1:i-1), dummy_matrix];
                else
                    X = [X(:,1:i-1), dummy_matrix, X(:,i+1:end)];
                end
            end
        end
        
        % Remove NaN rows for correlation calculation
        X = X(~any(isnan(X), 2), :);
        
        % Calculate correlation matrix
        test_results.correlation_matrix = corr(X);
        
        % Check for high correlations
        corr_matrix_noDiag = test_results.correlation_matrix - eye(size(test_results.correlation_matrix));
        test_results.high_correlation = any(abs(corr_matrix_noDiag(:)) > 0.8);
        
        % Calculate VIF if more than one predictor
        if size(X, 2) > 1
            test_results.vif = zeros(size(X, 2), 1);
            for i = 1:size(X, 2)
                y_i = X(:,i);
                X_i = X;
                X_i(:,i) = [];
                mdl = fitlm(X_i, y_i);
                test_results.vif(i) = 1/(1-mdl.Rsquared.Ordinary);
            end
            test_results.high_vif = any(test_results.vif > 10);
        end
    end
    
    % 4. Check random effects structure
    groups = unique(data.(grouping_var));
    test_results.number_of_groups = length(groups);
    
    % Count observations per group
    group_counts = arrayfun(@(g) sum(data.(grouping_var) == g), groups);
    test_results.min_group_size = min(group_counts);
    test_results.max_group_size = max(group_counts);
    test_results.mean_group_size = mean(group_counts);
    
    % Check if enough groups for random effects
    test_results.sufficient_groups = test_results.number_of_groups >= 5;
    
    % 5. Make distribution recommendations
    test_results.recommended_distribution = '';
    test_results.recommended_link = '';
    
    if test_results.is_binary
        test_results.recommended_distribution = 'binomial';
        test_results.recommended_link = 'logit';
    elseif test_results.is_count
        if test_results.overdispersion
            test_results.recommended_distribution = 'negative binomial';
            test_results.recommended_link = 'log';
            test_results.notes = 'Consider negative binomial due to overdispersion';
        else
            test_results.recommended_distribution = 'poisson';
            test_results.recommended_link = 'log';
        end
    else
        % Check normality for continuous response
        if length(y) > 3
            [~, p_norm] = lillietest(y);
            test_results.normality_p = p_norm;
            test_results.is_normal = p_norm > 0.05;
            
            if test_results.is_normal
                test_results.recommended_distribution = 'normal';
                test_results.recommended_link = 'identity';
            else
                % Check if strictly positive
                if all(y > 0)
                    test_results.recommended_distribution = 'gamma';
                    test_results.recommended_link = 'log';
                    test_results.notes = 'Non-normal positive data; consider gamma distribution';
                else
                    test_results.recommended_distribution = 'normal';
                    test_results.recommended_link = 'identity';
                    test_results.notes = 'Data is non-normal but using normal distribution with robust SE';
                end
            end
        end
    end
    
    % 6. Generate formula recommendation
    fixed_effects = join(string(predictor_vars), ' + ');
    test_results.recommended_formula = join([response_var ' ~ ' fixed_effects ' + (1|' grouping_var ')']);
    
    % Check if crossed random effects might be appropriate
    % if ismember('subject', predictor_vars) && ~strcmp(grouping_var, 'subject')
    %    test_results.notes_random = 'Consider crossed random effects model if observations are grouped by multiple factors';
    % end
    
    % 7. Sample size adequacy check
    test_results.total_observations = height(data);
    test_results.predictors_count = length(predictor_vars);
    
    if test_results.is_binary
        events = sum(y == 1);
        non_events = sum(y == 0);
        test_results.events_per_variable = min(events, non_events) / test_results.predictors_count;
        test_results.adequate_sample = test_results.events_per_variable >= 10;
    else
        test_results.observations_per_variable = test_results.total_observations / test_results.predictors_count;
        test_results.adequate_sample = test_results.observations_per_variable >= 15;
    end
end