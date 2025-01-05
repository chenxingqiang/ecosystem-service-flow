% YellowRiverESFAnalysis.m
% 基于生态系统服务流分析方法的黄河流域研究

% 清理工作空间
clear;
clc;

% 创建数据获取器实例
fetcher = GEEDataFetcher();

% 定义黄河流域研究区域
region = [95.0, 32.0, 119.0, 42.0];
resolution = 250;  % 空间分辨率（米）

% 创建输出目录
if ~exist('output/yellow_river_esf', 'dir')
    mkdir('output/yellow_river_esf');
end

% 1. 获取基础数据
fprintf('正在获取基础数据...\n');

% 1.1 地形数据
[dem, success] = fetcher.getDEM(region, resolution);
if success
    save('output/yellow_river_esf/dem.mat', 'dem');
    [slope, aspect] = gradient(dem);
    slope = atan(sqrt(slope.^2 + aspect.^2));
end

% 1.2 土地覆盖数据
[landcover, success] = fetcher.getLandCover(region, 2023, resolution);
if success
    save('output/yellow_river_esf/landcover.mat', 'landcover');
end

% 1.3 NDVI数据
[ndvi, success] = fetcher.getNDVI(region, '2023-01-01', '2023-12-31', resolution);
if success
    save('output/yellow_river_esf/ndvi.mat', 'ndvi');
end

% 1.4 降水数据
[precip, success] = fetcher.getPrecipitation(region, '2023-01-01', '2023-12-31', resolution);
if success
    save('output/yellow_river_esf/precip.mat', 'precip');
end

% 2. 生态系统服务供给区识别
fprintf('正在识别生态系统服务供给区...\n');

% 2.1 计算生态系统服务供给能力指数
% 基于土地利用类型的供给能力赋值
supply_capacity = zeros(size(landcover));
supply_capacity(landcover == 1) = 1.0;  % 森林
supply_capacity(landcover == 2) = 0.8;  % 草地
supply_capacity(landcover == 3) = 0.6;  % 农田
supply_capacity(landcover == 4) = 0.4;  % 水体
supply_capacity(landcover == 5) = 0.2;  % 建设用地

% 2.2 考虑地形和植被状况的修正
supply_index = supply_capacity .* (1 + ndvi) .* (1 - slope/max(slope(:)));
save('output/yellow_river_esf/supply_index.mat', 'supply_index');

% 3. 生态系统服务需求区识别
fprintf('正在识别生态系统服务需求区...\n');

% 3.1 计算需求强度
% 基于人口密度和土地利用强度
demand_intensity = zeros(size(landcover));
demand_intensity(landcover == 5) = 1.0;  % 建设用地最高需求
demand_intensity(landcover == 3) = 0.7;  % 农田次之
demand_intensity(landcover == 2) = 0.4;  % 草地
demand_intensity(landcover == 1) = 0.3;  % 森林
demand_intensity(landcover == 4) = 0.5;  % 水体

% 3.2 考虑地形和气候条件的修正
demand_index = demand_intensity .* (1 + precip/max(precip(:)));
save('output/yellow_river_esf/demand_index.mat', 'demand_index');

% 4. 生态系统服务流动路径分析
fprintf('正在分析生态系统服务流动路径...\n');

% 4.1 计算阻力面
% 基于地形、土地覆盖和人类活动的综合阻力
resistance = zeros(size(landcover));
resistance(landcover == 5) = 0.9;  % 建设用地阻力最大
resistance(landcover == 3) = 0.6;  % 农田
resistance(landcover == 2) = 0.4;  % 草地
resistance(landcover == 1) = 0.2;  % 森林
resistance(landcover == 4) = 0.7;  % 水体

% 考虑坡度的影响
resistance = resistance .* (1 + slope/max(slope(:)));
save('output/yellow_river_esf/resistance.mat', 'resistance');

% 4.2 计算最小累积阻力路径
% 使用改进的Dijkstra算法计算供需区之间的最小阻力路径
[flow_paths, accum_resistance] = calculateFlowPaths(supply_index, demand_index, resistance);
save('output/yellow_river_esf/flow_paths.mat', 'flow_paths', 'accum_resistance');

% 5. 生态系统服务流动量化
fprintf('正在量化生态系统服务流动...\n');

% 5.1 计算理论流量
theoretical_flow = calculateTheoreticalFlow(supply_index, demand_index);

% 5.2 计算实际流量
actual_flow = calculateActualFlow(theoretical_flow, resistance);

% 5.3 计算流动效率
flow_efficiency = actual_flow ./ (theoretical_flow + eps);

save('output/yellow_river_esf/flow_results.mat', 'theoretical_flow', 'actual_flow', 'flow_efficiency');

% 6. 可视化分析结果
fprintf('正在生成可视化结果...\n');

% 6.1 供需格局图
figure('Name', 'Supply-Demand Pattern');
subplot(2,2,1);
imagesc(supply_index);
colormap(gca, jet);
colorbar;
title('生态系统服务供给指数');

subplot(2,2,2);
imagesc(demand_index);
colormap(gca, jet);
colorbar;
title('生态系统服务需求指数');

subplot(2,2,3);
imagesc(resistance);
colormap(gca, hot);
colorbar;
title('生态系统服务流动阻力');

subplot(2,2,4);
imagesc(flow_efficiency);
colormap(gca, parula);
colorbar;
title('生态系统服务流动效率');

saveas(gcf, 'output/yellow_river_esf/supply_demand_pattern.png');

% 6.2 流动路径图
figure('Name', 'Service Flow Paths');
imagesc(flow_paths);
colormap(jet);
colorbar;
title('生态系统服务主要流动路径');
saveas(gcf, 'output/yellow_river_esf/flow_paths.png');

% 7. 生成分析报告
fid = fopen('output/yellow_river_esf/esf_analysis_report.txt', 'w');
fprintf(fid, '黄河流域生态系统服务流分析报告\n');
fprintf(fid, '================================\n\n');

% 7.1 基本信息
fprintf(fid, '1. 研究区域信息\n');
fprintf(fid, '   经度范围: %.1f°E - %.1f°E\n', region(1), region(3));
fprintf(fid, '   纬度范围: %.1f°N - %.1f°N\n', region(2), region(4));
fprintf(fid, '   空间分辨率: %d米\n\n', resolution);

% 7.2 供给区特征
fprintf(fid, '2. 供给区特征\n');
fprintf(fid, '   平均供给能力指数: %.2f\n', mean(supply_index(:)));
fprintf(fid, '   最大供给能力指数: %.2f\n', max(supply_index(:)));
fprintf(fid, '   供给区面积比例: %.1f%%\n\n', ...
    sum(supply_index(:) > mean(supply_index(:))) / numel(supply_index) * 100);

% 7.3 需求区特征
fprintf(fid, '3. 需求区特征\n');
fprintf(fid, '   平均需求强度指数: %.2f\n', mean(demand_index(:)));
fprintf(fid, '   最大需求强度指数: %.2f\n', max(demand_index(:)));
fprintf(fid, '   高需求区面积比例: %.1f%%\n\n', ...
    sum(demand_index(:) > mean(demand_index(:))) / numel(demand_index) * 100);

% 7.4 流动特征
fprintf(fid, '4. 服务流动特征\n');
fprintf(fid, '   平均流动效率: %.2f\n', mean(flow_efficiency(:)));
fprintf(fid, '   最大流动效率: %.2f\n', max(flow_efficiency(:)));
fprintf(fid, '   主要流动路径长度: %.1f km\n\n', ...
    sum(flow_paths(:) > 0) * resolution / 1000);

% 7.5 管理建议
fprintf(fid, '5. 管理建议\n');
fprintf(fid, '   - 加强重要供给区的保护和管理\n');
fprintf(fid, '   - 优化高需求区的空间布局\n');
fprintf(fid, '   - 降低关键流动路径上的阻力\n');
fprintf(fid, '   - 建立供需区协同管理机制\n');

fclose(fid);

fprintf('分析完成。结果保存在output/yellow_river_esf目录下。\n');

% 8. 特定生态系统服务分析
fprintf('正在分析特定生态系统服务...\n');

% 8.1 水源涵养服务
fprintf('分析水源涵养服务...\n');
water_regulation = struct();

% 计算水源涵养能力
water_regulation.capacity = (1 - slope/max(slope(:))) .* ndvi .* precip;

% 计算水源涵养服务供给
water_regulation.supply = water_regulation.capacity .* supply_capacity;

% 计算水源涵养服务需求
water_regulation.demand = demand_intensity .* (1 + precip/max(precip(:)));

% 计算水源涵养服务流动
water_regulation.flow = calculateActualFlow(sqrt(water_regulation.supply .* water_regulation.demand), resistance);

save('output/yellow_river_esf/water_regulation.mat', 'water_regulation');

% 8.2 土壤保持服务
fprintf('分析土壤保持服务...\n');
soil_conservation = struct();

% 计算土壤侵蚀因子
R_factor = precip .* 0.2;  % 降雨侵蚀力因子
K_factor = ones(size(landcover));  % 土壤可蚀性因子（简化）
LS_factor = sqrt(flow_paths) ./ 22.13 .* (sin(slope) ./ 0.0896).^1.3;  % 坡长坡度因子
C_factor = exp(-2 * ndvi);  % 植被覆盖因子
P_factor = ones(size(landcover));  % 水土保持措施因子（简化）

% 计算潜在土壤侵蚀量
soil_conservation.potential_erosion = R_factor .* K_factor .* LS_factor .* C_factor .* P_factor;

% 计算实际土壤侵蚀量
soil_conservation.actual_erosion = soil_conservation.potential_erosion .* (1 - supply_capacity);

% 计算土壤保持量
soil_conservation.retention = soil_conservation.potential_erosion - soil_conservation.actual_erosion;

save('output/yellow_river_esf/soil_conservation.mat', 'soil_conservation');

% 8.3 碳固定服务
fprintf('分析碳固定服务...\n');
carbon_sequestration = struct();

% 基于NDVI估算NPP
carbon_sequestration.npp = ndvi .* 1000;  % 简化的NPP估算

% 计算碳固定能力
carbon_sequestration.capacity = carbon_sequestration.npp .* supply_capacity;

% 计算碳固定服务供给
carbon_sequestration.supply = carbon_sequestration.capacity .* (1 - slope/max(slope(:)));

% 计算碳固定服务需求
carbon_sequestration.demand = demand_intensity;

% 计算碳固定服务流动
carbon_sequestration.flow = calculateActualFlow(sqrt(carbon_sequestration.supply .* carbon_sequestration.demand), resistance);

save('output/yellow_river_esf/carbon_sequestration.mat', 'carbon_sequestration');

% 8.4 食物供给服务
fprintf('分析食物供给服务...\n');
food_provision = struct();

% 计算食物生产潜力
food_provision.potential = zeros(size(landcover));
food_provision.potential(landcover == 3) = 1.0;  % 农田
food_provision.potential(landcover == 2) = 0.3;  % 草地（牧业）
food_provision.potential(landcover == 4) = 0.2;  % 水体（渔业）

% 考虑气候和土壤条件
food_provision.capacity = food_provision.potential .* (1 + ndvi) .* (precip/max(precip(:)));

% 计算食物供给
food_provision.supply = food_provision.capacity .* supply_capacity;

% 计算食物需求（基于人口密度）
food_provision.demand = demand_intensity;

% 计算食物供给服务流动
food_provision.flow = calculateActualFlow(sqrt(food_provision.supply .* food_provision.demand), resistance);

save('output/yellow_river_esf/food_provision.mat', 'food_provision');

% 8.5 水质净化服务
fprintf('分析水质净化服务...\n');
water_purification = struct();

% 计算净化能力
water_purification.capacity = zeros(size(landcover));
water_purification.capacity(landcover == 1) = 1.0;  % 森林
water_purification.capacity(landcover == 2) = 0.8;  % 草地
water_purification.capacity(landcover == 4) = 0.6;  % 水体
water_purification.capacity(landcover == 3) = 0.4;  % 农田

% 考虑地形和植被状况
water_purification.efficiency = water_purification.capacity .* ndvi .* (1 - slope/max(slope(:)));

% 计算净化服务供给
water_purification.supply = water_purification.efficiency .* supply_capacity;

% 计算净化服务需求
water_purification.demand = demand_intensity .* (1 + precip/max(precip(:)));

% 计算净化服务流动
water_purification.flow = calculateActualFlow(sqrt(water_purification.supply .* water_purification.demand), resistance);

save('output/yellow_river_esf/water_purification.mat', 'water_purification');

% 8.6 生物多样性维持服务
fprintf('分析生物多样性维持服务...\n');
biodiversity = struct();

% 计算栖息地质量
biodiversity.habitat_quality = zeros(size(landcover));
biodiversity.habitat_quality(landcover == 1) = 1.0;  % 森林
biodiversity.habitat_quality(landcover == 2) = 0.8;  % 草地
biodiversity.habitat_quality(landcover == 4) = 0.6;  % 水体
biodiversity.habitat_quality(landcover == 3) = 0.4;  % 农田
biodiversity.habitat_quality(landcover == 5) = 0.1;  % 建设用地

% 计算景观连通性
biodiversity.connectivity = calculateConnectivity(biodiversity.habitat_quality, 5);  % 5像素搜索半径

% 计算生物多样性维持能力
biodiversity.capacity = biodiversity.habitat_quality .* biodiversity.connectivity .* ndvi;

% 计算维持服务供给
biodiversity.supply = biodiversity.capacity .* supply_capacity;

% 计算维持服务需求
biodiversity.demand = ones(size(landcover)) .* (1 - demand_intensity);  % 反向需求

% 计算维持服务流动
biodiversity.flow = calculateActualFlow(sqrt(biodiversity.supply .* biodiversity.demand), resistance);

save('output/yellow_river_esf/biodiversity.mat', 'biodiversity');

% 8.7 文化服务
fprintf('分析文化服务...\n');
cultural_services = struct();

% 计算景观美学价值
cultural_services.aesthetic = zeros(size(landcover));
cultural_services.aesthetic(landcover == 1) = 1.0;  % 森林
cultural_services.aesthetic(landcover == 4) = 0.9;  % 水体
cultural_services.aesthetic(landcover == 2) = 0.8;  % 草地
cultural_services.aesthetic(landcover == 3) = 0.5;  % 农田
cultural_services.aesthetic(landcover == 5) = 0.3;  % 建设用地

% 计算地形多样性
[~, cultural_services.terrain_diversity] = gradient(dem);
cultural_services.terrain_diversity = abs(cultural_services.terrain_diversity);
cultural_services.terrain_diversity = cultural_services.terrain_diversity / max(cultural_services.terrain_diversity(:));

% 计算文化服务供给能力
cultural_services.capacity = cultural_services.aesthetic .* (1 + cultural_services.terrain_diversity);

% 计算文化服务供给
cultural_services.supply = cultural_services.capacity .* supply_capacity;

% 计算文化服务需求
cultural_services.demand = demand_intensity;

% 计算文化服务流动
cultural_services.flow = calculateActualFlow(sqrt(cultural_services.supply .* cultural_services.demand), resistance);

save('output/yellow_river_esf/cultural_services.mat', 'cultural_services');

% 9. 生态系统服务流空间特征分析
fprintf('分析生态系统服务流空间特征...\n');

% 9.1 计算服务流空间集聚度
spatial_metrics = struct();

% 计算供给区集聚度
supply_clusters = bwlabel(supply_index > mean(supply_index(:)) + std(supply_index(:)));
spatial_metrics.supply_aggregation = max(supply_clusters(:)) / sum(supply_clusters(:) > 0);

% 计算需求区集聚度
demand_clusters = bwlabel(demand_index > mean(demand_index(:)) + std(demand_index(:)));
spatial_metrics.demand_aggregation = max(demand_clusters(:)) / sum(demand_clusters(:) > 0);

% 计算流动路径连通性
spatial_metrics.flow_connectivity = sum(flow_paths(:) > 0) / numel(flow_paths);

save('output/yellow_river_esf/spatial_metrics.mat', 'spatial_metrics');

% 10. 可视化特定服务分析结果
fprintf('生成特定服务分析图表...\n');

% 10.1 水源涵养服务图
figure('Name', 'Water Regulation Service');
subplot(2,2,1);
imagesc(water_regulation.capacity);
colormap(gca, jet);
colorbar;
title('水源涵养能力');

subplot(2,2,2);
imagesc(water_regulation.supply);
colormap(gca, jet);
colorbar;
title('水源涵养服务供给');

subplot(2,2,3);
imagesc(water_regulation.demand);
colormap(gca, jet);
colorbar;
title('水源涵养服务需求');

subplot(2,2,4);
imagesc(water_regulation.flow);
colormap(gca, jet);
colorbar;
title('水源涵养服务流动');

saveas(gcf, 'output/yellow_river_esf/water_regulation.png');

% 10.2 土壤保持服务图
figure('Name', 'Soil Conservation Service');
subplot(2,2,1);
imagesc(soil_conservation.potential_erosion);
colormap(gca, hot);
colorbar;
title('潜在土壤侵蚀量');

subplot(2,2,2);
imagesc(soil_conservation.actual_erosion);
colormap(gca, hot);
colorbar;
title('实际土壤侵蚀量');

subplot(2,2,3);
imagesc(soil_conservation.retention);
colormap(gca, jet);
colorbar;
title('土壤保持量');

subplot(2,2,4);
imagesc(LS_factor);
colormap(gca, jet);
colorbar;
title('地形因子');

saveas(gcf, 'output/yellow_river_esf/soil_conservation.png');

% 10.3 碳固定服务图
figure('Name', 'Carbon Sequestration Service');
subplot(2,2,1);
imagesc(carbon_sequestration.npp);
colormap(gca, jet);
colorbar;
title('净初级生产力');

subplot(2,2,2);
imagesc(carbon_sequestration.capacity);
colormap(gca, jet);
colorbar;
title('碳固定能力');

subplot(2,2,3);
imagesc(carbon_sequestration.supply);
colormap(gca, jet);
colorbar;
title('碳固定服务供给');

subplot(2,2,4);
imagesc(carbon_sequestration.flow);
colormap(gca, jet);
colorbar;
title('碳固定服务流动');

saveas(gcf, 'output/yellow_river_esf/carbon_sequestration.png');

% 10.4 食物供给服务图
figure('Name', 'Food Provision Service');
subplot(2,2,1);
imagesc(food_provision.potential);
colormap(gca, jet);
colorbar;
title('食物生产潜力');

subplot(2,2,2);
imagesc(food_provision.capacity);
colormap(gca, jet);
colorbar;
title('食物生产能力');

subplot(2,2,3);
imagesc(food_provision.supply);
colormap(gca, jet);
colorbar;
title('食物供给');

subplot(2,2,4);
imagesc(food_provision.flow);
colormap(gca, jet);
colorbar;
title('食物供给服务流动');

saveas(gcf, 'output/yellow_river_esf/food_provision.png');

% 10.5 水质净化服务图
figure('Name', 'Water Purification Service');
subplot(2,2,1);
imagesc(water_purification.capacity);
colormap(gca, jet);
colorbar;
title('水质净化能力');

subplot(2,2,2);
imagesc(water_purification.efficiency);
colormap(gca, jet);
colorbar;
title('净化效率');

subplot(2,2,3);
imagesc(water_purification.supply);
colormap(gca, jet);
colorbar;
title('净化服务供给');

subplot(2,2,4);
imagesc(water_purification.flow);
colormap(gca, jet);
colorbar;
title('净化服务流动');

saveas(gcf, 'output/yellow_river_esf/water_purification.png');

% 10.6 生物多样性维持服务图
figure('Name', 'Biodiversity Maintenance Service');
subplot(2,2,1);
imagesc(biodiversity.habitat_quality);
colormap(gca, jet);
colorbar;
title('栖息地质量');

subplot(2,2,2);
imagesc(biodiversity.connectivity);
colormap(gca, jet);
colorbar;
title('景观连通性');

subplot(2,2,3);
imagesc(biodiversity.capacity);
colormap(gca, jet);
colorbar;
title('生物多样性维持能力');

subplot(2,2,4);
imagesc(biodiversity.flow);
colormap(gca, jet);
colorbar;
title('维持服务流动');

saveas(gcf, 'output/yellow_river_esf/biodiversity.png');

% 10.7 文化服务图
figure('Name', 'Cultural Services');
subplot(2,2,1);
imagesc(cultural_services.aesthetic);
colormap(gca, jet);
colorbar;
title('景观美学价值');

subplot(2,2,2);
imagesc(cultural_services.terrain_diversity);
colormap(gca, jet);
colorbar;
title('地形多样性');

subplot(2,2,3);
imagesc(cultural_services.capacity);
colormap(gca, jet);
colorbar;
title('文化服务能力');

subplot(2,2,4);
imagesc(cultural_services.flow);
colormap(gca, jet);
colorbar;
title('文化服务流动');

saveas(gcf, 'output/yellow_river_esf/cultural_services.png');

% 更新分析报告
fprintf(fid, '\n11. 食物供给服务分析\n');
fprintf(fid, '    平均生产潜力: %.2f\n', mean(food_provision.potential(:)));
fprintf(fid, '    平均供给量: %.2f\n', mean(food_provision.supply(:)));
fprintf(fid, '    服务流动量: %.2f\n\n', mean(food_provision.flow(:)));

fprintf(fid, '12. 水质净化服务分析\n');
fprintf(fid, '    平均净化能力: %.2f\n', mean(water_purification.capacity(:)));
fprintf(fid, '    平均净化效率: %.2f\n', mean(water_purification.efficiency(:)));
fprintf(fid, '    服务流动量: %.2f\n\n', mean(water_purification.flow(:)));

fprintf(fid, '13. 生物多样性维持服务分析\n');
fprintf(fid, '    平均栖息地质量: %.2f\n', mean(biodiversity.habitat_quality(:)));
fprintf(fid, '    平均景观连通性: %.2f\n', mean(biodiversity.connectivity(:)));
fprintf(fid, '    服务流动量: %.2f\n\n', mean(biodiversity.flow(:)));

fprintf(fid, '14. 文化服务分析\n');
fprintf(fid, '    平均景观美学价值: %.2f\n', mean(cultural_services.aesthetic(:)));
fprintf(fid, '    平均地形多样性: %.2f\n', mean(cultural_services.terrain_diversity(:)));
fprintf(fid, '    服务流动量: %.2f\n\n', mean(cultural_services.flow(:)));

% 11. 增强空间分析
fprintf('进行增强空间分析...\n');

% 11.1 景观格局分析
fprintf('分析景观格局特征...\n');
landscape_metrics = struct();

% 计算景观破碎度
landscape_metrics.fragmentation = calculateFragmentation(landcover);

% 计算景观多样性
landscape_metrics.diversity = calculateLandscapeDiversity(landcover);

% 计算边缘密度
landscape_metrics.edge_density = calculateEdgeDensity(landcover);

% 计算景观连接度
landscape_metrics.connectivity = calculateLandscapeConnectivity(landcover, 5);  % 5像素搜索半径

save('output/yellow_river_esf/landscape_metrics.mat', 'landscape_metrics');

% 11.2 空间自相关分析
fprintf('分析空间自相关性...\n');
spatial_autocorr = struct();

% 计算供给的Moran's I指数
spatial_autocorr.supply_moran = calculateMoranI(supply_index);

% 计算需求的Moran's I指数
spatial_autocorr.demand_moran = calculateMoranI(demand_index);

% 计算流动的Moran's I指数
spatial_autocorr.flow_moran = calculateMoranI(flow_paths);

save('output/yellow_river_esf/spatial_autocorr.mat', 'spatial_autocorr');

% 11.3 热点分析
fprintf('进行热点分析...\n');
hotspots = struct();

% 供给热点
hotspots.supply = calculateGetisOrd(supply_index);

% 需求热点
hotspots.demand = calculateGetisOrd(demand_index);

% 流动热点
hotspots.flow = calculateGetisOrd(flow_paths);

save('output/yellow_river_esf/hotspots.mat', 'hotspots');

% 11.4 尺度效应分析
fprintf('分析尺度效应...\n');
scale_effects = struct();

% 不同尺度下的供给聚集度
scale_effects.supply_aggregation = calculateScaleEffects(supply_index, [1, 2, 4, 8]);

% 不同尺度下的需求聚集度
scale_effects.demand_aggregation = calculateScaleEffects(demand_index, [1, 2, 4, 8]);

% 不同尺度下的流动连通性
scale_effects.flow_connectivity = calculateScaleEffects(flow_paths, [1, 2, 4, 8]);

save('output/yellow_river_esf/scale_effects.mat', 'scale_effects');

% 11.5 空间可视化
% 景观格局图
figure('Name', 'Landscape Pattern Analysis');
subplot(2,2,1);
imagesc(landscape_metrics.fragmentation);
colormap(gca, jet);
colorbar;
title('景观破碎度');

subplot(2,2,2);
imagesc(landscape_metrics.diversity);
colormap(gca, jet);
colorbar;
title('景观多样性');

subplot(2,2,3);
imagesc(landscape_metrics.edge_density);
colormap(gca, jet);
colorbar;
title('边缘密度');

subplot(2,2,4);
imagesc(landscape_metrics.connectivity);
colormap(gca, jet);
colorbar;
title('景观连接度');

saveas(gcf, 'output/yellow_river_esf/landscape_pattern.png');

% 热点分析图
figure('Name', 'Hotspot Analysis');
subplot(2,2,1);
imagesc(hotspots.supply);
colormap(gca, jet);
colorbar;
title('供给热点');

subplot(2,2,2);
imagesc(hotspots.demand);
colormap(gca, jet);
colorbar;
title('需求热点');

subplot(2,2,3);
imagesc(hotspots.flow);
colormap(gca, jet);
colorbar;
title('流动热点');

subplot(2,2,4);
imagesc(flow_paths .* (hotspots.supply > 0 & hotspots.demand > 0));
colormap(gca, jet);
colorbar;
title('关键流动区域');

saveas(gcf, 'output/yellow_river_esf/hotspots.png');

% 更新分析报告
fprintf(fid, '\n15. 景观格局分析\n');
fprintf(fid, '    平均破碎度: %.2f\n', mean(landscape_metrics.fragmentation(:)));
fprintf(fid, '    景观多样性: %.2f\n', mean(landscape_metrics.diversity(:)));
fprintf(fid, '    平均边缘密度: %.2f\n', mean(landscape_metrics.edge_density(:)));
fprintf(fid, '    整体连接度: %.2f\n\n', mean(landscape_metrics.connectivity(:)));

fprintf(fid, '16. 空间自相关分析\n');
fprintf(fid, '    供给Moran''s I: %.2f\n', spatial_autocorr.supply_moran);
fprintf(fid, '    需求Moran''s I: %.2f\n', spatial_autocorr.demand_moran);
fprintf(fid, '    流动Moran''s I: %.2f\n\n', spatial_autocorr.flow_moran);

fprintf(fid, '17. 热点分析\n');
fprintf(fid, '    供给热点区域比例: %.1f%%\n', sum(hotspots.supply(:) > 0) / numel(hotspots.supply) * 100);
fprintf(fid, '    需求热点区域比例: %.1f%%\n', sum(hotspots.demand(:) > 0) / numel(hotspots.demand) * 100);
fprintf(fid, '    流动热点区域比例: %.1f%%\n\n', sum(hotspots.flow(:) > 0) / numel(hotspots.flow) * 100);

% 12. 时间序列分析
fprintf('进行时间序列分析...\n');

% 12.1 季节性变化分析
fprintf('分析季节性变化...\n');
seasonal_analysis = struct();

% 计算各季节的供给指数
seasonal_analysis.spring_supply = supply_index .* spring_ndvi;
seasonal_analysis.summer_supply = supply_index .* summer_ndvi;
seasonal_analysis.autumn_supply = supply_index .* autumn_ndvi;
seasonal_analysis.winter_supply = supply_index .* winter_ndvi;

% 计算各季节的需求指数
seasonal_analysis.spring_demand = demand_index .* spring_precip;
seasonal_analysis.summer_demand = demand_index .* summer_precip;
seasonal_analysis.autumn_demand = demand_index .* autumn_precip;
seasonal_analysis.winter_demand = demand_index .* winter_precip;

% 计算季节性波动指数
seasonal_analysis.supply_variation = std([seasonal_analysis.spring_supply(:), ...
    seasonal_analysis.summer_supply(:), seasonal_analysis.autumn_supply(:), ...
    seasonal_analysis.winter_supply(:)], 0, 2);
seasonal_analysis.supply_variation = reshape(seasonal_analysis.supply_variation, size(supply_index));

seasonal_analysis.demand_variation = std([seasonal_analysis.spring_demand(:), ...
    seasonal_analysis.summer_demand(:), seasonal_analysis.autumn_demand(:), ...
    seasonal_analysis.winter_demand(:)], 0, 2);
seasonal_analysis.demand_variation = reshape(seasonal_analysis.demand_variation, size(demand_index));

save('output/yellow_river_esf/seasonal_analysis.mat', 'seasonal_analysis');

% 12.2 服务流动的时间动态
fprintf('分析服务流动的时间动态...\n');
temporal_dynamics = struct();

% 计算各季节的流动路径
temporal_dynamics.spring_flow = calculateActualFlow(...
    sqrt(seasonal_analysis.spring_supply .* seasonal_analysis.spring_demand), resistance);
temporal_dynamics.summer_flow = calculateActualFlow(...
    sqrt(seasonal_analysis.summer_supply .* seasonal_analysis.summer_demand), resistance);
temporal_dynamics.autumn_flow = calculateActualFlow(...
    sqrt(seasonal_analysis.autumn_supply .* seasonal_analysis.autumn_demand), resistance);
temporal_dynamics.winter_flow = calculateActualFlow(...
    sqrt(seasonal_analysis.winter_supply .* seasonal_analysis.winter_demand), resistance);

% 计算流动的时间稳定性
temporal_dynamics.flow_stability = calculateFlowStability([
    temporal_dynamics.spring_flow, temporal_dynamics.summer_flow, ...
    temporal_dynamics.autumn_flow, temporal_dynamics.winter_flow]);

save('output/yellow_river_esf/temporal_dynamics.mat', 'temporal_dynamics');

% 13. 生态系统服务束分析
fprintf('进行生态系统服务束分析...\n');

% 13.1 服务协同性分析
fprintf('分析服务协同性...\n');
service_bundles = struct();

% 整合各类服务
services_matrix = cat(3, ...
    water_regulation.supply, soil_conservation.retention, ...
    carbon_sequestration.supply, food_provision.supply, ...
    water_purification.supply, biodiversity.supply, ...
    cultural_services.supply);

% 计算服务间相关性
service_bundles.correlation = calculateServiceCorrelation(services_matrix);

% 识别服务束
service_bundles.clusters = identifyServiceBundles(services_matrix);

% 计算服务束空间分布
service_bundles.distribution = calculateBundleDistribution(service_bundles.clusters);

save('output/yellow_river_esf/service_bundles.mat', 'service_bundles');

% 13.2 权衡分析
fprintf('进行权衡分析...\n');
tradeoffs = struct();

% 计算服务间权衡关系
tradeoffs.matrix = calculateTradeoffs(services_matrix);

% 识别关键权衡区域
tradeoffs.hotspots = identifyTradeoffHotspots(tradeoffs.matrix, services_matrix);

% 计算权衡强度
tradeoffs.intensity = calculateTradeoffIntensity(tradeoffs.matrix);

save('output/yellow_river_esf/tradeoffs.mat', 'tradeoffs');

% 14. 可视化时间序列和服务束分析结果
% 14.1 季节性变化图
figure('Name', 'Seasonal Dynamics');
subplot(2,2,1);
imagesc(seasonal_analysis.supply_variation);
colormap(gca, jet);
colorbar;
title('供给季节性波动');

subplot(2,2,2);
imagesc(seasonal_analysis.demand_variation);
colormap(gca, jet);
colorbar;
title('需求季节性波动');

subplot(2,2,3);
imagesc(temporal_dynamics.flow_stability);
colormap(gca, jet);
colorbar;
title('流动时间稳定性');

subplot(2,2,4);
plot([mean(temporal_dynamics.spring_flow(:)), mean(temporal_dynamics.summer_flow(:)), ...
    mean(temporal_dynamics.autumn_flow(:)), mean(temporal_dynamics.winter_flow(:))]);
title('季节性流动变化');
xlabel('季节');
ylabel('平均流动量');

saveas(gcf, 'output/yellow_river_esf/seasonal_dynamics.png');

% 14.2 服务束分析图
figure('Name', 'Service Bundles Analysis');
subplot(2,2,1);
imagesc(service_bundles.correlation);
colormap(gca, jet);
colorbar;
title('服务协同性矩阵');

subplot(2,2,2);
imagesc(service_bundles.distribution);
colormap(gca, jet);
colorbar;
title('服务束空间分布');

subplot(2,2,3);
imagesc(tradeoffs.matrix);
colormap(gca, jet);
colorbar;
title('服务权衡矩阵');

subplot(2,2,4);
imagesc(tradeoffs.hotspots);
colormap(gca, jet);
colorbar;
title('权衡热点区域');

saveas(gcf, 'output/yellow_river_esf/service_bundles.png');

% 更新分析报告
fprintf(fid, '\n18. 时间序列分析\n');
fprintf(fid, '    供给季节性波动指数: %.2f\n', mean(seasonal_analysis.supply_variation(:)));
fprintf(fid, '    需求季节性波动指数: %.2f\n', mean(seasonal_analysis.demand_variation(:)));
fprintf(fid, '    流动时间稳定性指数: %.2f\n\n', mean(temporal_dynamics.flow_stability(:)));

fprintf(fid, '19. 服务束分析\n');
fprintf(fid, '    服务协同性指数: %.2f\n', mean(service_bundles.correlation(:)));
fprintf(fid, '    识别的服务束数量: %d\n', max(service_bundles.clusters(:)));
fprintf(fid, '    权衡热点区域比例: %.1f%%\n\n', ...
    sum(tradeoffs.hotspots(:) > 0) / numel(tradeoffs.hotspots) * 100);

% 新增辅助函数
function fragmentation = calculateFragmentation(landcover)
    % 计算每种土地利用类型的破碎度
    unique_types = unique(landcover);
    fragmentation = zeros(size(landcover));
    
    for type = unique_types'
        mask = landcover == type;
        labeled = bwlabel(mask);
        patch_count = max(labeled(:));
        patch_sizes = histcounts(labeled(labeled > 0));
        mean_patch_size = mean(patch_sizes);
        
        % 破碎度 = 斑块数量 / 平均斑块大小
        frag_index = patch_count / mean_patch_size;
        fragmentation(mask) = frag_index;
    end
    
    % 归一化
    fragmentation = fragmentation / max(fragmentation(:));
end

function diversity = calculateLandscapeDiversity(landcover)
    % 使用移动窗口计算Shannon多样性指数
    window_size = 5;
    [rows, cols] = size(landcover);
    diversity = zeros(rows, cols);
    
    for i = 1:rows
        for j = 1:cols
            % 提取窗口
            row_start = max(1, i-floor(window_size/2));
            row_end = min(rows, i+floor(window_size/2));
            col_start = max(1, j-floor(window_size/2));
            col_end = min(cols, j+floor(window_size/2));
            
            window = landcover(row_start:row_end, col_start:col_end);
            
            % 计算Shannon指数
            unique_types = unique(window);
            shannon = 0;
            for type = unique_types'
                p = sum(window(:) == type) / numel(window);
                shannon = shannon - p * log(p);
            end
            
            diversity(i,j) = shannon;
        end
    end
    
    % 归一化
    diversity = diversity / max(diversity(:));
end

function edge_density = calculateEdgeDensity(landcover)
    % 计算边缘密度
    [rows, cols] = size(landcover);
    edge_density = zeros(rows, cols);
    window_size = 5;
    
    for i = 1:rows
        for j = 1:cols
            % 提取窗口
            row_start = max(1, i-floor(window_size/2));
            row_end = min(rows, i+floor(window_size/2));
            col_start = max(1, j-floor(window_size/2));
            col_end = min(cols, j+floor(window_size/2));
            
            window = landcover(row_start:row_end, col_start:col_end);
            
            % 计算边缘
            [gx, gy] = gradient(double(window));
            edges = sqrt(gx.^2 + gy.^2);
            
            edge_density(i,j) = sum(edges(:)) / numel(window);
        end
    end
    
    % 归一化
    edge_density = edge_density / max(edge_density(:));
end

function moran = calculateMoranI(data)
    % 计算Moran's I指数
    [rows, cols] = size(data);
    n = numel(data);
    data_mean = mean(data(:));
    
    % 创建空间权重矩阵（简化为相邻单元权重为1）
    numerator = 0;
    denominator = 0;
    W = 0;  % 权重和
    
    for i = 1:rows
        for j = 1:cols
            for di = -1:1
                for dj = -1:1
                    if di == 0 && dj == 0
                        continue;
                    end
                    
                    ni = i + di;
                    nj = j + dj;
                    
                    if ni >= 1 && ni <= rows && nj >= 1 && nj <= cols
                        W = W + 1;
                        numerator = numerator + (data(i,j) - data_mean) * (data(ni,nj) - data_mean);
                    end
                end
            end
        end
    end
    
    denominator = sum((data(:) - data_mean).^2);
    moran = (n / W) * (numerator / denominator);
end

function hotspots = calculateGetisOrd(data)
    % 计算Getis-Ord Gi*统计量
    [rows, cols] = size(data);
    hotspots = zeros(rows, cols);
    window_size = 5;
    
    data_mean = mean(data(:));
    data_std = std(data(:));
    
    for i = 1:rows
        for j = 1:cols
            % 提取窗口
            row_start = max(1, i-floor(window_size/2));
            row_end = min(rows, i+floor(window_size/2));
            col_start = max(1, j-floor(window_size/2));
            col_end = min(cols, j+floor(window_size/2));
            
            window = data(row_start:row_end, col_start:col_end);
            
            % 计算Gi*统计量
            local_sum = sum(window(:));
            n = numel(window);
            
            Gi = (local_sum - n * data_mean) / (data_std * sqrt((n * sum(window(:).^2) - local_sum^2) / (n - 1)));
            
            % 显著性水平0.05
            if abs(Gi) > 1.96
                hotspots(i,j) = sign(Gi);
            end
        end
    end
end

function scale_metrics = calculateScaleEffects(data, scales)
    % 计算不同尺度下的指标
    scale_metrics = zeros(size(scales));
    
    for i = 1:length(scales)
        scale = scales(i);
        if scale > 1
            % 降采样
            downsampled = imresize(data, 1/scale);
            % 计算聚集度
            scale_metrics(i) = sum(downsampled(:) > mean(downsampled(:))) / numel(downsampled);
        else
            scale_metrics(i) = sum(data(:) > mean(data(:))) / numel(data);
        end
    end
end

function stability = calculateFlowStability(flow_series)
    % 计算流动的时间稳定性
    flow_mean = mean(flow_series, 2);
    flow_std = std(flow_series, 0, 2);
    stability = 1 - (flow_std ./ (flow_mean + eps));
    stability = reshape(stability, size(flow_series, 1), []);
end

function correlation = calculateServiceCorrelation(services)
    % 计算服务间相关性
    n_services = size(services, 3);
    correlation = zeros(n_services);
    
    for i = 1:n_services
        for j = 1:n_services
            if i ~= j
                corr_coef = corrcoef(services(:,:,i), services(:,:,j));
                correlation(i,j) = corr_coef(1,2);
            end
        end
    end
end

function clusters = identifyServiceBundles(services)
    % 使用K-means识别服务束
    [rows, cols, n_services] = size(services);
    data = reshape(services, [], n_services);
    
    % 使用轮廓系数确定最优聚类数
    max_clusters = 5;
    silhouette_scores = zeros(max_clusters-1, 1);
    
    for k = 2:max_clusters
        [idx, ~] = kmeans(data, k, 'Replicates', 5);
        silhouette_scores(k-1) = mean(silhouette(data, idx));
    end
    
    [~, optimal_k] = max(silhouette_scores);
    optimal_k = optimal_k + 1;
    
    [idx, ~] = kmeans(data, optimal_k, 'Replicates', 5);
    clusters = reshape(idx, rows, cols);
end

function distribution = calculateBundleDistribution(clusters)
    % 计算服务束的空间分布特征
    unique_clusters = unique(clusters);
    distribution = zeros(size(clusters));
    
    for i = 1:length(unique_clusters)
        cluster_mask = clusters == unique_clusters(i);
        labeled = bwlabel(cluster_mask);
        sizes = histcounts(labeled(labeled > 0));
        
        % 计算聚集度
        aggregation = mean(sizes) / max(sizes);
        distribution(cluster_mask) = aggregation;
    end
end

function tradeoff_matrix = calculateTradeoffs(services)
    % 计算服务间权衡关系
    n_services = size(services, 3);
    tradeoff_matrix = zeros(n_services);
    
    for i = 1:n_services
        for j = 1:n_services
            if i ~= j
                % 计算权衡指数
                service1 = services(:,:,i);
                service2 = services(:,:,j);
                
                % 标准化
                service1 = (service1 - min(service1(:))) / (max(service1(:)) - min(service1(:)));
                service2 = (service2 - min(service2(:))) / (max(service2(:)) - min(service2(:)));
                
                % 权衡指数 = 1 - 两个服务的最小值/最大值的比值
                tradeoff = 1 - mean(min(service1(:), service2(:)) ./ max(service1(:), service2(:)));
                tradeoff_matrix(i,j) = tradeoff;
            end
        end
    end
end

function hotspots = identifyTradeoffHotspots(tradeoff_matrix, services)
    % 识别权衡关系的热点区域
    [rows, cols, ~] = size(services);
    hotspots = zeros(rows, cols);
    
    % 找出最强的权衡关系
    [max_tradeoff, ~] = max(tradeoff_matrix(:));
    [service1_idx, service2_idx] = find(tradeoff_matrix == max_tradeoff);
    
    if ~isempty(service1_idx)
        service1 = services(:,:,service1_idx(1));
        service2 = services(:,:,service2_idx(1));
        
        % 标准化
        service1 = (service1 - min(service1(:))) / (max(service1(:)) - min(service1(:)));
        service2 = (service2 - min(service2(:))) / (max(service2(:)) - min(service2(:)));
        
        % 识别权衡热点（一个服务高而另一个服务低的区域）
        hotspots = (service1 > mean(service1(:)) + std(service1(:)) & ...
            service2 < mean(service2(:)) - std(service2(:))) | ...
            (service2 > mean(service2(:)) + std(service2(:)) & ...
            service1 < mean(service1(:)) - std(service1(:)));
    end
end

function intensity = calculateTradeoffIntensity(tradeoff_matrix)
    % 计算权衡强度
    intensity = mean(tradeoff_matrix, 2);
end

% 15. 生态系统服务流优化分析
fprintf('进行服务流优化分析...\n');

% 15.1 识别关键优化区域
fprintf('识别关键优化区域...\n');
optimization = struct();

% 计算供需匹配度
optimization.supply_demand_match = calculateSupplyDemandMatch(supply_index, demand_index);

% 识别供给不足区域
optimization.supply_deficit = identifySupplyDeficit(supply_index, demand_index);

% 识别需求过度区域
optimization.demand_excess = identifyDemandExcess(supply_index, demand_index);

% 识别流动瓶颈区域
optimization.flow_bottleneck = identifyFlowBottleneck(flow_paths, resistance);

save('output/yellow_river_esf/optimization.mat', 'optimization');

% 15.2 优化方案生成
fprintf('生成优化方案...\n');
optimization_plan = struct();

% 供给优化建议
optimization_plan.supply = generateSupplyOptimization(optimization.supply_deficit, landcover);

% 需求优化建议
optimization_plan.demand = generateDemandOptimization(optimization.demand_excess);

% 流动路径优化建议
optimization_plan.flow = generateFlowOptimization(optimization.flow_bottleneck, landcover);

save('output/yellow_river_esf/optimization_plan.mat', 'optimization_plan');

% 15.3 可视化优化分析结果
figure('Name', 'Optimization Analysis');
subplot(2,2,1);
imagesc(optimization.supply_demand_match);
colormap(gca, jet);
colorbar;
title('供需匹配度');

subplot(2,2,2);
imagesc(optimization.supply_deficit);
colormap(gca, hot);
colorbar;
title('供给不足区域');

subplot(2,2,3);
imagesc(optimization.demand_excess);
colormap(gca, hot);
colorbar;
title('需求过度区域');

subplot(2,2,4);
imagesc(optimization.flow_bottleneck);
colormap(gca, hot);
colorbar;
title('流动瓶颈区域');

saveas(gcf, 'output/yellow_river_esf/optimization_analysis.png');

% 更新分析报告
fprintf(fid, '\n22. 优化分析\n');
fprintf(fid, '    供需匹配度: %.2f\n', mean(optimization.supply_demand_match(:)));
fprintf(fid, '    供给不足区域比例: %.1f%%\n', ...
    sum(optimization.supply_deficit(:) > 0) / numel(optimization.supply_deficit) * 100);
fprintf(fid, '    需求过度区域比例: %.1f%%\n', ...
    sum(optimization.demand_excess(:) > 0) / numel(optimization.demand_excess) * 100);
fprintf(fid, '    流动瓶颈区域比例: %.1f%%\n\n', ...
    sum(optimization.flow_bottleneck(:) > 0) / numel(optimization.flow_bottleneck) * 100);

fprintf(fid, '23. 优化建议\n');
fprintf(fid, '    供给优化措施:\n');
fprintf(fid, '    - 加强生态系统保护和修复\n');
fprintf(fid, '    - 优化土地利用结构\n');
fprintf(fid, '    - 提高生态系统服务供给能力\n\n');

fprintf(fid, '    需求优化措施:\n');
fprintf(fid, '    - 合理控制开发强度\n');
fprintf(fid, '    - 优化人类活动空间布局\n');
fprintf(fid, '    - 提高资源利用效率\n\n');

fprintf(fid, '    流动优化措施:\n');
fprintf(fid, '    - 构建生态廊道\n');
fprintf(fid, '    - 降低景观阻力\n');
fprintf(fid, '    - 加强关键节点保护\n\n');

% 新增辅助函数
function match = calculateSupplyDemandMatch(supply, demand)
    % 计算供需匹配度
    supply_norm = supply / max(supply(:));
    demand_norm = demand / max(demand(:));
    match = 1 - abs(supply_norm - demand_norm);
end

function deficit = identifySupplyDeficit(supply, demand)
    % 识别供给不足区域
    supply_norm = supply / max(supply(:));
    demand_norm = demand / max(demand(:));
    deficit = max(0, demand_norm - supply_norm);
end

function excess = identifyDemandExcess(supply, demand)
    % 识别需求过度区域
    supply_norm = supply / max(supply(:));
    demand_norm = demand / max(demand(:));
    excess = max(0, demand_norm - 2*supply_norm);  % 需求超过供给两倍定义为过度
end

function bottleneck = identifyFlowBottleneck(flow_paths, resistance)
    % 识别流动瓶颈区域
    flow_intensity = flow_paths .* resistance;
    bottleneck = flow_intensity > mean(flow_intensity(:)) + std(flow_intensity(:));
end

function plan = generateSupplyOptimization(deficit, landcover)
    % 生成供给优化方案
    plan = struct();
    
    % 基于土地利用类型的优化建议
    [rows, cols] = size(deficit);
    plan.priority = zeros(rows, cols);
    
    for i = 1:rows
        for j = 1:cols
            if deficit(i,j) > 0
                switch landcover(i,j)
                    case 1  % 森林
                        plan.priority(i,j) = 3;  % 高优先级
                    case 2  % 草地
                        plan.priority(i,j) = 2;  % 中优先级
                    case 3  % 农田
                        plan.priority(i,j) = 1;  % 低优先级
                end
            end
        end
    end
end

function plan = generateDemandOptimization(excess)
    % 生成需求优化方案
    plan = struct();
    
    % 根据过度程度分级
    plan.priority = zeros(size(excess));
    plan.priority(excess > 0.66) = 3;  % 高优先级
    plan.priority(excess > 0.33 & excess <= 0.66) = 2;  % 中优先级
    plan.priority(excess > 0 & excess <= 0.33) = 1;  % 低优先级
end

function plan = generateFlowOptimization(bottleneck, landcover)
    % 生成流动路径优化方案
    plan = struct();
    
    % 识别潜在生态廊道
    [rows, cols] = size(bottleneck);
    plan.corridor = zeros(rows, cols);
    
    for i = 1:rows
        for j = 1:cols
            if bottleneck(i,j)
                % 检查周边8个像素
                window = landcover(max(1,i-1):min(rows,i+1), max(1,j-1):min(cols,j+1));
                if any(window(:) == 1) || any(window(:) == 2)  % 周边有森林或草地
                    plan.corridor(i,j) = 1;
                end
            end
        end
    end
end

% 添加政策分析部分
policy_analyzer = YellowRiverPolicy();
regional_analyzer = YellowRiverRegionalAnalyzer();

% 加载政策参数
policy_analyzer.loadPolicyParameters();

% 分析区域特征
regional_analyzer.analyzeRegionalCharacteristics();

% 评估区域服务
regional_results = regional_analyzer.evaluateRegionalService();

% 检查政策合规性
compliance = policy_analyzer.checkPolicyCompliance(regional_results);

% 生成优化建议
optimization_plan = generateOptimizationPlan(regional_results, compliance);

% 生成综合报告
report = struct();
report.policy_compliance = compliance;
report.regional_analysis = regional_results;
report.optimization = optimization_plan;

% 可视化结果
visualizeResults(report); 