% TestDataManager.m
% 测试数据管理模块的功能

% 清理工作空间
clear;
clc;

% 创建测试数据
[X, Y] = meshgrid(1:20, 1:20);
test_data = peaks(20);
test_data_with_nan = test_data;
test_data_with_nan(1:5, 1:5) = NaN;

% 创建数据管理器实例
data_manager = DataManager();

% 1. 测试数据验证设置
fprintf('测试数据验证设置...\n');
try
    settings = struct('allow_nan', true, 'check_range', true);
    data_manager.setValidationSettings(settings);
    fprintf('通过: 数据验证设置成功\n');
catch e
    fprintf('失败: 数据验证设置失败 - %s\n', e.message);
end

% 2. 测试数据导出
fprintf('\n测试数据导出功能...\n');

% 创建输出目录
if ~exist('output/test', 'dir')
    mkdir('output/test');
end

% 测试不同格式的导出
formats = {'.csv', '.xlsx', '.mat'};
for i = 1:length(formats)
    try
        filepath = ['output/test/test_data' formats{i}];
        data_manager.exportData(test_data, filepath);
        fprintf('通过: 成功导出%s格式\n', formats{i});
    catch e
        fprintf('失败: 导出%s格式失败 - %s\n', formats{i}, e.message);
    end
end

% 3. 测试数据导入
fprintf('\n测试数据导入功能...\n');
for i = 1:length(formats)
    try
        filepath = ['output/test/test_data' formats{i}];
        imported_data = data_manager.importData(filepath, 'test');
        
        % 验证导入数据的正确性
        if isequal(size(imported_data), size(test_data))
            fprintf('通过: 成功导入%s格式\n', formats{i});
        else
            fprintf('失败: 导入%s格式数据维度不匹配\n', formats{i});
        end
    catch e
        fprintf('失败: 导入%s格式失败 - %s\n', formats{i}, e.message);
    end
end

% 4. 测试数据预处理
fprintf('\n测试数据预处理功能...\n');

% 测试标准化
try
    operations = {struct('type', 'normalize', 'method', 'minmax')};
    data_manager.preprocessData('test', operations);
    fprintf('通过: 数据标准化成功\n');
catch e
    fprintf('失败: 数据标准化失败 - %s\n', e.message);
end

% 测试缺失值填充
try
    operations = {struct('type', 'fillmissing', 'method', 'mean')};
    data_manager.preprocessData('test', operations);
    fprintf('通过: 缺失值填充成功\n');
catch e
    fprintf('失败: 缺失值填充失败 - %s\n', e.message);
end

% 测试异常值处理
try
    operations = {struct('type', 'removeoutliers', 'threshold', 3)};
    data_manager.preprocessData('test', operations);
    fprintf('通过: 异常值处理成功\n');
catch e
    fprintf('失败: 异常值处理失败 - %s\n', e.message);
end

% 测试数据平滑
try
    operations = {struct('type', 'smooth', 'window', 3)};
    data_manager.preprocessData('test', operations);
    fprintf('通过: 数据平滑成功\n');
catch e
    fprintf('失败: 数据平滑失败 - %s\n', e.message);
end

% 测试数据重采样
try
    operations = {struct('type', 'resample', 'scale', 0.5)};
    data_manager.preprocessData('test', operations);
    fprintf('通过: 数据重采样成功\n');
catch e
    fprintf('失败: 数据重采样失败 - %s\n', e.message);
end

% 5. 测试数据获取
fprintf('\n测试数据获取功能...\n');
try
    data = data_manager.getData('test');
    fprintf('通过: 数据获取成功\n');
catch e
    fprintf('失败: 数据获取失败 - %s\n', e.message);
end

% 6. 测试GeoTIFF和ASC格式（如果有空间参考数据）
fprintf('\n测试空间数据格式...\n');

% 创建测试用的空间参考数据
try
    % GeoTIFF
    filepath = 'output/test/test_data.tif';
    ref_matrix = [1 0 0; 0 1 0; 0 0 1];  % 示例空间参考矩阵
    options.RefMatrix = ref_matrix;
    data_manager.exportData(test_data, filepath, options);
    fprintf('通过: GeoTIFF导出成功\n');
    
    imported_data = data_manager.importData(filepath, 'spatial');
    fprintf('通过: GeoTIFF导入成功\n');
catch e
    fprintf('失败: GeoTIFF测试失败 - %s\n', e.message);
end

try
    % ASC
    filepath = 'output/test/test_data.asc';
    options = struct('cellsize', 1, 'xllcorner', 0, 'yllcorner', 0, 'NODATA_value', -9999);
    data_manager.exportData(test_data, filepath, options);
    fprintf('通过: ASC导出成功\n');
    
    imported_data = data_manager.importData(filepath, 'spatial');
    fprintf('通过: ASC导入成功\n');
catch e
    fprintf('失败: ASC测试失败 - %s\n', e.message);
end

fprintf('\n测试完成\n'); 