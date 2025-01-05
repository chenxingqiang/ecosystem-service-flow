% TestSubsistenceFisheries.m
% Test script for the Subsistence Fisheries Model

% Setup
clear;
clc;

% Create output directory if it doesn't exist
if ~exist('output/test_results', 'dir')
    mkdir('output/test_results');
end

% Add source directory to path
addpath(genpath('../src'));

% Generate Test Data
fprintf('Generating test data...\n');
data = GenerateTestData();

% Initialize Model
fprintf('Initializing Subsistence Fisheries Model...\n');

try
    % Create model instance
    model = SubsistenceFisheriesModel(data.fish_population, data.fishing_effort, ...
        data.habitat_quality, data.marine_protection, ...
        'cell_width', data.cell_width, ...
        'cell_height', data.cell_height, ...
        'time_step', data.time_step);
    
    fprintf('Model initialized successfully.\n');
catch ME
    fprintf('Error initializing model: %s\n', ME.message);
    return;
end

% Test Fishery Yield Calculation
fprintf('\nTesting fishery yield calculation...\n');

try
    % Calculate fishery yield
    [yield, catch_per_unit_effort] = model.calculateFisheryYield();
    
    fprintf('Fishery yield calculation completed.\n');
    fprintf('Total Yield: %.2f tons\n', sum(yield(:)));
    fprintf('Mean CPUE: %.2f kg/hour\n', mean(catch_per_unit_effort(:)));
catch ME
    fprintf('Error calculating fishery yield: %s\n', ME.message);
end

% Test Fishery Dynamics Simulation
fprintf('\nTesting fishery dynamics simulation...\n');

try
    % Simulate fishery dynamics
    num_timesteps = 12;  % Simulate 12 months
    [population_dynamics, harvest_rate] = model.simulateFisheryDynamics(num_timesteps);
    
    fprintf('Fishery dynamics simulation completed.\n');
    fprintf('Final Mean Population: %.2f tons/km²\n', mean(population_dynamics(:,:,end)));
    fprintf('Mean Harvest Rate: %.2f%%\n', mean(harvest_rate(:)) * 100);
catch ME
    fprintf('Error simulating fishery dynamics: %s\n', ME.message);
end

% Visualization
fprintf('\nGenerating visualizations...\n');

try
    % Create figure
    figure('Position', [100 100 1200 800]);
    
    % Plot fish population
    subplot(2,3,1);
    imagesc(data.fish_population);
    colorbar;
    title('Fish Population');
    axis equal tight;
    
    % Plot fishing effort
    subplot(2,3,2);
    imagesc(data.fishing_effort);
    colorbar;
    title('Fishing Effort');
    axis equal tight;
    
    % Plot fishery yield
    subplot(2,3,3);
    imagesc(yield);
    colorbar;
    title('Fishery Yield');
    axis equal tight;
    
    % Plot CPUE
    subplot(2,3,4);
    imagesc(catch_per_unit_effort);
    colorbar;
    title('Catch Per Unit Effort');
    axis equal tight;
    
    % Plot final population
    subplot(2,3,5);
    imagesc(population_dynamics(:,:,end));
    colorbar;
    title('Final Population');
    axis equal tight;
    
    % Plot harvest rate
    subplot(2,3,6);
    imagesc(harvest_rate);
    colorbar;
    title('Harvest Rate');
    axis equal tight;
    
    % Adjust layout
    sgtitle('Subsistence Fisheries Model Results');
    
    % Save figure
    saveas(gcf, 'output/test_results/fisheries_results.png');
    fprintf('Visualizations saved.\n');
catch ME
    fprintf('Error generating visualizations: %s\n', ME.message);
end

% Save Results
fprintf('\nSaving results...\n');

try
    % Create results structure
    results = struct();
    results.fish_population = data.fish_population;
    results.fishing_effort = data.fishing_effort;
    results.habitat_quality = data.habitat_quality;
    results.marine_protection = data.marine_protection;
    results.yield = yield;
    results.catch_per_unit_effort = catch_per_unit_effort;
    results.population_dynamics = population_dynamics;
    results.harvest_rate = harvest_rate;
    
    % Calculate summary statistics
    results.summary = struct();
    results.summary.total_yield = sum(yield(:));
    results.summary.mean_cpue = mean(catch_per_unit_effort(:));
    results.summary.final_population = mean(population_dynamics(:,:,end));
    results.summary.mean_harvest_rate = mean(harvest_rate(:));
    
    % Save to file
    save('output/test_results/fisheries_detailed_results.mat', 'results');
    fprintf('Results saved successfully.\n');
catch ME
    fprintf('Error saving results: %s\n', ME.message);
end

% Performance Analysis
fprintf('\nAnalyzing performance...\n');

try
    % Time the main calculations
    tic;
    [yield, catch_per_unit_effort] = model.calculateFisheryYield();
    yield_time = toc;
    
    tic;
    [population_dynamics, harvest_rate] = model.simulateFisheryDynamics(num_timesteps);
    simulation_time = toc;
    
    % Print performance results
    fprintf('\nPerformance Results:\n');
    fprintf('Yield Calculation Time: %.3f seconds\n', yield_time);
    fprintf('Simulation Time: %.3f seconds\n', simulation_time);
    fprintf('Total Computation Time: %.3f seconds\n', ...
        yield_time + simulation_time);
catch ME
    fprintf('Error in performance analysis: %s\n', ME.message);
end

% Validation Checks
fprintf('\nPerforming validation checks...\n');

try
    % Check yield constraints
    valid_yield = all(yield(:) >= 0);
    valid_cpue = all(catch_per_unit_effort(:) >= 0);
    
    % Check population constraints
    valid_population = all(population_dynamics(:) >= 0);
    valid_harvest = all(harvest_rate(:) >= 0 & harvest_rate(:) <= 1);
    
    % Check mass conservation
    total_initial = sum(data.fish_population(:));
    total_final = sum(population_dynamics(:,:,end));
    total_harvest = sum(yield(:)) * num_timesteps;
    mass_balance_error = abs(total_initial - (total_final + total_harvest)) / total_initial;
    
    % Print validation results
    fprintf('\nValidation Results:\n');
    fprintf('Valid Yield: %s\n', string(valid_yield));
    fprintf('Valid CPUE: %s\n', string(valid_cpue));
    fprintf('Valid Population: %s\n', string(valid_population));
    fprintf('Valid Harvest Rate: %s\n', string(valid_harvest));
    fprintf('Mass Balance Error: %.2f%%\n', mass_balance_error * 100);
catch ME
    fprintf('Error in validation checks: %s\n', ME.message);
end

% Analysis by Habitat Quality
fprintf('\nAnalyzing fishery by habitat quality...\n');

try
    % Define habitat quality categories
    quality_levels = unique(data.habitat_quality);
    fprintf('\nFishery Metrics by Habitat Quality:\n');
    for i = 1:length(quality_levels)
        mask = data.habitat_quality == quality_levels(i);
        fprintf('Habitat Quality Level %d:\n', quality_levels(i));
        fprintf('  Mean Yield: %.2f tons\n', mean(yield(mask)));
        fprintf('  Mean CPUE: %.2f kg/hour\n', mean(catch_per_unit_effort(mask)));
        fprintf('  Mean Final Population: %.2f tons/km²\n', ...
            mean(population_dynamics(mask & population_dynamics(:,:,end))));
    end
catch ME
    fprintf('Error in habitat quality analysis: %s\n', ME.message);
end

% Temporal Analysis
fprintf('\nAnalyzing temporal patterns...\n');

try
    % Calculate monthly statistics
    monthly_population = reshape(mean(mean(population_dynamics, 1), 2), [], num_timesteps);
    
    % Print temporal patterns
    fprintf('\nMonthly Patterns:\n');
    fprintf('Initial Population: %.2f tons/km²\n', monthly_population(1));
    fprintf('Final Population: %.2f tons/km²\n', monthly_population(end));
    fprintf('Population Change: %.2f%%\n', ...
        (monthly_population(end) - monthly_population(1)) / monthly_population(1) * 100);
catch ME
    fprintf('Error in temporal analysis: %s\n', ME.message);
end

fprintf('\nTest completed successfully.\n'); 