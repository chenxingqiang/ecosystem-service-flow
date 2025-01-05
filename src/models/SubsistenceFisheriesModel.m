classdef SubsistenceFisheriesModel < handle
    % SubsistenceFisheriesModel 生计渔业模型
    % 实现基于SPAN模型的渔业资源服务评估
    
    properties
        % 输入数据层
        bathymetry      % 水深测量数据
        temperature    % 水温数据
        salinity       % 盐度数据
        nutrients      % 营养物质数据
        habitats       % 栖息地类型
        
        % 网格参数
        cell_width      % 网格宽度 (m)
        cell_height     % 网格高度 (m)
        
        % 渔业参数
        fish_species    % 鱼类物种特征
        growth_rates    % 生长速率
        mortality_rates % 死亡率
        carrying_capacity % 环境容量
        migration_rates  % 迁移率
        
        % 捕捞参数
        fishing_effort  % 捕捞努力量
        catch_efficiency % 捕捞效率
        gear_selectivity % 渔具选择性
        seasonal_limits  % 季节性限制
    end
    
    methods
        function obj = SubsistenceFisheriesModel(bathymetry_data, temperature_data, ...
                salinity_data, nutrients_data, habitats_data, varargin)
            % 构造函数
            % 输入参数:
            %   bathymetry_data - 水深测量数据
            %   temperature_data - 水温数据
            %   salinity_data - 盐度数据
            %   nutrients_data - 营养物质数据
            %   habitats_data - 栖息地类型数据
            %   varargin - 可选参数
            
            % 验证输入数据
            validateattributes(bathymetry_data, {'numeric'}, {'2d'});
            validateattributes(temperature_data, {'numeric'}, {'2d', 'size', size(bathymetry_data)});
            validateattributes(salinity_data, {'numeric'}, {'2d', 'size', size(bathymetry_data)});
            validateattributes(nutrients_data, {'numeric'}, {'2d', 'size', size(bathymetry_data)});
            validateattributes(habitats_data, {'numeric'}, {'2d', 'size', size(bathymetry_data)});
            
            % 存储输入数据
            obj.bathymetry = bathymetry_data;
            obj.temperature = temperature_data;
            obj.salinity = salinity_data;
            obj.nutrients = nutrients_data;
            obj.habitats = habitats_data;
            
            % 设置默认参数
            obj.cell_width = 30;     % 默认30米分辨率
            obj.cell_height = 30;
            
            % 初始化渔业参数
            obj.initializeFisheryParameters();
            
            % 处理可选参数
            if nargin > 5
                for i = 1:2:length(varargin)
                    switch lower(varargin{i})
                        case 'cell_width'
                            obj.cell_width = varargin{i+1};
                        case 'cell_height'
                            obj.cell_height = varargin{i+1};
                    end
                end
            end
        end
        
        function initializeFisheryParameters(obj)
            % 初始化渔业参数
            
            % 设置鱼类物种特征
            obj.fish_species = containers.Map();
            obj.fish_species('species1') = struct(...
                'name', '鲫鱼', ...
                'optimal_temp', 25, ...
                'optimal_depth', 5, ...
                'optimal_salinity', 0);
            obj.fish_species('species2') = struct(...
                'name', '鲤鱼', ...
                'optimal_temp', 23, ...
                'optimal_depth', 3, ...
                'optimal_salinity', 0);
            obj.fish_species('species3') = struct(...
                'name', '草鱼', ...
                'optimal_temp', 28, ...
                'optimal_depth', 2, ...
                'optimal_salinity', 0);
            
            % 设置生长率
            obj.growth_rates = containers.Map();
            obj.growth_rates('species1') = 0.3;
            obj.growth_rates('species2') = 0.25;
            obj.growth_rates('species3') = 0.35;
            
            % 设置死亡率
            obj.mortality_rates = containers.Map();
            obj.mortality_rates('species1') = 0.1;
            obj.mortality_rates('species2') = 0.12;
            obj.mortality_rates('species3') = 0.15;
            
            % 设置环境容量
            obj.carrying_capacity = containers.Map();
            obj.carrying_capacity('species1') = 1000;
            obj.carrying_capacity('species2') = 800;
            obj.carrying_capacity('species3') = 1200;
            
            % 设置迁移率
            obj.migration_rates = containers.Map();
            obj.migration_rates('species1') = 0.2;
            obj.migration_rates('species2') = 0.15;
            obj.migration_rates('species3') = 0.25;
            
            % 设置捕捞参数
            obj.fishing_effort = zeros(size(obj.bathymetry));
            obj.catch_efficiency = 0.3;
            obj.gear_selectivity = containers.Map();
            obj.gear_selectivity('net') = 0.8;
            obj.gear_selectivity('trap') = 0.6;
            obj.gear_selectivity('line') = 0.4;
            
            % 设置季节性限制
            obj.seasonal_limits = containers.Map();
            obj.seasonal_limits('spring') = 0.8;
            obj.seasonal_limits('summer') = 1.0;
            obj.seasonal_limits('autumn') = 0.9;
            obj.seasonal_limits('winter') = 0.6;
        end
        
        function [fish_abundance, catch_potential] = calculateFisheryYield(obj)
            % 计算渔业产量
            % 返回值:
            %   fish_abundance - 鱼类丰度矩阵
            %   catch_potential - 捕捞潜力矩阵
            
            % 获取数据尺寸
            [rows, cols] = size(obj.bathymetry);
            
            % 初始化结果矩阵
            fish_abundance = zeros(rows, cols);
            catch_potential = zeros(rows, cols);
            
            % 计算栖息地适宜性
            habitat_suitability = obj.calculateHabitatSuitability();
            
            % 计算环境压力
            environmental_stress = obj.calculateEnvironmentalStress();
            
            % 计算种群动态
            population_dynamics = obj.calculatePopulationDynamics(habitat_suitability);
            
            % 计算捕捞压力
            fishing_pressure = obj.calculateFishingPressure();
            
            % 综合计算鱼类丰度
            fish_abundance = population_dynamics .* (1 - environmental_stress);
            
            % 计算捕捞潜力
            catch_potential = fish_abundance .* fishing_pressure .* obj.catch_efficiency;
        end
        
        function habitat_suitability = calculateHabitatSuitability(obj)
            % 计算栖息地适宜性
            % 返回值:
            %   habitat_suitability - 栖息地适宜性矩阵 [0,1]
            
            [rows, cols] = size(obj.bathymetry);
            habitat_suitability = zeros(rows, cols);
            
            % 计算每个网格的栖息地适宜性
            for i = 1:rows
                for j = 1:cols
                    % 水深适宜性
                    depth_suitability = obj.calculateDepthSuitability(i, j);
                    
                    % 温度适宜性
                    temp_suitability = obj.calculateTemperatureSuitability(i, j);
                    
                    % 盐度适宜性
                    salinity_suitability = obj.calculateSalinitySuitability(i, j);
                    
                    % 营养条件适宜性
                    nutrient_suitability = obj.calculateNutrientSuitability(i, j);
                    
                    % 综合计算适宜性
                    habitat_suitability(i,j) = min([depth_suitability, ...
                        temp_suitability, salinity_suitability, nutrient_suitability]);
                end
            end
        end
        
        function environmental_stress = calculateEnvironmentalStress(obj)
            % 计算环境压力
            % 返回值:
            %   environmental_stress - 环境压力矩阵 [0,1]
            
            [rows, cols] = size(obj.bathymetry);
            environmental_stress = zeros(rows, cols);
            
            % 计算温度压力
            temp_stress = abs(obj.temperature - 25) / 15;  % 假设25℃为最适温度
            temp_stress = min(1, max(0, temp_stress));
            
            % 计算盐度压力
            salinity_stress = abs(obj.salinity - 30) / 30;  % 假设30‰为最适盐度
            salinity_stress = min(1, max(0, salinity_stress));
            
            % 计算营养压力
            nutrient_stress = 1 - obj.nutrients / max(obj.nutrients(:));
            
            % 综合环境压力
            environmental_stress = max(max(temp_stress, salinity_stress), nutrient_stress);
        end
        
        function population_dynamics = calculatePopulationDynamics(obj, habitat_suitability)
            % 计算种群动态
            % 输入参数:
            %   habitat_suitability - 栖息地适宜性矩阵
            % 返回值:
            %   population_dynamics - 种群动态矩阵
            
            [rows, cols] = size(obj.bathymetry);
            population_dynamics = zeros(rows, cols);
            
            % 计算每个物种的种群动态
            for species_key = keys(obj.fish_species)
                species = species_key{1};
                
                % 获取物种参数
                growth_rate = obj.growth_rates(species);
                mortality_rate = obj.mortality_rates(species);
                carrying_cap = obj.carrying_capacity(species);
                migration_rate = obj.migration_rates(species);
                
                % 计算种群变化
                for i = 1:rows
                    for j = 1:cols
                        % 基础增长
                        growth = growth_rate * habitat_suitability(i,j);
                        
                        % 密度依赖性死亡
                        mortality = mortality_rate * (1 + population_dynamics(i,j)/carrying_cap);
                        
                        % 迁移
                        migration = obj.calculateMigration(i, j, migration_rate, ...
                            population_dynamics);
                        
                        % 更新种群
                        population_dynamics(i,j) = population_dynamics(i,j) + ...
                            growth - mortality + migration;
                    end
                end
            end
            
            % 确保种群大小非负
            population_dynamics = max(0, population_dynamics);
        end
        
        function fishing_pressure = calculateFishingPressure(obj)
            % 计算捕捞压力
            % 返回值:
            %   fishing_pressure - 捕捞压力矩阵 [0,1]
            
            [rows, cols] = size(obj.bathymetry);
            fishing_pressure = zeros(rows, cols);
            
            % 计算每个网格的捕捞压力
            for i = 1:rows
                for j = 1:cols
                    % 基础捕捞压力
                    base_pressure = obj.fishing_effort(i,j) * obj.catch_efficiency;
                    
                    % 考虑渔具选择性
                    gear_type = obj.getGearType(i, j);
                    if isKey(obj.gear_selectivity, gear_type)
                        base_pressure = base_pressure * obj.gear_selectivity(gear_type);
                    end
                    
                    % 考虑季节性限制
                    season = obj.getCurrentSeason();
                    if isKey(obj.seasonal_limits, season)
                        base_pressure = base_pressure * obj.seasonal_limits(season);
                    end
                    
                    fishing_pressure(i,j) = min(1, base_pressure);
                end
            end
        end
        
        function depth_suitability = calculateDepthSuitability(obj, i, j)
            % 计算水深适宜性
            depth = obj.bathymetry(i,j);
            
            % 计算每个物种的水深适宜性
            depth_suitability = 0;
            for species_key = keys(obj.fish_species)
                species = species_key{1};
                optimal_depth = obj.fish_species(species).optimal_depth;
                
                % 使用高斯函数计算适宜性
                suitability = exp(-(depth - optimal_depth)^2 / (2 * 5^2));
                depth_suitability = max(depth_suitability, suitability);
            end
        end
        
        function temp_suitability = calculateTemperatureSuitability(obj, i, j)
            % 计算温度适宜性
            temp = obj.temperature(i,j);
            
            % 计算每个物种的温度适宜性
            temp_suitability = 0;
            for species_key = keys(obj.fish_species)
                species = species_key{1};
                optimal_temp = obj.fish_species(species).optimal_temp;
                
                % 使用高斯函数计算适宜性
                suitability = exp(-(temp - optimal_temp)^2 / (2 * 3^2));
                temp_suitability = max(temp_suitability, suitability);
            end
        end
        
        function salinity_suitability = calculateSalinitySuitability(obj, i, j)
            % 计算盐度适宜性
            salinity = obj.salinity(i,j);
            
            % 计算每个物种的盐度适宜性
            salinity_suitability = 0;
            for species_key = keys(obj.fish_species)
                species = species_key{1};
                optimal_salinity = obj.fish_species(species).optimal_salinity;
                
                % 使用高斯函数计算适宜性
                suitability = exp(-(salinity - optimal_salinity)^2 / (2 * 5^2));
                salinity_suitability = max(salinity_suitability, suitability);
            end
        end
        
        function nutrient_suitability = calculateNutrientSuitability(obj, i, j)
            % 计算营养条件适宜性
            nutrients = obj.nutrients(i,j);
            
            % 简化的营养适宜性计算
            nutrient_suitability = min(1, nutrients / 100);  % 假设100为最适营养水平
        end
        
        function migration = calculateMigration(obj, i, j, migration_rate, population)
            % 计算迁移量
            [rows, cols] = size(population);
            migration = 0;
            
            % 计算与相邻网格的种群交换
            for di = -1:1
                for dj = -1:1
                    if di == 0 && dj == 0
                        continue;
                    end
                    
                    ni = i + di;
                    nj = j + dj;
                    
                    % 检查边界
                    if ni >= 1 && ni <= rows && nj >= 1 && nj <= cols
                        % 计算迁移量（基于种群差异）
                        pop_diff = population(ni,nj) - population(i,j);
                        migration = migration + migration_rate * pop_diff;
                    end
                end
            end
            
            % 限制迁移量
            migration = migration / 8;  % 平均分配到8个相邻网格
        end
        
        function gear_type = getGearType(obj, i, j)
            % 获取渔具类型
            % 这里使用简化的判断逻辑
            if obj.bathymetry(i,j) < -10
                gear_type = 'net';
            elseif obj.bathymetry(i,j) < -5
                gear_type = 'trap';
            else
                gear_type = 'line';
            end
        end
        
        function season = getCurrentSeason(obj)
            % 获取当前季节
            % 这里使用简化的判断逻辑
            current_month = month(datetime('now'));
            if current_month >= 3 && current_month <= 5
                season = 'spring';
            elseif current_month >= 6 && current_month <= 8
                season = 'summer';
            elseif current_month >= 9 && current_month <= 11
                season = 'autumn';
            else
                season = 'winter';
            end
        end
        
        function visualizeResults(obj, fish_abundance, catch_potential)
            % 可视化结果
            figure('Name', 'Subsistence Fisheries Analysis');
            
            % 鱼类丰度
            subplot(2,2,1);
            imagesc(fish_abundance);
            colormap(gca, jet);
            colorbar;
            title('鱼类丰度');
            
            % 捕捞潜力
            subplot(2,2,2);
            imagesc(catch_potential);
            colormap(gca, jet);
            colorbar;
            title('捕捞潜力');
            
            % 栖息地适宜性
            subplot(2,2,3);
            habitat_suitability = obj.calculateHabitatSuitability();
            imagesc(habitat_suitability);
            colormap(gca, jet);
            colorbar;
            title('栖息地适宜性');
            
            % 环境压力
            subplot(2,2,4);
            environmental_stress = obj.calculateEnvironmentalStress();
            imagesc(environmental_stress);
            colormap(gca, jet);
            colorbar;
            title('环境压力');
        end
        
        function service_flow = calculateServiceFlow(obj, source_strength, ...
                sink_capacity, fish_abundance)
            % 计算服务流动
            % 输入参数:
            %   source_strength - 源强度（渔业资源强度）
            %   sink_capacity - 汇容量（捕捞需求）
            %   fish_abundance - 鱼类丰度
            % 返回值:
            %   service_flow - 服务流动量
            
            % 计算潜在流动量
            potential_flow = source_strength .* fish_abundance;
            
            % 考虑汇的容量限制
            service_flow = min(potential_flow, sink_capacity);
        end
    end
end 