function fit_normal(data)
% Fit a normal distribution to the data
pd = fitdist(data, 'Gamma');

% Create a histogram
histogram(data, 'Normalization', 'pdf', 'EdgeColor', 'k');  % Histogram

% Plot the fitted PDF
x = linspace(min(data), max(data), 100);
y = pdf(pd, x);
hold on;
plot(x, y, 'r', 'LineWidth', 2);  % Plot the fitted distribution

title('Weibull Fit');
xlabel('log(time) s');
ylabel('pdf');
legend('data', 'fit wbl');
grid on;
hold off
end