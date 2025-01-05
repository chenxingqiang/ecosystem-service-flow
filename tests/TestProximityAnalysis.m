% TestProximityAnalysis.m
% Test script for the Proximity Analysis Model

% Setup
clear;
clc;

% Create output directory if it doesn't exist
if ~exist('output/test_results', 'dir')
    mkdir('output/test_results');
end

% Add source directory to path
addpath(genpath('../src'));

% Create Test Data
fprintf('Creating test data...\n');

% Initialize grid
grid_size = 50;
[X, Y] = meshgrid(1:grid_size, 1:grid_size);

% Create DEM (using peaks function and scaling)
dem = peaks(grid_size) * 100;  % Scale to reasonable elevation values

% Create land use data (1: urban, 2: agriculture, 3: forest, 4: water)
landuse = ones(grid_size);  % Default to urban
landuse(15:35, 15:35) = 2;  % Agriculture in middle
landuse(20:30, 20:30) = 3;  % Forest in center
landuse(40:50, 1:10) = 4;   % Water body in corner

% Create road network (1: highway, 2: primary, 3: secondary, 4: tertiary)
road_network = zeros(grid_size);
road_network(25, :) = 1;     % Horizontal highway
road_network(:, 25) = 2;     % Vertical primary road
road_network(10:40, 10) = 3; % Secondary road
road_network(10, 10:40) = 3; % Secondary road

% Create barriers (1: impassable)
barriers = zeros(grid_size);
barriers(15:20, 35:40) = 1;  % Barrier block

% Create source points
source_points = [
    25 25;  % Center point
    10 10;  % Corner point
    40 40   % Another point
];

% Initialize Model
fprintf('Initializing Proximity Analysis Model...\n');

try
    % Create model instance
    model = ProximityAnalysisModel(dem, landuse, road_network, barriers, ...
        'cell_width', 30, ...
        'cell_height', 30, ...
        'max_distance', 2000, ...
        'decay_function', 'exponential', ...
        'decay_param', 0.001);
    
    fprintf('Model initialized successfully.\n');
catch ME
    fprintf('Error initializing model: %s\n', ME.message);
    return;
end

% Test Base Cost Calculation
fprintf('\nTesting base cost calculation...\n');

try
    % Calculate base cost
    base_cost = model.calculateBaseCost();
    
    fprintf('Base cost calculation completed.\n');
    fprintf('Mean Base Cost: %.2f\n', mean(base_cost(:)));
catch ME
    fprintf('Error calculating base cost: %s\n', ME.message);
    return;
end

% Test Cost Distance Calculation
fprintf('\nTesting cost distance calculation...\n');

try
    % Calculate cost distance for each source point
    cost_distances = zeros(grid_size, grid_size, size(source_points, 1));
    for i = 1:size(source_points, 1)
        cost_distances(:,:,i) = model.calculateCostDistance(...
            source_points(i,1), source_points(i,2), base_cost);
    end
    
    fprintf('Cost distance calculation completed.\n');
    fprintf('Maximum Cost Distance: %.2f\n', max(cost_distances(:)));
catch ME
    fprintf('Error calculating cost distance: %s\n', ME.message);
end

% Test Accessibility Calculation
fprintf('\nTesting accessibility calculation...\n');

try
    % Calculate accessibility
    [cost_surface, accessibility] = model.calculateAccessibility(source_points);
    
    fprintf('Accessibility calculation completed.\n');
    fprintf('Mean Accessibility: %.2f\n', mean(accessibility(:)));
catch ME
    fprintf('Error calculating accessibility: %s\n', ME.message);
end

% Test Service Flow Calculation
fprintf('\nTesting service flow calculation...\n');

try
    % Create source strength and sink capacity
    source_strength = zeros(grid_size);
    source_strength(sub2ind(size(source_strength), ...
        source_points(:,2), source_points(:,1))) = 100;
    sink_capacity = ones(grid_size) * 50;
    
    % Calculate service flow
    service_flow = model.calculateServiceFlow(source_strength, sink_capacity, accessibility);
    
    fprintf('Service flow calculation completed.\n');
    fprintf('Total Service Flow: %.2f\n', sum(service_flow(:)));
catch ME
    fprintf('Error calculating service flow: %s\n', ME.message);
end

% Visualization
fprintf('\nGenerating visualizations...\n');

try
    % Create figure
    figure('Position', [100 100 1200 800]);
    
    % Plot DEM with source points
    subplot(2,3,1);
    imagesc(dem);
    colorbar;
    hold on;
    plot(source_points(:,1), source_points(:,2), 'r^', 'MarkerSize', 10, 'LineWidth', 2);
    hold off;
    title('DEM with Source Points');
    axis equal tight;
    
    % Plot base cost
    subplot(2,3,2);
    imagesc(base_cost);
    colorbar;
    title('Base Cost Surface');
    axis equal tight;
    
    % Plot cost surface
    subplot(2,3,3);
    imagesc(cost_surface);
    colorbar;
    title('Cost Surface');
    axis equal tight;
    
    % Plot accessibility
    subplot(2,3,4);
    imagesc(accessibility);
    colorbar;
    title('Accessibility Index');
    axis equal tight;
    
    % Plot service flow
    subplot(2,3,5);
    imagesc(service_flow);
    colorbar;
    title('Service Flow');
    axis equal tight;
    
    % Plot road network and barriers
    subplot(2,3,6);
    imagesc(road_network + barriers * 5);  % Barriers shown brighter
    colorbar;
    title('Infrastructure and Barriers');
    axis equal tight;
    
    % Adjust layout
    sgtitle('Proximity Analysis Model Results');
    
    % Save figure
    saveas(gcf, 'output/test_results/proximity_analysis_results.png');
    fprintf('Visualizations saved.\n');
catch ME
    fprintf('Error generating visualizations: %s\n', ME.message);
end

% Save Results
fprintf('\nSaving results...\n');

try
    % Create results structure
    results = struct();
    results.dem = dem;
    results.landuse = landuse;
    results.road_network = road_network;
    results.barriers = barriers;
    results.source_points = source_points;
    results.base_cost = base_cost;
    results.cost_distances = cost_distances;
    results.cost_surface = cost_surface;
    results.accessibility = accessibility;
    results.service_flow = service_flow;
    
    % Calculate summary statistics
    results.summary = struct();
    results.summary.mean_base_cost = mean(base_cost(:));
    results.summary.max_cost_distance = max(cost_distances(:));
    results.summary.mean_accessibility = mean(accessibility(:));
    results.summary.total_service_flow = sum(service_flow(:));
    results.summary.accessible_area = sum(accessibility(:) > 0.1) / numel(accessibility);
    
    % Save to file
    save('output/test_results/proximity_analysis_detailed_results.mat', 'results');
    fprintf('Results saved successfully.\n');
catch ME
    fprintf('Error saving results: %s\n', ME.message);
end

% Performance Analysis
fprintf('\nAnalyzing performance...\n');

try
    % Time the main calculations
    tic;
    base_cost = model.calculateBaseCost();
    base_time = toc;
    
    tic;
    for i = 1:size(source_points, 1)
        model.calculateCostDistance(source_points(i,1), source_points(i,2), base_cost);
    end
    distance_time = toc;
    
    tic;
    [~, accessibility] = model.calculateAccessibility(source_points);
    accessibility_time = toc;
    
    tic;
    service_flow = model.calculateServiceFlow(source_strength, sink_capacity, accessibility);
    flow_time = toc;
    
    % Print performance results
    fprintf('\nPerformance Results:\n');
    fprintf('Base Cost Calculation Time: %.3f seconds\n', base_time);
    fprintf('Cost Distance Calculation Time: %.3f seconds\n', distance_time);
    fprintf('Accessibility Calculation Time: %.3f seconds\n', accessibility_time);
    fprintf('Service Flow Calculation Time: %.3f seconds\n', flow_time);
    fprintf('Total Computation Time: %.3f seconds\n', ...
        base_time + distance_time + accessibility_time + flow_time);
catch ME
    fprintf('Error in performance analysis: %s\n', ME.message);
end

% Validation Checks
fprintf('\nPerforming validation checks...\n');

try
    % Check accessibility range
    valid_accessibility = all(accessibility(:) >= 0 & accessibility(:) <= 1);
    
    % Check service flow conservation
    total_source = sum(source_strength(:));
    total_flow = sum(service_flow(:));
    flow_conservation = abs(total_flow - min(total_source, sum(sink_capacity(:)))) / total_source;
    
    % Check barrier effectiveness
    barrier_cells = barriers > 0;
    barrier_respected = all(accessibility(barrier_cells) == 0);
    
    % Print validation results
    fprintf('\nValidation Results:\n');
    fprintf('Valid Accessibility Range: %s\n', string(valid_accessibility));
    fprintf('Flow Conservation Error: %.2f%%\n', flow_conservation * 100);
    fprintf('Barrier Effectiveness: %s\n', string(barrier_respected));
catch ME
    fprintf('Error in validation checks: %s\n', ME.message);
end

% Analysis by Land Use Type
fprintf('\nAnalyzing accessibility by land use type...\n');

try
    % Calculate mean accessibility by land use type
    landuse_types = unique(landuse);
    fprintf('\nMean Accessibility by Land Use Type:\n');
    for i = 1:length(landuse_types)
        mean_access = mean(accessibility(landuse == landuse_types(i)));
        fprintf('Land Use Type %d: %.2f\n', landuse_types(i), mean_access);
    end
    
    % Calculate service flow by land use type
    fprintf('\nTotal Service Flow by Land Use Type:\n');
    for i = 1:length(landuse_types)
        total_flow = sum(service_flow(landuse == landuse_types(i)));
        fprintf('Land Use Type %d: %.2f\n', landuse_types(i), total_flow);
    end
catch ME
    fprintf('Error in land use analysis: %s\n', ME.message);
end

fprintf('\nTest completed successfully.\n'); 