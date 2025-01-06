classdef ServiceFlowAnalyzerFlowTest < matlab.unittest.TestCase
    properties
        Analyzer
    end
    
    methods(TestMethodSetup)
        function createAnalyzer(testCase)
            testCase.Analyzer = ServiceFlowAnalyzer();
        end
    end
    
    methods(Test)
        function testCalculateSupply(testCase)
            % 测试供给计算
            supply = [1 0; 0 2];
            testCase.Analyzer.setData('supply', supply);
            
            % 无空间数据时的计算
            result = testCase.Analyzer.calculateSupply();
            testCase.verifyEqual(result, supply, '基础供给计算错误');
            
            % 添加空间数据后的计算
            spatial = ones(2,2);
            testCase.Analyzer.setData('spatial', spatial);
            testCase.Analyzer.setParameters('alpha', 0.5);
            
            result = testCase.Analyzer.calculateSupply();
            testCase.verifyTrue(all(result(:) >= 0), '供给值不应为负');
            testCase.verifyTrue(all(result(:) <= supply(:)), '供给值不应超过原始值');
        end
        
        function testCalculateDemand(testCase)
            % 测试需求计算
            demand = [2 0; 0 1];
            testCase.Analyzer.setData('demand', demand);
            
            % 无空间数据时的计算
            result = testCase.Analyzer.calculateDemand();
            testCase.verifyEqual(result, demand, '基础需求计算错误');
            
            % 添加空间数据后的计算
            spatial = ones(2,2);
            testCase.Analyzer.setData('spatial', spatial);
            testCase.Analyzer.setParameters('beta', 0.5);
            
            result = testCase.Analyzer.calculateDemand();
            testCase.verifyTrue(all(result(:) >= 0), '需求值不应为负');
            testCase.verifyTrue(all(result(:) <= demand(:)), '需求值不应超过原始值');
        end
        
        function testCalculateResistance(testCase)
            % 测试阻力计算
            resistance = [1 2; 3 4];
            testCase.Analyzer.setData('resistance', resistance);
            testCase.Analyzer.setParameters('gamma', 2);
            
            result = testCase.Analyzer.calculateResistance();
            testCase.verifyEqual(result, resistance * 2, '阻力计算错误');
            
            % 测试负值处理
            resistance = [-1 2; 3 -4];
            testCase.Analyzer.setData('resistance', resistance);
            
            result = testCase.Analyzer.calculateResistance();
            testCase.verifyTrue(all(result(:) >= 0), '阻力值不应为负');
        end
        
        function testCalculateFlow(testCase)
            % 测试服务流动计算
            % 设置测试数据
            supply = [1 0; 0 0];
            demand = [0 0; 0 1];
            resistance = ones(2,2);
            
            testCase.Analyzer.setData('supply', supply);
            testCase.Analyzer.setData('demand', demand);
            testCase.Analyzer.setData('resistance', resistance);
            testCase.Analyzer.setParameters('max_distance', 2);
            
            % 计算流动
            flow = testCase.Analyzer.calculateFlow();
            
            % 验证结果
            testCase.verifyTrue(all(flow(:) >= 0), '流动值不应为负');
            testCase.verifyTrue(flow(1,1) > 0, '供给点应有流动值');
            testCase.verifyEqual(flow(2,1), 0, '非供给点不应有流动值');
        end
        
        function testBresenham(testCase)
            % 测试Bresenham算法
            [x, y] = testCase.Analyzer.bresenham(1, 1, 3, 3);
            
            % 验证路径的连续性
            for i = 2:length(x)
                dist = sqrt((x(i)-x(i-1))^2 + (y(i)-y(i-1))^2);
                testCase.verifyTrue(dist <= sqrt(2), '路径点之间的距离不应超过sqrt(2)');
            end
            
            % 验证起点和终点
            testCase.verifyEqual([x(1), y(1)], [1, 1], '起点错误');
            testCase.verifyEqual([x(end), y(end)], [3, 3], '终点错误');
        end
    end
end
