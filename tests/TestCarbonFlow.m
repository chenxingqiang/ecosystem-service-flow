%% TestCarbonFlow.m
% Test script for the Carbon Flow Model

%% Setup
clear;
clc;

% Create output directory if it doesn't exist
if ~exist('output/test_results', 'dir')
    mkdir('output/test_results');
end

% Add source directory to path
addpath(genpath('../src'));

%% Generate Test Data
fprintf('Generating test data...\n');
data = GenerateTestData();

%% Initialize Model
fprintf('Initializing Carbon Flow Model...\n');

try
    % Create model instance
    model = CarbonFlowModel(data.carbon_storage, data.carbon_sequestration, ...
        data.vegetation_cover, data.vegetation_type, ...
        'cell_width', data.cell_width, ...
        'cell_height', data.cell_height, ...
        'time_step', data.time_step);
    
    fprintf('Model initialized successfully.\n');
catch ME
    fprintf('Error initializing model: %s\n', ME.message);
    return;
end

%% Test Carbon Flow Calculation
fprintf('\nTesting carbon flow calculation...\n');

try
    % Calculate carbon flow
    [flow, sequestration_rate] = model.calculateCarbonFlow();
    
    fprintf('Carbon flow calculation completed.\n');
    fprintf('Total Carbon Flow: %.2f tons/year\n', sum(flow(:)));
    fprintf('Mean Sequestration Rate: %.2f tons/ha/year\n', mean(sequestration_rate(:)));
catch ME
    fprintf('Error calculating carbon flow: %s\n', ME.message);
end

%% Test Carbon Dynamics Simulation
fprintf('\nTesting carbon dynamics simulation...\n');

try
    % Simulate carbon dynamics
    num_timesteps = 12;  % Simulate 12 months
    [carbon_dynamics, flux_rates] = model.simulateCarbonDynamics(num_timesteps);
    
    fprintf('Carbon dynamics simulation completed.\n');
    fprintf('Final Total Carbon: %.2f tons\n', sum(carbon_dynamics(:,:,end)));
    fprintf('Mean Carbon Flux: %.2f tons/month\n', mean(flux_rates(:)));
catch ME
    fprintf('Error simulating carbon dynamics: %s\n', ME.message);
end

%% Visualization
fprintf('\nGenerating visualizations...\n');

try
    % Create figure
    figure('Position', [100 100 1200 800]);
    
    % Plot carbon storage
    subplot(2,3,1);
    imagesc(data.carbon_storage);
    colorbar;
    title('Carbon Storage');
    axis equal tight;
    
    % Plot carbon sequestration
    subplot(2,3,2);
    imagesc(data.carbon_sequestration);
    colorbar;
    title('Carbon Sequestration Rate');
    axis equal tight;
    
    % Plot carbon flow
    subplot(2,3,3);
    imagesc(flow);
    colorbar;
    title('Carbon Flow');
    axis equal tight;
    
    % Plot sequestration rate
    subplot(2,3,4);
    imagesc(sequestration_rate);
    colorbar;
    title('Actual Sequestration Rate');
    axis equal tight;
    
    % Plot final carbon state
    subplot(2,3,5);
    imagesc(carbon_dynamics(:,:,end));
    colorbar;
    title('Final Carbon State');
    axis equal tight;
    
    % Plot flux rates
    subplot(2,3,6);
    imagesc(flux_rates);
    colorbar;
    title('Carbon Flux Rates');
    axis equal tight;
    
    % Adjust layout
    sgtitle('Carbon Flow Model Results');
    
    % Save figure
    saveas(gcf, 'output/test_results/carbon_flow_results.png');
    fprintf('Visualizations saved.\n');
catch ME
    fprintf('Error generating visualizations: %s\n', ME.message);
end

%% Save Results
fprintf('\nSaving results...\n');

try
    % Create results structure
    results = struct();
    results.carbon_storage = data.carbon_storage;
    results.carbon_sequestration = data.carbon_sequestration;
    results.vegetation_cover = data.vegetation_cover;
    results.vegetation_type = data.vegetation_type;
    results.flow = flow;
    results.sequestration_rate = sequestration_rate;
    results.carbon_dynamics = carbon_dynamics;
    results.flux_rates = flux_rates;
    
    % Calculate summary statistics
    results.summary = struct();
    results.summary.total_flow = sum(flow(:));
    results.summary.mean_sequestration = mean(sequestration_rate(:));
    results.summary.final_carbon = sum(carbon_dynamics(:,:,end));
    results.summary.mean_flux = mean(flux_rates(:));
    
    % Save to file
    save('output/test_results/carbon_flow_detailed_results.mat', 'results');
    fprintf('Results saved successfully.\n');
catch ME
    fprintf('Error saving results: %s\n', ME.message);
end

%% Performance Analysis
fprintf('\nAnalyzing performance...\n');

try
    % Time the main calculations
    tic;
    [flow, sequestration_rate] = model.calculateCarbonFlow();
    flow_time = toc;
    
    tic;
    [carbon_dynamics, flux_rates] = model.simulateCarbonDynamics(num_timesteps);
    simulation_time = toc;
    
    % Print performance results
    fprintf('\nPerformance Results:\n');
    fprintf('Flow Calculation Time: %.3f seconds\n', flow_time);
    fprintf('Simulation Time: %.3f seconds\n', simulation_time);
    fprintf('Total Computation Time: %.3f seconds\n', ...
        flow_time + simulation_time);
catch ME
    fprintf('Error in performance analysis: %s\n', ME.message);
end

%% Validation Checks
fprintf('\nPerforming validation checks...\n');

try
    % Check flow constraints
    valid_flow = all(flow(:) >= 0);
    valid_sequestration = all(sequestration_rate(:) >= 0);
    
    % Check carbon dynamics constraints
    valid_carbon = all(carbon_dynamics(:) >= 0);
    valid_flux = all(abs(flux_rates(:)) <= max(data.carbon_sequestration(:)));
    
    % Check mass conservation
    total_initial = sum(data.carbon_storage(:));
    total_final = sum(carbon_dynamics(:,:,end));
    total_sequestered = sum(flow(:)) * num_timesteps;
    mass_balance_error = abs(total_final - (total_initial + total_sequestered)) / total_initial;
    
    % Print validation results
    fprintf('\nValidation Results:\n');
    fprintf('Valid Flow: %s\n', string(valid_flow));
    fprintf('Valid Sequestration: %s\n', string(valid_sequestration));
    fprintf('Valid Carbon: %s\n', string(valid_carbon));
    fprintf('Valid Flux: %s\n', string(valid_flux));
    fprintf('Mass Balance Error: %.2f%%\n', mass_balance_error * 100);
catch ME
    fprintf('Error in validation checks: %s\n', ME.message);
end

%% Analysis by Vegetation Type
fprintf('\nAnalyzing carbon by vegetation type...\n');

try
    % Define vegetation types
    veg_types = unique(data.vegetation_type);
    fprintf('\nCarbon Metrics by Vegetation Type:\n');
    for i = 1:length(veg_types)
        mask = data.vegetation_type == veg_types(i);
        fprintf('Vegetation Type %d:\n', veg_types(i));
        fprintf('  Mean Carbon Storage: %.2f tons/ha\n', mean(data.carbon_storage(mask)));
        fprintf('  Mean Sequestration: %.2f tons/ha/year\n', mean(sequestration_rate(mask)));
        fprintf('  Mean Carbon Flow: %.2f tons/year\n', mean(flow(mask)));
    end
catch ME
    fprintf('Error in vegetation type analysis: %s\n', ME.message);
end

%% Temporal Analysis
fprintf('\nAnalyzing temporal patterns...\n');

try
    % Calculate monthly statistics
    monthly_carbon = reshape(mean(mean(carbon_dynamics, 1), 2), [], num_timesteps);
    
    % Print temporal patterns
    fprintf('\nMonthly Patterns:\n');
    fprintf('Initial Carbon: %.2f tons\n', monthly_carbon(1));
    fprintf('Final Carbon: %.2f tons\n', monthly_carbon(end));
    fprintf('Carbon Change: %.2f%%\n', ...
        (monthly_carbon(end) - monthly_carbon(1)) / monthly_carbon(1) * 100);
catch ME
    fprintf('Error in temporal analysis: %s\n', ME.message);
end

fprintf('\nTest completed successfully.\n'); 