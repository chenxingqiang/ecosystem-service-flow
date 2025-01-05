%% TestLineOfSight.m
% Test script for the Line of Sight Model

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
fprintf('Initializing Line of Sight Model...\n');

try
    % Create model instance
    model = LineOfSightModel(data.dem, data.observation_points, ...
        data.observer_heights, ...
        'cell_width', data.cell_width, ...
        'cell_height', data.cell_height);
    
    fprintf('Model initialized successfully.\n');
catch ME
    fprintf('Error initializing model: %s\n', ME.message);
    return;
end

%% Test Visibility Calculation
fprintf('\nTesting visibility calculation...\n');

try
    % Calculate visibility
    [visibility, view_angles] = model.calculateVisibility();
    
    fprintf('Visibility calculation completed.\n');
    fprintf('Visible Area: %.2f%%\n', 100 * sum(visibility(:)) / numel(visibility));
    fprintf('Mean View Angle: %.2f degrees\n', mean(view_angles(visibility)));
catch ME
    fprintf('Error calculating visibility: %s\n', ME.message);
end

%% Test Viewshed Analysis
fprintf('\nTesting viewshed analysis...\n');

try
    % Calculate viewshed
    [viewshed, distance_to_observer] = model.calculateViewshed();
    
    fprintf('Viewshed analysis completed.\n');
    fprintf('Viewshed Coverage: %.2f%%\n', 100 * sum(viewshed(:)) / numel(viewshed));
    fprintf('Mean Distance to Observer: %.2f m\n', mean(distance_to_observer(viewshed)));
catch ME
    fprintf('Error calculating viewshed: %s\n', ME.message);
end

%% Test Atmospheric Effects
fprintf('\nTesting atmospheric effects...\n');

try
    % Calculate atmospheric visibility
    [atm_visibility, extinction] = model.calculateAtmosphericVisibility();
    
    fprintf('Atmospheric visibility calculation completed.\n');
    fprintf('Mean Atmospheric Visibility: %.2f%%\n', 100 * mean(atm_visibility(:)));
    fprintf('Mean Extinction Coefficient: %.4f\n', mean(extinction(:)));
catch ME
    fprintf('Error calculating atmospheric visibility: %s\n', ME.message);
end

%% Visualization
fprintf('\nGenerating visualizations...\n');

try
    % Create figure
    figure('Position', [100 100 1200 800]);
    
    % Plot DEM with observers
    subplot(2,3,1);
    imagesc(data.dem);
    hold on;
    [obs_y, obs_x] = find(data.observation_points);
    scatter(obs_x, obs_y, 50, 'r', 'filled');
    hold off;
    colorbar;
    title('DEM with Observers');
    axis equal tight;
    
    % Plot visibility
    subplot(2,3,2);
    imagesc(visibility);
    colorbar;
    title('Visibility');
    axis equal tight;
    
    % Plot view angles
    subplot(2,3,3);
    imagesc(view_angles);
    colorbar;
    title('View Angles');
    axis equal tight;
    
    % Plot viewshed
    subplot(2,3,4);
    imagesc(viewshed);
    colorbar;
    title('Viewshed');
    axis equal tight;
    
    % Plot distance to observer
    subplot(2,3,5);
    imagesc(distance_to_observer);
    colorbar;
    title('Distance to Observer');
    axis equal tight;
    
    % Plot atmospheric visibility
    subplot(2,3,6);
    imagesc(atm_visibility);
    colorbar;
    title('Atmospheric Visibility');
    axis equal tight;
    
    % Adjust layout
    sgtitle('Line of Sight Model Results');
    
    % Save figure
    saveas(gcf, 'output/test_results/line_of_sight_results.png');
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
    results.observation_points = data.observation_points;
    results.observer_heights = data.observer_heights;
    results.visibility = visibility;
    results.view_angles = view_angles;
    results.viewshed = viewshed;
    results.distance_to_observer = distance_to_observer;
    results.atmospheric_visibility = atm_visibility;
    results.extinction = extinction;
    
    % Calculate summary statistics
    results.summary = struct();
    results.summary.visible_area = sum(visibility(:)) / numel(visibility);
    results.summary.mean_view_angle = mean(view_angles(visibility));
    results.summary.viewshed_coverage = sum(viewshed(:)) / numel(viewshed);
    results.summary.mean_distance = mean(distance_to_observer(viewshed));
    results.summary.mean_atm_visibility = mean(atm_visibility(:));
    results.summary.mean_extinction = mean(extinction(:));
    
    % Save to file
    save('output/test_results/line_of_sight_detailed_results.mat', 'results');
    fprintf('Results saved successfully.\n');
catch ME
    fprintf('Error saving results: %s\n', ME.message);
end

%% Performance Analysis
fprintf('\nAnalyzing performance...\n');

try
    % Time the main calculations
    tic;
    [visibility, view_angles] = model.calculateVisibility();
    visibility_time = toc;
    
    tic;
    [viewshed, distance_to_observer] = model.calculateViewshed();
    viewshed_time = toc;
    
    tic;
    [atm_visibility, extinction] = model.calculateAtmosphericVisibility();
    atmospheric_time = toc;
    
    % Print performance results
    fprintf('\nPerformance Results:\n');
    fprintf('Visibility Calculation Time: %.3f seconds\n', visibility_time);
    fprintf('Viewshed Calculation Time: %.3f seconds\n', viewshed_time);
    fprintf('Atmospheric Effects Time: %.3f seconds\n', atmospheric_time);
    fprintf('Total Computation Time: %.3f seconds\n', ...
        visibility_time + viewshed_time + atmospheric_time);
catch ME
    fprintf('Error in performance analysis: %s\n', ME.message);
end

%% Validation Checks
fprintf('\nPerforming validation checks...\n');

try
    % Check visibility constraints
    valid_visibility = all(visibility(:) >= 0 & visibility(:) <= 1);
    valid_angles = all(view_angles(:) >= -180 & view_angles(:) <= 180);
    
    % Check viewshed constraints
    valid_viewshed = all(viewshed(:) >= 0 & viewshed(:) <= 1);
    valid_distance = all(distance_to_observer(:) >= 0);
    
    % Check atmospheric constraints
    valid_atm_visibility = all(atm_visibility(:) >= 0 & atm_visibility(:) <= 1);
    valid_extinction = all(extinction(:) >= 0);
    
    % Print validation results
    fprintf('\nValidation Results:\n');
    fprintf('Valid Visibility: %s\n', string(valid_visibility));
    fprintf('Valid View Angles: %s\n', string(valid_angles));
    fprintf('Valid Viewshed: %s\n', string(valid_viewshed));
    fprintf('Valid Distance: %s\n', string(valid_distance));
    fprintf('Valid Atmospheric Visibility: %s\n', string(valid_atm_visibility));
    fprintf('Valid Extinction: %s\n', string(valid_extinction));
catch ME
    fprintf('Error in validation checks: %s\n', ME.message);
end

%% Analysis by Observer
fprintf('\nAnalyzing visibility by observer...\n');

try
    % Find observer locations
    [obs_y, obs_x] = find(data.observation_points);
    num_observers = length(obs_x);
    
    fprintf('\nVisibility Metrics by Observer:\n');
    for i = 1:num_observers
        % Calculate visibility metrics for each observer
        observer_mask = distance_to_observer(:,:,i) > 0;
        visible_area = sum(observer_mask(:)) / numel(observer_mask);
        mean_distance = mean(distance_to_observer(observer_mask));
        max_distance = max(distance_to_observer(observer_mask));
        
        fprintf('Observer %d (x=%d, y=%d):\n', i, obs_x(i), obs_y(i));
        fprintf('  Visible Area: %.2f%%\n', 100 * visible_area);
        fprintf('  Mean View Distance: %.2f m\n', mean_distance);
        fprintf('  Maximum View Distance: %.2f m\n', max_distance);
    end
catch ME
    fprintf('Error in observer analysis: %s\n', ME.message);
end

%% Spatial Analysis
fprintf('\nAnalyzing spatial patterns...\n');

try
    % Calculate visibility statistics by elevation
    elevation_bins = linspace(min(data.dem(:)), max(data.dem(:)), 10);
    fprintf('\nVisibility by Elevation:\n');
    for i = 1:length(elevation_bins)-1
        mask = data.dem >= elevation_bins(i) & data.dem < elevation_bins(i+1);
        visible_ratio = sum(visibility(mask)) / sum(mask(:));
        fprintf('Elevation %.1f-%.1f m: %.2f%% visible\n', ...
            elevation_bins(i), elevation_bins(i+1), 100 * visible_ratio);
    end
catch ME
    fprintf('Error in spatial analysis: %s\n', ME.message);
end

fprintf('\nTest completed successfully.\n'); 