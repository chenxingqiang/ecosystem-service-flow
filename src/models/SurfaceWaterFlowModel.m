classdef SurfaceWaterFlowModel < handle
    % SurfaceWaterFlowModel 地表水流动模型
    % 实现基于SPAN模型的地表水流动服务评估
    
    properties
        % 输入数据层
        dem              % 数字高程模型
        precipitation    % 降水量
        landuse         % 土地利用
        soil_type       % 土壤类型
        
        % 模型参数
        cell_width      % 网格宽度 (m)
        cell_height     % 网格高度 (m)
        time_step      % 时间步长 (s)
        manning_n      % 曼宁粗糙度系数
        infiltration_rate % 下渗率 (mm/h)
        evaporation_rate % 蒸发率 (mm/h)
        baseflow_coef   % 基流系数
        stream_threshold % 河流提取阈值
    end
    
    methods
        function obj = SurfaceWaterFlowModel(flow_data, varargin)
            % 构造函数
            % 输入参数:
            %   flow_data - 包含所有环境因子的数据层 [rows x cols x layers]
            %   varargin - 可选参数
            
            % 验证输入数据
            validateattributes(flow_data, {'numeric'}, {'3d'});
            assert(size(flow_data, 3) >= 4, '地表水流动模型需要至少4个数据层');
            
            % 提取数据层
            obj.dem = flow_data(:,:,1);
            obj.precipitation = flow_data(:,:,2);
            obj.landuse = flow_data(:,:,3);
            obj.soil_type = flow_data(:,:,4);
            
            % 设置默认参数
            obj.cell_width = 30;     % 默认30米分辨率
            obj.cell_height = 30;
            obj.time_step = 3600;    % 默认1小时时间步长
            obj.manning_n = 0.035;   % 默认曼宁系数
            obj.infiltration_rate = 10; % 默认下渗率(mm/h)
            obj.evaporation_rate = 0.5; % 默认蒸发率(mm/h)
            obj.baseflow_coef = 0.3;  % 默认基流系数
            obj.stream_threshold = 100; % 默认河流提取阈值
            
            % 处理可选参数
            if nargin > 1
                for i = 1:2:length(varargin)
                    switch lower(varargin{i})
                        case 'cell_width'
                            obj.cell_width = varargin{i+1};
                        case 'cell_height'
                            obj.cell_height = varargin{i+1};
                        case 'time_step'
                            obj.time_step = varargin{i+1};
                        case 'manning_n'
                            obj.manning_n = varargin{i+1};
                        case 'infiltration_rate'
                            obj.infiltration_rate = varargin{i+1};
                        case 'evaporation_rate'
                            obj.evaporation_rate = varargin{i+1};
                        case 'baseflow_coef'
                            obj.baseflow_coef = varargin{i+1};
                        case 'stream_threshold'
                            obj.stream_threshold = varargin{i+1};
                    end
                end
            end
        end
        
        function [stream_network, drainage_area] = extractStreamNetwork(obj)
            % 提取河网和汇水区
            % 返回值:
            %   stream_network - 河网矩阵
            %   drainage_area - 汇水区矩阵
            
            % 计算流向和汇流累积量
            [flow_direction, flow_accumulation] = obj.calculateFlowDirection();
            
            % 提取河网（基于累积流量阈值）
            stream_network = flow_accumulation > obj.stream_threshold;
            
            % 计算汇水区
            drainage_area = obj.calculateDrainageArea(flow_direction, stream_network);
        end
        
        function [flow_direction, flow_accumulation] = calculateFlowDirection(obj)
            % 计算流向和汇流
            % 返回值:
            %   flow_direction - D8流向矩阵
            %   flow_accumulation - 汇流累积量矩阵
            
            [rows, cols] = size(obj.dem);
            flow_direction = zeros(rows, cols);
            flow_accumulation = zeros(rows, cols);
            
            % D8算法计算流向
            for i = 2:rows-1
                for j = 2:cols-1
                    % 提取3x3窗口
                    window = obj.dem(i-1:i+1, j-1:j+1);
                    center = window(2,2);
                    
                    % 计算高程差
                    diff = center - window;
                    diff(2,2) = -inf;  % 中心点设为-inf
                    
                    % 找到最大坡降方向
                    [~, idx] = max(diff(:));
                    flow_direction(i,j) = idx;
                end
            end
            
            % 计算汇流累积量
            visited = false(rows, cols);
            for i = 1:rows
                for j = 1:cols
                    if ~visited(i,j)
                        obj.accumulateFlow(i, j, flow_direction, flow_accumulation, visited);
                    end
                end
            end
        end
        
        function drainage_area = calculateDrainageArea(obj, flow_direction, stream_network)
            % 计算汇水区
            % 输入参数:
            %   flow_direction - 流向矩阵
            %   stream_network - 河网矩阵
            % 返回值:
            %   drainage_area - 汇水区矩阵
            
            [rows, cols] = size(flow_direction);
            drainage_area = zeros(rows, cols);
            
            % 标记河网单元格的上游区域
            for i = 1:rows
                for j = 1:cols
                    if stream_network(i,j)
                        drainage_area = drainage_area | ...
                            obj.traceUpstream(i, j, flow_direction);
                    end
                end
            end
        end
        
        function [water_depth, discharge] = simulateWaterMovement(obj, ...
                initial_depth, time_steps)
            % 模拟水流运动
            % 输入参数:
            %   initial_depth - 初始水深
            %   time_steps - 模拟时间步数
            % 返回值:
            %   water_depth - 水深时间序列
            %   discharge - 流量时间序列
            
            [rows, cols] = size(initial_depth);
            water_depth = zeros(rows, cols, time_steps);
            discharge = zeros(rows, cols, time_steps);
            
            % 设置初始条件
            water_depth(:,:,1) = initial_depth;
            
            % 计算地形参数
            [flow_direction, flow_accumulation] = obj.calculateFlowDirection();
            [slope, ~] = obj.calculateSlopeAspect();
            [stream_network, ~] = obj.extractStreamNetwork();
            
            % 时间循环
            for t = 2:time_steps
                % 计算水文过程
                [runoff, infiltration] = obj.calculateRunoff();
                evaporation = obj.calculateEvaporation(water_depth(:,:,t-1));
                baseflow = obj.calculateBaseflow(water_depth(:,:,t-1));
                
                % 计算流速和传输时间
                [velocity, ~] = obj.calculateFlowVelocity(slope, water_depth(:,:,t-1));
                
                % 更新水深和流量
                new_depth = water_depth(:,:,t-1);
                new_discharge = discharge(:,:,t-1);
                
                for i = 2:rows-1
                    for j = 2:cols-1
                        % 获取上游单元格的贡献
                        [up_i, up_j] = obj.getUpstreamCells(i, j, flow_direction);
                        inflow = 0;
                        
                        for k = 1:length(up_i)
                            % 计算从上游单元格的流入量
                            dist = sqrt((i-up_i(k))^2 + (j-up_j(k))^2) * obj.cell_width;
                            travel_t = dist / (velocity(up_i(k),up_j(k)) + eps);
                            
                            if travel_t <= obj.time_step
                                inflow = inflow + water_depth(up_i(k),up_j(k),t-1) * ...
                                    flow_accumulation(up_i(k),up_j(k)) / ...
                                    (flow_accumulation(i,j) + eps);
                            end
                        end
                        
                        % 更新水深（考虑所有水文过程）
                        new_depth(i,j) = water_depth(i,j,t-1) + ...
                            inflow + runoff(i,j) - infiltration(i,j) - ...
                            evaporation(i,j) + baseflow(i,j);
                        
                        % 在河网中的单元格使用不同的更新规则
                        if stream_network(i,j)
                            new_depth(i,j) = max(new_depth(i,j), 0.01); % 保持最小水深
                        else
                            new_depth(i,j) = max(new_depth(i,j), 0); % 允许干涸
                        end
                        
                        % 更新流量
                        new_discharge(i,j) = inflow / obj.time_step;
                    end
                end
                
                water_depth(:,:,t) = new_depth;
                discharge(:,:,t) = new_discharge;
            end
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
            aspect = mod(90 - aspect, 360);  % 转换为地理方位角
        end
        
        function [velocity, travel_time] = calculateFlowVelocity(obj, slope, depth)
            % 计算流速和传输时间
            % 输入参数:
            %   slope - 坡度矩阵
            %   depth - 水深矩阵
            % 返回值:
            %   velocity - 流速矩阵 (m/s)
            %   travel_time - 传输时间矩阵 (s)
            
            % 使用曼宁公式计算流速
            % V = (1/n) * R^(2/3) * S^(1/2)
            hydraulic_radius = depth;
            velocity = (1/obj.manning_n) .* (hydraulic_radius.^(2/3)) .* ...
                (sind(slope).^0.5);
            
            % 计算传输时间
            travel_time = obj.cell_width ./ (velocity + eps);
        end
        
        function [runoff, infiltration] = calculateRunoff(obj)
            % 计算产流和下渗
            % 返回值:
            %   runoff - 产流量矩阵 (mm)
            %   infiltration - 下渗量矩阵 (mm)
            
            % 计算时间步内的下渗量
            infiltration_depth = obj.infiltration_rate * obj.time_step / 3600;
            
            % 根据土地利用类型调整下渗率
            infiltration_factor = ones(size(obj.landuse));
            infiltration_factor(obj.landuse == 1) = 1.2;  % 森林
            infiltration_factor(obj.landuse == 2) = 1.0;  % 草地
            infiltration_factor(obj.landuse == 3) = 0.8;  % 农田
            infiltration_factor(obj.landuse == 4) = 0.0;  % 水体
            infiltration_factor(obj.landuse == 5) = 0.3;  % 建设用地
            
            % 计算实际下渗量
            infiltration = min(obj.precipitation, ...
                infiltration_depth .* infiltration_factor);
            
            % 计算产流量
            runoff = obj.precipitation - infiltration;
        end
        
        function evaporation = calculateEvaporation(obj, water_depth)
            % 计算蒸发量
            % 输入参数:
            %   water_depth - 水深矩阵
            % 返回值:
            %   evaporation - 蒸发量矩阵 (mm)
            
            % 计算时间步内的潜在蒸发量
            potential_evap = obj.evaporation_rate * obj.time_step / 3600;
            
            % 实际蒸发量不能超过可用水量
            evaporation = min(potential_evap, water_depth);
        end
        
        function baseflow = calculateBaseflow(obj, water_depth)
            % 计算基流量
            % 输入参数:
            %   water_depth - 水深矩阵
            % 返回值:
            %   baseflow - 基流量矩阵 (mm)
            
            % 使用线性水库模型计算基流
            baseflow = obj.baseflow_coef * water_depth;
        end
        
        function upstream_area = traceUpstream(obj, i, j, flow_direction)
            % 追踪上游区域
            % 输入参数:
            %   i, j - 当前单元格的行列索引
            %   flow_direction - 流向矩阵
            % 返回值:
            %   upstream_area - 上游区域标记矩阵
            
            [rows, cols] = size(flow_direction);
            upstream_area = false(rows, cols);
            upstream_area(i,j) = true;
            
            % 获取上游单元格
            [up_i, up_j] = obj.getUpstreamCells(i, j, flow_direction);
            
            % 递归处理上游单元格
            for k = 1:length(up_i)
                upstream_area = upstream_area | ...
                    obj.traceUpstream(up_i(k), up_j(k), flow_direction);
            end
        end
        
        function [up_i, up_j] = getUpstreamCells(obj, i, j, flow_direction)
            % 获取上游单元格位置
            [rows, cols] = size(flow_direction);
            up_i = [];
            up_j = [];
            
            % 检查8个相邻单元格
            for di = -1:1
                for dj = -1:1
                    if di == 0 && dj == 0
                        continue;
                    end
                    
                    ni = i + di;
                    nj = j + dj;
                    
                    % 检查边界
                    if ni < 1 || ni > rows || nj < 1 || nj > cols
                        continue;
                    end
                    
                    % 检查流向是否指向当前单元格
                    if obj.flowsTo(flow_direction(ni,nj), di, dj)
                        up_i = [up_i; ni];
                        up_j = [up_j; nj];
                    end
                end
            end
        end
        
        function flows_to = flowsTo(obj, direction, di, dj)
            % 检查流向是否指向指定方向
            dir_map = [7 8 9; 4 5 6; 1 2 3];
            target_dir = dir_map(di+2, dj+2);
            flows_to = (direction == target_dir);
        end
        
        function accumulateFlow(obj, i, j, flow_direction, flow_accumulation, visited)
            % 递归计算汇流累积量
            if visited(i,j)
                return;
            end
            
            visited(i,j) = true;
            flow_accumulation(i,j) = 1;
            
            % 获取上游单元格
            [up_i, up_j] = obj.getUpstreamCells(i, j, flow_direction);
            
            % 递归处理上游单元格
            for k = 1:length(up_i)
                if ~visited(up_i(k), up_j(k))
                    obj.accumulateFlow(up_i(k), up_j(k), flow_direction, ...
                        flow_accumulation, visited);
                    flow_accumulation(i,j) = flow_accumulation(i,j) + ...
                        flow_accumulation(up_i(k), up_j(k));
                end
            end
        end
    end
end 