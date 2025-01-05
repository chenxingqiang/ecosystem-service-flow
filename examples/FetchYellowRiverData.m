% FetchYellowRiverData.m
% 示例：从Google Earth Engine获取黄河流域研究数据

% 清理工作空间
clear;
clc;

% 创建数据获取器实例
fetcher = GEEDataFetcher();

% 定义黄河流域主要研究区域 [minLon, minLat, maxLon, maxLat]
% 覆盖黄河流域主要区域（从青海到山东）
% 扩大范围以包含整个流域
region = [95.0, 32.0, 119.0, 42.0];
resolution = 250;  % 考虑到区域范围，使用250米分辨率

% 创建输出目录
if ~exist('output/yellow_river', 'dir')
    mkdir('output/yellow_river');
end

% 定义研究时间范围（近5年数据）
years = 2019:2023;
months = 1:12;

% 1. 获取DEM数据
fprintf('正在获取黄河流域地形数据...\n');
[dem, success] = fetcher.getDEM(region, resolution);
if success
    % 保存数据
    save('output/yellow_river/dem.mat', 'dem');
    
    % 计算坡度和坡向
    [slope, aspect] = gradient(dem);
    slope = atan(sqrt(slope.^2 + aspect.^2));
    
    % 可视化地形特征
    figure('Name', 'Yellow River Basin - Terrain Analysis');
    
    % DEM
    subplot(2,2,1);
    imagesc(dem);
    colormap(gca, terrain);
    colorbar;
    title('地形高程 (meters)');
    axis equal tight;
    
    % Slope
    subplot(2,2,2);
    imagesc(slope);
    colormap(gca, jet);
    colorbar;
    title('坡度 (radians)');
    axis equal tight;
    
    % Aspect
    subplot(2,2,3);
    imagesc(aspect);
    colormap(gca, hsv);
    colorbar;
    title('坡向');
    axis equal tight;
    
    % 3D surface
    subplot(2,2,4);
    surf(dem, 'EdgeColor', 'none');
    colormap(gca, terrain);
    colorbar;
    title('3D地形');
    view(45, 45);
    
    saveas(gcf, 'output/yellow_river/terrain_analysis.png');
end

% 2. 获取多年土地覆盖变化数据
fprintf('正在获取土地覆盖变化数据...\n');
landcover_changes = zeros([size(dem), length(years)]);
for i = 1:length(years)
    [landcover, success] = fetcher.getLandCover(region, years(i), resolution);
    if success
        landcover_changes(:,:,i) = landcover;
        
        % 可视化每年的土地覆盖
        figure('Name', sprintf('Land Cover %d', years(i)));
        imagesc(landcover);
        colormap(parula);
        colorbar;
        title(sprintf('土地覆盖类型 - %d', years(i)));
        axis equal tight;
        saveas(gcf, sprintf('output/yellow_river/landcover_%d.png', years(i)));
    end
end
save('output/yellow_river/landcover_changes.mat', 'landcover_changes');

% 3. 获取月度NDVI数据
fprintf('正在获取植被指数数据...\n');
ndvi_monthly = zeros([size(dem), 12]);  % 存储月平均NDVI
for m = 1:12
    startDate = sprintf('2023-%02d-01', m);
    if m == 12
        endDate = '2023-12-31';
    else
        endDate = sprintf('2023-%02d-01', m+1);
    end
    
    [ndvi, success] = fetcher.getNDVI(region, startDate, endDate, resolution);
    if success
        ndvi_monthly(:,:,m) = ndvi;
    end
end
save('output/yellow_river/ndvi_monthly.mat', 'ndvi_monthly');

% 4. 获取水文数据
fprintf('正在获取水文数据...\n');
precip_monthly = zeros([size(dem), 12]);  % 存储月平均降水
for m = 1:12
    startDate = sprintf('2023-%02d-01', m);
    if m == 12
        endDate = '2023-12-31';
    else
        endDate = sprintf('2023-%02d-01', m+1);
    end
    
    [precip, success] = fetcher.getPrecipitation(region, startDate, endDate, resolution);
    if success
        precip_monthly(:,:,m) = precip;
    end
end
save('output/yellow_river/precip_monthly.mat', 'precip_monthly');

% 5. 计算流域特征
fprintf('正在计算流域特征...\n');

% 计算汇流累积量
flow_accum = zeros(size(dem));
[rows, cols] = size(dem);
for i = 2:rows-1
    for j = 2:cols-1
        % 简化的D8算法
        window = dem(i-1:i+1, j-1:j+1);
        [min_val, ~] = min(window(:));
        if dem(i,j) > min_val
            flow_accum(i,j) = sum(sum(window > dem(i,j)));
        end
    end
end

% 计算泥沙潜在流失量（RUSLE模型简化版）
% LS因子（坡长坡度因子）
L_factor = sqrt(flow_accum) / 22.13;
S_factor = (sin(slope) / 0.0896)^1.3;
LS_factor = L_factor .* S_factor;

% R因子（降雨侵蚀力因子）- 使用年降水量估算
R_factor = sum(precip_monthly, 3) * 0.2;  % 简化系数

% C因子（植被覆盖因子）- 使用NDVI估算
C_factor = exp(-2 * mean(ndvi_monthly, 3));

% 计算潜在土壤流失量
sediment_potential = R_factor .* LS_factor .* C_factor;

% 6. 生态系统服务评估
fprintf('正在评估生态系统服务...\n');

% 水源涵养服务
water_retention = (1 - slope/max(slope(:))) .* mean(ndvi_monthly, 3) .* mean(precip_monthly, 3);

% 土壤保持服务
soil_retention = 1 - sediment_potential/max(sediment_potential(:));

% 生物多样性维持服务
biodiversity = mean(ndvi_monthly, 3) .* (landcover_changes(:,:,end) == 1 | landcover_changes(:,:,end) == 2);

% 综合生态系统服务
service_capacity = (water_retention + soil_retention + biodiversity) / 3;

% 7. 可视化分析结果
fprintf('正在生成可视化结果...\n');

% 流域特征分析图
figure('Name', 'Yellow River Basin - Watershed Analysis');
subplot(2,2,1);
imagesc(flow_accum);
colormap(gca, jet);
colorbar;
title('汇流累积量');

subplot(2,2,2);
imagesc(sediment_potential);
colormap(gca, hot);
colorbar;
title('潜在土壤流失量');

subplot(2,2,3);
imagesc(water_retention);
colormap(gca, cool);
colorbar;
title('水源涵养能力');

subplot(2,2,4);
imagesc(service_capacity);
colormap(gca, parula);
colorbar;
title('综合生态系统服务');

saveas(gcf, 'output/yellow_river/watershed_analysis.png');

% 8. 生成详细报告
fid = fopen('output/yellow_river/detailed_analysis_report.txt', 'w');
fprintf(fid, '黄河流域生态系统服务详细分析报告\n');
fprintf(fid, '====================================\n\n');

% 基本信息
fprintf(fid, '1. 研究区域基本信息\n');
fprintf(fid, '   经度范围: %.1f°E - %.1f°E\n', region(1), region(3));
fprintf(fid, '   纬度范围: %.1f°N - %.1f°N\n', region(2), region(4));
fprintf(fid, '   空间分辨率: %d米\n', resolution);
fprintf(fid, '   时间范围: %d-%d\n\n', years(1), years(end));

% 地形特征
fprintf(fid, '2. 地形特征统计\n');
fprintf(fid, '   平均海拔: %.1f米\n', mean(dem(:)));
fprintf(fid, '   最高海拔: %.1f米\n', max(dem(:)));
fprintf(fid, '   最低海拔: %.1f米\n', min(dem(:)));
fprintf(fid, '   平均坡度: %.2f度\n\n', mean(slope(:)) * 180/pi);

% 水文特征
fprintf(fid, '3. 水文特征分析\n');
fprintf(fid, '   年均降水量: %.1f毫米\n', mean(sum(precip_monthly, 3), 'all'));
fprintf(fid, '   最大月降水量: %.1f毫米\n', max(precip_monthly, [], 'all'));
fprintf(fid, '   水源涵养能力指数: %.2f\n\n', mean(water_retention(:)));

% 土壤侵蚀
fprintf(fid, '4. 土壤侵蚀风险评估\n');
fprintf(fid, '   平均侵蚀潜力: %.2f\n', mean(sediment_potential(:)));
fprintf(fid, '   高侵蚀风险区比例: %.1f%%\n\n', ...
    sum(sediment_potential(:) > mean(sediment_potential(:)) + std(sediment_potential(:))) / numel(sediment_potential) * 100);

% 生态系统服务
fprintf(fid, '5. 生态系统服务评估\n');
fprintf(fid, '   综合服务能力: %.2f\n', mean(service_capacity(:)));
fprintf(fid, '   水源涵养服务: %.2f\n', mean(water_retention(:)));
fprintf(fid, '   土壤保持服务: %.2f\n', mean(soil_retention(:)));
fprintf(fid, '   生物多样性维持服务: %.2f\n\n', mean(biodiversity(:)));

% 建议
fprintf(fid, '6. 管理建议\n');
fprintf(fid, '   - 加强高侵蚀风险区的生态修复\n');
fprintf(fid, '   - 保护关键水源涵养区\n');
fprintf(fid, '   - 优化土地利用结构\n');
fprintf(fid, '   - 加强生物多样性保护\n');

fclose(fid);

fprintf('分析完成。详细结果保存在output/yellow_river目录下。\n'); 