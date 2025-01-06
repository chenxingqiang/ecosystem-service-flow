classdef DataManagementTest < matlab.unittest.TestCase
    % DataManagementTest 数据管理模块测试类
    % 测试数据导入导出、预处理和格式转换功能
    
    properties
        DataManager
        TestDataPath
        OutputPath
    end
    
    methods (TestMethodSetup)
        function setupTest(testCase)
            % 设置测试环境
            testCase.DataManager = DataManager();
            testCase.TestDataPath = fullfile(fileparts(mfilename('fullpath')), 'data', 'validation');
            testCase.OutputPath = fullfile(fileparts(mfilename('fullpath')), 'output');
            if ~exist(testCase.OutputPath, 'dir')
                mkdir(testCase.OutputPath);
            end
        end
    end
    
    methods (TestMethodTeardown)
        function teardownTest(testCase)
            % 清理测试输出
            if exist(testCase.OutputPath, 'dir')
                rmdir(testCase.OutputPath, 's');
            end
        end
    end
    
    methods (Test)
        function testDataImport(testCase)
            % 测试数据导入功能
            % 1. ASCII格式
            dem_file = fullfile(testCase.TestDataPath, 'dem.asc');
            dem_data = testCase.DataManager.importData(dem_file, 'supply');
            testCase.verifySize(dem_data, [100, 100], 'ASCII数据导入尺寸错误');
            
            % 2. GeoTIFF格式
            landuse_file = fullfile(testCase.TestDataPath, 'landuse.tif');
            landuse_data = testCase.DataManager.importData(landuse_file, 'spatial');
            testCase.verifySize(landuse_data, [100, 100], 'GeoTIFF数据导入尺寸错误');
            
            % 3. MAT格式
            supply_file = fullfile(testCase.TestDataPath, 'supply.mat');
            supply_data = testCase.DataManager.importData(supply_file, 'supply');
            testCase.verifySize(supply_data, [100, 100], 'MAT数据导入尺寸错误');
            
            % 4. CSV格式
            demand_file = fullfile(testCase.TestDataPath, 'demand.csv');
            demand_data = testCase.DataManager.importData(demand_file, 'demand');
            testCase.verifySize(demand_data, [100, 100], 'CSV数据导入尺寸错误');
            
            % 5. Excel格式
            resistance_file = fullfile(testCase.TestDataPath, 'resistance.xlsx');
            resistance_data = testCase.DataManager.importData(resistance_file, 'resistance');
            testCase.verifySize(resistance_data, [100, 100], 'Excel数据导入尺寸错误');
        end
        
        function testDataExport(testCase)
            % 测试数据导出功能
            test_data = rand(100);
            
            % 1. ASCII格式导出
            ascii_output = fullfile(testCase.OutputPath, 'test.asc');
            testCase.DataManager.exportData(test_data, ascii_output, '.asc');
            testCase.verifyTrue(exist(ascii_output, 'file') == 2, 'ASCII文件导出失败');
            
            % 2. GeoTIFF格式导出
            tiff_output = fullfile(testCase.OutputPath, 'test.tif');
            testCase.DataManager.exportData(test_data, tiff_output, '.tif');
            testCase.verifyTrue(exist(tiff_output, 'file') == 2, 'GeoTIFF文件导出失败');
            
            % 3. MAT格式导出
            mat_output = fullfile(testCase.OutputPath, 'test.mat');
            testCase.DataManager.exportData(test_data, mat_output, '.mat');
            testCase.verifyTrue(exist(mat_output, 'file') == 2, 'MAT文件导出失败');
            
            % 4. CSV格式导出
            csv_output = fullfile(testCase.OutputPath, 'test.csv');
            testCase.DataManager.exportData(test_data, csv_output, '.csv');
            testCase.verifyTrue(exist(csv_output, 'file') == 2, 'CSV文件导出失败');
            
            % 5. Excel格式导出
            xlsx_output = fullfile(testCase.OutputPath, 'test.xlsx');
            testCase.DataManager.exportData(test_data, xlsx_output, '.xlsx');
            testCase.verifyTrue(exist(xlsx_output, 'file') == 2, 'Excel文件导出失败');
        end
        
        function testDataPreprocessing(testCase)
            % 测试数据预处理功能
            raw_data = rand(100) * 1000;
            
            % 1. 数据标准化
            operations = {struct('type', 'normalize')};
            testCase.DataManager.setSupplyData(raw_data);
            testCase.DataManager.preprocessData('supply', operations);
            normalized_data = testCase.DataManager.getData('supply');
            testCase.verifyGreaterThanOrEqual(normalized_data, 0, '标准化数据范围错误');
            testCase.verifyLessThanOrEqual(normalized_data, 1, '标准化数据范围错误');
            
            % 2. 数据平滑
            operations = {struct('type', 'smooth', 'sigma', 1.0)};
            testCase.DataManager.setDemandData(raw_data);
            testCase.DataManager.preprocessData('demand', operations);
            smoothed_data = testCase.DataManager.getData('demand');
            testCase.verifyNotEqual(smoothed_data, raw_data, '数据平滑无效');
            
            % 3. 缺失值处理
            missing_data = raw_data;
            missing_data(1:10, 1:10) = NaN;
            operations = {struct('type', 'fillmissing', 'method', 'linear')};
            testCase.DataManager.setResistanceData(missing_data);
            testCase.DataManager.preprocessData('resistance', operations);
            filled_data = testCase.DataManager.getData('resistance');
            testCase.verifyTrue(~any(isnan(filled_data(:))), '数据插值后仍存在缺失值');
        end
    end
end
