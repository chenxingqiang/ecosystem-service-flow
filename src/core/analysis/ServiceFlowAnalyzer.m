classdef ServiceFlowAnalyzer < handle
    properties (Access = protected)
        Data = struct('supply',[],'demand',[],'resistance',[],'flow',[],'spatial',[]);
        Parameters = struct('alpha',0.5,'beta',0.5,'gamma',1.0,'max_distance',100);
    end
    
    methods
        function obj = ServiceFlowAnalyzer()
        end
        
        function data = getData(obj, data_type)
            if ~isfield(obj.Data, data_type)
                error('不支持的数据类型: %s', data_type);
            end
            data = obj.Data.(data_type);
            if isempty(data)
                data = [];
            end
        end
        
        function setData(obj, data_type, data)
            if ~isfield(obj.Data, data_type)
                error('不支持的数据类型: %s', data_type);
            end
            if ~isnumeric(data)
                error('数据必须是数值类型');
            end
            if ~isempty(obj.Data.supply) && ~isequal(size(data), size(obj.Data.supply))
                error('数据维度不一致');
            end
            obj.Data.(data_type) = data;
        end
        
        function params = getParameters(obj)
            params = obj.Parameters;
        end
        
        function setParameters(obj, paramName, value)
            if ~isfield(obj.Parameters, paramName)
                error('无效的参数名称: %s', paramName);
            end
            obj.Parameters.(paramName) = value;
        end
        
        function supply = calculateSupply(obj)
            % 计算供给能力
            % 返回:
            %   supply - 供给能力矩阵
            
            if isempty(obj.Data.supply)
                error('供给数据未设置');
            end
            
            % 基础供给能力
            supply = obj.Data.supply;
            
            % 考虑空间衰减
            if ~isempty(obj.Data.spatial)
                [rows, cols] = size(supply);
                [X, Y] = meshgrid(1:cols, 1:rows);
                
                for i = 1:rows
                    for j = 1:cols
                        if supply(i,j) > 0
                            % 计算空间距离衰减
                            dist = sqrt((X-j).^2 + (Y-i).^2);
                            decay = exp(-obj.Parameters.alpha * dist);
                            supply = supply .* decay;
                        end
                    end
                end
            end
        end
        
        function demand = calculateDemand(obj)
            % 计算需求强度
            % 返回:
            %   demand - 需求强度矩阵
            
            if isempty(obj.Data.demand)
                error('需求数据未设置');
            end
            
            % 基础需求强度
            demand = obj.Data.demand;
            
            % 考虑空间衰减
            if ~isempty(obj.Data.spatial)
                [rows, cols] = size(demand);
                [X, Y] = meshgrid(1:cols, 1:rows);
                
                for i = 1:rows
                    for j = 1:cols
                        if demand(i,j) > 0
                            % 计算空间距离衰减
                            dist = sqrt((X-j).^2 + (Y-i).^2);
                            decay = exp(-obj.Parameters.beta * dist);
                            demand = demand .* decay;
                        end
                    end
                end
            end
        end
        
        function resistance = calculateResistance(obj)
            % 计算流动阻力
            % 返回:
            %   resistance - 阻力矩阵
            
            if isempty(obj.Data.resistance)
                error('阻力数据未设置');
            end
            
            % 基础阻力
            resistance = obj.Data.resistance;
            
            % 考虑阻力影响系数
            resistance = resistance * obj.Parameters.gamma;
            
            % 确保阻力非负
            resistance(resistance < 0) = 0;
        end
        
        function flow = calculateFlow(obj)
            % 计算服务流动
            % 返回:
            %   flow - 服务流动矩阵
            
            % 计算供给、需求和阻力
            supply = obj.calculateSupply();
            demand = obj.calculateDemand();
            resistance = obj.calculateResistance();
            
            % 初始化流动矩阵
            [rows, cols] = size(supply);
            flow = zeros(rows, cols);
            
            % 计算每个点的服务流动
            for i = 1:rows
                for j = 1:cols
                    if supply(i,j) > 0
                        % 供给点
                        for m = 1:rows
                            for n = 1:cols
                                if demand(m,n) > 0
                                    % 需求点
                                    % 计算距离
                                    dist = sqrt((m-i)^2 + (n-j)^2);
                                    
                                    if dist <= obj.Parameters.max_distance
                                        % 计算路径上的平均阻力
                                        path_resistance = obj.calculatePathResistance(i, j, m, n, resistance);
                                        
                                        % 计算流动强度
                                        flow_intensity = supply(i,j) * demand(m,n) * ...
                                            exp(-path_resistance * dist);
                                        
                                        % 累加到流动矩阵
                                        flow(i,j) = flow(i,j) + flow_intensity;
                                    end
                                end
                            end
                        end
                    end
                end
            end
            
            % 保存结果
            obj.Data.flow = flow;
        end
        
        function resistance = calculatePathResistance(obj, i1, j1, i2, j2, resistance_matrix)
            % 计算两点之间路径的平均阻力
            % 输入:
            %   i1, j1 - 起点坐标
            %   i2, j2 - 终点坐标
            %   resistance_matrix - 阻力矩阵
            % 返回:
            %   resistance - 平均阻力值
            
            % 使用Bresenham算法找到两点之间的路径
            [x, y] = obj.bresenham(i1, j1, i2, j2);
            
            % 计算路径上的平均阻力
            path_resistance = 0;
            for k = 1:length(x)
                path_resistance = path_resistance + resistance_matrix(x(k), y(k));
            end
            resistance = path_resistance / length(x);
        end
        
        function [x, y] = bresenham(~, x1, y1, x2, y2)
            % Bresenham直线算法
            % 输入:
            %   x1, y1 - 起点坐标
            %   x2, y2 - 终点坐标
            % 返回:
            %   x, y - 路径上的点坐标
            
            dx = abs(x2 - x1);
            dy = abs(y2 - y1);
            steep = dy > dx;
            
            if steep
                [x1, y1] = deal(y1, x1);
                [x2, y2] = deal(y2, x2);
            end
            
            if x1 > x2
                [x1, x2] = deal(x2, x1);
                [y1, y2] = deal(y2, y1);
            end
            
            dx = x2 - x1;
            dy = abs(y2 - y1);
            error = dx / 2;
            
            if y1 < y2
                ystep = 1;
            else
                ystep = -1;
            end
            
            x = x1;
            y = y1;
            points_x = x;
            points_y = y;
            
            for x = (x1+1):x2
                error = error - dy;
                if error < 0
                    y = y + ystep;
                    error = error + dx;
                end
                points_x(end+1) = x;
                points_y(end+1) = y;
            end
            
            if steep
                [x, y] = deal(points_y, points_x);
            else
                x = points_x;
                y = points_y;
            end
        end
        
        function [paths, intensities] = calculateFlowPaths(obj)
            % 计算并返回所有服务流动路径
            % 返回:
            %   paths - 包含所有路径的元胞数组，每个元素是一个n*2的矩阵，表示路径上的点坐标
            %   intensities - 对应每条路径的流动强度
            
            supply = obj.calculateSupply();
            demand = obj.calculateDemand();
            resistance = obj.calculateResistance();
            
            paths = {};
            intensities = [];
            
            [rows, cols] = size(supply);
            for i = 1:rows
                for j = 1:cols
                    if supply(i,j) > 0
                        for m = 1:rows
                            for n = 1:cols
                                if demand(m,n) > 0
                                    dist = sqrt((m-i)^2 + (n-j)^2);
                                    if dist <= obj.Parameters.max_distance
                                        % 获取路径点
                                        [x, y] = obj.bresenham(i, j, m, n);
                                        path = [x', y'];
                                        
                                        % 计算路径阻力
                                        path_resistance = obj.calculatePathResistance(i, j, m, n, resistance);
                                        
                                        % 计算流动强度
                                        intensity = supply(i,j) * demand(m,n) * exp(-path_resistance * dist);
                                        
                                        % 保存路径和强度
                                        paths{end+1} = path;
                                        intensities(end+1) = intensity;
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        
        function stats = calculateFlowStatistics(obj)
            % 计算服务流动的统计指标
            % 返回:
            %   stats - 包含各种统计指标的结构体
            
            flow = obj.calculateFlow();
            [paths, intensities] = obj.calculateFlowPaths();
            
            stats = struct();
            
            % 基本统计量
            stats.total_flow = sum(flow(:));
            stats.mean_flow = mean(flow(:));
            stats.max_flow = max(flow(:));
            stats.flow_std = std(flow(:));
            
            % 路径统计
            path_lengths = cellfun(@(x) size(x,1), paths);
            stats.mean_path_length = mean(path_lengths);
            stats.max_path_length = max(path_lengths);
            stats.total_paths = length(paths);
            
            % 流动强度统计
            stats.mean_intensity = mean(intensities);
            stats.max_intensity = max(intensities);
            stats.total_intensity = sum(intensities);
        end
        
        function efficiency = calculateFlowEfficiency(obj)
            % 计算服务流动效率
            % 返回:
            %   efficiency - 流动效率指标
            
            supply = obj.calculateSupply();
            demand = obj.calculateDemand();
            flow = obj.calculateFlow();
            
            % 计算理论最大流动量（无阻力情况下）
            total_supply = sum(supply(:));
            total_demand = sum(demand(:));
            theoretical_max = min(total_supply, total_demand);
            
            % 计算实际流动量
            actual_flow = sum(flow(:));
            
            % 计算效率
            efficiency = actual_flow / theoretical_max;
        end
        
        function [bottlenecks, scores] = identifyBottlenecks(obj)
            % 识别服务流动的瓶颈位置
            % 返回:
            %   bottlenecks - 瓶颈位置的坐标矩阵 n*2
            %   scores - 对应的瓶颈得分
            
            resistance = obj.calculateResistance();
            [paths, intensities] = obj.calculateFlowPaths();
            
            % 初始化瓶颈得分矩阵
            [rows, cols] = size(resistance);
            bottleneck_scores = zeros(rows, cols);
            
            % 计算每个点的瓶颈得分
            for i = 1:length(paths)
                path = paths{i};
                intensity = intensities(i);
                
                % 对路径上的每个点累加瓶颈得分
                for j = 1:size(path,1)
                    x = path(j,1);
                    y = path(j,2);
                    bottleneck_scores(x,y) = bottleneck_scores(x,y) + ...
                        intensity * resistance(x,y);
                end
            end
            
            % 找出得分最高的点
            [sorted_scores, indices] = sort(bottleneck_scores(:), 'descend');
            [x, y] = ind2sub([rows, cols], indices);
            
            % 返回前N个瓶颈点（这里取前5个）
            N = min(5, length(indices));
            bottlenecks = [x(1:N), y(1:N)];
            scores = sorted_scores(1:N);
        end
    end
end
