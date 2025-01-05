classdef ServiceFlowAnalyzerTest < matlab.unittest.TestCase
    % ServiceFlowAnalyzerTest 服务流量化分析测试类
    
    properties
        Analyzer
        TestData
    end
    
    methods (TestMethodSetup)
        function setupTest(testCase)
            % 测试初始化
            testCase.Analyzer = ServiceFlowAnalyzer();
            testCase.TestData = testCase.generateTestData();
        end
    end
    
    methods (Test)
        function testDataValidation(testCase)
            % 测试数据验证
            % 1. 测试正常数据
            testCase.verifyNotError(@() testCase.Analyzer.validateData());
            
            % 2. 测试维度不一致
            invalid_data = ones(3,4);
            testCase.Analyzer.setSupplyData(invalid_data);
            testCase.verifyError(@() testCase.Analyzer.validateData(), ...
                               '数据维度不一致');
            
            % 恢复正常数据
            testCase.Analyzer.setSupplyData(testCase.TestData.supply);
        end
        
        function testDataPreprocessing(testCase)
            % 测试数据预处理
            % 1. 添加异常值
            data_with_outliers = testCase.TestData.supply;
            data_with_outliers(1,1) = 1000;  % 添加异常值
            testCase.Analyzer.setSupplyData(data_with_outliers);
            
            % 2. 预处理
            testCase.Analyzer.preprocessData();
            
            % 3. 验证异常值已被处理
            processed_data = testCase.Analyzer.getResults().supply;
            testCase.verifyLessThan(max(processed_data(:)), 1000);
        end
        
        function testSupplyAnalysis(testCase)
            % 测试供给分析
            % 1. 运行分析
            results = testCase.Analyzer.analyzeSupply([]);
            
            % 2. 验证结果结构
            testCase.verifyTrue(isfield(results, 'capacity'));
            testCase.verifyTrue(isfield(results, 'quality'));
            testCase.verifyTrue(isfield(results, 'distribution'));
            testCase.verifyTrue(isfield(results, 'potential'));
            
            % 3. 验证数值范围
            testCase.verifyGreaterThanOrEqual(results.capacity.total, 0);
            testCase.verifyLessThanOrEqual(results.capacity.total, sum(testCase.TestData.supply(:)));
        end
        
        function testDemandAnalysis(testCase)
            % 测试需求分析
            % 1. 运行分析
            results = testCase.Analyzer.analyzeDemand([]);
            
            % 2. 验证结果结构
            testCase.verifyTrue(isfield(results, 'quantity'));
            testCase.verifyTrue(isfield(results, 'intensity'));
            testCase.verifyTrue(isfield(results, 'distribution'));
            testCase.verifyTrue(isfield(results, 'pressure'));
            
            % 3. 验证数值范围
            testCase.verifyGreaterThanOrEqual(results.quantity.total, 0);
            testCase.verifyLessThanOrEqual(results.quantity.total, sum(testCase.TestData.demand(:)));
        end
        
        function testResistanceAnalysis(testCase)
            % 测试阻力分析
            % 1. 运行分析
            results = testCase.Analyzer.analyzeResistance([]);
            
            % 2. 验证结果结构
            testCase.verifyTrue(isfield(results, 'coefficient'));
            testCase.verifyTrue(isfield(results, 'impact'));
            testCase.verifyTrue(isfield(results, 'distribution'));
            testCase.verifyTrue(isfield(results, 'accumulation'));
            
            % 3. 验证数值范围
            testCase.verifyGreaterThanOrEqual(min(results.coefficient.weighted(:)), 0);
            testCase.verifyLessThanOrEqual(max(results.coefficient.weighted(:)), 1);
        end
        
        function testFlowAnalysis(testCase)
            % 测试流动分析
            % 1. 运行分析
            results = testCase.Analyzer.analyzeSpatialFlow([]);
            
            % 2. 验证结果结构
            testCase.verifyTrue(isfield(results, 'paths'));
            testCase.verifyTrue(isfield(results, 'intensity'));
            testCase.verifyTrue(isfield(results, 'efficiency'));
            testCase.verifyTrue(isfield(results, 'flux'));
            
            % 3. 验证路径有效性
            if ~isempty(results.paths)
                path = results.paths{1};
                if ~isempty(path)
                    testCase.verifySize(path, [NaN 2]);  % 路径应该是Nx2矩阵
                end
            end
        end
        
        function testUncertaintyAnalysis(testCase)
            % 测试不确定性分析
            % 1. 运行完整分析
            results = testCase.Analyzer.analyzeServiceFlow([]);
            
            % 2. 验证不确定性结构
            testCase.verifyTrue(isfield(results, 'uncertainty'));
            testCase.verifyTrue(isfield(results.uncertainty, 'supply'));
            testCase.verifyTrue(isfield(results.uncertainty, 'demand'));
            testCase.verifyTrue(isfield(results.uncertainty, 'resistance'));
            testCase.verifyTrue(isfield(results.uncertainty, 'total'));
            
            % 3. 验证数值范围
            testCase.verifyGreaterThanOrEqual(results.uncertainty.total, 0);
            testCase.verifyLessThanOrEqual(results.uncertainty.total, 1);
        end
        
        function testEvaluation(testCase)
            % 测试综合评价
            % 1. 运行完整分析
            results = testCase.Analyzer.analyzeServiceFlow([]);
            
            % 2. 验证评价结构
            testCase.verifyTrue(isfield(results, 'evaluation'));
            testCase.verifyTrue(isfield(results.evaluation, 'balance_score'));
            testCase.verifyTrue(isfield(results.evaluation, 'efficiency_score'));
            testCase.verifyTrue(isfield(results.evaluation, 'spatial_score'));
            testCase.verifyTrue(isfield(results.evaluation, 'resistance_score'));
            testCase.verifyTrue(isfield(results.evaluation, 'uncertainty_score'));
            testCase.verifyTrue(isfield(results.evaluation, 'total_score'));
            
            % 3. 验证分数范围
            scores = struct2array(results.evaluation);
            testCase.verifyGreaterThanOrEqual(min(scores), 0);
            testCase.verifyLessThanOrEqual(max(scores), 1);
        end
    end
    
    methods (Access = private)
        function test_data = generateTestData(testCase)
            % 生成测试数据
            % 1. 设置随机种子
            rng(42);
            
            % 2. 生成网格
            [X, Y] = meshgrid(1:10, 1:10);
            
            % 3. 生成供给数据（高斯分布）
            supply = exp(-(((X-5).^2 + (Y-5).^2)/20));
            
            % 4. 生成需求数据（多个热点）
            demand = zeros(10,10);
            hotspots = [2 2; 8 8; 5 5];
            for i = 1:size(hotspots,1)
                demand = demand + exp(-(((X-hotspots(i,1)).^2 + (Y-hotspots(i,2)).^2)/10));
            end
            
            % 5. 生成阻力数据（随机地形）
            resistance = peaks(10)/5 + 0.5;
            
            % 6. 生成空间数据（DEM）
            spatial = peaks(10) + 10;
            
            % 7. 打包数据
            test_data = struct(...
                'supply', supply, ...
                'demand', demand, ...
                'resistance', resistance, ...
                'spatial', spatial);
        end
    end
end 