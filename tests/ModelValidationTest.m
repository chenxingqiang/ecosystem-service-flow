classdef ModelValidationTest < matlab.unittest.TestCase
    % ModelValidationTest 模型验证测试类
    
    properties
        Analyzer
        TestData
        FieldData
        ValidationMetrics
    end
    
    methods (TestMethodSetup)
        function setupTest(testCase)
            % 每个测试方法前的设置
            testCase.Analyzer = ServiceFlowAnalyzer();
            testCase.TestData = testCase.loadTestData();
            testCase.FieldData = testCase.loadFieldData();
            testCase.ValidationMetrics = struct(...
                'rmse', @(x,y) sqrt(mean((x(:)-y(:)).^2)), ...
                'mae', @(x,y) mean(abs(x(:)-y(:))), ...
                'r2', @(x,y) corr(x(:),y(:))^2, ...
                'nse', @(x,y) 1 - sum((x(:)-y(:)).^2)/sum((y(:)-mean(y(:))).^2));
        end
    end
    
    methods (Test)
        function testWaterFlowValidation(testCase)
            % 测试水流模拟结果验证
            
            % 1. 测试流量模拟
            simulated_flow = testCase.Analyzer.simulateWaterFlow();
            observed_flow = testCase.FieldData.water_flow;
            
            % 验证流量精度
            testCase.verifyGreaterThan(testCase.ValidationMetrics.r2(...
                simulated_flow, observed_flow), 0.6);
            testCase.verifyLessThan(testCase.ValidationMetrics.rmse(...
                simulated_flow, observed_flow), 0.3);
            
            % 2. 测试水位模拟
            simulated_level = testCase.Analyzer.simulateWaterLevel();
            observed_level = testCase.FieldData.water_level;
            
            % 验证水位精度
            testCase.verifyGreaterThan(testCase.ValidationMetrics.nse(...
                simulated_level, observed_level), 0.7);
            
            % 3. 测试流速模拟
            simulated_velocity = testCase.Analyzer.simulateWaterVelocity();
            observed_velocity = testCase.FieldData.water_velocity;
            
            % 验证流速精度
            testCase.verifyLessThan(testCase.ValidationMetrics.mae(...
                simulated_velocity, observed_velocity), 0.2);
        end
        
        function testSedimentTransportValidation(testCase)
            % 测试泥沙输移模拟结果验证
            
            % 1. 测试泥沙浓度
            simulated_concentration = testCase.Analyzer.simulateSedimentConcentration();
            observed_concentration = testCase.FieldData.sediment_concentration;
            
            % 验证浓度精度
            testCase.verifyGreaterThan(testCase.ValidationMetrics.r2(...
                simulated_concentration, observed_concentration), 0.5);
            
            % 2. 测试输沙量
            simulated_load = testCase.Analyzer.simulateSedimentLoad();
            observed_load = testCase.FieldData.sediment_load;
            
            % 验证输沙量精度
            testCase.verifyGreaterThan(testCase.ValidationMetrics.nse(...
                simulated_load, observed_load), 0.6);
            
            % 3. 测试沉积分布
            simulated_deposition = testCase.Analyzer.simulateSedimentDeposition();
            observed_deposition = testCase.FieldData.sediment_deposition;
            
            % 验证沉积分布精度
            testCase.verifyLessThan(testCase.ValidationMetrics.rmse(...
                simulated_deposition, observed_deposition), 0.4);
        end
        
        function testCarbonFluxValidation(testCase)
            % 测试碳通量模拟结果验证
            
            % 1. 测试碳固定
            simulated_sequestration = testCase.Analyzer.simulateCarbonSequestration();
            observed_sequestration = testCase.FieldData.carbon_sequestration;
            
            % 验证固碳精度
            testCase.verifyGreaterThan(testCase.ValidationMetrics.r2(...
                simulated_sequestration, observed_sequestration), 0.5);
            
            % 2. 测试碳储量
            simulated_storage = testCase.Analyzer.simulateCarbonStorage();
            observed_storage = testCase.FieldData.carbon_storage;
            
            % 验证储量精度
            testCase.verifyLessThan(testCase.ValidationMetrics.mae(...
                simulated_storage, observed_storage), 0.3);
            
            % 3. 测试碳排放
            simulated_emission = testCase.Analyzer.simulateCarbonEmission();
            observed_emission = testCase.FieldData.carbon_emission;
            
            % 验证排放精度
            testCase.verifyGreaterThan(testCase.ValidationMetrics.nse(...
                simulated_emission, observed_emission), 0.6);
        end
        
        function testSoilErosionValidation(testCase)
            % 测试土壤侵蚀模拟结果验证
            
            % 1. 测试侵蚀量
            simulated_erosion = testCase.Analyzer.simulateSoilErosion();
            observed_erosion = testCase.FieldData.soil_erosion;
            
            % 验证侵蚀量精度
            testCase.verifyGreaterThan(testCase.ValidationMetrics.r2(...
                simulated_erosion, observed_erosion), 0.5);
            
            % 2. 测试土壤流失
            simulated_loss = testCase.Analyzer.simulateSoilLoss();
            observed_loss = testCase.FieldData.soil_loss;
            
            % 验证流失精度
            testCase.verifyLessThan(testCase.ValidationMetrics.rmse(...
                simulated_loss, observed_loss), 0.4);
            
            % 3. 测试沉积再分布
            simulated_redistribution = testCase.Analyzer.simulateSoilRedistribution();
            observed_redistribution = testCase.FieldData.soil_redistribution;
            
            % 验证再分布精度
            testCase.verifyGreaterThan(testCase.ValidationMetrics.nse(...
                simulated_redistribution, observed_redistribution), 0.5);
        end
        
        function testServiceFlowValidation(testCase)
            % 测试服务流模拟结果验证
            
            % 1. 测试供给流
            simulated_supply = testCase.Analyzer.simulateServiceSupply();
            observed_supply = testCase.FieldData.service_supply;
            
            % 验证供给流精度
            testCase.verifyGreaterThan(testCase.ValidationMetrics.r2(...
                simulated_supply, observed_supply), 0.6);
            
            % 2. 测试需求流
            simulated_demand = testCase.Analyzer.simulateServiceDemand();
            observed_demand = testCase.FieldData.service_demand;
            
            % 验证需求流精度
            testCase.verifyLessThan(testCase.ValidationMetrics.mae(...
                simulated_demand, observed_demand), 0.3);
            
            % 3. 测试实际流动
            simulated_flow = testCase.Analyzer.simulateActualFlow();
            observed_flow = testCase.FieldData.actual_flow;
            
            % 验证实际流动精度
            testCase.verifyGreaterThan(testCase.ValidationMetrics.nse(...
                simulated_flow, observed_flow), 0.6);
        end
        
        function testUncertaintyValidation(testCase)
            % 测试不确定性分析验证
            
            % 1. 测试参数不确定性
            uncertainty = testCase.Analyzer.analyzeParameterUncertainty();
            testCase.verifyTrue(isfield(uncertainty, 'confidence_intervals'));
            testCase.verifyTrue(all(uncertainty.confidence_intervals > 0));
            
            % 2. 测试模型结构不确定性
            structural = testCase.Analyzer.analyzeStructuralUncertainty();
            testCase.verifyTrue(isfield(structural, 'model_comparison'));
            testCase.verifyTrue(isfield(structural, 'model_weights'));
            
            % 3. 测试情景不确定性
            scenario = testCase.Analyzer.analyzeScenarioUncertainty();
            testCase.verifyTrue(isfield(scenario, 'range'));
            testCase.verifyTrue(isfield(scenario, 'probability'));
        end
    end
    
    methods (Access = private)
        function data = loadTestData(testCase)
            % 加载测试数据
            data = load('data/validation/test_data.mat');
        end
        
        function data = loadFieldData(testCase)
            % 加载实测数据
            data = load('data/validation/field_data.mat');
        end
    end
end 