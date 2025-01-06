classdef ServiceFlowAnalyzerAdvancedTest < matlab.unittest.TestCase
    properties
        Analyzer
    end
    
    methods(TestMethodSetup)
        function createAnalyzer(testCase)
            testCase.Analyzer = ServiceFlowAnalyzer();
            
            % 设置基本测试数据
            supply = [2 0 0; 0 0 0; 0 0 1];
            demand = [0 0 1; 0 0 0; 1 0 0];
            resistance = [1 2 1; 2 3 2; 1 2 1];
            
            testCase.Analyzer.setData('supply', supply);
            testCase.Analyzer.setData('demand', demand);
            testCase.Analyzer.setData('resistance', resistance);
            testCase.Analyzer.setParameters('max_distance', 5);
            testCase.Analyzer.setParameters('alpha', 0.5);
            testCase.Analyzer.setParameters('beta', 0.5);
            testCase.Analyzer.setParameters('gamma', 1.0);
        end
    end
    
    methods(Test)
        function testCalculateFlowPaths(testCase)
            % 测试流动路径计算
            [paths, intensities] = testCase.Analyzer.calculateFlowPaths();
            
            % 验证基本属性
            testCase.verifyTrue(~isempty(paths), '应该存在流动路径');
            testCase.verifyEqual(length(paths), length(intensities), '路径和强度数量应该相等');
            
            % 验证路径的有效性
            for i = 1:length(paths)
                path = paths{i};
                testCase.verifyTrue(size(path,2) == 2, '路径应该是n*2的矩阵');
                testCase.verifyTrue(all(path(:) >= 1), '路径坐标应该为正');
                testCase.verifyTrue(all(path(:,1) <= 3) && all(path(:,2) <= 3), '路径坐标不应超出范围');
            end
            
            % 验证强度的有效性
            testCase.verifyTrue(all(intensities >= 0), '流动强度应该非负');
        end
        
        function testCalculateFlowStatistics(testCase)
            % 测试流动统计计算
            stats = testCase.Analyzer.calculateFlowStatistics();
            
            % 验证统计指标的存在性
            testCase.verifyTrue(isfield(stats, 'total_flow'), '应包含总流量');
            testCase.verifyTrue(isfield(stats, 'mean_flow'), '应包含平均流量');
            testCase.verifyTrue(isfield(stats, 'max_flow'), '应包含最大流量');
            testCase.verifyTrue(isfield(stats, 'flow_std'), '应包含流量标准差');
            testCase.verifyTrue(isfield(stats, 'total_paths'), '应包含总路径数');
            
            % 验证统计值的有效性
            testCase.verifyTrue(stats.total_flow >= 0, '总流量应该非负');
            testCase.verifyTrue(stats.mean_flow >= 0, '平均流量应该非负');
            testCase.verifyTrue(stats.max_flow >= stats.mean_flow, '最大流量应该不小于平均流量');
            testCase.verifyTrue(stats.flow_std >= 0, '标准差应该非负');
            testCase.verifyTrue(stats.total_paths > 0, '应该存在流动路径');
        end
        
        function testCalculateFlowEfficiency(testCase)
            % 测试流动效率计算
            efficiency = testCase.Analyzer.calculateFlowEfficiency();
            
            % 验证效率值的范围
            testCase.verifyTrue(efficiency >= 0 && efficiency <= 1, '效率应该在0到1之间');
            
            % 测试无阻力情况
            testCase.Analyzer.setData('resistance', zeros(3,3));
            efficiency_no_resistance = testCase.Analyzer.calculateFlowEfficiency();
            testCase.verifyTrue(efficiency_no_resistance > efficiency, '无阻力时效率应该更高');
            
            % 测试高阻力情况
            testCase.Analyzer.setData('resistance', ones(3,3) * 10);
            efficiency_high_resistance = testCase.Analyzer.calculateFlowEfficiency();
            testCase.verifyTrue(efficiency_high_resistance < efficiency, '高阻力时效率应该更低');
        end
        
        function testIdentifyBottlenecks(testCase)
            % 测试瓶颈识别
            [bottlenecks, scores] = testCase.Analyzer.identifyBottlenecks();
            
            % 验证瓶颈点的数量和维度
            testCase.verifyTrue(size(bottlenecks,2) == 2, '瓶颈点应该是n*2的矩阵');
            testCase.verifyEqual(size(bottlenecks,1), length(scores), '瓶颈点和得分数量应该相等');
            
            % 验证瓶颈点的有效性
            testCase.verifyTrue(all(bottlenecks(:) >= 1), '瓶颈点坐标应该为正');
            testCase.verifyTrue(all(bottlenecks(:,1) <= 3) && all(bottlenecks(:,2) <= 3), ...
                '瓶颈点坐标不应超出范围');
            
            % 验证得分的有效性
            testCase.verifyTrue(all(scores >= 0), '瓶颈得分应该非负');
            testCase.verifyTrue(issorted(scores, 'descend'), '得分应该是降序排列的');
            
            % 验证瓶颈识别的合理性
            % 在供给点和需求点之间的高阻力点更可能是瓶颈
            supply = testCase.Analyzer.getData('supply');
            demand = testCase.Analyzer.getData('demand');
            [supply_i, supply_j] = find(supply > 0);
            [demand_i, demand_j] = find(demand > 0);
            
            % 检查每个瓶颈点是否在某条可能的流动路径上
            for k = 1:size(bottlenecks,1)
                bottleneck = bottlenecks(k,:);
                is_on_path = false;
                
                for s = 1:length(supply_i)
                    for d = 1:length(demand_i)
                        % 获取供给点到需求点的路径
                        [path_x, path_y] = testCase.Analyzer.bresenham(...
                            supply_i(s), supply_j(s), ...
                            demand_i(d), demand_j(d));
                        
                        % 检查瓶颈点是否在路径上
                        if any(path_x == bottleneck(1) & path_y == bottleneck(2))
                            is_on_path = true;
                            break;
                        end
                    end
                    if is_on_path
                        break;
                    end
                end
                
                testCase.verifyTrue(is_on_path, sprintf('瓶颈点(%d,%d)应该位于某条可能的流动路径上', ...
                    bottleneck(1), bottleneck(2)));
            end
        end
    end
end
