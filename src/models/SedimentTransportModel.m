classdef SedimentTransportModel < handle
    % SedimentTransportModel 泥沙输移模型
    % 实现基于SPAN模型的泥沙调节服务评估
    
    properties
        % 输入数据层
        dem              % 数字高程模型
        precipitation    % 降水量
        landuse         % 土地利用
        soil_type       % 土壤类型
        vegetation      % 植被覆盖
        
        % 水文模型
        water_model     % 地表水流动模型实例
        
        % 模型参数
        cell_width      % 网格宽度 (m)
        cell_height     % 网格高度 (m)
        time_step      % 时间步长 (s)
        
        % USLE参数
        R_factor       % 降雨侵蚀力因子
        K_factor       % 土壤可蚀性因子
        LS_factor      % 坡长坡度因子
        C_factor       % 植被覆盖因子
        P_factor       % 水土保持措施因子
        
        % 输移参数
        critical_shear_stress  % 临界切应力 (N/m^2)
        settling_velocity     % 沉降速度 (m/s)
        erosion_rate         % 侵蚀率系数
        deposition_rate      % 沉积率系数
    end
    
    methods
        function obj = SedimentTransportModel(flow_data, water_model, varargin)
            % 构造函数
            % 输入参数:
            %   flow_data - 包含所有环境因子的数据层 [rows x cols x layers]
            %   water_model - 地表水流动模型实例
            %   varargin - 可选参数
            
            % 验证输入数据
            validateattributes(flow_data, {'numeric'}, {'3d'});
            assert(size(flow_data, 3) >= 5, '泥沙输移模型需要至少5个数据层');
            
            % 提取数据层
            obj.dem = flow_data(:,:,1);
            obj.precipitation = flow_data(:,:,2);
            obj.landuse = flow_data(:,:,3);
            obj.soil_type = flow_data(:,:,4);
            obj.vegetation = flow_data(:,:,5);
            
            % 存储水文模型实例
            obj.water_model = water_model;
            
            % 设置默认参数
            obj.cell_width = water_model.cell_width;
            obj.cell_height = water_model.cell_height;
            obj.time_step = water_model.time_step;
            
            % 设置默认USLE参数
            obj.initializeUSLEFactors();
            
            % 设置默认输移参数
            obj.critical_shear_stress = 0.1;  % N/m^2
            obj.settling_velocity = 0.001;    % m/s
            obj.erosion_rate = 0.0001;       % kg/m^2/s
            obj.deposition_rate = 0.001;      % kg/m^2/s
            
            % 处理可选参数
            if nargin > 2
                for i = 1:2:length(varargin)
                    switch lower(varargin{i})
                        case 'critical_shear_stress'
                            obj.critical_shear_stress = varargin{i+1};
                        case 'settling_velocity'
                            obj.settling_velocity = varargin{i+1};
                        case 'erosion_rate'
                            obj.erosion_rate = varargin{i+1};
                        case 'deposition_rate'
                            obj.deposition_rate = varargin{i+1};
                    end
                end
            end
        end
        
        function initializeUSLEFactors(obj)
            % 初始化USLE因子
            
            % 计算R因子（基于降雨量）
            obj.R_factor = 0.548 * obj.precipitation;  % 简化计算
            
            % 设置K因子（基于土壤类型）
            obj.K_factor = zeros(size(obj.soil_type));
            obj.K_factor(obj.soil_type == 1) = 0.45;  % 粘土
            obj.K_factor(obj.soil_type == 2) = 0.30;  % 壤土
            obj.K_factor(obj.soil_type == 3) = 0.15;  % 砂土
            
            % 计算LS因子
            [slope, ~] = obj.water_model.calculateSlopeAspect();
            flow_length = obj.calculateFlowLength();
            obj.LS_factor = obj.calculateLSFactor(slope, flow_length);
            
            % 设置C因子（基于植被覆盖）
            obj.C_factor = exp(-0.0456 * obj.vegetation);
            
            % 设置P因子（基于土地利用）
            obj.P_factor = ones(size(obj.landuse));
            obj.P_factor(obj.landuse == 1) = 0.2;  % 森林
            obj.P_factor(obj.landuse == 2) = 0.5;  % 草地
            obj.P_factor(obj.landuse == 3) = 0.8;  % 农田
            obj.P_factor(obj.landuse == 4) = 1.0;  % 水体
            obj.P_factor(obj.landuse == 5) = 1.0;  % 建设用地
        end
        
        function flow_length = calculateFlowLength(obj)
            % 计算坡长
            [flow_direction, ~] = obj.water_model.calculateFlowDirection();
            [rows, cols] = size(flow_direction);
            flow_length = zeros(rows, cols);
            
            % 计算每个单元格的累积流长
            for i = 1:rows
                for j = 1:cols
                    flow_length(i,j) = obj.traceFlowLength(i, j, flow_direction);
                end
            end
        end
        
        function length = traceFlowLength(obj, i, j, flow_direction)
            % 追踪计算流长
            length = 0;
            current_i = i;
            current_j = j;
            [rows, cols] = size(flow_direction);
            
            while true
                % 获取下游单元格
                [di, dj] = obj.getDownstreamDirection(flow_direction(current_i, current_j));
                next_i = current_i + di;
                next_j = current_j + dj;
                
                % 检查是否到达边界或汇流点
                if next_i < 1 || next_i > rows || next_j < 1 || next_j > cols
                    break;
                end
                
                % 累加流长
                length = length + sqrt(di^2 + dj^2) * obj.cell_width;
                
                % 更新当前位置
                current_i = next_i;
                current_j = next_j;
            end
        end
        
        function [di, dj] = getDownstreamDirection(obj, direction)
            % 获取下游方向
            dir_map = [-1 -1; -1 0; -1 1; 0 -1; 0 0; 0 1; 1 -1; 1 0; 1 1];
            di = dir_map(direction, 1);
            dj = dir_map(direction, 2);
        end
        
        function LS = calculateLSFactor(obj, slope, flow_length)
            % 计算LS因子
            % LS = (λ/22.13)^m * (sin(θ)/0.0896)^n
            % λ为坡长(m)，θ为坡度(度)
            % m和n为经验参数
            
            m = 0.5;  % 经验参数
            n = 1.3;  % 经验参数
            
            % 计算LS因子
            LS = (flow_length/22.13).^m .* (sind(slope)/0.0896).^n;
        end
        
        function [erosion, deposition] = simulateSedimentTransport(obj, ...
                water_depth, discharge, time_steps)
            % 模拟泥沙输移过程
            % 输入参数:
            %   water_depth - 水深时间序列
            %   discharge - 流量时间序列
            %   time_steps - 模拟时间步数
            % 返回值:
            %   erosion - 侵蚀量时间序列
            %   deposition - 沉积量时间序列
            
            [rows, cols] = size(obj.dem);
            erosion = zeros(rows, cols, time_steps);
            deposition = zeros(rows, cols, time_steps);
            
            % 计算USLE潜在侵蚀量
            potential_erosion = obj.R_factor .* obj.K_factor .* obj.LS_factor .* ...
                obj.C_factor .* obj.P_factor;
            
            % 获取水文参数
            [slope, ~] = obj.water_model.calculateSlopeAspect();
            [~, flow_accumulation] = obj.water_model.calculateFlowDirection();
            
            % 时间循环
            for t = 1:time_steps
                % 计算水动力参数
                [shear_stress, stream_power] = obj.calculateHydraulicParameters(...
                    water_depth(:,:,t), discharge(:,:,t), slope);
                
                % 计算实际侵蚀和沉积
                for i = 2:rows-1
                    for j = 2:cols-1
                        % 计算侵蚀量
                        if shear_stress(i,j) > obj.critical_shear_stress
                            erosion(i,j,t) = min(potential_erosion(i,j), ...
                                obj.erosion_rate * (shear_stress(i,j) - ...
                                obj.critical_shear_stress) * obj.time_step);
                        end
                        
                        % 计算沉积量
                        if water_depth(i,j,t) > 0
                            settling_flux = obj.settling_velocity * ...
                                flow_accumulation(i,j) / (water_depth(i,j,t) + eps);
                            deposition(i,j,t) = obj.deposition_rate * ...
                                settling_flux * obj.time_step;
                        end
                    end
                end
            end
        end
        
        function [shear_stress, stream_power] = calculateHydraulicParameters(...
                obj, water_depth, discharge, slope)
            % 计算水动力参数
            % 输入参数:
            %   water_depth - 水深矩阵
            %   discharge - 流量矩阵
            %   slope - 坡度矩阵
            % 返回值:
            %   shear_stress - 切应力矩阵 (N/m^2)
            %   stream_power - 流水功率矩阵 (W/m^2)
            
            % 水的密度 (kg/m^3)
            rho = 1000;
            
            % 重力加速度 (m/s^2)
            g = 9.81;
            
            % 计算切应力 τ = ρgh*S
            shear_stress = rho * g * water_depth .* sind(slope);
            
            % 计算流水功率 Ω = τV
            [velocity, ~] = obj.water_model.calculateFlowVelocity(slope, water_depth);
            stream_power = shear_stress .* velocity;
        end
        
        function sediment_load = calculateSedimentLoad(obj, erosion, deposition)
            % 计算泥沙负荷
            % 输入参数:
            %   erosion - 侵蚀量矩阵
            %   deposition - 沉积量矩阵
            % 返回值:
            %   sediment_load - 泥沙负荷矩阵
            
            % 计算净侵蚀量
            sediment_load = erosion - deposition;
        end
        
        function visualizeResults(obj, erosion, deposition, sediment_load)
            % 可视化结果
            figure('Name', 'Sediment Transport Results');
            
            % 侵蚀量
            subplot(2,2,1);
            imagesc(erosion);
            colormap(gca, jet);
            colorbar;
            title('侵蚀量 (kg/m^2)');
            
            % 沉积量
            subplot(2,2,2);
            imagesc(deposition);
            colormap(gca, jet);
            colorbar;
            title('沉积量 (kg/m^2)');
            
            % 泥沙负荷
            subplot(2,2,3);
            imagesc(sediment_load);
            colormap(gca, jet);
            colorbar;
            title('泥沙负荷 (kg/m^2)');
            
            % 累积流量
            subplot(2,2,4);
            [~, flow_accumulation] = obj.water_model.calculateFlowDirection();
            imagesc(log(flow_accumulation + 1));
            colormap(gca, jet);
            colorbar;
            title('累积流量 (log)');
        end
    end
end 