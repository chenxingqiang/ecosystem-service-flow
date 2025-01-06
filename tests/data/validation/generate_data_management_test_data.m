% Generate test data for data management module testing

% Create test directory if it doesn't exist
test_dir = fileparts(mfilename('fullpath'));
if ~exist(test_dir, 'dir')
    mkdir(test_dir);
end

% Generate test data with known dimensions (100x100)
test_size = [100, 100];

% 1. Generate DEM data (ASCII format)
x = linspace(-3,3,test_size(2));
y = linspace(-3,3,test_size(1));
[X, Y] = meshgrid(x, y);
dem = 3*(1-X).^2.*exp(-(X.^2) - (Y+1).^2) ...
    - 10*(X/5 - X.^3 - Y.^5).*exp(-X.^2-Y.^2) ...
    - 1/3*exp(-(X+1).^2 - Y.^2);  % Modified peaks function
dem_file = fullfile(test_dir, 'dem.asc');
% Write header
fid = fopen(dem_file, 'w');
fprintf(fid, 'ncols %d\n', test_size(2));
fprintf(fid, 'nrows %d\n', test_size(1));
fprintf(fid, 'xllcorner 0.0\n');
fprintf(fid, 'yllcorner 0.0\n');
fprintf(fid, 'cellsize 1.0\n');
fprintf(fid, 'nodata_value -9999\n');
% Write data
for i = 1:test_size(1)
    fprintf(fid, '%.6f ', dem(i,:));
    fprintf(fid, '\n');
end
fclose(fid);

% 2. Generate land use data (GeoTIFF format)
landuse = uint8(randi([1 5], test_size));  % 5 land use types
landuse_file = fullfile(test_dir, 'landuse.tif');
imwrite(landuse, landuse_file);

% 3. Generate supply data (MAT format)
supply = rand(test_size);
supply_file = fullfile(test_dir, 'supply.mat');
save(supply_file, 'supply');

% 4. Generate demand data (CSV format)
demand = rand(test_size);
demand_file = fullfile(test_dir, 'demand.csv');
writematrix(demand, demand_file);

% 5. Generate resistance data (Excel format)
resistance = rand(test_size);
resistance_file = fullfile(test_dir, 'resistance.xlsx');
writematrix(resistance, resistance_file);

fprintf('Test data generation completed.\n');
fprintf('Files generated in: %s\n', test_dir);
fprintf('  - dem.asc (ASCII Grid)\n');
fprintf('  - landuse.tif (GeoTIFF)\n');
fprintf('  - supply.mat (MATLAB)\n');
fprintf('  - demand.csv (CSV)\n');
fprintf('  - resistance.xlsx (Excel)\n');
