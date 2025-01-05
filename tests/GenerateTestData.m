function data = GenerateTestData()
% GenerateTestData Generate test data for all ecosystem service flow models
%   Returns a structure containing all necessary test data layers

% Initialize random number generator for reproducibility
rng(42);

% Set grid size
grid_size = 50;
[X, Y] = meshgrid(1:grid_size, 1:grid_size);

% Common data structure
data = struct();

%% Elevation and Terrain Data
% Digital Elevation Model (DEM)
data.dem = peaks(grid_size) * 100;  % Scale to reasonable elevation values
% Slope (degrees)
[fx, fy] = gradient(data.dem);
data.slope = atan2(sqrt(fx.^2 + fy.^2), 1) * 180/pi;
% Aspect (degrees)
data.aspect = atan2(fy, fx) * 180/pi;

%% Land Cover and Vegetation
% Land use/cover (1: urban, 2: agriculture, 3: forest, 4: water, 5: wetland)
data.land_use = randi([1 5], grid_size);
% Vegetation cover (0-1)
data.vegetation_cover = rand(grid_size);
data.vegetation_cover(data.land_use == 3) = 0.7 + 0.3*rand(sum(data.land_use(:) == 3), 1);
% Leaf area index
data.leaf_area_index = 2 + 4 * data.vegetation_cover;

%% Climate and Weather
% Temperature (°C)
data.temperature = 20 + 10 * rand(grid_size);
% Precipitation (mm)
data.precipitation = 100 + 900 * rand(grid_size);
% Wind speed (m/s)
data.wind_speed = 2 + 8 * rand(grid_size);
% Wind direction (degrees)
data.wind_direction = 360 * rand(grid_size);

%% Soil and Geology
% Soil type (1: clay, 2: silt, 3: sand, 4: loam, 5: rock)
data.soil_type = randi([1 5], grid_size);
% Soil depth (m)
data.soil_depth = 0.5 + 1.5 * rand(grid_size);
% Soil organic carbon (%)
data.soil_carbon = 2 + 3 * rand(grid_size);
% Infiltration rate (mm/hr)
data.infiltration_rate = zeros(grid_size);
for i = 1:5
    mask = data.soil_type == i;
    data.infiltration_rate(mask) = (i * 10 + 5 * rand(sum(mask(:)), 1));
end

%% Hydrology
% Flow accumulation
data.flow_accumulation = zeros(grid_size);
for i = 1:grid_size
    for j = 1:grid_size
        data.flow_accumulation(i,j) = sum(data.dem(1:i,1:j), 'all');
    end
end
% Flow direction (1-8, D8 method)
data.flow_direction = randi([1 8], grid_size);
% Channel network (binary)
data.channel_network = data.flow_accumulation > prctile(data.flow_accumulation(:), 90);
% Water depth (m)
data.water_depth = zeros(grid_size);
data.water_depth(data.channel_network) = 0.5 + 1.5 * rand(sum(data.channel_network(:)), 1);

%% Coastal and Marine
% Bathymetry (m)
data.bathymetry = -100 + peaks(grid_size) * 50;
% Wave height (m)
data.wave_height = 1 + 2 * rand(grid_size);
% Storm surge potential (m)
data.storm_surge = zeros(grid_size);
coastal_zone = abs(data.bathymetry) < 10;
data.storm_surge(coastal_zone) = 2 + 3 * rand(sum(coastal_zone(:)), 1);

%% Ecosystem Services
% Carbon storage (Mg/ha)
data.carbon_storage = 50 + 150 * data.vegetation_cover;
% Biodiversity index (0-1)
data.biodiversity = 0.2 + 0.8 * data.vegetation_cover .* (1 - abs(data.dem)/max(abs(data.dem(:))));
% Habitat quality (0-1)
data.habitat_quality = data.biodiversity .* (1 - abs(data.slope)/90);

%% Infrastructure and Human Factors
% Population density (people/km²)
data.population = zeros(grid_size);
urban_areas = data.land_use == 1;
data.population(urban_areas) = 1000 + 4000 * rand(sum(urban_areas(:)), 1);
% Road network (binary)
data.road_network = false(grid_size);
data.road_network(1:5:end,:) = true;
data.road_network(:,1:5:end) = true;
% Building footprints (binary)
data.buildings = false(grid_size);
data.buildings(urban_areas & rand(grid_size) < 0.3) = true;

%% Observation Points and Barriers
% Observation points (x,y coordinates)
num_observers = 10;
data.observer_points = [randi([1 grid_size], num_observers, 1), randi([1 grid_size], num_observers, 1)];
% Target points (x,y coordinates)
num_targets = 20;
data.target_points = [randi([1 grid_size], num_targets, 1), randi([1 grid_size], num_targets, 1)];
% Barriers (binary)
data.barriers = false(grid_size);
data.barriers(rand(grid_size) < 0.1) = true;

%% Source and Sink Data
% Source strength (generic units)
data.source_strength = zeros(grid_size);
source_areas = data.vegetation_cover > 0.7;
data.source_strength(source_areas) = 50 + 50 * rand(sum(source_areas(:)), 1);
% Sink capacity (generic units)
data.sink_capacity = zeros(grid_size);
sink_areas = data.land_use == 1 | data.land_use == 2;
data.sink_capacity(sink_areas) = 30 + 70 * rand(sum(sink_areas(:)), 1);

%% Fisheries Data
% Fish population (individuals)
data.fish_population = zeros(grid_size);
water_areas = data.land_use == 4;
data.fish_population(water_areas) = 500 + 500 * rand(sum(water_areas(:)), 1);
% Fishing pressure (0-1)
data.fishing_pressure = zeros(grid_size);
data.fishing_pressure(water_areas) = 0.2 + 0.6 * rand(sum(water_areas(:)), 1);

%% Additional Parameters
% Cell dimensions
data.cell_width = 30;  % meters
data.cell_height = 30;  % meters
% Time step
data.time_step = 3600;  % seconds (1 hour)
% Simulation period
data.simulation_period = 24;  % time steps

end 