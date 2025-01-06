% Generate synthetic DEM for Yellow River test data

% Create a synthetic Digital Elevation Model
dem.elevation = rand(500, 500) * 1000;  % Random elevation between 0-1000m
dem.slope = gradient(dem.elevation);
dem.aspect = atan2(gradient(dem.elevation, 2), gradient(dem.elevation, 1));

% Save the DEM data
save('dem.mat', '-struct', 'dem');
