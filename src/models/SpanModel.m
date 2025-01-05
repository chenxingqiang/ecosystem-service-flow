classdef SpanModel < handle
    % SpanModel 生态系统服务流动模型
    % 实现基于空间流动的生态系统服务评估
    
    properties
        % 输入数据
        source_data      % 源数据
        sink_data       % 汇数据
        use_data        % 使用数据
        flow_data       % 流动数据层
        
        % 模型参数
        source_threshold  % 源阈值
        sink_threshold   % 汇阈值
        use_threshold    % 使用阈值
        trans_threshold  % 传输阈值
        cell_width      % 网格宽度
        cell_height     % 网格高度
        source_type     % 源类型 ('finite' 或 'infinite')
        sink_type       % 汇类型 ('finite' 或 'infinite')
        use_type        % 使用类型 ('finite' 或 'infinite')
        benefit_type    % 收益类型 ('rival' 或 'non-rival')
        flow_model      % 流动模型类型
        
        % 计算结果
        results         % 存储计算结果的结构体
    end
    
    methods
        function obj = SpanModel(source_data, sink_data, use_data, flow_data, varargin)
            % 构造函数
            % 输入参数:
            %   source_data - 源数据矩阵
            %   sink_data - 汇数据矩阵
            %   use_data - 使用数据矩阵
            %   flow_data - 流动数据层
            %   varargin - 名值对参数
            
            % 验证输入数据维度
            validateattributes(source_data, {'numeric'}, {'2d'});
            validateattributes(sink_data, {'numeric'}, {'2d', 'size', size(source_data)});
            validateattributes(use_data, {'numeric'}, {'2d', 'size', size(source_data)});
            validateattributes(flow_data, {'numeric'}, {'3d', 'size', [size(source_data), NaN]});
            
            % 存储输入数据
            obj.source_data = source_data;
            obj.sink_data = sink_data;
            obj.use_data = use_data;
            obj.flow_data = flow_data;
            
            % 设置默认参数
            obj.source_threshold = 0.1;
            obj.sink_threshold = 0.1;
            obj.use_threshold = 0.1;
            obj.trans_threshold = 0.1;
            obj.cell_width = 30;
            obj.cell_height = 30;
            obj.source_type = 'finite';
            obj.sink_type = 'finite';
            obj.use_type = 'finite';
            obj.benefit_type = 'rival';
            obj.flow_model = 'carbon';
            
            % 处理可选参数
            if nargin > 4
                for i = 1:2:length(varargin)
                    switch lower(varargin{i})
                        case 'source_threshold'
                            obj.source_threshold = varargin{i+1};
                        case 'sink_threshold'
                            obj.sink_threshold = varargin{i+1};
                        case 'use_threshold'
                            obj.use_threshold = varargin{i+1};
                        case 'trans_threshold'
                            obj.trans_threshold = varargin{i+1};
                        case 'cell_width'
                            obj.cell_width = varargin{i+1};
                        case 'cell_height'
                            obj.cell_height = varargin{i+1};
                        case 'source_type'
                            obj.source_type = varargin{i+1};
                        case 'sink_type'
                            obj.sink_type = varargin{i+1};
                        case 'use_type'
                            obj.use_type = varargin{i+1};
                        case 'benefit_type'
                            obj.benefit_type = varargin{i+1};
                        case 'flow_model'
                            obj.flow_model = varargin{i+1};
                    end
                end
            end
        end
        
        function results = runModel(obj)
            % 运行SPAN模型
            % 返回值:
            %   results - 包含计算结果的结构体
            
            % 初始化结果结构体
            results = struct();
            results.flow = struct();
            results.summary = struct();
            
            % 根据流动模型类型选择相应的计算方法
            switch lower(obj.flow_model)
                case 'carbon'
                    [flow, summary] = obj.calculateCarbonFlow();
                case 'flood-water'
                    [flow, summary] = obj.calculateFloodWaterFlow();
                case 'surface-water'
                    [flow, summary] = obj.calculateSurfaceWaterFlow();
                case 'sediment'
                    [flow, summary] = obj.calculateSedimentFlow();
                case 'line-of-sight'
                    [flow, summary] = obj.calculateLineOfSightFlow();
                case 'proximity'
                    [flow, summary] = obj.calculateProximityFlow();
                case 'coastal-storm-protection'
                    [flow, summary] = obj.calculateCoastalStormProtectionFlow();
                case 'subsistence-fisheries'
                    [flow, summary] = obj.calculateSubsistenceFisheriesFlow();
                otherwise
                    error('不支持的流动模型类型: %s', obj.flow_model);
            end
            
            % 存储结果
            results.flow = flow;
            results.summary = summary;
            obj.results = results;
        end
        
        function [flow, summary] = calculateCarbonFlow(obj)
            % 计算碳流动
            [flow, summary] = obj.calculateGenericFlow('carbon');
        end
        
        function [flow, summary] = calculateFloodWaterFlow(obj)
            % 计算洪水流动
            [flow, summary] = obj.calculateGenericFlow('flood-water');
        end
        
        function [flow, summary] = calculateSurfaceWaterFlow(obj)
            % 计算地表水流动
            [flow, summary] = obj.calculateGenericFlow('surface-water');
        end
        
        function [flow, summary] = calculateSedimentFlow(obj)
            % 计算泥沙流动
            [flow, summary] = obj.calculateGenericFlow('sediment');
        end
        
        function [flow, summary] = calculateLineOfSightFlow(obj)
            % 计算视线流动
            [flow, summary] = obj.calculateGenericFlow('line-of-sight');
        end
        
        function [flow, summary] = calculateProximityFlow(obj)
            % 计算邻近性流动
            [flow, summary] = obj.calculateGenericFlow('proximity');
        end
        
        function [flow, summary] = calculateCoastalStormProtectionFlow(obj)
            % 计算海岸风暴防护流动
            [flow, summary] = obj.calculateGenericFlow('coastal-storm-protection');
        end
        
        function [flow, summary] = calculateSubsistenceFisheriesFlow(obj)
            % 计算生计渔业流动
            [flow, summary] = obj.calculateGenericFlow('subsistence-fisheries');
        end
        
        function [flow, summary] = calculateGenericFlow(obj, flow_type)
            % 通用流动计算方法
            % 输入参数:
            %   flow_type - 流动类型
            % 返回值:
            %   flow - 流动结果
            %   summary - 汇总统计
            
            % 获取数据维度
            [rows, cols] = size(obj.source_data);
            
            % 应用阈值
            source_mask = obj.source_data >= obj.source_threshold;
            sink_mask = obj.sink_data >= obj.sink_threshold;
            use_mask = obj.use_data >= obj.use_threshold;
            
            % 计算理论流动
            theoretical_flow = zeros(rows, cols);
            for i = 1:size(obj.flow_data, 3)
                theoretical_flow = theoretical_flow + obj.flow_data(:,:,i);
            end
            theoretical_flow = theoretical_flow .* source_mask;
            
            % 计算实际流动
            actual_flow = theoretical_flow;
            if strcmp(obj.source_type, 'finite')
                actual_flow = min(actual_flow, obj.source_data);
            end
            
            % 计算阻滞量
            blocked_flow = zeros(rows, cols);
            if strcmp(obj.sink_type, 'finite')
                blocked_flow = min(actual_flow, obj.sink_data .* sink_mask);
                actual_flow = actual_flow - blocked_flow;
            end
            
            % 计算使用量
            used_flow = zeros(rows, cols);
            if strcmp(obj.benefit_type, 'rival')
                used_flow = min(actual_flow, obj.use_data .* use_mask);
                actual_flow = actual_flow - used_flow;
            else
                used_flow = min(actual_flow, obj.use_data .* use_mask);
            end
            
            % 创建流动结果结构体
            flow = struct();
            flow.theoretical = theoretical_flow;
            flow.actual = actual_flow;
            flow.blocked = blocked_flow;
            flow.used = used_flow;
            
            % 计算汇总统计
            summary = struct();
            summary.total_theoretical = sum(theoretical_flow(:));
            summary.total_actual = sum(actual_flow(:));
            summary.total_blocked = sum(blocked_flow(:));
            summary.total_used = sum(used_flow(:));
            
            % 计算效率指标
            if summary.total_theoretical > 0
                summary.delivery_ratio = summary.total_actual / summary.total_theoretical;
                summary.use_ratio = summary.total_used / summary.total_theoretical;
                summary.block_ratio = summary.total_blocked / summary.total_theoretical;
            else
                summary.delivery_ratio = 0;
                summary.use_ratio = 0;
                summary.block_ratio = 0;
            end
        end
    end
end 