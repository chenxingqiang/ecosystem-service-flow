% 测试SPAN模型的使用

% 1. 创建测试数据
[X, Y] = meshgrid(1:50, 1:50);
dem = peaks(50);  % 使用MATLAB的peaks函数生成测试地形

% 生成源数据（例如：森林分布）
source_data = exp(-(X-25).^2/300 - (Y-25).^2/300);

% 生成汇数据（例如：城市分布）
sink_data = exp(-(X-40).^2/200 - (Y-40).^2/200);

% 生成使用数据（例如：人口分布）
use_data = exp(-(X-35).^2/250 - (Y-35).^2/250);

% 生成流动数据层
flow_data = zeros(50, 50, 4);
flow_data(:,:,1) = exp(-(X-25).^2/400 - (Y-25).^2/400);  % 植被覆盖
flow_data(:,:,2) = (sin(X/10) + cos(Y/10) + 2) / 4;      % 生产力
flow_data(:,:,3) = (cos(X/15) + sin(Y/15) + 2) / 4;      % 气候因子
flow_data(:,:,4) = dem / max(dem(:));                     % 地形因子

% 2. 创建SPAN模型实例
model = SpanModel(source_data, sink_data, use_data, flow_data, ...
    'source_threshold', 0.1, ...
    'sink_threshold', 0.1, ...
    'use_threshold', 0.1, ...
    'trans_threshold', 0.1, ...
    'cell_width', 30, ...
    'cell_height', 30, ...
    'source_type', 'finite', ...
    'sink_type', 'finite', ...
    'use_type', 'finite', ...
    'benefit_type', 'rival', ...
    'flow_model', 'carbon');

% 3. 运行模型
results = model.runModel();

% 4. 可视化结果
model.visualizeResults(results);

% 5. 打印汇总统计
fprintf('\n碳固定服务流分析结果：\n');
fprintf('理论流动总量：%.2f\n', results.summary.total_theoretical);
fprintf('实际流动总量：%.2f\n', results.summary.total_actual);
fprintf('使用总量：%.2f\n', results.summary.total_used);
fprintf('阻滞总量：%.2f\n', results.summary.total_blocked);
fprintf('传输效率：%.2f%%\n', results.summary.delivery_ratio * 100);
fprintf('使用效率：%.2f%%\n', results.summary.use_ratio * 100);
fprintf('阻滞率：%.2f%%\n', results.summary.block_ratio * 100);

% 6. 测试其他流动模型
% 创建洪水模型实例
flood_model = SpanModel(source_data, sink_data, use_data, flow_data, ...
    'flow_model', 'flood-water');

% 运行洪水模型
flood_results = flood_model.runModel();

% 可视化洪水模型结果
flood_model.visualizeResults(flood_results);

% 打印洪水模型汇总统计
fprintf('\n洪水服务流分析结果：\n');
fprintf('理论流动总量：%.2f\n', flood_results.summary.total_theoretical);
fprintf('实际流动总量：%.2f\n', flood_results.summary.total_actual);
fprintf('使用总量：%.2f\n', flood_results.summary.total_used);
fprintf('阻滞总量：%.2f\n', flood_results.summary.total_blocked);
fprintf('传输效率：%.2f%%\n', flood_results.summary.delivery_ratio * 100);
fprintf('使用效率：%.2f%%\n', flood_results.summary.use_ratio * 100);
fprintf('阻滞率：%.2f%%\n', flood_results.summary.block_ratio * 100); 