classdef ProximityAnalysisModel < handle
    % ProximityAnalysisModel 邻近性分析模型
    % 实现基于SPAN模型的空间可达性服务评估
    
    properties
        % 输入数据层
        dem              % 数字高程模型
        landuse         % 土地利用
        road_network    % 道路网络
        barriers        % 障碍物
        
        % 网格参数
        cell_width      % 网格宽度 (m)
        cell_height     % 网格高度 (m)
        
        % 可达性参数
        max_distance    % 最大分析距离 (m)
        decay_function  % 距离衰减函数类型
        decay_param     % 衰减函数参数
        
        % 交通参数
        travel_speeds   % 不同类型道路的行进速度 (m/s)
        impedance_factors % 不同土地利用类型的阻抗因子
    end
    
    methods
        function obj = ProximityAnalysisModel(dem_data, landuse_data, road_data, barriers_data, varargin)
            % 构造函数
            % 输入参数:
            %   dem_data - 数字高程模型数据
            %   landuse_data - 土地利用数据
            %   road_data - 道路网络数据
            %   barriers_data - 障碍物数据
            %   varargin - 可选参数
            
            % 验证输入数据
            validateattributes(dem_data, {'numeric'}, {'2d'});
            validateattributes(landuse_data, {'numeric'}, {'2d', 'size', size(dem_data)});
            validateattributes(road_data, {'numeric'}, {'2d', 'size', size(dem_data)});
            validateattributes(barriers_data, {'numeric'}, {'2d', 'size', size(dem_data)});
            
            % 存储输入数据
            obj.dem = dem_data;
            obj.landuse = landuse_data;
            obj.road_network = road_data;
            obj.barriers = barriers_data;
            
            % 设置默认参数
            obj.cell_width = 30;     % 默认30米分辨率
            obj.cell_height = 30;
            obj.max_distance = 5000;  % 默认5km最大分析距离
            obj.decay_function = 'exponential';  % 默认指数衰减
            obj.decay_param = 0.001;  % 默认衰减参数
            
            % 设置默认交通参数
            obj.initializeTransportParameters();
            
            % 处理可选参数
            if nargin > 4
                for i = 1:2:length(varargin)
                    switch lower(varargin{i})
                        case 'cell_width'
                            obj.cell_width = varargin{i+1};
                        case 'cell_height'
                            obj.cell_height = varargin{i+1};
                        case 'max_distance'
                            obj.max_distance = varargin{i+1};
                        case 'decay_function'
                            obj.decay_function = varargin{i+1};
                        case 'decay_param'
                            obj.decay_param = varargin{i+1};
                    end
                end
            end
        end
        
        function initializeTransportParameters(obj)
            % 初始化交通参数
            
            % 设置不同道路类型的行进速度 (m/s)
            obj.travel_speeds = containers.Map();
            obj.travel_speeds('highway') = 30;     % 高速公路
            obj.travel_speeds('primary') = 20;     % 主干道
            obj.travel_speeds('secondary') = 15;   % 次干道
            obj.travel_speeds('tertiary') = 10;    % 支路
            obj.travel_speeds('path') = 5;         % 小路
            obj.travel_speeds('offroad') = 1;      % 无路
            
            % 设置不同土地利用类型的阻抗因子
            obj.impedance_factors = containers.Map();
            obj.impedance_factors('urban') = 1.0;      % 城市
            obj.impedance_factors('agriculture') = 1.5; % 农田
            obj.impedance_factors('forest') = 2.0;     % 森林
            obj.impedance_factors('water') = 5.0;      % 水体
            obj.impedance_factors('wetland') = 3.0;    % 湿地
            obj.impedance_factors('barren') = 1.2;     % 裸地
        end
        
        function [cost_surface, accessibility] = calculateAccessibility(obj, source_points)
            % 计算可达性
            % 输入参数:
            %   source_points - 源点坐标矩阵 [n x 2]
            % 返回值:
            %   cost_surface - 累积成本面
            %   accessibility - 可达性指数
            
            % 初始化成本面
            [rows, cols] = size(obj.dem);
            cost_surface = inf(rows, cols);
            
            % 计算基础成本面
            base_cost = obj.calculateBaseCost();
            
            % 对每个源点计算成本距离
            for i = 1:size(source_points, 1)
                % 使用Dijkstra算法计算最短路径
                point_cost = obj.calculateCostDistance(...
                    source_points(i,1), source_points(i,2), base_cost);
                
                % 更新累积成本面
                cost_surface = min(cost_surface, point_cost);
            end
            
            % 计算可达性指数
            accessibility = obj.calculateAccessibilityIndex(cost_surface);
        end
        
        function base_cost = calculateBaseCost(obj)
            % 计算基础成本面
            % 返回值:
            %   base_cost - 基础成本矩阵
            
            [rows, cols] = size(obj.dem);
            base_cost = ones(rows, cols);
            
            % 考虑坡度影响
            [slope, ~] = obj.calculateSlopeAspect();
            slope_factor = 1 + tand(slope);
            base_cost = base_cost .* slope_factor;
            
            % 考虑土地利用影响
            for i = 1:rows
                for j = 1:cols
                    landuse_type = obj.getLandUseType(i, j);
                    if isKey(obj.impedance_factors, landuse_type)
                        base_cost(i,j) = base_cost(i,j) * ...
                            obj.impedance_factors(landuse_type);
                    end
                end
            end
            
            % 考虑道路网络影响
            for i = 1:rows
                for j = 1:cols
                    road_type = obj.getRoadType(i, j);
                    if isKey(obj.travel_speeds, road_type)
                        base_cost(i,j) = base_cost(i,j) / ...
                            obj.travel_speeds(road_type);
                    end
                end
            end
            
            % 考虑障碍物影响
            base_cost(obj.barriers > 0) = inf;
        end
        
        function [slope, aspect] = calculateSlopeAspect(obj)
            % 计算坡度和坡向
            % 返回值:
            %   slope - 坡度矩阵（度）
            %   aspect - 坡向矩阵（度）
            
            [dx, dy] = gradient(obj.dem, obj.cell_width, obj.cell_height);
            
            % 计算坡度（度）
            slope = atand(sqrt(dx.^2 + dy.^2));
            
            % 计算坡向（度）
            aspect = atan2d(dy, dx);
            aspect = mod(90 - aspect, 360);
        end
        
        function cost_distance = calculateCostDistance(obj, start_x, start_y, base_cost)
            % 使用Dijkstra算法计算成本距离
            % 输入参数:
            %   start_x, start_y - 起点坐标
            %   base_cost - 基础成本矩阵
            % 返回值:
            %   cost_distance - 成本距离矩阵
            
            [rows, cols] = size(base_cost);
            cost_distance = inf(rows, cols);
            cost_distance(start_y, start_x) = 0;
            
            % 初始化优先队列
            queue = java.util.PriorityQueue;
            queue.add([start_y, start_x, 0]);
            
            % 访问标记
            visited = false(rows, cols);
            
            while ~queue.isEmpty
                % 获取当前最小成本点
                [cy, cx, ccost] = queue.poll;
                
                if visited(cy, cx)
                    continue;
                end
                
                visited(cy, cx) = true;
                
                % 检查8个邻域
                for dy = -1:1
                    for dx = -1:1
                        if dy == 0 && dx == 0
                            continue;
                        end
                        
                        ny = cy + dy;
                        nx = cx + dx;
                        
                        % 检查边界
                        if ny < 1 || ny > rows || nx < 1 || nx > cols
                            continue;
                        end
                        
                        % 计算新成本
                        move_dist = sqrt(dx^2 + dy^2) * obj.cell_width;
                        new_cost = ccost + move_dist * ...
                            (base_cost(cy,cx) + base_cost(ny,nx)) / 2;
                        
                        % 更新最小成本
                        if new_cost < cost_distance(ny,nx)
                            cost_distance(ny,nx) = new_cost;
                            queue.add([ny, nx, new_cost]);
                        end
                    end
                end
            end
        end
        
        function accessibility = calculateAccessibilityIndex(obj, cost_surface)
            % 计算可达性指数
            % 输入参数:
            %   cost_surface - 成本面
            % 返回值:
            %   accessibility - 可达性指数
            
            % 应用距离衰减函数
            switch obj.decay_function
                case 'exponential'
                    accessibility = exp(-obj.decay_param * cost_surface);
                case 'linear'
                    accessibility = max(0, 1 - obj.decay_param * cost_surface);
                case 'power'
                    accessibility = cost_surface.^(-obj.decay_param);
                case 'gaussian'
                    accessibility = exp(-(cost_surface.^2) * obj.decay_param);
                otherwise
                    error('不支持的衰减函数类型');
            end
            
            % 标准化
            accessibility = accessibility / max(accessibility(:));
            
            % 处理不可达区域
            accessibility(cost_surface == inf) = 0;
        end
        
        function landuse_type = getLandUseType(obj, i, j)
            % 获取土地利用类型
            landuse_type = 'urban';  % 默认类型
            
            % 根据土地利用数据获取实际类型
            landuse_code = obj.landuse(i,j);
            switch landuse_code
                case 1
                    landuse_type = 'urban';
                case 2
                    landuse_type = 'agriculture';
                case 3
                    landuse_type = 'forest';
                case 4
                    landuse_type = 'water';
                case 5
                    landuse_type = 'wetland';
                case 6
                    landuse_type = 'barren';
            end
        end
        
        function road_type = getRoadType(obj, i, j)
            % 获取道路类型
            road_type = 'offroad';  % 默认类型
            
            % 根据道路网络数据获取实际类型
            road_code = obj.road_network(i,j);
            switch road_code
                case 1
                    road_type = 'highway';
                case 2
                    road_type = 'primary';
                case 3
                    road_type = 'secondary';
                case 4
                    road_type = 'tertiary';
                case 5
                    road_type = 'path';
            end
        end
        
        function visualizeResults(obj, cost_surface, accessibility)
            % 可视化结果
            figure('Name', 'Proximity Analysis Results');
            
            % 成本面
            subplot(2,2,1);
            imagesc(cost_surface);
            colormap(gca, jet);
            colorbar;
            title('累积成本面');
            
            % 可达性指数
            subplot(2,2,2);
            imagesc(accessibility);
            colormap(gca, jet);
            colorbar;
            title('可达性指数');
            
            % 道路网络
            subplot(2,2,3);
            imagesc(obj.road_network);
            colormap(gca, jet);
            colorbar;
            title('道路网络');
            
            % 土地利用
            subplot(2,2,4);
            imagesc(obj.landuse);
            colormap(gca, jet);
            colorbar;
            title('土地利用');
        end
        
        function service_flow = calculateServiceFlow(obj, source_strength, ...
                sink_capacity, accessibility)
            % 计算服务流动
            % 输入参数:
            %   source_strength - 源强度
            %   sink_capacity - 汇容量
            %   accessibility - 可达性指数
            % 返回值:
            %   service_flow - 服务流动量
            
            % 计算潜在流动量
            potential_flow = source_strength .* accessibility;
            
            % 考虑汇的容量限制
            service_flow = min(potential_flow, sink_capacity);
        end
    end
end 