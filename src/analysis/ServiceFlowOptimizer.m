classdef ServiceFlowOptimizer
    % ServiceFlowOptimizer 生态系统服务流优化分析类
    
    properties
        supply_index
        demand_index
        resistance
        flow_paths
        landcover
    end
    
    methods
        function obj = ServiceFlowOptimizer(supply, demand, resistance, flow_paths, landcover)
            % 构造函数
            obj.supply_index = supply;
            obj.demand_index = demand;
            obj.resistance = resistance;
            obj.flow_paths = flow_paths;
            obj.landcover = landcover;
        end
        
        function [match, deficit, excess] = analyzeSupplyDemandBalance(obj)
            % 分析供需平衡状况
            
            % 标准化供给和需求
            supply_norm = obj.supply_index / max(obj.supply_index(:));
            demand_norm = obj.demand_index / max(obj.demand_index(:));
            
            % 计算供需匹配度
            match = 1 - abs(supply_norm - demand_norm);
            
            % 识别供给不足区域
            deficit = max(0, demand_norm - supply_norm);
            
            % 识别需求过度区域
            excess = max(0, demand_norm - 2*supply_norm);
        end
        
        function bottleneck = identifyFlowBottlenecks(obj)
            % 识别服务流动瓶颈
            flow_intensity = obj.flow_paths .* obj.resistance;
            bottleneck = flow_intensity > mean(flow_intensity(:)) + std(flow_intensity(:));
        end
        
        function optimization_plan = generateOptimizationPlan(obj)
            % 生成优化方案
            optimization_plan = struct();
            
            % 分析供需平衡
            [match, deficit, excess] = obj.analyzeSupplyDemandBalance();
            bottleneck = obj.identifyFlowBottlenecks();
            
            % 供给优化
            optimization_plan.supply = obj.generateSupplyOptimization(deficit);
            
            % 需求优化
            optimization_plan.demand = obj.generateDemandOptimization(excess);
            
            % 流动优化
            optimization_plan.flow = obj.generateFlowOptimization(bottleneck);
            
            % 添加评估指标
            optimization_plan.metrics = struct();
            optimization_plan.metrics.supply_demand_match = mean(match(:));
            optimization_plan.metrics.supply_deficit_ratio = sum(deficit(:) > 0) / numel(deficit);
            optimization_plan.metrics.demand_excess_ratio = sum(excess(:) > 0) / numel(excess);
            optimization_plan.metrics.bottleneck_ratio = sum(bottleneck(:)) / numel(bottleneck);
        end
        
        function supply_plan = generateSupplyOptimization(obj, deficit)
            % 生成供给优化方案
            supply_plan = struct();
            
            % 优化优先级
            [rows, cols] = size(deficit);
            supply_plan.priority = zeros(rows, cols);
            
            for i = 1:rows
                for j = 1:cols
                    if deficit(i,j) > 0
                        switch obj.landcover(i,j)
                            case 1  % 森林
                                supply_plan.priority(i,j) = 3;  % 高优先级
                            case 2  % 草地
                                supply_plan.priority(i,j) = 2;  % 中优先级
                            case 3  % 农田
                                supply_plan.priority(i,j) = 1;  % 低优先级
                        end
                    end
                end
            end
            
            % 优化建议
            supply_plan.recommendations = {
                '加强生态系统保护和修复',
                '优化土地利用结构',
                '提高生态系统服务供给能力'
            };
        end
        
        function demand_plan = generateDemandOptimization(obj, excess)
            % 生成需求优化方案
            demand_plan = struct();
            
            % 优化优先级
            demand_plan.priority = zeros(size(excess));
            demand_plan.priority(excess > 0.66) = 3;  % 高优先级
            demand_plan.priority(excess > 0.33 & excess <= 0.66) = 2;  % 中优先级
            demand_plan.priority(excess > 0 & excess <= 0.33) = 1;  % 低优先级
            
            % 优化建议
            demand_plan.recommendations = {
                '合理控制开发强度',
                '优化人类活动空间布局',
                '提高资源利用效率'
            };
        end
        
        function flow_plan = generateFlowOptimization(obj, bottleneck)
            % 生成流动优化方案
            flow_plan = struct();
            
            % 识别潜在生态廊道
            [rows, cols] = size(bottleneck);
            flow_plan.corridor = zeros(rows, cols);
            
            for i = 1:rows
                for j = 1:cols
                    if bottleneck(i,j)
                        % 检查周边8个像素
                        window = obj.landcover(max(1,i-1):min(rows,i+1), ...
                            max(1,j-1):min(cols,j+1));
                        if any(window(:) == 1) || any(window(:) == 2)  % 周边有森林或草地
                            flow_plan.corridor(i,j) = 1;
                        end
                    end
                end
            end
            
            % 优化建议
            flow_plan.recommendations = {
                '构建生态廊道',
                '降低景观阻力',
                '加强关键节点保护'
            };
        end
        
        function visualizeOptimization(obj, optimization_plan)
            % 可视化优化方案
            
            % 创建图形窗口
            figure('Name', 'Service Flow Optimization');
            
            % 供给优化优先级
            subplot(2,2,1);
            imagesc(optimization_plan.supply.priority);
            colormap(gca, jet);
            colorbar;
            title('供给优化优先级');
            
            % 需求优化优先级
            subplot(2,2,2);
            imagesc(optimization_plan.demand.priority);
            colormap(gca, jet);
            colorbar;
            title('需求优化优先级');
            
            % 潜在生态廊道
            subplot(2,2,3);
            imagesc(optimization_plan.flow.corridor);
            colormap(gca, jet);
            colorbar;
            title('潜在生态廊道');
            
            % 优化指标
            subplot(2,2,4);
            metrics = [optimization_plan.metrics.supply_demand_match, ...
                      optimization_plan.metrics.supply_deficit_ratio, ...
                      optimization_plan.metrics.demand_excess_ratio, ...
                      optimization_plan.metrics.bottleneck_ratio];
            bar(metrics);
            title('优化评估指标');
            xlabel('指标类型');
            ylabel('值');
            set(gca, 'XTickLabel', {'匹配度', '不足率', '过度率', '瓶颈率'});
        end
    end
end 