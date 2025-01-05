%% TestFloodWater.m
% Test script for the Flood Water Flow Model

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
fprintf('Initializing Flood Water Flow Model...\n');

try
    % Create model instance
    model = FloodWaterFlowModel(data.dem, data.precipitation, ...
        data.land_use, data.soil_type, ...
        'cell_width', data.cell_width, ...
        'cell_height', data.cell_height, ...
        'time_step', data.time_step);
    
    fprintf('Model initialized successfully.\n');
catch ME
    fprintf('Error initializing model: %s\n', ME.message);
    return;
end

%% Test Flow Direction Calculation
fprintf('\nTesting flow direction calculation...\n');

try
    % Calculate flow direction
    [flow_dir, slope] = model.calculateFlowDirection();
    
    fprintf('Flow direction calculation completed.\n');
    fprintf('Mean Slope: %.2f degrees\n', mean(slope(:)));
catch ME
    fprintf('Error calculating flow direction: %s\n', ME.message);
end

%% Test Flood Propagation Simulation
fprintf('\nTesting flood propagation simulation...\n');

try
    % Simulate flood propagation
    num_timesteps = 24;  % Simulate 24 hours
    [flood_depth, flow_velocity] = model.simulateFloodPropagation(num_timesteps);
    
    fprintf('Flood propagation simulation completed.\n');
    fprintf('Maximum Flood Depth: %.2f meters\n', max(flood_depth(:)));
    fprintf('Mean Flow Velocity: %.2f m/s\n', mean(flow_velocity(:)));
catch ME
    fprintf('Error simulating flood propagation: %s\n', ME.message);
end

%% Test Runoff Calculation
fprintf('\nTesting runoff calculation...\n');

try
    % Calculate runoff
    [runoff, infiltration] = model.calculateRunoff();
    
    fprintf('Runoff calculation completed.\n');
    fprintf('Total Runoff: %.2f m³\n', sum(runoff(:)));
    fprintf('Total Infiltration: %.2f m³\n', sum(infiltration(:)));
catch ME
    fprintf('Error calculating runoff: %s\n', ME.message);
end

%% Visualization
fprintf('\nGenerating visualizations...\n');

try
    % Create figure
    figure('Position', [100 100 1200 800]);
    
    % Plot DEM
    subplot(2,3,1);
    imagesc(data.dem);
    colorbar;
    title('Digital Elevation Model');
    axis equal tight;
    
    % Plot flow direction
    subplot(2,3,2);
    imagesc(flow_dir);
    colorbar;
    title('Flow Direction');
    axis equal tight;
    
    % Plot slope
    subplot(2,3,3);
    imagesc(slope);
    colorbar;
    title('Slope');
    axis equal tight;
    
    % Plot flood depth
    subplot(2,3,4);
    imagesc(flood_depth(:,:,end));
    colorbar;
    title('Final Flood Depth');
    axis equal tight;
    
    % Plot flow velocity
    subplot(2,3,5);
    imagesc(flow_velocity(:,:,end));
    colorbar;
    title('Final Flow Velocity');
    axis equal tight;
    
    % Plot runoff
    subplot(2,3,6);
    imagesc(runoff);
    colorbar;
    title('Runoff');
    axis equal tight;
    
    % Adjust layout
    sgtitle('Flood Water Flow Model Results');
    
    % Save figure
    saveas(gcf, 'output/test_results/flood_water_results.png');
    fprintf('Visualizations saved.\n');
catch ME
    fprintf('Error generating visualizations: %s\n', ME.message);
end

%% Save Results
fprintf('\nSaving results...\n');

try
    % Create results structure
    results = struct();
    results.dem = data.dem;
    results.precipitation = data.precipitation;
    results.land_use = data.land_use;
    results.soil_type = data.soil_type;
    results.flow_direction = flow_dir;
    results.slope = slope;
    results.flood_depth = flood_depth;
    results.flow_velocity = flow_velocity;
    results.runoff = runoff;
    results.infiltration = infiltration;
    
    % Calculate summary statistics
    results.summary = struct();
    results.summary.mean_slope = mean(slope(:));
    results.summary.max_flood_depth = max(flood_depth(:));
    results.summary.mean_velocity = mean(flow_velocity(:));
    results.summary.total_runoff = sum(runoff(:));
    results.summary.total_infiltration = sum(infiltration(:));
    
    % Save to file
    save('output/test_results/flood_water_detailed_results.mat', 'results');
    fprintf('Results saved successfully.\n');
catch ME
    fprintf('Error saving results: %s\n', ME.message);
end

%% Performance Analysis
fprintf('\nAnalyzing performance...\n');

try
    % Time the main calculations
    tic;
    [flow_dir, slope] = model.calculateFlowDirection();
    flow_time = toc;
    
    tic;
    [flood_depth, flow_velocity] = model.simulateFloodPropagation(num_timesteps);
    simulation_time = toc;
    
    tic;
    [runoff, infiltration] = model.calculateRunoff();
    runoff_time = toc;
    
    % Print performance results
    fprintf('\nPerformance Results:\n');
    fprintf('Flow Direction Time: %.3f seconds\n', flow_time);
    fprintf('Simulation Time: %.3f seconds\n', simulation_time);
    fprintf('Runoff Calculation Time: %.3f seconds\n', runoff_time);
    fprintf('Total Computation Time: %.3f seconds\n', ...
        flow_time + simulation_time + runoff_time);
catch ME
    fprintf('Error in performance analysis: %s\n', ME.message);
end

%% Validation Checks
fprintf('\nPerforming validation checks...\n');

try
    % Check flow direction validity
    valid_direction = all(flow_dir(:) >= 1 & flow_dir(:) <= 8);
    valid_slope = all(slope(:) >= 0);
    
    % Check flood dynamics constraints
    valid_depth = all(flood_depth(:) >= 0);
    valid_velocity = all(flow_velocity(:) >= 0);
    
    % Check water balance
    total_precipitation = sum(data.precipitation(:)) * data.cell_width * data.cell_height;
    total_runoff = sum(runoff(:));
    total_infiltration = sum(infiltration(:));
    water_balance_error = abs(total_precipitation - (total_runoff + total_infiltration)) / total_precipitation;
    
    % Print validation results
    fprintf('\nValidation Results:\n');
    fprintf('Valid Flow Direction: %s\n', string(valid_direction));
    fprintf('Valid Slope: %s\n', string(valid_slope));
    fprintf('Valid Depth: %s\n', string(valid_depth));
    fprintf('Valid Velocity: %s\n', string(valid_velocity));
    fprintf('Water Balance Error: %.2f%%\n', water_balance_error * 100);
catch ME
    fprintf('Error in validation checks: %s\n', ME.message);
end

%% Analysis by Land Use Type
fprintf('\nAnalyzing flood characteristics by land use type...\n');

try
    % Calculate statistics by land use type
    land_use_types = unique(data.land_use);
    fprintf('\nFlood Metrics by Land Use Type:\n');
    for i = 1:length(land_use_types)
        mask = data.land_use == land_use_types(i);
        fprintf('Land Use Type %d:\n', land_use_types(i));
        fprintf('  Mean Flood Depth: %.2f m\n', mean(flood_depth(mask)));
        fprintf('  Mean Flow Velocity: %.2f m/s\n', mean(flow_velocity(mask)));
        fprintf('  Mean Runoff: %.2f m³\n', mean(runoff(mask)));
    end
catch ME
    fprintf('Error in land use analysis: %s\n', ME.message);
end

%% Temporal Analysis
fprintf('\nAnalyzing temporal patterns...\n');

try
    % Calculate hourly statistics
    hourly_depth = reshape(mean(mean(flood_depth, 1), 2), [], num_timesteps);
    hourly_velocity = reshape(mean(mean(flow_velocity, 1), 2), [], num_timesteps);
    
    % Print temporal patterns
    fprintf('\nHourly Patterns:\n');
    fprintf('Peak Flood Depth: %.2f m at hour %d\n', ...
        max(hourly_depth), find(hourly_depth == max(hourly_depth)));
    fprintf('Peak Flow Velocity: %.2f m/s at hour %d\n', ...
        max(hourly_velocity), find(hourly_velocity == max(hourly_velocity)));
catch ME
    fprintf('Error in temporal analysis: %s\n', ME.message);
end

fprintf('\nTest completed successfully.\n'); 