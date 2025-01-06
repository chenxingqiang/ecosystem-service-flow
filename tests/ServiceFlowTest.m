classdef ServiceFlowTest < matlab.unittest.TestCase
    % ServiceFlowTest 服务流分析模块测试类
    % 测试供给、需求、阻力和服务流计算功能
    
    properties
        Analyzer
        TestSize = [50, 50]  % 使用较小的测试数据以加快测试速度
    end
    
    methods (TestMethodSetup)
        function setupTest(testCase)
            % 设置测试环境
            testCase.Analyzer = ServiceFlowAnalyzer();
            
            % 生成测试数据
            % 1. 供给数据：在几个点上有供给源
            supply = zeros(testCase.TestSize);
            supply(10,10) = 1.0;
            supply(30,30) = 0.8;
            supply(40,10) = 0.6;
            testCase.Analyzer.setData('supply', supply);
            
            % 2. 需求数据：在几个区域有需求
            demand = zeros(testCase.TestSize);
            demand(20,20) = 0.7;
            demand(15,35) = 0.9;
            demand(45,25) = 0.5;
            testCase.Analyzer.setData('demand', demand);
            
            % 3. 阻力数据：使用随机阻力场，但保持一定的空间自相关性
            resistance = zeros(testCase.TestSize);
            [X, Y] = meshgrid(1:testCase.TestSize(2), 1:testCase.TestSize(1));
            for i = 1:3
                center = rand(1,2) .* testCase.TestSize;
                resistance = resistance + exp(-0.01 * ((X-center(1)).^2 + (Y-center(2)).^2));
            end
            resistance = resistance / max(resistance(:));  % 归一化
            testCase.Analyzer.setData('resistance', resistance);
            
            % 4. 空间数据：简单的距离矩阵
            spatial = ones(testCase.TestSize);  % 均质空间
            testCase.Analyzer.setData('spatial', spatial);
        end
    end
    
    methods (Test)
        function testSupplyCalculation(testCase)
            % 测试供给计算
            supply = testCase.Analyzer.calculateSupply();
            
            % 验证基本属性
            testCase.verifySize(supply, testCase.TestSize, '供给矩阵维度错误');
            testCase.verifyGreaterThanOrEqual(supply, 0, '供给值不应为负');
            
            % 验证空间衰减效应
            [~,idx] = max(supply(:));
            [max_i, max_j] = ind2sub(testCase.TestSize, idx);
            for i = 1:testCase.TestSize(1)
                for j = 1:testCase.TestSize(2)
                    if i ~= max_i || j ~= max_j
                        testCase.verifyLessThanOrEqual(supply(i,j), supply(max_i,max_j), ...
                            '供给强度应随距离衰减');
                    end
                end
            end
        end
        
        function testDemandCalculation(testCase)
            % 测试需求计算
            demand = testCase.Analyzer.calculateDemand();
            
            % 验证基本属性
            testCase.verifySize(demand, testCase.TestSize, '需求矩阵维度错误');
            testCase.verifyGreaterThanOrEqual(demand, 0, '需求值不应为负');
            
            % 验证空间衰减效应
            [~,idx] = max(demand(:));
            [max_i, max_j] = ind2sub(testCase.TestSize, idx);
            for i = 1:testCase.TestSize(1)
                for j = 1:testCase.TestSize(2)
                    if i ~= max_i || j ~= max_j
                        testCase.verifyLessThanOrEqual(demand(i,j), demand(max_i,max_j), ...
                            '需求强度应随距离衰减');
                    end
                end
            end
        end
        
        function testResistanceCalculation(testCase)
            % 测试阻力计算
            resistance = testCase.Analyzer.calculateResistance();
            
            % 验证基本属性
            testCase.verifySize(resistance, testCase.TestSize, '阻力矩阵维度错误');
            testCase.verifyGreaterThanOrEqual(resistance, 0, '阻力值不应为负');
            
            % 验证阻力系数影响
            gamma = 2.0;
            testCase.Analyzer.setParameter('gamma', gamma);
            resistance_scaled = testCase.Analyzer.calculateResistance();
            testCase.verifyEqual(resistance_scaled, resistance * gamma, ...
                '阻力系数未正确应用');
        end
        
        function testFlowCalculation(testCase)
            % 测试服务流计算
            [flow, paths] = testCase.Analyzer.calculateFlow();
            
            % 验证基本属性
            testCase.verifySize(flow, testCase.TestSize, '流量矩阵维度错误');
            testCase.verifyGreaterThanOrEqual(flow, 0, '流量不应为负');
            
            % 验证路径存在性
            supply_points = find(testCase.Analyzer.getData('supply') > 0);
            demand_points = find(testCase.Analyzer.getData('demand') > 0);
            
            for i = 1:length(supply_points)
                [si, sj] = ind2sub(testCase.TestSize, supply_points(i));
                testCase.verifyNotEmpty(paths{si,sj}, ...
                    sprintf('供给点(%d,%d)应有流动路径', si, sj));
            end
            
            % 验证最大流动距离约束
            max_distance = testCase.Analyzer.getParameter('max_distance');
            for i = 1:testCase.TestSize(1)
                for j = 1:testCase.TestSize(2)
                    if ~isempty(paths{i,j})
                        for k = 1:length(paths{i,j})
                            path = paths{i,j}{k};
                            path_length = size(path, 1) - 1;  % 路径上的步数
                            testCase.verifyLessThanOrEqual(path_length, max_distance, ...
                                '路径长度超过最大流动距离');
                        end
                    end
                end
            end
        end
        
        function testParameterSetting(testCase)
            % 测试参数设置
            % 设置有效参数
            testCase.Analyzer.setParameter('alpha', 0.8);
            testCase.verifyEqual(testCase.Analyzer.getParameter('alpha'), 0.8, ...
                '参数设置失败');
            
            % 设置无效参数应抛出错误
            testCase.verifyError(@() testCase.Analyzer.setParameter('invalid', 1), ...
                '', '无效参数未被拒绝');
        end
    end
end
