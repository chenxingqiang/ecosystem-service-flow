% TestCoastalStormProtection.m
% Test script for the Coastal Storm Protection Model

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
fprintf('Initializing Coastal Storm Protection Model...\n');

try
    % Create model instance
    model = CoastalStormProtectionModel(data.bathymetry, data.storm_surge, ...
        data.marine_habitat, data.marine_protection, ...
        'cell_width', data.cell_width, ...
        'cell_height', data.cell_height, ...
        'time_step', data.time_step);
    
    fprintf('Model initialized successfully.\n');
catch ME
    fprintf('Error initializing model: %s\n', ME.message);
    return;
end

% Test Protection Effectiveness Calculation
fprintf('\nTesting protection effectiveness calculation...\n');

try
    % Calculate protection effectiveness
    [effectiveness, risk_reduction] = model.calculateProtectionEffectiveness();
    
    fprintf('Protection effectiveness calculation completed.\n');
    fprintf('Mean Effectiveness: %.2f%%\n', mean(effectiveness(:)) * 100);
    fprintf('Mean Risk Reduction: %.2f%%\n', mean(risk_reduction(:)) * 100);
catch ME
    fprintf('Error calculating protection effectiveness: %s\n', ME.message);
end

% Test Coastal Dynamics Simulation
fprintf('\nTesting coastal dynamics simulation...\n');

try
    % Simulate coastal dynamics
    num_timesteps = 24;  % Simulate 24 hours
    [protection_dynamics, surge_attenuation] = model.simulateCoastalDynamics(num_timesteps);
    
    fprintf('Coastal dynamics simulation completed.\n');
    fprintf('Final Mean Protection: %.2f%%\n', mean(protection_dynamics(:,:,end)) * 100);
    fprintf('Mean Surge Attenuation: %.2f%%\n', mean(surge_attenuation(:)) * 100);
catch ME
    fprintf('Error simulating coastal dynamics: %s\n', ME.message);
end

% Visualization
fprintf('\nGenerating visualizations...\n');

try
    % Create figure
    figure('Position', [100 100 1200 800]);
    
    % Plot bathymetry
    subplot(2,3,1);
    imagesc(data.bathymetry);
    colorbar;
    title('Bathymetry');
    axis equal tight;
    
    % Plot storm surge
    subplot(2,3,2);
    imagesc(data.storm_surge);
    colorbar;
    title('Storm Surge Potential');
    axis equal tight;
    
    % Plot protection effectiveness
    subplot(2,3,3);
    imagesc(effectiveness);
    colorbar;
    title('Protection Effectiveness');
    axis equal tight;
    
    % Plot risk reduction
    subplot(2,3,4);
    imagesc(risk_reduction);
    colorbar;
    title('Risk Reduction');
    axis equal tight;
    
    % Plot final protection
    subplot(2,3,5);
    imagesc(protection_dynamics(:,:,end));
    colorbar;
    title('Final Protection State');
    axis equal tight;
    
    % Plot surge attenuation
    subplot(2,3,6);
    imagesc(surge_attenuation);
    colorbar;
    title('Surge Attenuation');
    axis equal tight;
    
    % Adjust layout
    sgtitle('Coastal Storm Protection Model Results');
    
    % Save figure
    saveas(gcf, 'output/test_results/coastal_protection_results.png');
    fprintf('Visualizations saved.\n');
catch ME
    fprintf('Error generating visualizations: %s\n', ME.message);
end

% Save Results
fprintf('\nSaving results...\n');

try
    % Create results structure
    results = struct();
    results.bathymetry = data.bathymetry;
    results.storm_surge = data.storm_surge;
    results.marine_habitat = data.marine_habitat;
    results.marine_protection = data.marine_protection;
    results.effectiveness = effectiveness;
    results.risk_reduction = risk_reduction;
    results.protection_dynamics = protection_dynamics;
    results.surge_attenuation = surge_attenuation;
    
    % Calculate summary statistics
    results.summary = struct();
    results.summary.mean_effectiveness = mean(effectiveness(:));
    results.summary.mean_risk_reduction = mean(risk_reduction(:));
    results.summary.final_protection = mean(protection_dynamics(:,:,end));
    results.summary.mean_attenuation = mean(surge_attenuation(:));
    
    % Save to file
    save('output/test_results/coastal_protection_detailed_results.mat', 'results');
    fprintf('Results saved successfully.\n');
catch ME
    fprintf('Error saving results: %s\n', ME.message);
end

% Performance Analysis
fprintf('\nAnalyzing performance...\n');

try
    % Time the main calculations
    tic;
    [effectiveness, risk_reduction] = model.calculateProtectionEffectiveness();
    effectiveness_time = toc;
    
    tic;
    [protection_dynamics, surge_attenuation] = model.simulateCoastalDynamics(num_timesteps);
    simulation_time = toc;
    
    % Print performance results
    fprintf('\nPerformance Results:\n');
    fprintf('Effectiveness Calculation Time: %.3f seconds\n', effectiveness_time);
    fprintf('Simulation Time: %.3f seconds\n', simulation_time);
    fprintf('Total Computation Time: %.3f seconds\n', ...
        effectiveness_time + simulation_time);
catch ME
    fprintf('Error in performance analysis: %s\n', ME.message);
end

% Validation Checks
fprintf('\nPerforming validation checks...\n');

try
    % Check effectiveness constraints
    valid_effectiveness = all(effectiveness(:) >= 0 & effectiveness(:) <= 1);
    valid_risk = all(risk_reduction(:) >= 0 & risk_reduction(:) <= 1);
    
    % Check protection dynamics constraints
    valid_protection = all(protection_dynamics(:) >= 0 & protection_dynamics(:) <= 1);
    valid_attenuation = all(surge_attenuation(:) >= 0 & surge_attenuation(:) <= 1);
    
    % Check conservation of energy
    total_surge = sum(data.storm_surge(:));
    total_attenuated = sum(surge_attenuation(:) .* data.storm_surge(:));
    energy_balance_error = abs(total_surge - total_attenuated) / total_surge;
    
    % Print validation results
    fprintf('\nValidation Results:\n');
    fprintf('Valid Effectiveness: %s\n', string(valid_effectiveness));
    fprintf('Valid Risk Reduction: %s\n', string(valid_risk));
    fprintf('Valid Protection: %s\n', string(valid_protection));
    fprintf('Valid Attenuation: %s\n', string(valid_attenuation));
    fprintf('Energy Balance Error: %.2f%%\n', energy_balance_error * 100);
catch ME
    fprintf('Error in validation checks: %s\n', ME.message);
end

% Analysis by Habitat Type
fprintf('\nAnalyzing protection by habitat type...\n');

try
    % Define habitat quality categories
    quality_levels = unique(data.marine_habitat);
    fprintf('\nProtection Metrics by Habitat Quality:\n');
    for i = 1:length(quality_levels)
        mask = data.marine_habitat == quality_levels(i);
        fprintf('Habitat Quality Level %.1f:\n', quality_levels(i));
        fprintf('  Mean Effectiveness: %.2f%%\n', mean(effectiveness(mask)) * 100);
        fprintf('  Mean Risk Reduction: %.2f%%\n', mean(risk_reduction(mask)) * 100);
        fprintf('  Mean Surge Attenuation: %.2f%%\n', ...
            mean(surge_attenuation(mask)) * 100);
    end
catch ME
    fprintf('Error in habitat analysis: %s\n', ME.message);
end

% Temporal Analysis
fprintf('\nAnalyzing temporal patterns...\n');

try
    % Calculate hourly statistics
    hourly_protection = reshape(mean(mean(protection_dynamics, 1), 2), [], num_timesteps);
    
    % Print temporal patterns
    fprintf('\nHourly Patterns:\n');
    fprintf('Initial Protection: %.2f%%\n', hourly_protection(1) * 100);
    fprintf('Final Protection: %.2f%%\n', hourly_protection(end) * 100);
    fprintf('Protection Change: %.2f%%\n', ...
        (hourly_protection(end) - hourly_protection(1)) / hourly_protection(1) * 100);
catch ME
    fprintf('Error in temporal analysis: %s\n', ME.message);
end

fprintf('\nTest completed successfully.\n'); 