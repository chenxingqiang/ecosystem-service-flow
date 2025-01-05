% TestServiceFlowAnalyzer.m
% 测试服务流分析模块的功能

% 清理工作空间
clear;
clc;

% 创建测试数据
[X, Y] = meshgrid(1:20, 1:20);
test_supply = peaks(20);
test_demand = flipud(peaks(20));
test_resistance = ones(20) * 0.5;
test_elevation = peaks(20) * 10;

% 创建服务流分析器实例
flow_analyzer = ServiceFlowAnalyzer();

% 1. 测试基本流模型设置
fprintf('测试基本流模型设置...\n');
try
    flow_analyzer.setFlowModel('proximity');
    fprintf('通过: 流模型设置成功\n');
catch e
    fprintf('失败: 流模型设置失败 - %s\n', e.message);
end

% 2. 测试理论流计算
fprintf('\n测试理论流计算...\n');
try
    theoretical_flow = flow_analyzer.calculateTheoreticalFlow(test_supply, test_demand);
    if ~isempty(theoretical_flow) && all(size(theoretical_flow) == size(test_supply))
        fprintf('通过: 理论流计算成功\n');
    else
        fprintf('失败: 理论流计算结果维度不正确\n');
    end
catch e
    fprintf('失败: 理论流计算失败 - %s\n', e.message);
end

% 3. 测试实际流计算
fprintf('\n测试实际流计算...\n');
try
    actual_flow = flow_analyzer.calculateActualFlow(theoretical_flow, test_resistance);
    if ~isempty(actual_flow) && all(size(actual_flow) == size(test_supply))
        fprintf('通过: 实际流计算成功\n');
    else
        fprintf('失败: 实际流计算结果维度不正确\n');
    end
catch e
    fprintf('失败: 实际流计算失败 - %s\n', e.message);
end

% 4. 测试沉积物流模型
fprintf('\n测试沉积物流模型...\n');

% 测试坡度和坡向计算
try
    [slope, aspect] = flow_analyzer.calculateSlopeAspect(test_elevation);
    if ~isempty(slope) && ~isempty(aspect)
        fprintf('通过: 坡度和坡向计算成功\n');
    else
        fprintf('失败: 坡度和坡向计算结果为空\n');
    end
catch e
    fprintf('失败: 坡度和坡向计算失败 - %s\n', e.message);
end

% 测试侵蚀计算
try
    erosion = flow_analyzer.calculateErosion(slope, test_supply);
    if ~isempty(erosion)
        fprintf('通过: 侵蚀计算成功\n');
    else
        fprintf('失败: 侵蚀计算结果为空\n');
    end
catch e
    fprintf('失败: 侵蚀计算失败 - %s\n', e.message);
end

% 测试沉积物运移计算
try
    transport = flow_analyzer.calculateSedimentTransport(erosion, slope, aspect);
    if ~isempty(transport)
        fprintf('通过: 沉积物运移计算成功\n');
    else
        fprintf('失败: 沉积物运移计算结果为空\n');
    end
catch e
    fprintf('失败: 沉积物运移计算失败 - %s\n', e.message);
end

% 测试沉积计算
try
    deposition = flow_analyzer.calculateDeposition(transport, slope);
    if ~isempty(deposition)
        fprintf('通过: 沉积计算成功\n');
    else
        fprintf('失败: 沉积计算结果为空\n');
    end
catch e
    fprintf('失败: 沉积计算失败 - %s\n', e.message);
end

% 5. 测试视线流模型
fprintf('\n测试视线流模型...\n');

% 测试视点获取
try
    viewpoints = flow_analyzer.getViewPoints(test_supply, 5);  % 获取前5个最高点作为视点
    if ~isempty(viewpoints)
        fprintf('通过: 视点获取成功\n');
    else
        fprintf('失败: 视点获取结果为空\n');
    end
catch e
    fprintf('失败: 视点获取失败 - %s\n', e.message);
end

% 测试可视性分析
try
    visibility = flow_analyzer.calculateVisibility(viewpoints, test_elevation);
    if ~isempty(visibility)
        fprintf('通过: 可视性分析成功\n');
    else
        fprintf('失败: 可视性分析结果为空\n');
    end
catch e
    fprintf('失败: 可视性分析失败 - %s\n', e.message);
end

% 测试视觉质量评估
try
    view_quality = flow_analyzer.calculateViewQuality(visibility, test_supply);
    if ~isempty(view_quality)
        fprintf('通过: 视觉质量评估成功\n');
    else
        fprintf('失败: 视觉质量评估结果为空\n');
    end
catch e
    fprintf('失败: 视觉质量评估失败 - %s\n', e.message);
end

% 6. 测试邻近度流模型
fprintf('\n测试邻近度流模型...\n');

% 测试邻近度计算
try
    proximity_flow = flow_analyzer.calculateProximityFlow(test_supply, test_demand, test_resistance);
    if ~isempty(proximity_flow)
        fprintf('通过: 邻近度流计算成功\n');
    else
        fprintf('失败: 邻近度流计算结果为空\n');
    end
catch e
    fprintf('失败: 邻近度流计算失败 - %s\n', e.message);
end

% 7. 测试流效率分析
fprintf('\n测试流效率分析...\n');
try
    efficiency = flow_analyzer.analyzeFlowEfficiency(theoretical_flow, actual_flow);
    if ~isempty(efficiency)
        fprintf('通过: 流效率分析成功\n');
    else
        fprintf('失败: 流效率分析结果为空\n');
    end
catch e
    fprintf('失败: 流效率分析失败 - %s\n', e.message);
end

% 8. 测试结果验证
fprintf('\n测试结果验证...\n');

% 验证流量守恒
try
    total_supply = sum(test_supply(:));
    total_flow = sum(actual_flow(:));
    if abs(total_supply - total_flow) / total_supply < 0.1  % 允许10%的误差
        fprintf('通过: 流量守恒验证成功\n');
    else
        fprintf('失败: 流量守恒验证失败\n');
    end
catch e
    fprintf('失败: 流量守恒验证失败 - %s\n', e.message);
end

% 验证边界条件
try
    if all(actual_flow(:) >= 0)  % 确保没有负流量
        fprintf('通过: 边界条件验证成功\n');
    else
        fprintf('失败: 存在负流量\n');
    end
catch e
    fprintf('失败: 边界条件验证失败 - %s\n', e.message);
end

fprintf('\n测试完成\n'); 