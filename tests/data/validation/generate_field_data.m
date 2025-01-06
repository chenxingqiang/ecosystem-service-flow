% Generate synthetic field validation data

% Water Flow Field Data
field_data.water_flow.discharge_rate = rand(100, 100);
field_data.water_flow.water_level = cumsum(field_data.water_flow.discharge_rate, 2);

% Sediment Transport Field Data
field_data.sediment_transport.sediment_concentration = rand(100, 100);
field_data.sediment_transport.erosion_rate = rand(100, 100);

% Carbon Flux Field Data
field_data.carbon_flux.biomass_carbon = rand(100, 100);
field_data.carbon_flux.soil_carbon = rand(100, 100);

% Soil Erosion Field Data
field_data.soil_erosion.soil_loss = rand(100, 100);
field_data.soil_erosion.slope = rand(100, 100);

% Service Flow Field Data
field_data.service_flow.ecosystem_service_index = rand(100, 100);
field_data.service_flow.service_demand = rand(100, 100);

% Uncertainty Field Data
field_data.uncertainty.parameter_variability = struct(...
    'mean', rand(1, 5), ...
    'std', rand(1, 5) * 0.1 ...
);

% Save the field data
save('field_data.mat', 'field_data');
