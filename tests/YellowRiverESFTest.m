classdef YellowRiverESFTest < matlab.unittest.TestCase
    % YellowRiverESFTest 黄河流域生态系统服务流测试类
    
    properties
        Analyzer
        TestData
        BasinBoundary
    end
    
    methods (TestMethodSetup)
        function setupTest(testCase)
            % 每个测试方法前的设置
            testCase.Analyzer = ServiceFlowAnalyzer();
            testCase.TestData = testCase.loadYellowRiverData();
            testCase.BasinBoundary = testCase.loadBasinBoundary();
            
            % 初始化分析器
            testCase.Analyzer.setSupplyData(testCase.TestData.supply);
            testCase.Analyzer.setDemandData(testCase.TestData.demand);
            testCase.Analyzer.setResistanceData(testCase.TestData.resistance);
            testCase.Analyzer.setSpatialData(testCase.TestData.spatial);
        end
    end
    
    methods (Test)
        function testDataPreparation(testCase)
            % 测试数据准备和预处理
            
            % 1. 验证数据完整性
            testCase.verifyTrue(isfield(testCase.TestData, 'dem'));
            testCase.verifyTrue(isfield(testCase.TestData, 'landcover'));
            testCase.verifyTrue(isfield(testCase.TestData, 'ndvi'));
            testCase.verifyTrue(isfield(testCase.TestData, 'precipitation'));
            
            % 2. 验证空间参考一致性
            spatial_ref = testCase.Analyzer.validateSpatialReference();
            testCase.verifyTrue(spatial_ref.isValid);
            testCase.verifyEqual(spatial_ref.projection, 'Albers_Equal_Area');
            
            % 3. 验证数据范围
            testCase.verifyTrue(all(inpolygon(testCase.TestData.spatial.X(:), ...
                testCase.TestData.spatial.Y(:), ...
                testCase.BasinBoundary.X, testCase.BasinBoundary.Y)));
        end
        
        function testWaterRegulationService(testCase)
            % 测试水源涵养服务
            
            % 1. 测试供给计算
            supply = testCase.Analyzer.calculateWaterSupply();
            testCase.verifyTrue(all(supply(:) >= 0));
            testCase.verifyTrue(corr(supply(:), testCase.TestData.ndvi(:)) > 0.3);
            
            % 2. 测试需求计算
            demand = testCase.Analyzer.calculateWaterDemand();
            testCase.verifyTrue(all(demand(:) >= 0));
            testCase.verifyTrue(corr(demand(:), testCase.TestData.population(:)) > 0);
            
            % 3. 测试流动路径
            flow_paths = testCase.Analyzer.analyzeWaterFlowPaths();
            testCase.verifyTrue(isfield(flow_paths, 'direction'));
            testCase.verifyTrue(isfield(flow_paths, 'accumulation'));
        end
        
        function testSoilConservationService(testCase)
            % 测试水土保持服务
            
            % 1. 测试侵蚀潜力
            erosion = testCase.Analyzer.calculateErosionPotential();
            testCase.verifyTrue(all(erosion(:) >= 0));
            testCase.verifyTrue(corr(erosion(:), testCase.TestData.slope(:)) > 0);
            
            % 2. 测试保持能力
            retention = testCase.Analyzer.calculateSoilRetention();
            testCase.verifyTrue(all(retention(:) >= 0));
            testCase.verifyTrue(corr(retention(:), testCase.TestData.vegetation(:)) > 0);
            
            % 3. 测试受益区识别
            benefit_areas = testCase.Analyzer.identifySoilBenefitAreas();
            testCase.verifyTrue(isfield(benefit_areas, 'direct'));
            testCase.verifyTrue(isfield(benefit_areas, 'indirect'));
        end
        
        function testCarbonSequestrationService(testCase)
            % 测试碳固定服务
            
            % 1. 测试固碳能力
            sequestration = testCase.Analyzer.calculateCarbonSequestration();
            testCase.verifyTrue(all(sequestration(:) >= 0));
            testCase.verifyTrue(corr(sequestration(:), testCase.TestData.ndvi(:)) > 0.4);
            
            % 2. 测试碳储量
            storage = testCase.Analyzer.calculateCarbonStorage();
            testCase.verifyTrue(all(storage(:) >= 0));
            testCase.verifyTrue(corr(storage(:), testCase.TestData.biomass(:)) > 0.5);
            
            % 3. 测试气候调节效益
            benefits = testCase.Analyzer.analyzeCarbonBenefits();
            testCase.verifyTrue(isfield(benefits, 'local'));
            testCase.verifyTrue(isfield(benefits, 'global'));
        end
        
        function testSandFixationService(testCase)
            % 测试固沙防风服务
            
            % 1. 测试风蚀潜力
            wind_erosion = testCase.Analyzer.calculateWindErosion();
            testCase.verifyTrue(all(wind_erosion(:) >= 0));
            testCase.verifyTrue(corr(wind_erosion(:), testCase.TestData.wind_speed(:)) > 0);
            
            % 2. 测试固沙能力
            fixation = testCase.Analyzer.calculateSandFixation();
            testCase.verifyTrue(all(fixation(:) >= 0));
            testCase.verifyTrue(corr(fixation(:), testCase.TestData.vegetation(:)) > 0);
            
            % 3. 测试防护效益
            protection = testCase.Analyzer.analyzeSandProtection();
            testCase.verifyTrue(isfield(protection, 'intensity'));
            testCase.verifyTrue(isfield(protection, 'beneficiaries'));
        end
        
        function testServiceInteractions(testCase)
            % 测试服务间相互作用
            
            % 1. 测试协同效应
            synergies = testCase.Analyzer.analyzeServiceSynergies();
            testCase.verifyTrue(isfield(synergies, 'matrix'));
            testCase.verifyTrue(isfield(synergies, 'hotspots'));
            
            % 2. 测试权衡关系
            tradeoffs = testCase.Analyzer.analyzeServiceTradeoffs();
            testCase.verifyTrue(isfield(tradeoffs, 'matrix'));
            testCase.verifyTrue(isfield(tradeoffs, 'conflict_zones'));
            
            % 3. 测试综合评价
            evaluation = testCase.Analyzer.evaluateServiceBundle();
            testCase.verifyTrue(isfield(evaluation, 'scores'));
            testCase.verifyTrue(isfield(evaluation, 'priorities'));
        end
        
        function testTemporalDynamics(testCase)
            % 测试时间动态特征
            
            % 1. 测试季节变化
            seasonal = testCase.Analyzer.analyzeSeasonalDynamics();
            testCase.verifyTrue(isfield(seasonal, 'patterns'));
            testCase.verifyTrue(isfield(seasonal, 'variations'));
            
            % 2. 测试年际变化
            interannual = testCase.Analyzer.analyzeInterannualTrends();
            testCase.verifyTrue(isfield(interannual, 'trends'));
            testCase.verifyTrue(isfield(interannual, 'significance'));
            
            % 3. 测试长期趋势
            longterm = testCase.Analyzer.analyzeLongTermChanges();
            testCase.verifyTrue(isfield(longterm, 'direction'));
            testCase.verifyTrue(isfield(longterm, 'magnitude'));
        end
    end
    
    methods (Access = private)
        function data = loadYellowRiverData(testCase)
            % 加载黄河流域数据
            
            % 1. 加载DEM数据
            dem = load('data/yellow_river/dem.mat');
            
            % 2. 加载土地利用数据
            landcover = load('data/yellow_river/landcover.mat');
            
            % 3. 加载气候数据
            climate = load('data/yellow_river/climate.mat');
            
            % 4. 加载植被数据
            vegetation = load('data/yellow_river/vegetation.mat');
            
            % 5. 加载社会经济数据
            socioeconomic = load('data/yellow_river/socioeconomic.mat');
            
            % 6. 打包数据
            data = struct(...
                'dem', dem.data, ...
                'landcover', landcover.data, ...
                'ndvi', vegetation.ndvi, ...
                'precipitation', climate.precipitation, ...
                'temperature', climate.temperature, ...
                'population', socioeconomic.population, ...
                'gdp', socioeconomic.gdp, ...
                'slope', dem.slope, ...
                'aspect', dem.aspect, ...
                'wind_speed', climate.wind_speed, ...
                'vegetation', vegetation.cover, ...
                'biomass', vegetation.biomass);
        end
        
        function boundary = loadBasinBoundary(testCase)
            % 加载流域边界数据
            boundary_data = load('data/yellow_river/basin_boundary.mat');
            boundary = struct(...
                'X', boundary_data.X, ...
                'Y', boundary_data.Y);
        end
    end
end 