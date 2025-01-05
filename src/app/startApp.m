% startApp.m
% 启动生态系统服务流分析系统

function startApp()
    % 清理工作空间
    clear;
    clc;
    
    % 添加所有必要的路径
    addRequiredPaths();
    
    % 检查系统要求
    checkSystemRequirements();
    
    % 创建输出目录
    createOutputDirectories();
    
    % 启动主程序
    try
        % 创建分析器实例
        analyzer = ServiceFlowAnalyzer();
        
        % 创建可视化器实例
        visualizer = FlowVisualizer();
        
        % 打印欢迎信息
        printWelcomeMessage();
        
        % 返回实例供用户使用
        assignin('base', 'analyzer', analyzer);
        assignin('base', 'visualizer', visualizer);
        
    catch e
        fprintf('错误: 系统启动失败\n');
        fprintf('错误信息: %s\n', e.message);
        return;
    end
end

function addRequiredPaths()
    % 获取当前文件所在目录
    current_dir = fileparts(mfilename('fullpath'));
    
    % 获取项目根目录
    project_root = fileparts(fileparts(current_dir));
    
    % 添加必要的路径
    addpath(genpath(fullfile(project_root, 'src')));
    addpath(genpath(fullfile(project_root, 'tests')));
    addpath(genpath(fullfile(project_root, 'docs')));
end

function checkSystemRequirements()
    % 检查MATLAB版本
    required_version = '9.10'; % R2021a
    if verLessThan('matlab', required_version)
        error('需要MATLAB R2021a或更高版本');
    end
    
    % 检查必要的工具箱
    required_toolboxes = {'Mapping Toolbox', ...
                         'Statistics and Machine Learning Toolbox', ...
                         'Optimization Toolbox', ...
                         'Image Processing Toolbox'};
    
    v = ver;
    installed_toolboxes = {v.Name};
    
    missing_toolboxes = setdiff(required_toolboxes, installed_toolboxes);
    if ~isempty(missing_toolboxes)
        error('缺少必要的工具箱：\n%s', strjoin(missing_toolboxes, '\n'));
    end
end

function createOutputDirectories()
    % 创建输出目录
    output_dirs = {'./output', ...
                  './output/maps', ...
                  './output/plots', ...
                  './output/reports', ...
                  './output/temp'};
    
    for i = 1:length(output_dirs)
        if ~exist(output_dirs{i}, 'dir')
            mkdir(output_dirs{i});
        end
    end
end

function printWelcomeMessage()
    fprintf('\n');
    fprintf('=================================================\n');
    fprintf('      欢迎使用生态系统服务流分析系统 v1.0        \n');
    fprintf('=================================================\n');
    fprintf('\n');
    fprintf('系统已成功启动！\n');
    fprintf('- 分析器实例 (analyzer) 已创建\n');
    fprintf('- 可视化器实例 (visualizer) 已创建\n');
    fprintf('\n');
    fprintf('可用的流动模型:\n');
    fprintf('1. surface-water          - 地表水流动\n');
    fprintf('2. sediment              - 泥沙流动\n');
    fprintf('3. line-of-sight         - 视线流动\n');
    fprintf('4. proximity             - 邻近度流动\n');
    fprintf('5. carbon                - 碳流动\n');
    fprintf('6. flood-water           - 洪水流动\n');
    fprintf('7. coastal-storm-protection - 海岸风暴防护\n');
    fprintf('8. subsistence-fisheries - 生计渔业\n');
    fprintf('\n');
    fprintf('使用示例:\n');
    fprintf('>> analyzer.setFlowModel(''surface-water'');\n');
    fprintf('>> results = analyzer.analyzeServiceFlow([]);\n');
    fprintf('>> visualizer.visualizeFlowPaths(results.spatial_flow.paths, dem_data, ''流动路径分析'');\n');
    fprintf('\n');
end 