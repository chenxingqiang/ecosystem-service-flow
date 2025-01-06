% 生成数据管理模块的测试数据

% 创建测试目录
test_dir = fileparts(mfilename('fullpath'));
if ~exist(test_dir, 'dir')
    mkdir(test_dir);
end

% 1. 生成DEM数据
dem = peaks(100);  % 使用MATLAB内置的peaks函数生成测试地形
dem_file = fullfile(test_dir, 'dem.asc');
dlmwrite(dem_file, dem, 'delimiter', ' ', 'precision', '%.6f');

% 2. 生成土地利用数据
landuse = randi([1 5], 100, 100);  % 随机生成5种土地利用类型
landuse_file = fullfile(test_dir, 'landuse.tif');
imwrite(uint8(landuse), landuse_file);

% 3. 生成供给数据
supply = rand(100);
supply_file = fullfile(test_dir, 'supply.mat');
save(supply_file, 'supply');

% 4. 生成需求数据
demand = rand(100);
demand_file = fullfile(test_dir, 'demand.csv');
writematrix(demand, demand_file);

% 5. 生成阻力数据
resistance = rand(100);
resistance_file = fullfile(test_dir, 'resistance.xlsx');
writematrix(resistance, resistance_file);

fprintf('测试数据生成完成。\n');
