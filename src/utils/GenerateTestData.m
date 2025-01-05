function data = GenerateTestData()
% GENERATETESTDATA Generate test data for all ecosystem service flow models
%   This function generates synthetic test data for all models in the ecosystem
%   service flow analysis framework. The data includes digital elevation models,
%   land use, vegetation cover, climate factors, soil properties, hydrology,
%   coastal and marine data, ecosystem services, infrastructure, and more.
%
%   Returns:
%       data: A structure containing all generated test data layers and parameters

%% Initialize random number generator for reproducibility
rng(42);

%% Set grid parameters
data.grid_size = 50;
data.cell_width = 30;  % meters
data.cell_height = 30; % meters
data.time_step = 3600; % seconds (1 hour)

% Create meshgrid
[X, Y] = meshgrid(1:data.grid_size, 1:data.grid_size);

%% Generate Topographic Data
% Digital Elevation Model (DEM)
data.dem = peaks(data.grid_size) * 500;  % Scale to reasonable elevation values

% Calculate slope and aspect
[fx, fy] = gradient(data.dem);
data.slope = atand(sqrt(fx.^2 + fy.^2));
data.aspect = atan2d(fy, fx);

%% Generate Land Use Data
% 1: urban, 2: agriculture, 3: forest, 4: water, 5: wetland, 6: barren
data.land_use = ones(data.grid_size);
% Urban areas
data.land_use(15:25, 15:25) = 1;
% Agricultural areas
data.land_use(30:40, 30:40) = 2;
% Forest areas
data.land_use(5:15, 30:40) = 3;
% Water bodies
data.land_use(35:45, 5:15) = 4;
% Wetlands
data.land_use(20:25, 35:40) = 5;
% Random scattered barren areas
barren_mask = rand(data.grid_size) > 0.9;
data.land_use(barren_mask) = 6;

%% Generate Vegetation Data
% Vegetation cover (0-1 scale)
data.vegetation_cover = zeros(data.grid_size);
% High cover in forest areas
forest_mask = data.land_use == 3;
data.vegetation_cover(forest_mask) = 0.8 + 0.2 * rand(sum(forest_mask(:)), 1);
% Medium cover in agricultural areas
ag_mask = data.land_use == 2;
data.vegetation_cover(ag_mask) = 0.4 + 0.3 * rand(sum(ag_mask(:)), 1);
% Low cover in urban areas
urban_mask = data.land_use == 1;
data.vegetation_cover(urban_mask) = 0.1 + 0.2 * rand(sum(urban_mask(:)), 1);

%% Generate Climate Data
% Temperature (°C)
data.temperature = 20 + 5 * sin(2*pi*X/data.grid_size) + ...
    3 * cos(2*pi*Y/data.grid_size) + 2 * randn(data.grid_size);

% Precipitation (mm/day)
data.precipitation = 50 + 20 * sin(4*pi*X/data.grid_size) + ...
    15 * cos(4*pi*Y/data.grid_size) + 5 * randn(data.grid_size);
data.precipitation = max(data.precipitation, 0);

% Wind speed (m/s) and direction (degrees)
data.wind_speed = 5 + 2 * sin(2*pi*X/data.grid_size) + randn(data.grid_size);
data.wind_direction = 180 + 45 * sin(2*pi*Y/data.grid_size);

%% Generate Soil Data
% Soil type (1: clay, 2: silt, 3: sand, 4: loam)
data.soil_type = randi([1 4], data.grid_size);

% Soil properties
data.soil_depth = 1 + 0.5 * rand(data.grid_size);  % meters

%% Generate Hydrological Data
% Flow accumulation
data.flow_accumulation = zeros(data.grid_size);
for i = 2:data.grid_size-1
    for j = 2:data.grid_size-1
        data.flow_accumulation(i,j) = sum(sum(data.dem(i-1:i+1,j-1:j+1) > data.dem(i,j)));
    end
end

% Water depth (meters)
data.water_depth = zeros(data.grid_size);
water_mask = data.land_use == 4;
data.water_depth(water_mask) = 2 + 3 * rand(sum(water_mask(:)), 1);

%% Generate Coastal and Marine Data
% Bathymetry (negative elevation for underwater terrain)
data.bathymetry = -100 + peaks(data.grid_size) * 50;

% Marine habitat quality (0-1 scale)
data.marine_habitat = zeros(data.grid_size);
marine_mask = data.bathymetry < 0;
data.marine_habitat(marine_mask) = 0.2 + 0.6 * rand(sum(marine_mask(:)), 1);

%% Generate Infrastructure Data
% Road network (0: no road, 1: local, 2: arterial, 3: highway)
data.road_network = zeros(data.grid_size);
% Main highway
data.road_network(25, :) = 3;
% Arterial roads
data.road_network(:, 25) = 2;
% Random local roads
local_roads = rand(data.grid_size) > 0.95;
data.road_network(local_roads) = 1;

% Barriers (0: no barrier, 1: barrier)
data.barriers = zeros(data.grid_size);
data.barriers(15:20, 15:20) = 1;  % Example barrier

%% Generate Observation Points
% Random selection of observation points
data.observation_points = zeros(data.grid_size);
num_points = 10;
for i = 1:num_points
    x = randi([1 data.grid_size]);
    y = randi([1 data.grid_size]);
    data.observation_points(x,y) = 1;
end

%% Generate Carbon Storage Data
data.carbon_storage = 50 * data.vegetation_cover + 20 * rand(data.grid_size);

%% Generate Fish Population Data
data.fish_population = zeros(data.grid_size);
data.fish_population(water_mask) = 500 + 500 * rand(sum(water_mask(:)), 1);

%% Validate and preprocess data
validator = TestDataValidator();
[isValid, errors] = validator.validate(data);

if ~isValid
    warning('Generated test data has validation errors:');
    for i = 1:length(errors)
        warning('%s', errors{i});
    end
end

% Preprocess data to ensure consistency
data = validator.preprocess(data);

end 