%% TestSedimentTransport.m
% Test script for the Sediment Transport Model

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
fprintf('Initializing Sediment Transport Model...\n');

try
    % Create model instance
    model = SedimentTransportModel(data.dem, data.flow_velocity, ...
        data.water_depth, data.soil_type, ...
        'cell_width', data.cell_width, ...
        'cell_height', data.cell_height, ...
        'time_step', data.time_step);
    
    fprintf('Model initialized successfully.\n');
catch ME
    fprintf('Error initializing model: %s\n', ME.message);
    return;
end

%% Test Sediment Transport Calculation
fprintf('\nTesting sediment transport calculation...\n');

try
    % Calculate sediment transport
    [transport_rate, sediment_load] = model.calculateSedimentTransport();
    
    fprintf('Sediment transport calculation completed.\n');
    fprintf('Total Transport Rate: %.2f kg/s\n', sum(transport_rate(:)));
    fprintf('Mean Sediment Load: %.2f kg/m³\n', mean(sediment_load(:)));
catch ME
    fprintf('Error calculating sediment transport: %s\n', ME.message);
end

%% Test Erosion and Deposition
fprintf('\nTesting erosion and deposition calculation...\n');

try
    % Calculate erosion and deposition
    [erosion_rate, deposition_rate] = model.calculateErosionDeposition();
    
    fprintf('Erosion and deposition calculation completed.\n');
    fprintf('Total Erosion Rate: %.2f kg/s\n', sum(erosion_rate(:)));
    fprintf('Total Deposition Rate: %.2f kg/s\n', sum(deposition_rate(:)));
catch ME
    fprintf('Error calculating erosion and deposition: %s\n', ME.message);
end

%% Test Sediment Dynamics Simulation
fprintf('\nTesting sediment dynamics simulation...\n');

try
    % Simulate sediment dynamics
    num_timesteps = 24;  % Simulate 24 hours
    [bed_elevation, suspended_sediment] = model.simulateSedimentDynamics(num_timesteps);
    
    fprintf('Sediment dynamics simulation completed.\n');
    fprintf('Mean Bed Elevation Change: %.2f m\n', ...
        mean(bed_elevation(:,:,end) - bed_elevation(:,:,1)));
    fprintf('Mean Suspended Sediment: %.2f kg/m³\n', mean(suspended_sediment(:)));
catch ME
    fprintf('Error simulating sediment dynamics: %s\n', ME.message);
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
    
    % Plot transport rate
    subplot(2,3,2);
    imagesc(transport_rate);
    colorbar;
    title('Sediment Transport Rate');
    axis equal tight;
    
    % Plot erosion rate
    subplot(2,3,3);
    imagesc(erosion_rate);
    colorbar;
    title('Erosion Rate');
    axis equal tight;
    
    % Plot deposition rate
    subplot(2,3,4);
    imagesc(deposition_rate);
    colorbar;
    title('Deposition Rate');
    axis equal tight;
    
    % Plot bed elevation change
    subplot(2,3,5);
    imagesc(bed_elevation(:,:,end) - bed_elevation(:,:,1));
    colorbar;
    title('Bed Elevation Change');
    axis equal tight;
    
    % Plot suspended sediment
    subplot(2,3,6);
    imagesc(suspended_sediment(:,:,end));
    colorbar;
    title('Final Suspended Sediment');
    axis equal tight;
    
    % Adjust layout
    sgtitle('Sediment Transport Model Results');
    
    % Save figure
    saveas(gcf, 'output/test_results/sediment_transport_results.png');
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
    results.flow_velocity = data.flow_velocity;
    results.water_depth = data.water_depth;
    results.soil_type = data.soil_type;
    results.transport_rate = transport_rate;
    results.sediment_load = sediment_load;
    results.erosion_rate = erosion_rate;
    results.deposition_rate = deposition_rate;
    results.bed_elevation = bed_elevation;
    results.suspended_sediment = suspended_sediment;
    
    % Calculate summary statistics
    results.summary = struct();
    results.summary.total_transport = sum(transport_rate(:));
    results.summary.mean_sediment_load = mean(sediment_load(:));
    results.summary.total_erosion = sum(erosion_rate(:));
    results.summary.total_deposition = sum(deposition_rate(:));
    results.summary.mean_bed_change = mean(bed_elevation(:,:,end) - bed_elevation(:,:,1));
    results.summary.mean_suspended = mean(suspended_sediment(:));
    
    % Save to file
    save('output/test_results/sediment_transport_detailed_results.mat', 'results');
    fprintf('Results saved successfully.\n');
catch ME
    fprintf('Error saving results: %s\n', ME.message);
end

%% Performance Analysis
fprintf('\nAnalyzing performance...\n');

try
    % Time the main calculations
    tic;
    [transport_rate, sediment_load] = model.calculateSedimentTransport();
    transport_time = toc;
    
    tic;
    [erosion_rate, deposition_rate] = model.calculateErosionDeposition();
    erosion_time = toc;
    
    tic;
    [bed_elevation, suspended_sediment] = model.simulateSedimentDynamics(num_timesteps);
    simulation_time = toc;
    
    % Print performance results
    fprintf('\nPerformance Results:\n');
    fprintf('Transport Calculation Time: %.3f seconds\n', transport_time);
    fprintf('Erosion Calculation Time: %.3f seconds\n', erosion_time);
    fprintf('Simulation Time: %.3f seconds\n', simulation_time);
    fprintf('Total Computation Time: %.3f seconds\n', ...
        transport_time + erosion_time + simulation_time);
catch ME
    fprintf('Error in performance analysis: %s\n', ME.message);
end

%% Validation Checks
fprintf('\nPerforming validation checks...\n');

try
    % Check physical constraints
    valid_transport = all(transport_rate(:) >= 0);
    valid_erosion = all(erosion_rate(:) >= 0);
    valid_deposition = all(deposition_rate(:) >= 0);
    valid_suspended = all(suspended_sediment(:) >= 0);
    
    % Check sediment mass conservation
    total_eroded = sum(erosion_rate(:)) * data.time_step * num_timesteps;
    total_deposited = sum(deposition_rate(:)) * data.time_step * num_timesteps;
    total_suspended = sum(suspended_sediment(:,:,end));
    sediment_balance_error = abs(total_eroded - (total_deposited + total_suspended)) / total_eroded;
    
    % Print validation results
    fprintf('\nValidation Results:\n');
    fprintf('Valid Transport Rate: %s\n', string(valid_transport));
    fprintf('Valid Erosion Rate: %s\n', string(valid_erosion));
    fprintf('Valid Deposition Rate: %s\n', string(valid_deposition));
    fprintf('Valid Suspended Sediment: %s\n', string(valid_suspended));
    fprintf('Sediment Balance Error: %.2f%%\n', sediment_balance_error * 100);
catch ME
    fprintf('Error in validation checks: %s\n', ME.message);
end

%% Analysis by Soil Type
fprintf('\nAnalyzing sediment characteristics by soil type...\n');

try
    % Calculate statistics by soil type
    soil_types = unique(data.soil_type);
    fprintf('\nSediment Metrics by Soil Type:\n');
    for i = 1:length(soil_types)
        mask = data.soil_type == soil_types(i);
        fprintf('Soil Type %d:\n', soil_types(i));
        fprintf('  Mean Transport Rate: %.2f kg/s\n', mean(transport_rate(mask)));
        fprintf('  Mean Erosion Rate: %.2f kg/s\n', mean(erosion_rate(mask)));
        fprintf('  Mean Deposition Rate: %.2f kg/s\n', mean(deposition_rate(mask)));
        fprintf('  Mean Bed Change: %.2f m\n', ...
            mean(bed_elevation(mask,end) - bed_elevation(mask,1)));
    end
catch ME
    fprintf('Error in soil type analysis: %s\n', ME.message);
end

%% Temporal Analysis
fprintf('\nAnalyzing temporal patterns...\n');

try
    % Calculate hourly statistics
    hourly_elevation = reshape(mean(mean(bed_elevation, 1), 2), [], num_timesteps);
    hourly_suspended = reshape(mean(mean(suspended_sediment, 1), 2), [], num_timesteps);
    
    % Print temporal patterns
    fprintf('\nHourly Patterns:\n');
    fprintf('Maximum Bed Change: %.2f m at hour %d\n', ...
        max(abs(diff(hourly_elevation))), ...
        find(abs(diff(hourly_elevation)) == max(abs(diff(hourly_elevation)))));
    fprintf('Peak Suspended Sediment: %.2f kg/m³ at hour %d\n', ...
        max(hourly_suspended), find(hourly_suspended == max(hourly_suspended)));
    fprintf('Net Bed Change: %.2f m\n', hourly_elevation(end) - hourly_elevation(1));
catch ME
    fprintf('Error in temporal analysis: %s\n', ME.message);
end

fprintf('\nTest completed successfully.\n'); 