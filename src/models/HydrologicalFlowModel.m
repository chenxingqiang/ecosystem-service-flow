classdef HydrologicalFlowModel
    % HydrologicalFlowModel 水文服务流动模型
    
    properties
        dem           % 数字高程模型
        precipitation % 降水量
        landuse      % 土地利用
        soil_type    % 土壤类型
        cell_width   % 栅格宽度
        cell_height  % 栅格高度
    end
    
    methods
        function obj = HydrologicalFlowModel(flow_data, cell_width, cell_height)
            % 构造函数
            obj.dem = flow_data(:,:,1);
            obj.precipitation = flow_data(:,:,2);
            obj.landuse = flow_data(:,:,3);
            obj.soil_type = flow_data(:,:,4);
            obj.cell_width = cell_width;
            obj.cell_height = cell_height;
        end
        
        function results = calculateFlow(obj, source_data, sink_data, use_data)
            % 计算水文服务流动
            results = struct();
            
            % 1. 计算流向和汇流
            [flow_direction, flow_accumulation] = obj.calculateFlowDirection();
            
            % 2. 计算坡度和坡向
            [slope, aspect] = obj.calculateSlopeAspect();
            
            % 3. 计算下渗和产流
            [infiltration, runoff] = obj.calculateInfiltration();
            
            % 4. 提取河网
            stream_network = obj.extractStreamNetwork(flow_accumulation);
            
            % 5. 计算流速和传输时间
            roughness = obj.calculateRoughness();
            [velocity, travel_time] = obj.calculateFlowVelocity(slope, roughness, flow_accumulation);
            
            % 6. 模拟水流运动
            [water_depth, discharge] = obj.simulateWaterMovement(runoff, flow_direction, ...
                flow_accumulation, stream_network, velocity, travel_time);
            
            % 7. 计算服务流动
            results.flow = obj.calculateServiceFlow(water_depth, sink_data, use_data);
            
            % 保存中间结果
            results.flow_direction = flow_direction;
            results.flow_accumulation = flow_accumulation;
            results.slope = slope;
            results.aspect = aspect;
            results.infiltration = infiltration;
            results.runoff = runoff;
            results.stream_network = stream_network;
            results.velocity = velocity;
            results.travel_time = travel_time;
            results.water_depth = water_depth;
            results.discharge = discharge;
        end
        
        function [flow_direction, flow_accumulation] = calculateFlowDirection(obj)
            % 计算流向和汇流
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
        
        function accumulateFlow(obj, i, j, flow_direction, flow_accumulation, visited)
            % 递归计算汇流累积量
            if visited(i,j)
                return;
            end
            
            visited(i,j) = true;
            flow_accumulation(i,j) = 1;  % 当前单元格贡献量
            
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
        
        function [slope, aspect] = calculateSlopeAspect(obj)
            % 计算坡度和坡向
            [dx, dy] = gradient(obj.dem, obj.cell_width, obj.cell_height);
            
            % 计算坡度（度）
            slope = atand(sqrt(dx.^2 + dy.^2));
            
            % 计算坡向（度）
            aspect = atan2d(dy, dx);
            aspect = mod(90 - aspect, 360);  % 转换为地理方位角
        end
        
        function [infiltration, runoff] = calculateInfiltration(obj)
            % 计算下渗和产流
            
            % 设置土地利用的初始下渗率（mm/h）
            infiltration_rate = zeros(size(obj.landuse));
            infiltration_rate(obj.landuse == 1) = 30;  % 森林
            infiltration_rate(obj.landuse == 2) = 20;  % 草地
            infiltration_rate(obj.landuse == 3) = 15;  % 农田
            infiltration_rate(obj.landuse == 4) = 0;   % 水体
            infiltration_rate(obj.landuse == 5) = 5;   % 建设用地
            
            % 考虑土壤类型的影响
            soil_factor = zeros(size(obj.soil_type));
            soil_factor(obj.soil_type == 1) = 0.6;  % 粘土
            soil_factor(obj.soil_type == 2) = 1.0;  % 壤土
            soil_factor(obj.soil_type == 3) = 1.4;  % 砂土
            
            % 计算实际下渗率
            infiltration_rate = infiltration_rate .* soil_factor;
            
            % 计算下渗量和产流量
            infiltration = min(obj.precipitation, infiltration_rate);
            runoff = obj.precipitation - infiltration;
        end
        
        function roughness = calculateRoughness(obj)
            % 计算曼宁粗糙度
            roughness = zeros(size(obj.landuse));
            
            % 根据土地利用类型设置基础粗糙度
            roughness(obj.landuse == 1) = 0.1;   % 森林
            roughness(obj.landuse == 2) = 0.05;  % 草地
            roughness(obj.landuse == 3) = 0.03;  % 农田
            roughness(obj.landuse == 4) = 0.01;  % 水体
            roughness(obj.landuse == 5) = 0.02;  % 建设用地
            
            % 考虑土壤类型的影响
            soil_factor = zeros(size(obj.soil_type));
            soil_factor(obj.soil_type == 1) = 1.2;  % 粘土
            soil_factor(obj.soil_type == 2) = 1.0;  % 壤土
            soil_factor(obj.soil_type == 3) = 0.8;  % 砂土
            
            roughness = roughness .* soil_factor;
        end
        
        function [velocity, travel_time] = calculateFlowVelocity(obj, slope, roughness, flow_accumulation)
            % 计算流速和传输时间
            
            % 使用曼宁公式计算流速
            % V = (1/n) * R^(2/3) * S^(1/2)
            % 其中：n为粗糙度，R为水力半径，S为坡度
            
            % 简化的水力半径估算（基于汇流累积量）
            hydraulic_radius = log(flow_accumulation + 1) / log(max(flow_accumulation(:)) + 1);
            
            % 计算流速（m/s）
            velocity = (1./roughness) .* (hydraulic_radius.^(2/3)) .* (sind(slope).^0.5);
            
            % 计算传输时间（s）
            travel_time = obj.cell_width ./ (velocity + eps);  % 添加eps避免除零
        end
        
        function stream_network = extractStreamNetwork(obj, flow_accumulation)
            % 提取河网
            
            % 设置河网提取阈值（根据汇流累积量）
            threshold = mean(flow_accumulation(:)) + std(flow_accumulation(:));
            
            % 初始化河网
            stream_network = flow_accumulation > threshold;
            
            % 提取主要河段
            labeled = bwlabel(stream_network);
            
            % 计算各河段的重要性
            stats = regionprops(labeled, flow_accumulation, 'MeanIntensity', 'Area');
            importance = [stats.MeanIntensity] .* [stats.Area];
            
            % 保留重要的河段
            significant_streams = importance > mean(importance);
            stream_network = ismember(labeled, find(significant_streams));
        end
        
        function [water_depth, discharge] = simulateWaterMovement(obj, runoff, flow_direction, ...
                flow_accumulation, stream_network, velocity, travel_time)
            % 模拟水流运动
            [rows, cols] = size(runoff);
            water_depth = zeros(rows, cols);
            discharge = zeros(rows, cols);
            
            % 初始化水深
            water_depth = runoff;
            
            % 时间步长（s）
            dt = min(travel_time(:)) / 2;
            
            % 模拟时间（s）
            t_max = max(travel_time(:)) * 10;
            
            % 时间循环
            for t = 0:dt:t_max
                % 计算水流传播
                new_depth = water_depth;
                new_discharge = discharge;
                
                for i = 2:rows-1
                    for j = 2:cols-1
                        % 获取上游单元格的贡献
                        [up_i, up_j] = obj.getUpstreamCells(i, j, flow_direction);
                        inflow = 0;
                        
                        for k = 1:length(up_i)
                            % 计算从上游单元格的流入量
                            dist = sqrt((i-up_i(k))^2 + (j-up_j(k))^2) * obj.cell_width;
                            travel_t = dist / (velocity(up_i(k),up_j(k)) + eps);
                            
                            if travel_t <= dt
                                flow_amount = water_depth(up_i(k),up_j(k)) * ...
                                    flow_accumulation(up_i(k),up_j(k)) / ...
                                    (flow_accumulation(i,j) + eps);
                                inflow = inflow + flow_amount;
                                
                                % 更新流量
                                new_discharge(i,j) = new_discharge(i,j) + ...
                                    flow_amount / dt;
                            end
                        end
                        
                        % 更新水深
                        new_depth(i,j) = water_depth(i,j) + inflow;
                    end
                end
                
                water_depth = new_depth;
                discharge = new_discharge;
            end
            
            % 考虑河网的影响
            water_depth = water_depth .* (1 + stream_network);
            discharge = discharge .* (1 + stream_network);
        end
        
        function flow = calculateServiceFlow(obj, water_depth, sink_data, use_data)
            % 计算服务流动
            flow = struct();
            
            % 计算理论流动量
            flow.theoretical = water_depth;
            
            % 考虑汇的影响（如蒸发、渗漏）
            flow.blocked = min(flow.theoretical, sink_data);
            flow.actual = flow.theoretical - flow.blocked;
            
            % 考虑使用的影响（如取水）
            flow.used = min(flow.actual, use_data);
            flow.actual = flow.actual - flow.used;
        end
        
        function [up_i, up_j] = getUpstreamCells(obj, i, j, flow_direction)
            % 获取上游单元格的位置
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
            % direction: 1-8表示8个方向（从左上角顺时针编号）
            
            % 方向对应关系
            dir_map = [7 8 9; 4 5 6; 1 2 3];
            target_dir = dir_map(di+2, dj+2);
            
            flows_to = (direction == target_dir);
        end
        
        function visualizeResults(obj, results)
            % 可视化结果
            
            % 流向和汇流
            figure('Name', 'Flow Direction and Accumulation');
            subplot(2,2,1);
            imagesc(results.flow_direction);
            colormap(gca, jet);
            colorbar;
            title('流向');
            
            subplot(2,2,2);
            imagesc(log(results.flow_accumulation + 1));
            colormap(gca, jet);
            colorbar;
            title('汇流累积量');
            
            subplot(2,2,3);
            imagesc(results.stream_network);
            colormap(gca, jet);
            colorbar;
            title('河网');
            
            subplot(2,2,4);
            imagesc(results.velocity);
            colormap(gca, jet);
            colorbar;
            title('流速');
            
            % 水文过程
            figure('Name', 'Hydrological Processes');
            subplot(2,2,1);
            imagesc(results.infiltration);
            colormap(gca, jet);
            colorbar;
            title('下渗量');
            
            subplot(2,2,2);
            imagesc(results.runoff);
            colormap(gca, jet);
            colorbar;
            title('产流量');
            
            subplot(2,2,3);
            imagesc(results.water_depth);
            colormap(gca, jet);
            colorbar;
            title('水深');
            
            subplot(2,2,4);
            imagesc(results.discharge);
            colormap(gca, jet);
            colorbar;
            title('流量');
            
            % 服务流动
            figure('Name', 'Service Flow');
            subplot(2,2,1);
            imagesc(results.flow.theoretical);
            colormap(gca, jet);
            colorbar;
            title('理论流动量');
            
            subplot(2,2,2);
            imagesc(results.flow.actual);
            colormap(gca, jet);
            colorbar;
            title('实际流动量');
            
            subplot(2,2,3);
            imagesc(results.flow.used);
            colormap(gca, jet);
            colorbar;
            title('使用量');
            
            subplot(2,2,4);
            imagesc(results.flow.blocked);
            colormap(gca, jet);
            colorbar;
            title('阻滞量');
        end
    end
end 