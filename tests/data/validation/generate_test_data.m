% Generate synthetic test data for model validation

% Water Flow Validation Data
test_data.water_flow.input = rand(100, 100);
test_data.water_flow.expected_output = cumsum(test_data.water_flow.input, 2);

% Sediment Transport Validation Data
test_data.sediment_transport.elevation = rand(100, 100);
test_data.sediment_transport.flow_velocity = rand(100, 100);
test_data.sediment_transport.sediment_concentration = rand(100, 100);

% Carbon Flux Validation Data
test_data.carbon_flux.biomass = rand(100, 100);
test_data.carbon_flux.soil_carbon = rand(100, 100);

% Soil Erosion Validation Data
test_data.soil_erosion.slope = rand(100, 100);
test_data.soil_erosion.rainfall = rand(100, 100);

% Service Flow Validation Data
test_data.service_flow.supply = rand(100, 100);
test_data.service_flow.demand = rand(100, 100);

% Uncertainty Validation Data
test_data.uncertainty.parameter_ranges = struct(...
    'min', rand(1, 5), ...
    'max', rand(1, 5) + 1 ...
);

% Save the test data
save(fullfile(fileparts(mfilename('fullpath')), 'test_data.mat'), 'test_data');
