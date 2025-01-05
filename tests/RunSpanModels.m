% RunSpanModels.m
% Comprehensive test script for all ecosystem service flow models

% Setup
clear;
clc;

% Create output directory if it doesn't exist
if ~exist('output/test_results', 'dir')
    mkdir('output/test_results');
end

% Add source directory to path
addpath(genpath('../src'));

% Initialize test grid
grid_size = 50;
dem = peaks(grid_size) * 100;  % Digital Elevation Model
landuse = randi(6, grid_size);  % Random land use types
road_network = zeros(grid_size);  % Road network
barriers = zeros(grid_size);  % Barriers

% Create some test roads
road_network(25, :) = 1;  % Horizontal road
road_network(:, 25) = 1;  % Vertical road

% Create random source points
source_points = [25 25; 40 40; 10 10];

% Test Carbon Flow Model
fprintf('Testing Carbon Flow Model...\n');

try
    % Create test data
    vegetation_cover = rand(grid_size);
    climate_factors = ones(grid_size);
    soil_factors = ones(grid_size);
    
    % Initialize model
    carbon_model = CarbonFlowModel(vegetation_cover, climate_factors, soil_factors);
    
    % Calculate flows
    [theoretical_flow, actual_flow] = carbon_model.calculateFlow();
    efficiency = carbon_model.calculateFixationEfficiency();
    
    % Save results
    save('output/test_results/carbon_results.mat', 'theoretical_flow', 'actual_flow', 'efficiency');
    fprintf('Carbon Flow Model test completed successfully.\n');
catch ME
    fprintf('Error in Carbon Flow Model test: %s\n', ME.message);
end

% Test Flood Water Flow Model
fprintf('\nTesting Flood Water Flow Model...\n');

try
    % Create test data
    precipitation = rand(grid_size) * 100;  % Random precipitation
    
    % Initialize model
    flood_model = FloodWaterFlowModel(dem, precipitation, landuse);
    
    % Calculate flows
    [flow_direction, flow_accumulation] = flood_model.calculateFlowDirection();
    [runoff, infiltration] = flood_model.calculateRunoff();
    
    % Save results
    save('output/test_results/flood_results.mat', 'flow_direction', 'flow_accumulation', 'runoff', 'infiltration');
    fprintf('Flood Water Flow Model test completed successfully.\n');
catch ME
    fprintf('Error in Flood Water Flow Model test: %s\n', ME.message);
end

% Test Surface Water Flow Model
fprintf('\nTesting Surface Water Flow Model...\n');

try
    % Initialize model
    surface_model = SurfaceWaterFlowModel(dem, precipitation, landuse);
    
    % Calculate flows
    [flow_direction, flow_accumulation] = surface_model.calculateFlowDirection();
    [runoff, infiltration] = surface_model.calculateRunoff();
    
    % Save results
    save('output/test_results/surface_results.mat', 'flow_direction', 'flow_accumulation', 'runoff', 'infiltration');
    fprintf('Surface Water Flow Model test completed successfully.\n');
catch ME
    fprintf('Error in Surface Water Flow Model test: %s\n', ME.message);
end

% Test Sediment Transport Model
fprintf('\nTesting Sediment Transport Model...\n');

try
    % Create test data
    sediment_concentration = rand(grid_size);
    flow_velocity = rand(grid_size) * 2;
    
    % Initialize model
    sediment_model = SedimentTransportModel(sediment_concentration, flow_velocity);
    
    % Calculate transport
    [transport_rate, deposition_rate] = sediment_model.calculateSedimentTransport();
    
    % Save results
    save('output/test_results/sediment_results.mat', 'transport_rate', 'deposition_rate');
    fprintf('Sediment Transport Model test completed successfully.\n');
catch ME
    fprintf('Error in Sediment Transport Model test: %s\n', ME.message);
end

% Test Line of Sight Model
fprintf('\nTesting Line of Sight Model...\n');

try
    % Create observer points
    observers = [25 25; 40 40];
    
    % Initialize model
    los_model = LineOfSightModel(dem);
    
    % Calculate visibility
    visibility = los_model.calculateVisibility(observers);
    
    % Save results
    save('output/test_results/los_results.mat', 'visibility');
    fprintf('Line of Sight Model test completed successfully.\n');
catch ME
    fprintf('Error in Line of Sight Model test: %s\n', ME.message);
end

% Test Proximity Analysis Model
fprintf('\nTesting Proximity Analysis Model...\n');

try
    % Initialize model
    proximity_model = ProximityAnalysisModel(dem, landuse, road_network, barriers);
    
    % Calculate accessibility
    [cost_surface, accessibility] = proximity_model.calculateAccessibility(source_points);
    
    % Create source strength and sink capacity
    source_strength = zeros(grid_size);
    source_strength(sub2ind(size(source_strength), source_points(:,2), source_points(:,1))) = 100;
    sink_capacity = ones(grid_size) * 50;
    
    % Calculate service flow
    service_flow = proximity_model.calculateServiceFlow(source_strength, sink_capacity, accessibility);
    
    % Save results
    save('output/test_results/proximity_results.mat', 'cost_surface', 'accessibility', 'service_flow');
    fprintf('Proximity Analysis Model test completed successfully.\n');
catch ME
    fprintf('Error in Proximity Analysis Model test: %s\n', ME.message);
end

% Test Coastal Storm Protection Model
fprintf('\nTesting Coastal Storm Protection Model...\n');

try
    % Create test data
    bathymetry = zeros(grid_size);
    for i = 1:grid_size
        if i > grid_size/2
            bathymetry(i,:) = dem(i,:);
        else
            bathymetry(i,:) = -20 + i/5;
        end
    end
    landcover = ones(grid_size);
    coastal_type = ones(grid_size);
    
    % Initialize model
    coastal_model = CoastalStormProtectionModel(dem, bathymetry, landcover, coastal_type);
    
    % Calculate protection
    [protection_level, inundation_risk] = coastal_model.calculateProtection();
    
    % Save results
    save('output/test_results/coastal_results.mat', 'protection_level', 'inundation_risk');
    fprintf('Coastal Storm Protection Model test completed successfully.\n');
catch ME
    fprintf('Error in Coastal Storm Protection Model test: %s\n', ME.message);
end

% Test Subsistence Fisheries Model
fprintf('\nTesting Subsistence Fisheries Model...\n');

try
    % Create test data
    bathymetry = -100 + peaks(grid_size) * 50;
    habitat_quality = rand(grid_size);
    fishing_pressure = zeros(grid_size);
    fishing_pressure(25:35, 25:35) = 0.8;
    fishing_pressure(15:45, 15:45) = 0.4;
    fish_density = ones(grid_size) * 500;
    
    % Initialize model
    fisheries_model = SubsistenceFisheriesModel(bathymetry, habitat_quality, fishing_pressure, fish_density);
    
    % Calculate yield
    [yield, sustainability] = fisheries_model.calculateFisheryYield();
    
    % Save results
    save('output/test_results/fisheries_results.mat', 'yield', 'sustainability');
    fprintf('Subsistence Fisheries Model test completed successfully.\n');
catch ME
    fprintf('Error in Subsistence Fisheries Model test: %s\n', ME.message);
end

% Generate Summary Report
fprintf('\nGenerating summary report...\n');

try
    % Create summary structure
    summary = struct();
    
    % Load all results
    carbon_results = load('output/test_results/carbon_results.mat');
    flood_results = load('output/test_results/flood_results.mat');
    surface_results = load('output/test_results/surface_results.mat');
    sediment_results = load('output/test_results/sediment_results.mat');
    los_results = load('output/test_results/los_results.mat');
    proximity_results = load('output/test_results/proximity_results.mat');
    coastal_results = load('output/test_results/coastal_results.mat');
    fisheries_results = load('output/test_results/fisheries_results.mat');
    
    % Calculate summary statistics
    summary.carbon_efficiency = mean(carbon_results.efficiency(:));
    summary.flood_accumulation = sum(flood_results.flow_accumulation(:));
    summary.surface_runoff = mean(surface_results.runoff(:));
    summary.sediment_transport = mean(sediment_results.transport_rate(:));
    summary.visibility_coverage = mean(los_results.visibility(:));
    summary.mean_accessibility = mean(proximity_results.accessibility(:));
    summary.protection_level = mean(coastal_results.protection_level(:));
    summary.fishery_sustainability = mean(fisheries_results.sustainability(:));
    
    % Save summary
    save('output/test_results/summary.mat', 'summary');
    
    % Display summary
    fprintf('\nTest Summary:\n');
    fprintf('Carbon Flow Efficiency: %.2f%%\n', summary.carbon_efficiency * 100);
    fprintf('Flood Accumulation Total: %.2f\n', summary.flood_accumulation);
    fprintf('Mean Surface Runoff: %.2f\n', summary.surface_runoff);
    fprintf('Mean Sediment Transport Rate: %.2f\n', summary.sediment_transport);
    fprintf('Visibility Coverage: %.2f%%\n', summary.visibility_coverage * 100);
    fprintf('Mean Accessibility: %.2f\n', summary.mean_accessibility);
    fprintf('Mean Protection Level: %.2f\n', summary.protection_level);
    fprintf('Mean Fishery Sustainability: %.2f\n', summary.fishery_sustainability);
    
    fprintf('\nAll tests completed successfully. Results saved in output/test_results/\n');
catch ME
    fprintf('Error generating summary report: %s\n', ME.message);
end 