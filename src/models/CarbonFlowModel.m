classdef CarbonFlowModel < handle
    % CarbonFlowModel 碳流动模型
    % 实现基于SPAN模型的碳固定服务流动评估
    
    properties
        % 输入数据层
        vegetation_cover  % 植被覆盖
        productivity     % 生产力
        climate_factor   % 气候因子
        soil_factor      % 土壤因子
        
        % 模型参数
        carbon_rate      % 碳固定速率 (tC/ha/year)
        turnover_rate    % 碳周转率
        storage_capacity % 碳储存容量
    end
    
    methods
        function obj = CarbonFlowModel(flow_data)
            % 构造函数
            % 输入参数:
            %   flow_data - 包含所有环境因子的数据层 [rows x cols x layers]
            
            % 验证输入数据
            validateattributes(flow_data, {'numeric'}, {'3d'});
            assert(size(flow_data, 3) >= 4, '碳流动模型需要至少4个数据层');
            
            % 提取数据层
            obj.vegetation_cover = flow_data(:,:,1);
            obj.productivity = flow_data(:,:,2);
            obj.climate_factor = flow_data(:,:,3);
            obj.soil_factor = flow_data(:,:,4);
            
            % 设置默认参数
            obj.carbon_rate = 2.5;      % 平均碳固定速率 (tC/ha/year)
            obj.turnover_rate = 0.1;    % 年碳周转率
            obj.storage_capacity = 200;  % 最大碳储存容量 (tC/ha)
        end
        
        function [theoretical_flow, actual_flow] = calculateFlow(obj, source_data)
            % 计算碳流动
            % 输入参数:
            %   source_data - 源强度数据
            % 返回值:
            %   theoretical_flow - 理论碳流动
            %   actual_flow - 实际碳流动
            
            % 计算潜在碳固定量
            potential_fixation = obj.carbon_rate .* obj.vegetation_cover .* ...
                obj.productivity .* obj.climate_factor .* obj.soil_factor;
            
            % 计算理论流动量（考虑源强度）
            theoretical_flow = potential_fixation .* source_data;
            
            % 计算实际流动量（考虑储存容量限制）
            storage_limit = obj.storage_capacity .* (1 - exp(-obj.turnover_rate));
            actual_flow = min(theoretical_flow, storage_limit);
        end
        
        function importance = calculateSourceImportance(obj, source_data)
            % 计算源点重要性
            % 输入参数:
            %   source_data - 源强度数据
            % 返回值:
            %   importance - 源点重要性指数
            
            % 计算生态条件适宜性
            suitability = obj.vegetation_cover .* obj.productivity .* ...
                obj.climate_factor .* obj.soil_factor;
            
            % 计算源点对碳固定的贡献
            contribution = source_data .* suitability;
            
            % 计算重要性指数（归一化）
            importance = contribution ./ max(contribution(:));
        end
        
        function efficiency = calculateFixationEfficiency(obj, actual_flow, theoretical_flow)
            % 计算碳固定效率
            % 输入参数:
            %   actual_flow - 实际碳流动
            %   theoretical_flow - 理论碳流动
            % 返回值:
            %   efficiency - 碳固定效率指标
            
            efficiency = struct();
            
            % 计算总量
            efficiency.total_theoretical = sum(theoretical_flow(:));
            efficiency.total_actual = sum(actual_flow(:));
            
            % 计算效率指标
            if efficiency.total_theoretical > 0
                efficiency.fixation_ratio = efficiency.total_actual / ...
                    efficiency.total_theoretical;
            else
                efficiency.fixation_ratio = 0;
            end
            
            % 计算空间分布指标
            efficiency.spatial_heterogeneity = std(actual_flow(:)) / mean(actual_flow(:));
        end
        
        function [carbon_stock, carbon_flux] = simulateCarbonDynamics(obj, ...
                initial_stock, time_steps)
            % 模拟碳储量动态变化
            % 输入参数:
            %   initial_stock - 初始碳储量
            %   time_steps - 模拟时间步长
            % 返回值:
            %   carbon_stock - 碳储量时间序列
            %   carbon_flux - 碳通量时间序列
            
            % 初始化结果数组
            [rows, cols] = size(initial_stock);
            carbon_stock = zeros(rows, cols, time_steps);
            carbon_flux = zeros(rows, cols, time_steps);
            
            % 设置初始状态
            carbon_stock(:,:,1) = initial_stock;
            
            % 时间循环
            for t = 2:time_steps
                % 计算碳输入（固定量）
                [~, carbon_input] = obj.calculateFlow(ones(size(initial_stock)));
                
                % 计算碳输出（分解量）
                carbon_output = carbon_stock(:,:,t-1) * obj.turnover_rate;
                
                % 更新碳储量
                carbon_stock(:,:,t) = carbon_stock(:,:,t-1) + ...
                    carbon_input - carbon_output;
                
                % 记录碳通量
                carbon_flux(:,:,t) = carbon_input - carbon_output;
            end
        end
    end
end 