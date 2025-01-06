% Generate synthetic landcover data for Yellow River test

% Create a synthetic landcover matrix
landcover.data = randi([1, 10], 500, 500);  % Random landcover types
landcover.types = {'Forest', 'Grassland', 'Cropland', 'Urban', 'Water', ...
                   'Barren', 'Shrubland', 'Wetland', 'Savanna', 'Tundra'};
landcover.type_codes = 1:10;

% Save the landcover data
save('landcover.mat', '-struct', 'landcover');
