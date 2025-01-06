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
            
            % 设置测试数据
            supply_data = testCase.TestData.water_flow.input;
            demand_data = testCase.TestData.water_flow.input;
            resistance_data = ones(size(testCase.TestData.water_flow.input)); % Use uniform resistance
            spatial_data = struct(...
                'elevation', supply_data, ...
                'flow_velocity', demand_data ...
            );
            
            testCase.Analyzer.setSupplyData(supply_data);
            testCase.Analyzer.setDemandData(demand_data);
            testCase.Analyzer.setResistanceData(resistance_data);
            testCase.Analyzer.setSpatialData(spatial_data);
            
            % 1. 测试流量模拟
            testCase.Analyzer.setFlowModel('surface-water');
            flow_results = testCase.Analyzer.analyzeServiceFlow();
            simulated_flow = flow_results.actual_flow;
            observed_flow = testCase.TestData.water_flow.expected_output;
            
            % 验证流量精度
            testCase.verifyGreaterThan(testCase.ValidationMetrics.r2(...
                simulated_flow, observed_flow), 0.6);
            testCase.verifyLessThan(testCase.ValidationMetrics.rmse(...
                simulated_flow, observed_flow), 0.3);
        end
        
        function testSedimentTransportValidation(testCase)
            % 测试泥沙输移模拟结果验证
            
            % 设置测试数据
            supply_data = testCase.TestData.sediment_transport.elevation;
            demand_data = testCase.TestData.sediment_transport.flow_velocity;
            resistance_data = ones(size(testCase.TestData.sediment_transport.elevation)); % Use uniform resistance
            spatial_data = struct(...
                'elevation', supply_data, ...
                'flow_velocity', demand_data, ...
                'sediment_concentration', testCase.TestData.sediment_transport.sediment_concentration ...
            );
            
            testCase.Analyzer.setSupplyData(supply_data);
            testCase.Analyzer.setDemandData(demand_data);
            testCase.Analyzer.setResistanceData(resistance_data);
            testCase.Analyzer.setSpatialData(spatial_data);
            
            % 1. 测试泥沙浓度
            testCase.Analyzer.setFlowModel('sediment');
            sediment_results = testCase.Analyzer.analyzeServiceFlow();
            simulated_concentration = sediment_results.actual_flow;
            observed_concentration = testCase.TestData.sediment_transport.sediment_concentration;
            
            % 验证浓度精度
            testCase.verifyGreaterThan(testCase.ValidationMetrics.r2(...
                simulated_concentration, observed_concentration), 0.5);
        end
        
        function testCarbonFluxValidation(testCase)
            % 测试碳通量模拟结果验证
            
            % 设置测试数据
            supply_data = testCase.TestData.carbon_flux.biomass;
            demand_data = testCase.TestData.carbon_flux.soil_carbon;
            resistance_data = ones(size(testCase.TestData.carbon_flux.biomass)); % Use uniform resistance
            spatial_data = struct(...
                'biomass', supply_data, ...
                'soil_carbon', demand_data ...
            );
            
            testCase.Analyzer.setSupplyData(supply_data);
            testCase.Analyzer.setDemandData(demand_data);
            testCase.Analyzer.setResistanceData(resistance_data);
            testCase.Analyzer.setSpatialData(spatial_data);
            
            % 1. 测试碳固定
            testCase.Analyzer.setFlowModel('carbon');
            carbon_results = testCase.Analyzer.analyzeServiceFlow();
            simulated_sequestration = carbon_results.actual_flow;
            observed_sequestration = testCase.TestData.carbon_flux.biomass;
            
            % 验证固碳精度
            testCase.verifyGreaterThan(testCase.ValidationMetrics.r2(...
                simulated_sequestration, observed_sequestration), 0.5);
        end
        
        function testSoilErosionValidation(testCase)
            % 测试土壤侵蚀模拟结果验证
            
            % 设置测试数据
            supply_data = testCase.TestData.soil_erosion.slope;
            demand_data = testCase.TestData.soil_erosion.rainfall;
            resistance_data = ones(size(testCase.TestData.soil_erosion.slope)); % Use uniform resistance
            spatial_data = struct(...
                'slope', supply_data, ...
                'rainfall', demand_data ...
            );
            
            testCase.Analyzer.setSupplyData(supply_data);
            testCase.Analyzer.setDemandData(demand_data);
            testCase.Analyzer.setResistanceData(resistance_data);
            testCase.Analyzer.setSpatialData(spatial_data);
            
            % 1. 测试侵蚀量
            testCase.Analyzer.setFlowModel('surface-water');
            soil_results = testCase.Analyzer.analyzeServiceFlow();
            simulated_erosion = soil_results.actual_flow;
            observed_erosion = testCase.TestData.soil_erosion.slope;
            
            % 验证侵蚀量精度
            testCase.verifyGreaterThan(testCase.ValidationMetrics.r2(...
                simulated_erosion, observed_erosion), 0.5);
        end
        
        function testServiceFlowValidation(testCase)
            % 测试服务流模拟结果验证
            
            % 设置测试数据
            supply_data = testCase.TestData.service_flow.supply;
            demand_data = testCase.TestData.service_flow.demand;
            resistance_data = ones(size(testCase.TestData.service_flow.supply)); % Use uniform resistance
            spatial_data = struct(...
                'supply', supply_data, ...
                'demand', demand_data ...
            );
            
            testCase.Analyzer.setSupplyData(supply_data);
            testCase.Analyzer.setDemandData(demand_data);
            testCase.Analyzer.setResistanceData(resistance_data);
            testCase.Analyzer.setSpatialData(spatial_data);
            
            % 1. 测试服务流
            testCase.Analyzer.setFlowModel('proximity');
            service_results = testCase.Analyzer.analyzeServiceFlow();
            simulated_flow = service_results.actual_flow;
            observed_flow = testCase.TestData.service_flow.demand;
            
            % 验证服务流精度
            testCase.verifyGreaterThan(testCase.ValidationMetrics.r2(...
                simulated_flow, observed_flow), 0.6);
        end
        
        function testUncertaintyValidation(testCase)
            % 测试不确定性分析验证
            
            % 1. 测试参数不确定性
            param_ranges = testCase.TestData.uncertainty.parameter_ranges;
            
            % 使用参数范围作为输入数据
            supply_data = param_ranges.min;
            demand_data = param_ranges.max;
            resistance_data = ones(size(param_ranges.min)); % Use uniform resistance
            spatial_data = struct(...
                'parameter_ranges', param_ranges ...
            );
            
            testCase.Analyzer.setSupplyData(supply_data);
            testCase.Analyzer.setDemandData(demand_data);
            testCase.Analyzer.setResistanceData(resistance_data);
            testCase.Analyzer.setSpatialData(spatial_data);
            
            uncertainty_results = testCase.Analyzer.calculateDataUncertainty(testCase.TestData);
            testCase.verifyTrue(isfield(uncertainty_results, 'coefficient_of_variation'));
            testCase.verifyTrue(isfield(uncertainty_results, 'spatial_autocorrelation'));
        end
    end
    
    methods (Access = private)
        function data = loadTestData(testCase)
            % 加载测试数据
            load(fullfile('/Users/xingqiangchen/TASK/ecosystem-service-flow/tests', 'data/validation/test_data.mat'), 'test_data');
            data = test_data;
        end
        
        function data = loadFieldData(testCase)
            % 加载实测数据
            load(fullfile('/Users/xingqiangchen/TASK/ecosystem-service-flow/tests', 'data/validation/field_data.mat'), 'field_data');
            data = field_data;
        end
    end
end 