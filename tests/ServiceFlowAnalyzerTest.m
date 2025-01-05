classdef ServiceFlowAnalyzerTest < matlab.unittest.TestCase
    % ServiceFlowAnalyzerTest 服务流分析器测试类
    
    properties
        Analyzer
        TestData
    end
    
    methods (TestMethodSetup)
        function setupTest(testCase)
            % 每个测试方法前的设置
            testCase.Analyzer = ServiceFlowAnalyzer();
            testCase.TestData = testCase.generateTestData();
            
            % 设置数据
            testCase.Analyzer.setSupplyData(testCase.TestData.supply);
            testCase.Analyzer.setDemandData(testCase.TestData.demand);
            testCase.Analyzer.setResistanceData(testCase.TestData.resistance);
            testCase.Analyzer.setSpatialData(testCase.TestData.spatial);
        end
    end
    
    methods (Test)
        function testDataValidation(testCase)
            % 测试数据验证功能
            
            % 1. 测试正常数据
            testCase.verifyWarningFree(@() testCase.Analyzer.validateData());
            
            % 2. 测试缺失数据
            analyzer_missing = ServiceFlowAnalyzer();
            testCase.verifyError(@() analyzer_missing.validateData(), ...
                '数据不完整');
            
            % 3. 测试数据维度不一致
            analyzer_inconsistent = ServiceFlowAnalyzer();
            analyzer_inconsistent.setSupplyData(ones(10,10));
            analyzer_inconsistent.setDemandData(ones(10,11));
            analyzer_inconsistent.setResistanceData(ones(10,10));
            analyzer_inconsistent.setSpatialData(ones(10,10));
            testCase.verifyError(@() analyzer_inconsistent.validateData(), ...
                '数据维度不一致');
        end
        
        function testDataPreprocessing(testCase)
            % 测试数据预处理功能
            
            % 1. 测试异常值处理
            data_with_outliers = testCase.TestData.supply;
            data_with_outliers(1,1) = 1000;  % 添加异常值
            testCase.Analyzer.setSupplyData(data_with_outliers);
            testCase.Analyzer.preprocessData();
            processed_data = testCase.Analyzer.SupplyData;
            testCase.verifyNotEqual(processed_data(1,1), 1000);
            
            % 2. 测试标准化
            testCase.verifyGreaterThanOrEqual(min(processed_data(:)), 0);
            testCase.verifyLessThanOrEqual(max(processed_data(:)), 1);
            
            % 3. 测试缺失值插值
            data_with_nan = testCase.TestData.supply;
            data_with_nan(1,1) = NaN;
            testCase.Analyzer.setSupplyData(data_with_nan);
            testCase.Analyzer.preprocessData();
            processed_data = testCase.Analyzer.SupplyData;
            testCase.verifyFalse(any(isnan(processed_data(:))));
        end
        
        function testFlowAnalysis(testCase)
            % 测试流动分析功能
            
            % 1. 测试理论流动计算
            results = testCase.Analyzer.analyzeServiceFlow(struct());
            testCase.verifyTrue(isfield(results, 'theoretical_flow'));
            testCase.verifyTrue(isfield(results, 'actual_flow'));
            
            % 2. 验证流动效率
            testCase.verifyTrue(isfield(results, 'efficiency'));
            testCase.verifyGreaterThanOrEqual(results.efficiency.ratio, 0);
            testCase.verifyLessThanOrEqual(results.efficiency.ratio, 1);
            
            % 3. 验证不确定性分析
            testCase.verifyTrue(isfield(results, 'uncertainty'));
            testCase.verifyTrue(results.uncertainty.total >= 0);
        end
        
        function testModelSpecificValidation(testCase)
            % 测试模型特定验证
            
            % 1. 测试地表水模型验证
            testCase.Analyzer.setFlowModel('surface-water');
            results = testCase.Analyzer.validateModelSpecific();
            testCase.verifyTrue(isfield(results, 'hydrological_continuity'));
            testCase.verifyTrue(isfield(results, 'flow_direction'));
            
            % 2. 测试泥沙模型验证
            testCase.Analyzer.setFlowModel('sediment');
            results = testCase.Analyzer.validateModelSpecific();
            testCase.verifyTrue(isfield(results, 'concentration_range'));
            testCase.verifyTrue(isfield(results, 'transport_capacity'));
            
            % 3. 测试视线模型验证
            testCase.Analyzer.setFlowModel('line-of-sight');
            results = testCase.Analyzer.validateModelSpecific();
            testCase.verifyTrue(isfield(results, 'viewpoint_position'));
            testCase.verifyTrue(isfield(results, 'visibility_range'));
        end
        
        function testPhysicalConstraints(testCase)
            % 测试物理约束验证
            
            % 1. 测试质量守恒
            results = testCase.Analyzer.validatePhysicalConstraints();
            testCase.verifyTrue(isfield(results, 'mass_conservation'));
            
            % 2. 测试能量守恒
            testCase.verifyTrue(isfield(results, 'energy_conservation'));
            
            % 3. 测试流动约束
            testCase.verifyTrue(isfield(results, 'flow_constraints'));
        end
        
        function testVisualization(testCase)
            % 测试可视化功能
            
            % 1. 测试验证结果可视化
            testCase.Analyzer.validateData();
            testCase.verifyWarningFree(@() testCase.Analyzer.visualizeValidationResults());
            
            % 2. 测试不确定性可视化
            results = testCase.Analyzer.analyzeServiceFlow(struct());
            testCase.verifyWarningFree(@() testCase.Analyzer.visualizeUncertainty());
            
            % 3. 测试验证总结可视化
            testCase.verifyWarningFree(@() testCase.Analyzer.visualizeValidationSummary());
        end
        
        function testErrorHandling(testCase)
            % 测试错误处理
            
            % 1. 测试无效的流动模型类型
            testCase.verifyError(@() testCase.Analyzer.setFlowModel('invalid-model'), ...
                '不支持的流动模型类型');
            
            % 2. 测试无效的参数设置
            invalid_params = struct('supply_weight', -1);
            testCase.verifyError(@() testCase.Analyzer.setParameters(invalid_params), ...
                '参数值无效');
            
            % 3. 测试数据范围验证
            invalid_data = -ones(10,10);
            testCase.Analyzer.setSupplyData(invalid_data);
            results = testCase.Analyzer.validateValueRanges();
            testCase.verifyFalse(results.supply.non_negative);
        end
        
        function testPerformance(testCase)
            % 测试性能
            
            % 1. 测试大规模数据处理
            large_data = rand(100,100);
            testCase.Analyzer.setSupplyData(large_data);
            testCase.Analyzer.setDemandData(large_data);
            testCase.Analyzer.setResistanceData(large_data);
            testCase.Analyzer.setSpatialData(large_data);
            
            tic;
            testCase.Analyzer.analyzeServiceFlow(struct());
            execution_time = toc;
            
            testCase.verifyLessThan(execution_time, 60);  % 确保执行时间在合理范围内
        end
        
        function testEdgeCases(testCase)
            % 测试边界情况
            
            % 1. 测试零供给/需求
            zero_data = zeros(10,10);
            testCase.Analyzer.setSupplyData(zero_data);
            testCase.Analyzer.setDemandData(zero_data);
            results = testCase.Analyzer.analyzeServiceFlow(struct());
            testCase.verifyEqual(results.theoretical_flow.max_flow, 0);
            
            % 2. 测试极大值
            max_data = ones(10,10) * realmax;
            testCase.Analyzer.setSupplyData(max_data);
            testCase.verifyWarningFree(@() testCase.Analyzer.validateData());
            
            % 3. 测试稀疏数据
            sparse_data = sparse(10,10);
            sparse_data(1,1) = 1;
            testCase.Analyzer.setSupplyData(full(sparse_data));
            testCase.verifyWarningFree(@() testCase.Analyzer.validateData());
        end
        
        function testSpatialConsistency(testCase)
            % 测试空间一致性验证
            
            % 1. 测试投影一致性
            results = testCase.Analyzer.validateSpatialConsistency();
            testCase.verifyTrue(isfield(results, 'projection_match'));
            testCase.verifyTrue(results.projection_match);
            
            % 2. 测试分辨率一致性
            testCase.verifyTrue(isfield(results, 'resolution_match'));
            testCase.verifyTrue(results.resolution_match);
            
            % 3. 测试范围一致性
            testCase.verifyTrue(isfield(results, 'extent_match'));
            testCase.verifyTrue(results.extent_match);
        end
        
        function testTemporalValidation(testCase)
            % 测试时间维度验证
            
            % 1. 测试时间序列完整性
            temporal_data = struct('timestamps', datenum(2020:2022,1,1));
            testCase.Analyzer.setTemporalData(temporal_data);
            results = testCase.Analyzer.validateTemporalData();
            testCase.verifyTrue(isfield(results, 'temporal_continuity'));
            
            % 2. 测试时间分辨率
            testCase.verifyTrue(isfield(results, 'temporal_resolution'));
            
            % 3. 测试季节性模式
            testCase.verifyTrue(isfield(results, 'seasonal_patterns'));
        end
        
        function testAdvancedFlowAnalysis(testCase)
            % 测试高级流动分析功能
            
            % 1. 测试多路径分析
            results = testCase.Analyzer.analyzeMultipleFlowPaths();
            testCase.verifyTrue(isfield(results, 'path_count'));
            testCase.verifyTrue(isfield(results, 'path_efficiency'));
            
            % 2. 测试瓶颈识别
            bottleneck_results = testCase.Analyzer.identifyBottlenecks();
            testCase.verifyTrue(isfield(bottleneck_results, 'locations'));
            testCase.verifyTrue(isfield(bottleneck_results, 'severity'));
            
            % 3. 测试流动累积
            accumulation_results = testCase.Analyzer.calculateFlowAccumulation();
            testCase.verifyTrue(isfield(accumulation_results, 'accumulation_map'));
            testCase.verifyTrue(all(accumulation_results.accumulation_map(:) >= 0));
        end
        
        function testModelCalibration(testCase)
            % 测试模型校准功能
            
            % 1. 测试参数敏感性分析
            sensitivity_results = testCase.Analyzer.analyzeSensitivity();
            testCase.verifyTrue(isfield(sensitivity_results, 'parameters'));
            testCase.verifyTrue(isfield(sensitivity_results, 'sensitivity_scores'));
            
            % 2. 测试模型校准
            calibration_data = struct('observed', rand(10,10), 'parameters', struct());
            calibration_results = testCase.Analyzer.calibrateModel(calibration_data);
            testCase.verifyTrue(isfield(calibration_results, 'optimized_parameters'));
            testCase.verifyTrue(isfield(calibration_results, 'calibration_error'));
            
            % 3. 测试模型验证
            validation_results = testCase.Analyzer.validateModel(calibration_data);
            testCase.verifyTrue(isfield(validation_results, 'validation_metrics'));
            testCase.verifyTrue(isfield(validation_results, 'validation_error'));
        end
        
        function testScenarioAnalysis(testCase)
            % 测试情景分析功能
            
            % 1. 测试气候变化情景
            climate_scenario = struct('temperature_change', 2, 'precipitation_change', -0.1);
            climate_results = testCase.Analyzer.analyzeClimateScenario(climate_scenario);
            testCase.verifyTrue(isfield(climate_results, 'flow_changes'));
            
            % 2. 测试土地利用变化情景
            landuse_scenario = struct('conversion_matrix', eye(4));
            landuse_results = testCase.Analyzer.analyzeLandUseScenario(landuse_scenario);
            testCase.verifyTrue(isfield(landuse_results, 'service_changes'));
            
            % 3. 测试政策情景
            policy_scenario = struct('protection_level', 0.3);
            policy_results = testCase.Analyzer.analyzePolicyScenario(policy_scenario);
            testCase.verifyTrue(isfield(policy_results, 'impact_assessment'));
        end
        
        function testUncertaintyPropagation(testCase)
            % 测试不确定性传播分析
            
            % 1. 测试参数不确定性
            param_uncertainty = testCase.Analyzer.analyzeParameterUncertainty();
            testCase.verifyTrue(isfield(param_uncertainty, 'parameter_ranges'));
            testCase.verifyTrue(isfield(param_uncertainty, 'output_ranges'));
            
            % 2. 测试输入数据不确定性
            input_uncertainty = testCase.Analyzer.analyzeInputUncertainty();
            testCase.verifyTrue(isfield(input_uncertainty, 'input_effects'));
            
            % 3. 测试模型结构不确定性
            structural_uncertainty = testCase.Analyzer.analyzeStructuralUncertainty();
            testCase.verifyTrue(isfield(structural_uncertainty, 'model_comparison'));
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