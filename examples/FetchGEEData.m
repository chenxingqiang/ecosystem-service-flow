% FetchGEEData.m
% 示例：从Google Earth Engine获取研究数据

% 清理工作空间
clear;
clc;

% 创建数据获取器实例
fetcher = GEEDataFetcher();

% 定义研究区域 [minLon, minLat, maxLon, maxLat]
% 这里以北京市为例
region = [116.0, 39.6, 116.8, 40.2];
resolution = 30;  % 30米分辨率

% 创建输出目录
if ~exist('output/gee_data', 'dir')
    mkdir('output/gee_data');
end

% 1. 获取DEM数据
[dem, success] = fetcher.getDEM(region, resolution);
if success
    % 保存数据
    save('output/gee_data/dem.mat', 'dem');
    
    % 可视化
    figure('Name', 'Digital Elevation Model');
    imagesc(dem);
    colorbar;
    title('DEM (meters)');
    axis equal tight;
    saveas(gcf, 'output/gee_data/dem.png');
end

% 2. 获取土地覆盖数据
[landcover, success] = fetcher.getLandCover(region, 2020, resolution);
if success
    % 保存数据
    save('output/gee_data/landcover.mat', 'landcover');
    
    % 可视化
    figure('Name', 'Land Cover');
    imagesc(landcover);
    colorbar;
    title('Land Cover Classes');
    axis equal tight;
    saveas(gcf, 'output/gee_data/landcover.png');
end

% 3. 获取NDVI数据
startDate = '2023-01-01';
endDate = '2023-12-31';
[ndvi, success] = fetcher.getNDVI(region, startDate, endDate, resolution);
if success
    % 保存数据
    save('output/gee_data/ndvi.mat', 'ndvi');
    
    % 可视化
    figure('Name', 'NDVI');
    imagesc(ndvi, [-1 1]);
    colorbar;
    title('NDVI');
    axis equal tight;
    saveas(gcf, 'output/gee_data/ndvi.png');
end

% 4. 获取降水数据
[precip, success] = fetcher.getPrecipitation(region, startDate, endDate, resolution);
if success
    % 保存数据
    save('output/gee_data/precipitation.mat', 'precip');
    
    % 可视化
    figure('Name', 'Precipitation');
    imagesc(precip);
    colorbar;
    title('Average Daily Precipitation (mm)');
    axis equal tight;
    saveas(gcf, 'output/gee_data/precipitation.png');
end

% 数据预处理
% 1. 标准化DEM数据
dem_norm = (dem - min(dem(:))) / (max(dem(:)) - min(dem(:)));

% 2. 重分类土地覆盖数据为生态系统服务供给能力
% 简化的分类方案：
% 1: 森林 -> 1.0
% 2: 草地 -> 0.8
% 3: 农田 -> 0.6
% 4: 水体 -> 0.4
% 5: 建设用地 -> 0.2
landcover_service = zeros(size(landcover));
landcover_service(landcover == 1) = 1.0;  % 森林
landcover_service(landcover == 2) = 0.8;  % 草地
landcover_service(landcover == 3) = 0.6;  % 农田
landcover_service(landcover == 4) = 0.4;  % 水体
landcover_service(landcover == 5) = 0.2;  % 建设用地

% 3. 标准化NDVI数据（已在-1到1范围内）
ndvi_norm = (ndvi + 1) / 2;  % 转换到0-1范围

% 4. 标准化降水数据
precip_norm = (precip - min(precip(:))) / (max(precip(:)) - min(precip(:)));

% 计算综合生态系统服务供给能力
% 使用加权平均方法
weights = [0.3, 0.3, 0.2, 0.2];  % DEM、土地覆盖、NDVI、降水的权重
service_capacity = weights(1) * dem_norm + ...
                  weights(2) * landcover_service + ...
                  weights(3) * ndvi_norm + ...
                  weights(4) * precip_norm;

% 保存结果
save('output/gee_data/service_capacity.mat', 'service_capacity');

% 可视化综合生态系统服务供给能力
figure('Name', 'Ecosystem Service Capacity');
imagesc(service_capacity, [0 1]);
colorbar;
title('Ecosystem Service Supply Capacity');
axis equal tight;
saveas(gcf, 'output/gee_data/service_capacity.png');

fprintf('数据获取和处理完成。结果保存在output/gee_data目录下。\n'); 