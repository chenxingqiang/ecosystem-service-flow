classdef LineOfSightModel < handle
    % LineOfSightModel 视线可达性模型
    % 实现基于SPAN模型的视觉服务流动评估
    
    properties
        % 输入数据层
        dem              % 数字高程模型
        landcover       % 土地覆盖
        obstacles       % 障碍物高度
        
        % 观察点参数
        observer_height  % 观察点高度 (m)
        target_height   % 目标点高度 (m)
        max_distance    % 最大可视距离 (m)
        
        % 大气参数
        visibility      % 能见度 (m)
        refraction_coef % 大气折射系数
        
        % 网格参数
        cell_width      % 网格宽度 (m)
        cell_height     % 网格高度 (m)
        
        % 视域分析参数
        azimuth_range   % 方位角范围 [min max] (度)
        vertical_range  % 垂直角范围 [min max] (度)
        angle_step     % 角度步长 (度)
    end
    
    methods
        function obj = LineOfSightModel(dem_data, landcover_data, obstacles_data, varargin)
            % 构造函数
            % 输入参数:
            %   dem_data - 数字高程模型数据
            %   landcover_data - 土地覆盖数据
            %   obstacles_data - 障碍物高度数据
            %   varargin - 可选参数
            
            % 验证输入数据
            validateattributes(dem_data, {'numeric'}, {'2d'});
            validateattributes(landcover_data, {'numeric'}, {'2d', 'size', size(dem_data)});
            validateattributes(obstacles_data, {'numeric'}, {'2d', 'size', size(dem_data)});
            
            % 存储输入数据
            obj.dem = dem_data;
            obj.landcover = landcover_data;
            obj.obstacles = obstacles_data;
            
            % 设置默认参数
            obj.observer_height = 1.7;     % 默认人眼高度
            obj.target_height = 0;         % 默认目标点高度
            obj.max_distance = 5000;       % 默认最大可视距离5km
            obj.visibility = 10000;        % 默认能见度10km
            obj.refraction_coef = 0.13;    % 默认大气折射系数
            obj.cell_width = 30;           % 默认30米分辨率
            obj.cell_height = 30;
            obj.azimuth_range = [0 360];   % 默认全方位
            obj.vertical_range = [-45 45];  % 默认垂直视角范围
            obj.angle_step = 1;            % 默认1度步长
            
            % 处理可选参数
            if nargin > 3
                for i = 1:2:length(varargin)
                    switch lower(varargin{i})
                        case 'observer_height'
                            obj.observer_height = varargin{i+1};
                        case 'target_height'
                            obj.target_height = varargin{i+1};
                        case 'max_distance'
                            obj.max_distance = varargin{i+1};
                        case 'visibility'
                            obj.visibility = varargin{i+1};
                        case 'refraction_coef'
                            obj.refraction_coef = varargin{i+1};
                        case 'cell_width'
                            obj.cell_width = varargin{i+1};
                        case 'cell_height'
                            obj.cell_height = varargin{i+1};
                        case 'azimuth_range'
                            obj.azimuth_range = varargin{i+1};
                        case 'vertical_range'
                            obj.vertical_range = varargin{i+1};
                        case 'angle_step'
                            obj.angle_step = varargin{i+1};
                    end
                end
            end
        end
        
        function viewshed = calculateViewshed(obj, observer_x, observer_y)
            % 计算视域
            % 输入参数:
            %   observer_x, observer_y - 观察点坐标（网格索引）
            % 返回值:
            %   viewshed - 视域矩阵（布尔型）
            
            [rows, cols] = size(obj.dem);
            viewshed = false(rows, cols);
            
            % 获取观察点高程
            observer_elev = obj.dem(observer_y, observer_x) + obj.observer_height;
            
            % 计算搜索范围
            max_cells = ceil(obj.max_distance / obj.cell_width);
            [X, Y] = meshgrid(-max_cells:max_cells, -max_cells:max_cells);
            
            % 遍历方位角
            for azimuth = obj.azimuth_range(1):obj.angle_step:obj.azimuth_range(2)
                % 遍历垂直角
                for vertical = obj.vertical_range(1):obj.angle_step:obj.vertical_range(2)
                    % 计算视线路径
                    [visible_cells, ~] = obj.traceViewLine(observer_x, observer_y, ...
                        observer_elev, azimuth, vertical);
                    
                    % 更新视域
                    for k = 1:size(visible_cells, 1)
                        i = visible_cells(k,1);
                        j = visible_cells(k,2);
                        if i >= 1 && i <= rows && j >= 1 && j <= cols
                            viewshed(i,j) = true;
                        end
                    end
                end
            end
        end
        
        function [visible_cells, visibility_factor] = traceViewLine(obj, ...
                observer_x, observer_y, observer_elev, azimuth, vertical)
            % 追踪视线路径
            % 输入参数:
            %   observer_x, observer_y - 观察点坐标
            %   observer_elev - 观察点高程
            %   azimuth - 方位角 (度)
            %   vertical - 垂直角 (度)
            % 返回值:
            %   visible_cells - 可见单元格坐标
            %   visibility_factor - 可见度因子
            
            % 初始化结果
            visible_cells = [];
            visibility_factor = [];
            
            % 计算视线方向向量
            dx = cosd(vertical) * sind(azimuth);
            dy = cosd(vertical) * cosd(azimuth);
            dz = sind(vertical);
            
            % 使用Bresenham算法追踪视线
            max_steps = ceil(obj.max_distance / obj.cell_width);
            current_x = observer_x;
            current_y = observer_y;
            
            for step = 1:max_steps
                % 计算下一个单元格位置
                next_x = round(observer_x + step * dx);
                next_y = round(observer_y + step * dy);
                
                % 检查边界
                if next_x < 1 || next_x > size(obj.dem, 2) || ...
                   next_y < 1 || next_y > size(obj.dem, 1)
                    break;
                end
                
                % 计算实际距离
                dist = sqrt((next_x-observer_x)^2 + (next_y-observer_y)^2) * obj.cell_width;
                if dist > obj.max_distance
                    break;
                end
                
                % 计算目标点高程
                target_elev = obj.dem(next_y, next_x) + ...
                    obj.obstacles(next_y, next_x) + obj.target_height;
                
                % 考虑地球曲率和大气折射的影响
                earth_curv = obj.calculateEarthCurvature(dist);
                target_elev = target_elev - earth_curv;
                
                % 计算视线高程
                line_elev = observer_elev + dist * dz;
                
                % 检查可见性
                if line_elev >= target_elev
                    % 计算可见度因子
                    vis_factor = obj.calculateVisibilityFactor(dist);
                    
                    % 存储结果
                    visible_cells = [visible_cells; next_y next_x];
                    visibility_factor = [visibility_factor; vis_factor];
                else
                    break;  % 视线被阻挡
                end
                
                % 更新当前位置
                current_x = next_x;
                current_y = next_y;
            end
        end
        
        function earth_curv = calculateEarthCurvature(obj, distance)
            % 计算地球曲率影响
            % 输入参数:
            %   distance - 水平距离 (m)
            % 返回值:
            %   earth_curv - 地球曲率修正值 (m)
            
            % 地球半径 (m)
            earth_radius = 6371000;
            
            % 计算地球曲率和大气折射的综合影响
            earth_curv = (1 - obj.refraction_coef) * (distance^2) / (2 * earth_radius);
        end
        
        function vis_factor = calculateVisibilityFactor(obj, distance)
            % 计算可见度因子
            % 输入参数:
            %   distance - 距离 (m)
            % 返回值:
            %   vis_factor - 可见度因子 [0,1]
            
            % 考虑距离衰减和大气能见度的影响
            vis_factor = exp(-distance / obj.visibility);
        end
        
        function quality = calculateVisualQuality(obj, viewshed, landcover)
            % 计算视觉质量
            % 输入参数:
            %   viewshed - 视域矩阵
            %   landcover - 土地覆盖类型
            % 返回值:
            %   quality - 视觉质量评分矩阵
            
            % 初始化视觉质量矩阵
            quality = zeros(size(viewshed));
            
            % 设置不同土地覆盖类型的视觉质量权重
            weights = containers.Map();
            weights('forest') = 1.0;      % 森林
            weights('water') = 0.9;       % 水体
            weights('grassland') = 0.8;   % 草地
            weights('agriculture') = 0.6;  % 农田
            weights('urban') = 0.4;       % 城市
            weights('barren') = 0.3;      % 裸地
            
            % 计算视觉质量
            for i = 1:size(viewshed, 1)
                for j = 1:size(viewshed, 2)
                    if viewshed(i,j)
                        % 获取土地覆盖类型
                        cover_type = landcover(i,j);
                        
                        % 应用权重
                        if isKey(weights, cover_type)
                            quality(i,j) = weights(cover_type);
                        end
                    end
                end
            end
        end
        
        function visualizeResults(obj, viewshed, quality)
            % 可视化结果
            figure('Name', 'Line of Sight Analysis Results');
            
            % 视域范围
            subplot(2,2,1);
            imagesc(viewshed);
            colormap(gca, [1 1 1; 0 0.7 0]);  % 白色表示不可见，绿色表示可见
            colorbar;
            title('视域范围');
            
            % 高程模型
            subplot(2,2,2);
            imagesc(obj.dem);
            colormap(gca, jet);
            colorbar;
            title('数字高程模型');
            
            % 视觉质量
            subplot(2,2,3);
            imagesc(quality);
            colormap(gca, jet);
            colorbar;
            title('视觉质量评分');
            
            % 土地覆盖
            subplot(2,2,4);
            imagesc(obj.landcover);
            colormap(gca, jet);
            colorbar;
            title('土地覆盖类型');
        end
    end
end 