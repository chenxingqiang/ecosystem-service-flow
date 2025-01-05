classdef SpanModelIntegrationTest < matlab.unittest.TestCase
    % SpanModelIntegrationTest SPAN模型集成测试类
    
    properties
        SpanModel
        TestData
    end
    
    methods (TestMethodSetup)
        function setupTest(testCase)
            % 每个测试方法前的设置
            testCase.SpanModel = SpanModelManager();
            testCase.TestData = testCase.generateTestData();
            
            % 初始化模型
            testCase.SpanModel.initialize(testCase.TestData);
        end
    end
    
    methods (Test)
        function testModelIntegration(testCase)
            % 测试模型集成
            
            % 1. 测试模型链接
            models = testCase.SpanModel.getLinkedModels();
            testCase.verifyTrue(~isempty(models));
            testCase.verifyTrue(all(cellfun(@(x) isa(x, 'ServiceFlowModel'), models)));
            
            % 2. 测试数据流
            dataflow = testCase.SpanModel.validateDataFlow();
            testCase.verifyTrue(dataflow.isValid);
            testCase.verifyEmpty(dataflow.errors);
            
            % 3. 测试模型依赖
            dependencies = testCase.SpanModel.checkDependencies();
            testCase.verifyTrue(dependencies.satisfied);
        end
        
        function testCascadingEffects(testCase)
            % 测试级联效应
            
            % 1. 测试上游变化影响
            upstream_changes = struct('location', [5 5], 'magnitude', 0.5);
            cascade_results = testCase.SpanModel.analyzeCascadingEffects(upstream_changes);
            testCase.verifyTrue(isfield(cascade_results, 'affected_services'));
            testCase.verifyTrue(isfield(cascade_results, 'impact_magnitude'));
            
            % 2. 测试阈值效应
            threshold_results = testCase.SpanModel.analyzeThresholdEffects();
            testCase.verifyTrue(isfield(threshold_results, 'thresholds'));
            testCase.verifyTrue(isfield(threshold_results, 'regime_shifts'));
            
            % 3. 测试反馈循环
            feedback_results = testCase.SpanModel.analyzeFeedbackLoops();
            testCase.verifyTrue(isfield(feedback_results, 'loops'));
            testCase.verifyTrue(isfield(feedback_results, 'stability'));
        end
        
        function testSynergiesAndTradeoffs(testCase)
            % 测试协同效应和权衡关系
            
            % 1. 测试服务协同
            synergy_results = testCase.SpanModel.analyzeSynergies();
            testCase.verifyTrue(isfield(synergy_results, 'synergy_matrix'));
            testCase.verifyTrue(isfield(synergy_results, 'synergy_hotspots'));
            
            % 2. 测试服务权衡
            tradeoff_results = testCase.SpanModel.analyzeTradeoffs();
            testCase.verifyTrue(isfield(tradeoff_results, 'tradeoff_matrix'));
            testCase.verifyTrue(isfield(tradeoff_results, 'conflict_areas'));
            
            % 3. 测试多准则评价
            evaluation_results = testCase.SpanModel.evaluateMultiCriteria();
            testCase.verifyTrue(isfield(evaluation_results, 'criteria_scores'));
            testCase.verifyTrue(isfield(evaluation_results, 'overall_score'));
        end
        
        function testScenarioIntegration(testCase)
            % 测试情景集成分析
            
            % 1. 测试多情景组合
            scenarios = struct('climate', struct(), 'landuse', struct(), 'policy', struct());
            integration_results = testCase.SpanModel.integrateScenarios(scenarios);
            testCase.verifyTrue(isfield(integration_results, 'combined_effects'));
            
            % 2. 测试情景权重
            weight_results = testCase.SpanModel.analyzeScenarioWeights();
            testCase.verifyTrue(isfield(weight_results, 'weights'));
            testCase.verifyTrue(isfield(weight_results, 'sensitivity'));
            
            % 3. 测试情景排序
            ranking_results = testCase.SpanModel.rankScenarios();
            testCase.verifyTrue(isfield(ranking_results, 'rankings'));
            testCase.verifyTrue(isfield(ranking_results, 'robustness'));
        end
        
        function testSystemStability(testCase)
            % 测试系统稳定性
            
            % 1. 测试恢复力
            resilience_results = testCase.SpanModel.analyzeResilience();
            testCase.verifyTrue(isfield(resilience_results, 'recovery_time'));
            testCase.verifyTrue(isfield(resilience_results, 'stability_index'));
            
            % 2. 测试脆弱性
            vulnerability_results = testCase.SpanModel.analyzeVulnerability();
            testCase.verifyTrue(isfield(vulnerability_results, 'vulnerable_areas'));
            testCase.verifyTrue(isfield(vulnerability_results, 'risk_levels'));
            
            % 3. 测试适应性
            adaptability_results = testCase.SpanModel.analyzeAdaptability();
            testCase.verifyTrue(isfield(adaptability_results, 'adaptation_capacity'));
            testCase.verifyTrue(isfield(adaptability_results, 'adaptation_options'));
        end
    end
    
    methods (Access = private)
        function test_data = generateTestData(testCase)
            % 生成测试数据
            
            % 1. 生成空间数据
            [X, Y] = meshgrid(1:20, 1:20);
            dem = peaks(20) * 100;
            landcover = randi([1 5], 20, 20);
            
            % 2. 生成气候数据
            temperature = 20 + randn(20, 20) * 2;
            precipitation = 1000 + randn(20, 20) * 100;
            
            % 3. 生成生态系统服务数据
            carbon_storage = exp(-(((X-10).^2 + (Y-10).^2)/50));
            water_yield = precipitation .* (1 - exp(-0.5 * dem/100));
            sediment_retention = 1./(1 + exp(-0.1 * (dem - mean(dem(:)))));
            
            % 4. 生成社会经济数据
            population = zeros(20, 20);
            population(8:12, 8:12) = randi([100 1000], 5, 5);
            gdp = population * 10000 + randn(20, 20) * 1000;
            
            % 5. 打包数据
            test_data = struct(...
                'dem', dem, ...
                'landcover', landcover, ...
                'temperature', temperature, ...
                'precipitation', precipitation, ...
                'carbon_storage', carbon_storage, ...
                'water_yield', water_yield, ...
                'sediment_retention', sediment_retention, ...
                'population', population, ...
                'gdp', gdp);
        end
    end
end 