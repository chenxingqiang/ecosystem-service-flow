%% TestSurfaceWater.m
% Test script for the Surface Water Flow Model

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
fprintf('Initializing Surface Water Flow Model...\n');

try
    % Create model instance
    model = SurfaceWaterFlowModel(data.dem, data.precipitation, ...
        data.land_use, data.soil_type, data.soil_moisture, ...
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

%% Test Water Movement Simulation
fprintf('\nTesting water movement simulation...\n');

try
    % Simulate water movement
    num_timesteps = 24;  % Simulate 24 hours
    [water_depth, flow_velocity] = model.simulateWaterMovement(num_timesteps);
    
    fprintf('Water movement simulation completed.\n');
    fprintf('Maximum Water Depth: %.2f meters\n', max(water_depth(:)));
    fprintf('Mean Flow Velocity: %.2f m/s\n', mean(flow_velocity(:)));
catch ME
    fprintf('Error simulating water movement: %s\n', ME.message);
end

%% Test Water Balance Calculation
fprintf('\nTesting water balance calculation...\n');

try
    % Calculate water balance components
    [runoff, infiltration, evaporation] = model.calculateWaterBalance();
    
    fprintf('Water balance calculation completed.\n');
    fprintf('Total Runoff: %.2f m³\n', sum(runoff(:)));
    fprintf('Total Infiltration: %.2f m³\n', sum(infiltration(:)));
    fprintf('Total Evaporation: %.2f m³\n', sum(evaporation(:)));
catch ME
    fprintf('Error calculating water balance: %s\n', ME.message);
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
    
    % Plot water depth
    subplot(2,3,3);
    imagesc(water_depth(:,:,end));
    colorbar;
    title('Final Water Depth');
    axis equal tight;
    
    % Plot flow velocity
    subplot(2,3,4);
    imagesc(flow_velocity(:,:,end));
    colorbar;
    title('Final Flow Velocity');
    axis equal tight;
    
    % Plot runoff
    subplot(2,3,5);
    imagesc(runoff);
    colorbar;
    title('Runoff');
    axis equal tight;
    
    % Plot infiltration
    subplot(2,3,6);
    imagesc(infiltration);
    colorbar;
    title('Infiltration');
    axis equal tight;
    
    % Adjust layout
    sgtitle('Surface Water Flow Model Results');
    
    % Save figure
    saveas(gcf, 'output/test_results/surface_water_results.png');
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
    results.soil_moisture = data.soil_moisture;
    results.flow_direction = flow_dir;
    results.slope = slope;
    results.water_depth = water_depth;
    results.flow_velocity = flow_velocity;
    results.runoff = runoff;
    results.infiltration = infiltration;
    results.evaporation = evaporation;
    
    % Calculate summary statistics
    results.summary = struct();
    results.summary.mean_slope = mean(slope(:));
    results.summary.max_water_depth = max(water_depth(:));
    results.summary.mean_velocity = mean(flow_velocity(:));
    results.summary.total_runoff = sum(runoff(:));
    results.summary.total_infiltration = sum(infiltration(:));
    results.summary.total_evaporation = sum(evaporation(:));
    
    % Save to file
    save('output/test_results/surface_water_detailed_results.mat', 'results');
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
    [water_depth, flow_velocity] = model.simulateWaterMovement(num_timesteps);
    simulation_time = toc;
    
    tic;
    [runoff, infiltration, evaporation] = model.calculateWaterBalance();
    balance_time = toc;
    
    % Print performance results
    fprintf('\nPerformance Results:\n');
    fprintf('Flow Direction Time: %.3f seconds\n', flow_time);
    fprintf('Simulation Time: %.3f seconds\n', simulation_time);
    fprintf('Water Balance Time: %.3f seconds\n', balance_time);
    fprintf('Total Computation Time: %.3f seconds\n', ...
        flow_time + simulation_time + balance_time);
catch ME
    fprintf('Error in performance analysis: %s\n', ME.message);
end

%% Validation Checks
fprintf('\nPerforming validation checks...\n');

try
    % Check flow direction validity
    valid_direction = all(flow_dir(:) >= 1 & flow_dir(:) <= 8);
    valid_slope = all(slope(:) >= 0);
    
    % Check water dynamics constraints
    valid_depth = all(water_depth(:) >= 0);
    valid_velocity = all(flow_velocity(:) >= 0);
    
    % Check water balance
    total_precipitation = sum(data.precipitation(:)) * data.cell_width * data.cell_height;
    total_runoff = sum(runoff(:));
    total_infiltration = sum(infiltration(:));
    total_evaporation = sum(evaporation(:));
    water_balance_error = abs(total_precipitation - ...
        (total_runoff + total_infiltration + total_evaporation)) / total_precipitation;
    
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

%% Analysis by Land Use and Soil Type
fprintf('\nAnalyzing water characteristics by land use and soil type...\n');

try
    % Analysis by land use type
    land_use_types = unique(data.land_use);
    fprintf('\nWater Metrics by Land Use Type:\n');
    for i = 1:length(land_use_types)
        mask = data.land_use == land_use_types(i);
        fprintf('Land Use Type %d:\n', land_use_types(i));
        fprintf('  Mean Water Depth: %.2f m\n', mean(water_depth(mask)));
        fprintf('  Mean Flow Velocity: %.2f m/s\n', mean(flow_velocity(mask)));
        fprintf('  Mean Runoff: %.2f m³\n', mean(runoff(mask)));
        fprintf('  Mean Infiltration: %.2f m³\n', mean(infiltration(mask)));
    end
    
    % Analysis by soil type
    soil_types = unique(data.soil_type);
    fprintf('\nWater Metrics by Soil Type:\n');
    for i = 1:length(soil_types)
        mask = data.soil_type == soil_types(i);
        fprintf('Soil Type %d:\n', soil_types(i));
        fprintf('  Mean Infiltration: %.2f m³\n', mean(infiltration(mask)));
        fprintf('  Mean Soil Moisture: %.2f\n', mean(data.soil_moisture(mask)));
    end
catch ME
    fprintf('Error in land use and soil type analysis: %s\n', ME.message);
end

%% Temporal Analysis
fprintf('\nAnalyzing temporal patterns...\n');

try
    % Calculate hourly statistics
    hourly_depth = reshape(mean(mean(water_depth, 1), 2), [], num_timesteps);
    hourly_velocity = reshape(mean(mean(flow_velocity, 1), 2), [], num_timesteps);
    
    % Print temporal patterns
    fprintf('\nHourly Patterns:\n');
    fprintf('Peak Water Depth: %.2f m at hour %d\n', ...
        max(hourly_depth), find(hourly_depth == max(hourly_depth)));
    fprintf('Peak Flow Velocity: %.2f m/s at hour %d\n', ...
        max(hourly_velocity), find(hourly_velocity == max(hourly_velocity)));
    fprintf('Water Depth Change: %.2f%%\n', ...
        (hourly_depth(end) - hourly_depth(1)) / hourly_depth(1) * 100);
catch ME
    fprintf('Error in temporal analysis: %s\n', ME.message);
end

fprintf('\nTest completed successfully.\n'); 