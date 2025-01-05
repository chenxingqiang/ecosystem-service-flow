classdef CoastalStormProtectionModel < handle
    % CoastalStormProtectionModel 海岸风暴防护模型
    % 实现基于SPAN模型的海岸防护服务评估
    
    properties
        % 输入数据层
        dem              % 数字高程模型
        bathymetry      % 水深测量数据
        landcover       % 土地覆盖
        coastal_type    % 海岸类型
        
        % 网格参数
        cell_width      % 网格宽度 (m)
        cell_height     % 网格高度 (m)
        
        % 风暴参数
        storm_intensity   % 风暴强度 (1-5级)
        storm_duration    % 风暴持续时间 (h)
        storm_surge      % 风暴潮高度 (m)
        wave_height      % 波浪高度 (m)
        wind_speed       % 风速 (m/s)
        wind_direction   % 风向 (度)
        
        % 防护参数
        vegetation_factors    % 不同植被类型的防护系数
        coastal_structures    % 海岸防护设施
        protection_threshold  % 防护阈值
    end
    
    methods
        function obj = CoastalStormProtectionModel(dem_data, bathymetry_data, ...
                landcover_data, coastal_type_data, varargin)
            % 构造函数
            % 输入参数:
            %   dem_data - 数字高程模型数据
            %   bathymetry_data - 水深测量数据
            %   landcover_data - 土地覆盖数据
            %   coastal_type_data - 海岸类型数据
            %   varargin - 可选参数
            
            % 验证输入数据
            validateattributes(dem_data, {'numeric'}, {'2d'});
            validateattributes(bathymetry_data, {'numeric'}, {'2d', 'size', size(dem_data)});
            validateattributes(landcover_data, {'numeric'}, {'2d', 'size', size(dem_data)});
            validateattributes(coastal_type_data, {'numeric'}, {'2d', 'size', size(dem_data)});
            
            % 存储输入数据
            obj.dem = dem_data;
            obj.bathymetry = bathymetry_data;
            obj.landcover = landcover_data;
            obj.coastal_type = coastal_type_data;
            
            % 设置默认参数
            obj.cell_width = 30;     % 默认30米分辨率
            obj.cell_height = 30;
            
            % 设置默认风暴参数
            obj.storm_intensity = 3;  % 默认3级风暴
            obj.storm_duration = 24;  % 默认24小时
            obj.storm_surge = 3;      % 默认3米风暴潮
            obj.wave_height = 5;      % 默认5米波浪
            obj.wind_speed = 30;      % 默认30m/s风速
            obj.wind_direction = 90;   % 默认东风
            
            % 初始化防护参数
            obj.initializeProtectionParameters();
            
            % 处理可选参数
            if nargin > 4
                for i = 1:2:length(varargin)
                    switch lower(varargin{i})
                        case 'cell_width'
                            obj.cell_width = varargin{i+1};
                        case 'cell_height'
                            obj.cell_height = varargin{i+1};
                        case 'storm_intensity'
                            obj.storm_intensity = varargin{i+1};
                        case 'storm_duration'
                            obj.storm_duration = varargin{i+1};
                        case 'storm_surge'
                            obj.storm_surge = varargin{i+1};
                        case 'wave_height'
                            obj.wave_height = varargin{i+1};
                        case 'wind_speed'
                            obj.wind_speed = varargin{i+1};
                        case 'wind_direction'
                            obj.wind_direction = varargin{i+1};
                    end
                end
            end
        end
        
        function initializeProtectionParameters(obj)
            % 初始化防护参数
            
            % 设置不同植被类型的防护系数
            obj.vegetation_factors = containers.Map();
            obj.vegetation_factors('mangrove') = 0.8;     % 红树林
            obj.vegetation_factors('seagrass') = 0.6;     % 海草床
            obj.vegetation_factors('marsh') = 0.7;        % 盐沼
            obj.vegetation_factors('coral') = 0.9;        % 珊瑚礁
            obj.vegetation_factors('forest') = 0.5;       % 海岸林
            obj.vegetation_factors('dune') = 0.4;         % 沙丘植被
            
            % 设置防护阈值
            obj.protection_threshold = 0.3;  % 默认防护阈值
        end
        
        function [protection_level, inundation_risk] = calculateProtection(obj)
            % 计算防护等级和淹没风险
            % 返回值:
            %   protection_level - 防护等级矩阵 [0,1]
            %   inundation_risk - 淹没风险矩阵 [0,1]
            
            % 获取数据尺寸
            [rows, cols] = size(obj.dem);
            
            % 初始化结果矩阵
            protection_level = zeros(rows, cols);
            inundation_risk = ones(rows, cols);
            
            % 计算地形防护
            terrain_protection = obj.calculateTerrainProtection();
            
            % 计算植被防护
            vegetation_protection = obj.calculateVegetationProtection();
            
            % 计算结构防护
            structure_protection = obj.calculateStructureProtection();
            
            % 综合计算防护等级
            protection_level = max(max(terrain_protection, vegetation_protection), ...
                structure_protection);
            
            % 计算淹没风险
            inundation_risk = obj.calculateInundationRisk(protection_level);
        end
        
        function terrain_protection = calculateTerrainProtection(obj)
            % 计算地形防护能力
            % 返回值:
            %   terrain_protection - 地形防护等级矩阵 [0,1]
            
            % 获取数据尺寸
            [rows, cols] = size(obj.dem);
            terrain_protection = zeros(rows, cols);
            
            % 计算坡度
            [slope, aspect] = obj.calculateSlopeAspect();
            
            % 考虑高程和坡度的影响
            for i = 1:rows
                for j = 1:cols
                    % 高程防护
                    elev_factor = min(1, max(0, (obj.dem(i,j) - obj.storm_surge) / 10));
                    
                    % 坡度防护
                    slope_factor = min(1, slope(i,j) / 45);  % 45度为最大防护坡度
                    
                    % 计算地形防护系数
                    terrain_protection(i,j) = max(elev_factor, slope_factor);
                end
            end
        end
        
        function vegetation_protection = calculateVegetationProtection(obj)
            % 计算植被防护能力
            % 返回值:
            %   vegetation_protection - 植被防护等级矩阵 [0,1]
            
            % 获取数据尺寸
            [rows, cols] = size(obj.landcover);
            vegetation_protection = zeros(rows, cols);
            
            % 计算每个网格的植被防护能力
            for i = 1:rows
                for j = 1:cols
                    % 获取植被类型
                    veg_type = obj.getVegetationType(i, j);
                    
                    % 应用植被防护系数
                    if isKey(obj.vegetation_factors, veg_type)
                        vegetation_protection(i,j) = obj.vegetation_factors(veg_type);
                    end
                end
            end
            
            % 考虑植被密度和健康状况
            vegetation_protection = vegetation_protection .* ...
                obj.calculateVegetationDensity();
        end
        
        function structure_protection = calculateStructureProtection(obj)
            % 计算结构防护能力
            % 返回值:
            %   structure_protection - 结构防护等级矩阵 [0,1]
            
            % 获取数据尺寸
            [rows, cols] = size(obj.coastal_structures);
            structure_protection = zeros(rows, cols);
            
            % 计算每个网格的结构防护能力
            for i = 1:rows
                for j = 1:cols
                    % 获取结构类型
                    struct_type = obj.getStructureType(i, j);
                    
                    % 根据结构类型设置防护等级
                    switch struct_type
                        case 'seawall'
                            structure_protection(i,j) = 0.9;
                        case 'breakwater'
                            structure_protection(i,j) = 0.8;
                        case 'groin'
                            structure_protection(i,j) = 0.6;
                        case 'revetment'
                            structure_protection(i,j) = 0.7;
                    end
                end
            end
        end
        
        function inundation_risk = calculateInundationRisk(obj, protection_level)
            % 计算淹没风险
            % 输入参数:
            %   protection_level - 防护等级矩阵
            % 返回值:
            %   inundation_risk - 淹没风险矩阵 [0,1]
            
            % 获取数据尺寸
            [rows, cols] = size(obj.dem);
            inundation_risk = ones(rows, cols);
            
            % 计算暴露度
            exposure = obj.calculateExposure();
            
            % 计算脆弱性
            vulnerability = obj.calculateVulnerability();
            
            % 综合计算淹没风险
            for i = 1:rows
                for j = 1:cols
                    % 考虑防护等级
                    if protection_level(i,j) >= obj.protection_threshold
                        risk_reduction = (protection_level(i,j) - obj.protection_threshold) / ...
                            (1 - obj.protection_threshold);
                        inundation_risk(i,j) = exposure(i,j) * vulnerability(i,j) * ...
                            (1 - risk_reduction);
                    else
                        inundation_risk(i,j) = exposure(i,j) * vulnerability(i,j);
                    end
                end
            end
        end
        
        function exposure = calculateExposure(obj)
            % 计算暴露度
            % 返回值:
            %   exposure - 暴露度矩阵 [0,1]
            
            % 获取数据尺寸
            [rows, cols] = size(obj.dem);
            exposure = zeros(rows, cols);
            
            % 计算距离海岸线的距离
            coast_distance = obj.calculateCoastDistance();
            
            % 计算地形暴露度
            for i = 1:rows
                for j = 1:cols
                    % 考虑高程
                    elev_exposure = max(0, min(1, 1 - (obj.dem(i,j) / 10)));
                    
                    % 考虑距离衰减
                    dist_factor = exp(-coast_distance(i,j) / 1000);  % 1km特征距离
                    
                    % 综合计算暴露度
                    exposure(i,j) = elev_exposure * dist_factor;
                end
            end
            
            % 考虑风向影响
            exposure = exposure .* obj.calculateWindExposure();
        end
        
        function vulnerability = calculateVulnerability(obj)
            % 计算脆弱性
            % 返回值:
            %   vulnerability - 脆弱性矩阵 [0,1]
            
            % 获取数据尺寸
            [rows, cols] = size(obj.dem);
            vulnerability = zeros(rows, cols);
            
            % 计算每个网格的脆弱性
            for i = 1:rows
                for j = 1:cols
                    % 获取土地类型
                    land_type = obj.getLandType(i, j);
                    
                    % 根据土地类型设置基础脆弱性
                    switch land_type
                        case 'urban'
                            vulnerability(i,j) = 0.9;
                        case 'agriculture'
                            vulnerability(i,j) = 0.7;
                        case 'forest'
                            vulnerability(i,j) = 0.4;
                        case 'wetland'
                            vulnerability(i,j) = 0.5;
                        case 'barren'
                            vulnerability(i,j) = 0.3;
                    end
                end
            end
            
            % 考虑坡度影响
            [slope, ~] = obj.calculateSlopeAspect();
            slope_factor = 1 ./ (1 + slope/10);  % 坡度越大，脆弱性越小
            vulnerability = vulnerability .* slope_factor;
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
        
        function wind_exposure = calculateWindExposure(obj)
            % 计算风向暴露度
            % 返回值:
            %   wind_exposure - 风向暴露度矩阵 [0,1]
            
            [rows, cols] = size(obj.dem);
            wind_exposure = ones(rows, cols);
            
            % 计算每个网格相对于风向的暴露度
            for i = 1:rows
                for j = 1:cols
                    % 计算网格与风向的夹角
                    [~, aspect] = obj.calculateSlopeAspect();
                    angle_diff = abs(aspect(i,j) - obj.wind_direction);
                    if angle_diff > 180
                        angle_diff = 360 - angle_diff;
                    end
                    
                    % 计算暴露系数
                    wind_exposure(i,j) = cosd(angle_diff);
                end
            end
            
            % 标准化到[0,1]区间
            wind_exposure = max(0, wind_exposure);
        end
        
        function coast_distance = calculateCoastDistance(obj)
            % 计算到海岸线的距离
            % 返回值:
            %   coast_distance - 距离矩阵 (m)
            
            % 识别海岸线
            coastline = obj.identifyCoastline();
            
            % 计算距离变换
            coast_distance = bwdist(coastline) * obj.cell_width;
        end
        
        function coastline = identifyCoastline(obj)
            % 识别海岸线
            % 返回值:
            %   coastline - 海岸线二值图
            
            [rows, cols] = size(obj.dem);
            coastline = false(rows, cols);
            
            % 识别陆地和水体的交界处
            for i = 2:rows-1
                for j = 2:cols-1
                    if obj.bathymetry(i,j) >= 0 && ...
                            any(obj.bathymetry(i-1:i+1,j-1:j+1) < 0)
                        coastline(i,j) = true;
                    end
                end
            end
        end
        
        function veg_density = calculateVegetationDensity(obj)
            % 计算植被密度
            % 返回值:
            %   veg_density - 植被密度矩阵 [0,1]
            
            % 这里使用简化的计算方法
            % 实际应用中可能需要更复杂的植被指数计算
            [rows, cols] = size(obj.landcover);
            veg_density = zeros(rows, cols);
            
            for i = 1:rows
                for j = 1:cols
                    veg_type = obj.getVegetationType(i, j);
                    if isKey(obj.vegetation_factors, veg_type)
                        veg_density(i,j) = 0.8;  % 假设标准密度
                    end
                end
            end
        end
        
        function veg_type = getVegetationType(obj, i, j)
            % 获取植被类型
            veg_type = 'none';  % 默认无植被
            
            % 根据土地覆盖数据获取植被类型
            landcover_code = obj.landcover(i,j);
            switch landcover_code
                case 1
                    veg_type = 'mangrove';
                case 2
                    veg_type = 'seagrass';
                case 3
                    veg_type = 'marsh';
                case 4
                    veg_type = 'coral';
                case 5
                    veg_type = 'forest';
                case 6
                    veg_type = 'dune';
            end
        end
        
        function struct_type = getStructureType(obj, i, j)
            % 获取结构类型
            struct_type = 'none';  % 默认无结构
            
            % 根据海岸结构数据获取结构类型
            if obj.coastal_structures(i,j) > 0
                switch obj.coastal_structures(i,j)
                    case 1
                        struct_type = 'seawall';
                    case 2
                        struct_type = 'breakwater';
                    case 3
                        struct_type = 'groin';
                    case 4
                        struct_type = 'revetment';
                end
            end
        end
        
        function land_type = getLandType(obj, i, j)
            % 获取土地类型
            land_type = 'barren';  % 默认类型
            
            % 根据土地覆盖数据获取土地类型
            landcover_code = obj.landcover(i,j);
            switch landcover_code
                case 1
                    land_type = 'urban';
                case 2
                    land_type = 'agriculture';
                case 3
                    land_type = 'forest';
                case 4
                    land_type = 'wetland';
                case 5
                    land_type = 'barren';
            end
        end
        
        function visualizeResults(obj, protection_level, inundation_risk)
            % 可视化结果
            figure('Name', 'Coastal Storm Protection Analysis');
            
            % 防护等级
            subplot(2,2,1);
            imagesc(protection_level);
            colormap(gca, jet);
            colorbar;
            title('防护等级');
            
            % 淹没风险
            subplot(2,2,2);
            imagesc(inundation_risk);
            colormap(gca, jet);
            colorbar;
            title('淹没风险');
            
            % 地形和水深
            subplot(2,2,3);
            combined_elev = obj.dem;
            combined_elev(obj.bathymetry < 0) = obj.bathymetry(obj.bathymetry < 0);
            imagesc(combined_elev);
            colormap(gca, jet);
            colorbar;
            title('地形和水深');
            
            % 植被覆盖
            subplot(2,2,4);
            imagesc(obj.landcover);
            colormap(gca, jet);
            colorbar;
            title('植被覆盖');
        end
        
        function service_flow = calculateServiceFlow(obj, source_strength, ...
                sink_capacity, protection_level)
            % 计算服务流动
            % 输入参数:
            %   source_strength - 源强度（防护要素强度）
            %   sink_capacity - 汇容量（防护需求）
            %   protection_level - 防护等级
            % 返回值:
            %   service_flow - 服务流动量
            
            % 计算潜在流动量
            potential_flow = source_strength .* protection_level;
            
            % 考虑汇的容量限制
            service_flow = min(potential_flow, sink_capacity);
        end
    end
end 