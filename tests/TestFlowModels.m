% TestFlowModels.m
% 测试所有流动模型的功能

% 清理工作空间
clear;
clc;

% 创建测试数据
[X, Y] = meshgrid(1:20, 1:20);
dem_data = peaks(20) + 10;
supply_data = exp(-(((X-10).^2 + (Y-10).^2)/50));
demand_data = zeros(20,20);
hotspots = [5 5; 15 15; 10 10];
for i = 1:size(hotspots,1)
    demand_data = demand_data + exp(-(((X-hotspots(i,1)).^2 + (Y-hotspots(i,2)).^2)/20));
end
resistance_data = peaks(20)/5 + 0.5;

% 创建分析器实例
analyzer = ServiceFlowAnalyzer();

% 设置数据
analyzer.setSupplyData(supply_data);
analyzer.setDemandData(demand_data);
analyzer.setResistanceData(resistance_data);
analyzer.setSpatialData(dem_data);

% 创建可视化器实例
visualizer = FlowVisualizer();

% 测试所有流动模型
flow_models = {'surface-water', 'sediment', 'line-of-sight', 'proximity', ...
               'carbon', 'flood-water', 'coastal-storm-protection', ...
               'subsistence-fisheries'};

% 创建图形窗口
figure('Position', [100 100 1200 800]);

for i = 1:length(flow_models)
    % 设置当前流动模型
    analyzer.setFlowModel(flow_models{i});
    
    % 运行分析
    try
        results = analyzer.analyzeServiceFlow([]);
        
        % 创建子图
        subplot(2, 4, i);
        
        % 可视化结果
        imagesc(results.actual_flow.final);
        colormap(turbo);
        colorbar;
        title(flow_models{i}, 'Interpreter', 'none');
        axis equal tight;
        
        % 打印基本统计信息
        fprintf('\n模型: %s\n', flow_models{i});
        fprintf('最大流量: %.4f\n', max(results.actual_flow.final(:)));
        fprintf('平均流量: %.4f\n', mean(results.actual_flow.final(:)));
        fprintf('效率比: %.2f%%\n', results.efficiency.ratio * 100);
        
    catch e
        fprintf('错误: 模型 %s 运行失败\n', flow_models{i});
        fprintf('错误信息: %s\n', e.message);
    end
end

% 调整布局
sgtitle('生态系统服务流动模型比较');

% 保存结果
saveas(gcf, 'flow_models_comparison.png');

% 测试可视化功能
try
    % 1. 供需分布可视化
    visualizer.visualizeSupplyDemand(supply_data, demand_data, '供需分布分析');
    
    % 2. 流动路径可视化
    visualizer.visualizeFlowPaths(results.spatial_flow.paths, dem_data, '流动路径分析');
    
    % 3. 流动强度可视化
    visualizer.visualizeFlowIntensity(results.spatial_flow.intensity.final, '流动强度分析');
    
    % 4. 阻力分布可视化
    visualizer.visualizeResistance(resistance_data, results.resistance.impact.barriers, '阻力分布分析');
    
    % 5. 流动效率可视化
    visualizer.visualizeFlowEfficiency(results.efficiency, '流动效率分析');
    
    % 6. 3D流动可视化
    visualizer.visualize3DFlow(dem_data, results.actual_flow.final, '3D流动分析');
    
catch e
    fprintf('错误: 可视化失败\n');
    fprintf('错误信息: %s\n', e.message);
end

fprintf('\n测试完成\n'); 