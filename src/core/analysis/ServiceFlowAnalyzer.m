classdef ServiceFlowAnalyzer
    % ServiceFlowAnalyzer 服务流量化分析类
    % 用于分析生态系统服务流的供给、需求和流动特征
    
    properties (Access = private)
        SupplyData           % 供给数据
        DemandData          % 需求数据
        ResistanceData      % 阻力数据
        SpatialData         % 空间关系数据
        Results             % 分析结果
        ValidationResults   % 验证结果
        
        % 分析参数
        Parameters = struct(...
            'supply_weight', 1.0, ...      % 供给能力权重
            'demand_weight', 1.0, ...      % 需求强度权重
            'resistance_factor', 0.5, ...  % 阻力衰减因子
            'distance_decay', 0.1, ...     % 距离衰减系数
            'flow_threshold', 0.01, ...    % 流动阈值
            'source_type', 'finite', ...   % 源类型：finite/infinite
            'sink_type', 'finite', ...     % 汇类型：finite/infinite
            'use_type', 'finite', ...      % 使用类型：finite/infinite
            'benefit_type', 'rival', ...   % 效益类型：rival/non-rival
            'cell_width', 100, ...         % 栅格宽度(米)
            'cell_height', 100, ...        % 栅格高度(米)
            'downscaling_factor', 1, ...   % 降尺度因子
            'validation_threshold', 0.95,... % 验证阈值
            'uncertainty_threshold', 0.2 ... % 不确定性阈值
        )
        
        % 流动模型类型
        FlowModel = 'surface-water'  % 可选：surface-water, sediment, line-of-sight, proximity, etc.
    end
    
    methods
        function obj = ServiceFlowAnalyzer()
            % 构造函数
            obj.SupplyData = [];
            obj.DemandData = [];
            obj.ResistanceData = [];
            obj.SpatialData = [];
            obj.Results = struct();
        end
        
        function setSupplyData(obj, data)
            % 设置供给数据
            obj.SupplyData = data;
        end
        
        function setDemandData(obj, data)
            % 设置需求数据
            obj.DemandData = data;
        end
        
        function setResistanceData(obj, data)
            % 设置阻力数据
            obj.ResistanceData = data;
        end
        
        function setSpatialData(obj, data)
            % 设置空间关系数据
            obj.SpatialData = data;
        end
        
        function setParameters(obj, params)
            % 设置分析参数
            fields = fieldnames(params);
            for i = 1:length(fields)
                if isfield(obj.Parameters, fields{i})
                    obj.Parameters.(fields{i}) = params.(fields{i});
                end
            end
        end
        
        function setFlowModel(obj, model_type)
            % 设置流动模型类型
            valid_models = {'surface-water', 'sediment', 'line-of-sight', ...
                          'proximity', 'carbon', 'flood-water', ...
                          'coastal-storm-protection', 'subsistence-fisheries'};
            if ~ismember(model_type, valid_models)
                error('不支持的流动模型类型');
            end
            obj.FlowModel = model_type;
        end
        
        function results = analyzeServiceFlow(obj, options)
            % 综合分析服务流
            if any(isempty([obj.SupplyData, obj.DemandData, obj.ResistanceData]))
                error('数据不完整');
            end
            
            % 1. 数据预处理和验证
            obj.validateData();
            obj.preprocessData();
            
            % 2. 分析供给
            supply_results = obj.analyzeSupply(options);
            
            % 3. 分析需求
            demand_results = obj.analyzeDemand(options);
            
            % 4. 分析阻力
            resistance_results = obj.analyzeResistance(options);
            
            % 5. 分析空间流动
            flow_results = obj.analyzeSpatialFlow(options);
            
            % 6. 计算理论和实际流动
            theoretical_flow = obj.calculateTheoreticalFlow(supply_results, demand_results);
            actual_flow = obj.calculateActualFlow(theoretical_flow, resistance_results);
            
            % 7. 分析流动效率
            efficiency = obj.analyzeFlowEfficiency(theoretical_flow, actual_flow);
            
            % 8. 计算不确定性
            uncertainty = obj.calculateUncertainty(supply_results, demand_results, resistance_results);
            
            % 9. 生成综合评价
            evaluation = obj.generateEvaluation(supply_results, demand_results, ...
                                             resistance_results, flow_results, ...
                                             theoretical_flow, actual_flow, ...
                                             efficiency, uncertainty);
            
            % 保存结果
            results = struct(...
                'theoretical_flow', theoretical_flow, ...
                'actual_flow', actual_flow, ...
                'efficiency', efficiency, ...
                'supply', supply_results, ...
                'demand', demand_results, ...
                'resistance', resistance_results, ...
                'flow', flow_results, ...
                'uncertainty', uncertainty, ...
                'evaluation', evaluation);
            
            obj.Results = results;
        end
        
        function validateData(obj)
            % 验证数据有效性
            validation_results = struct();
            
            % 1. 基础数据验证
            validation_results.basic = obj.validateBasicData();
            
            % 2. 空间一致性验证
            validation_results.spatial = obj.validateSpatialConsistency();
            
            % 3. 数值范围验证
            validation_results.range = obj.validateValueRanges();
            
            % 4. 物理约束验证
            validation_results.physical = obj.validatePhysicalConstraints();
            
            % 5. 模型特定验证
            validation_results.model = obj.validateModelSpecific();
            
            % 保存验证结果
            obj.ValidationResults = validation_results;
            
            % 检查是否通过所有验证
            if ~obj.checkValidationResults(validation_results)
                error('数据验证失败，请检查验证结果');
            end
        end
        
        function results = validateBasicData(obj)
            % 基础数据验证
            results = struct();
            
            % 检查数据完整性
            results.completeness = struct(...
                'supply', ~isempty(obj.SupplyData), ...
                'demand', ~isempty(obj.DemandData), ...
                'resistance', ~isempty(obj.ResistanceData), ...
                'spatial', ~isempty(obj.SpatialData));
            
            % 检查数据类型
            results.data_type = struct(...
                'supply', isnumeric(obj.SupplyData), ...
                'demand', isnumeric(obj.DemandData), ...
                'resistance', isnumeric(obj.ResistanceData), ...
                'spatial', isnumeric(obj.SpatialData));
            
            % 检查数据质量
            results.quality = struct(...
                'supply', ~any(isnan(obj.SupplyData(:)) | isinf(obj.SupplyData(:))), ...
                'demand', ~any(isnan(obj.DemandData(:)) | isinf(obj.DemandData(:))), ...
                'resistance', ~any(isnan(obj.ResistanceData(:)) | isinf(obj.ResistanceData(:))), ...
                'spatial', ~any(isnan(obj.SpatialData(:)) | isinf(obj.SpatialData(:))));
        end
        
        function results = validateSpatialConsistency(obj)
            % 空间一致性验证
            results = struct();
            
            % 检查栅格尺寸一致性
            base_size = size(obj.SpatialData);
            results.size_consistency = struct(...
                'supply', isequal(size(obj.SupplyData), base_size), ...
                'demand', isequal(size(obj.DemandData), base_size), ...
                'resistance', isequal(size(obj.ResistanceData), base_size));
            
            % 检查空间参考一致性
            results.spatial_reference = true;  % 需要根据实际数据格式扩展
            
            % 检查边界一致性
            results.boundary_consistency = obj.checkBoundaryConsistency();
        end
        
        function results = validateValueRanges(obj)
            % 数值范围验证
            results = struct();
            
            % 供给数据范围验证
            results.supply = struct(...
                'non_negative', all(obj.SupplyData(:) >= 0), ...
                'within_bounds', all(obj.SupplyData(:) <= max(obj.SupplyData(:))));
            
            % 需求数据范围验证
            results.demand = struct(...
                'non_negative', all(obj.DemandData(:) >= 0), ...
                'within_bounds', all(obj.DemandData(:) <= max(obj.DemandData(:))));
            
            % 阻力数据范围验证
            results.resistance = struct(...
                'non_negative', all(obj.ResistanceData(:) >= 0), ...
                'normalized', all(obj.ResistanceData(:) <= 1));
            
            % 空间数据范围验证
            results.spatial = struct(...
                'elevation_valid', obj.validateElevationRange(), ...
                'slope_valid', obj.validateSlopeRange());
        end
        
        function results = validatePhysicalConstraints(obj)
            % 物理约束验证
            results = struct();
            
            % 质量守恒验证
            results.mass_conservation = obj.validateMassConservation();
            
            % 能量守恒验证
            results.energy_conservation = obj.validateEnergyConservation();
            
            % 流动约束验证
            results.flow_constraints = obj.validateFlowConstraints();
        end
        
        function results = validateModelSpecific(obj)
            % 模型特定验证
            results = struct();
            
            % 根据不同流动模型类型进行特定验证
            switch obj.FlowModel
                case 'surface-water'
                    results = obj.validateSurfaceWaterModel();
                case 'sediment'
                    results = obj.validateSedimentModel();
                case 'line-of-sight'
                    results = obj.validateLineOfSightModel();
                case 'proximity'
                    results = obj.validateProximityModel();
                case 'carbon'
                    results = obj.validateCarbonModel();
                case 'flood-water'
                    results = obj.validateFloodWaterModel();
                case 'coastal-storm-protection'
                    results = obj.validateCoastalStormProtectionModel();
                case 'subsistence-fisheries'
                    results = obj.validateSubsistenceFisheriesModel();
                otherwise
                    error('不支持的流动模型类型');
            end
        end
        
        function valid = checkValidationResults(obj, results)
            % 检查验证结果
            valid = true;
            
            % 检查基础数据验证结果
            if ~all(structfun(@all, results.basic.completeness)) || ...
               ~all(structfun(@all, results.basic.data_type)) || ...
               ~all(structfun(@all, results.basic.quality))
                valid = false;
                return;
            end
            
            % 检查空间一致性验证结果
            if ~all(structfun(@all, results.spatial.size_consistency)) || ...
               ~results.spatial.spatial_reference || ...
               ~results.spatial.boundary_consistency
                valid = false;
                return;
            end
            
            % 检查数值范围验证结果
            if ~all(structfun(@all, results.range.supply)) || ...
               ~all(structfun(@all, results.range.demand)) || ...
               ~all(structfun(@all, results.range.resistance)) || ...
               ~all(structfun(@all, results.range.spatial))
                valid = false;
                return;
            end
            
            % 检查物理约束验证结果
            if ~results.physical.mass_conservation || ...
               ~results.physical.energy_conservation || ...
               ~results.physical.flow_constraints
                valid = false;
                return;
            end
            
            % 检查模型特定验证结果
            if ~obj.checkModelSpecificValidation(results.model)
                valid = false;
                return;
            end
        end
        
        function preprocessData(obj)
            % 数据预处理
            % 1. 去除异常值
            obj.SupplyData = obj.removeOutliers(obj.SupplyData);
            obj.DemandData = obj.removeOutliers(obj.DemandData);
            obj.ResistanceData = obj.removeOutliers(obj.ResistanceData);
            
            % 2. 数据标准化
            obj.SupplyData = obj.normalizeData(obj.SupplyData);
            obj.DemandData = obj.normalizeData(obj.DemandData);
            obj.ResistanceData = obj.normalizeData(obj.ResistanceData);
            
            % 3. 空间插值（处理缺失值）
            obj.SupplyData = obj.interpolateMissingValues(obj.SupplyData);
            obj.DemandData = obj.interpolateMissingValues(obj.DemandData);
            obj.ResistanceData = obj.interpolateMissingValues(obj.ResistanceData);
        end
        
        function data_clean = removeOutliers(obj, data)
            % 去除异常值
            % 使用3σ准则
            mean_val = mean(data(:));
            std_val = std(data(:));
            threshold = 3 * std_val;
            
            data_clean = data;
            outliers = abs(data - mean_val) > threshold;
            data_clean(outliers) = mean_val;
        end
        
        function data_norm = normalizeData(obj, data)
            % 数据标准化
            data_norm = (data - min(data(:))) / (max(data(:)) - min(data(:)));
        end
        
        function data_interp = interpolateMissingValues(obj, data)
            % 空间插值
            [rows, cols] = size(data);
            [X, Y] = meshgrid(1:cols, 1:rows);
            
            % 找到缺失值位置
            missing = isnan(data);
            
            if any(missing(:))
                % 使用有效值进行插值
                valid = ~missing;
                F = scatteredInterpolant(X(valid), Y(valid), data(valid), 'natural');
                
                % 插值缺失位置
                data_interp = data;
                data_interp(missing) = F(X(missing), Y(missing));
            else
                data_interp = data;
            end
        end
        
        function uncertainty = calculateUncertainty(obj, supply_results, demand_results, resistance_results)
            % 计算不确定性
            % 1. 供给不确定性
            supply_uncertainty = obj.calculateDataUncertainty(supply_results);
            
            % 2. 需求不确定性
            demand_uncertainty = obj.calculateDataUncertainty(demand_results);
            
            % 3. 阻力不确定性
            resistance_uncertainty = obj.calculateDataUncertainty(resistance_results);
            
            % 4. 综合不确定性
            total_uncertainty = sqrt(supply_uncertainty^2 + ...
                                  demand_uncertainty^2 + ...
                                  resistance_uncertainty^2);
            
            uncertainty = struct(...
                'supply', supply_uncertainty, ...
                'demand', demand_uncertainty, ...
                'resistance', resistance_uncertainty, ...
                'total', total_uncertainty);
        end
        
        function uncertainty = calculateDataUncertainty(obj, data_results)
            % 计算数据不确定性
            % 使用变异系数(CV)和空间自相关
            if isstruct(data_results)
                % 提取数值数据
                fields = fieldnames(data_results);
                numeric_fields = fields(structfun(@isnumeric, data_results));
                
                if ~isempty(numeric_fields)
                    % 计算每个数值字段的不确定性
                    field_uncertainty = zeros(length(numeric_fields), 1);
                    for i = 1:length(numeric_fields)
                        data = data_results.(numeric_fields{i});
                        if isnumeric(data) && ~isempty(data)
                            % 计算变异系数
                            cv = std(data(:)) / mean(data(:));
                            % 计算空间自相关
                            [r, ~] = xcorr2(data);
                            spatial_correlation = max(r(:));
                            % 综合不确定性
                            field_uncertainty(i) = cv * (1 - spatial_correlation);
                        end
                    end
                    uncertainty = mean(field_uncertainty);
                else
                    uncertainty = 0;
                end
            else
                uncertainty = 0;
            end
        end
        
        function evaluation = generateEvaluation(obj, supply_results, demand_results, ...
                                              resistance_results, flow_results, ...
                                              theoretical_flow, actual_flow, ...
                                              efficiency, uncertainty)
            % 生成综合评价
            % 1. 供需平衡评价
            balance_score = obj.evaluateSupplyDemandBalance(supply_results, demand_results);
            
            % 2. 流动效率评价
            efficiency_score = obj.evaluateFlowEfficiency(theoretical_flow, actual_flow);
            
            % 3. 空间格局评价
            spatial_score = obj.evaluateSpatialPattern(flow_results);
            
            % 4. 阻力影响评价
            resistance_score = obj.evaluateResistanceEffect(resistance_results);
            
            % 5. 不确定性评价
            uncertainty_score = obj.evaluateUncertainty(uncertainty);
            
            % 6. 计算综合得分
            total_score = obj.calculateTotalScore([balance_score, efficiency_score, ...
                                                 spatial_score, resistance_score, ...
                                                 uncertainty_score]);
            
            evaluation = struct(...
                'balance_score', balance_score, ...
                'efficiency_score', efficiency_score, ...
                'spatial_score', spatial_score, ...
                'resistance_score', resistance_score, ...
                'uncertainty_score', uncertainty_score, ...
                'total_score', total_score);
        end
        
        function score = evaluateSupplyDemandBalance(obj, supply_results, demand_results)
            % 评价供需平衡
            supply_total = supply_results.capacity.total;
            demand_total = demand_results.quantity.total;
            
            % 计算供需比
            ratio = supply_total / demand_total;
            
            % 评分规则：供需比越接近1分数越高
            score = 1 - min(abs(ratio - 1), 1);
        end
        
        function score = evaluateFlowEfficiency(obj, theoretical_flow, actual_flow)
            % 评价流动效率
            if theoretical_flow.max_flow > 0
                score = actual_flow.final / theoretical_flow.max_flow;
            else
                score = 0;
            end
        end
        
        function score = evaluateSpatialPattern(obj, flow_results)
            % 评价空间格局
            % 1. 计算空间集中度
            intensity = flow_results.intensity.final;
            [~, num_clusters] = bwlabel(intensity > mean(intensity(:)));
            cluster_score = 1 / (1 + num_clusters);
            
            % 2. 计算空间连续性
            [gx, gy] = gradient(intensity);
            gradient_magnitude = sqrt(gx.^2 + gy.^2);
            continuity_score = 1 - mean(gradient_magnitude(:));
            
            % 3. 综合评分
            score = (cluster_score + continuity_score) / 2;
        end
        
        function score = evaluateResistanceEffect(obj, resistance_results)
            % 评价阻力影响
            % 1. 计算阻力强度
            resistance_strength = mean(resistance_results.coefficient.weighted(:));
            
            % 2. 计算阻力分布
            resistance_distribution = std(resistance_results.coefficient.weighted(:));
            
            % 3. 综合评分（阻力越小越好）
            score = 1 - (resistance_strength + resistance_distribution) / 2;
        end
        
        function score = evaluateUncertainty(obj, uncertainty)
            % 评价不确定性
            % 不确定性越小越好
            score = 1 - min(uncertainty.total, 1);
        end
        
        function total_score = calculateTotalScore(obj, scores)
            % 计算综合得分
            % 使用加权平均
            weights = [0.3, 0.2, 0.2, 0.2, 0.1];  % 各项评分的权重
            total_score = sum(scores .* weights);
        end
        
        function theoretical_flow = calculateTheoreticalFlow(obj, supply_results, demand_results)
            % 计算理论流动
            switch obj.Parameters.source_type
                case 'finite'
                    max_flow = min(supply_results.capacity.total, demand_results.quantity.total);
                case 'infinite'
                    max_flow = demand_results.quantity.total;
                otherwise
                    error('不支持的源类型');
            end
            
            theoretical_flow = struct(...
                'max_flow', max_flow, ...
                'source_distribution', supply_results.distribution, ...
                'demand_distribution', demand_results.distribution);
        end
        
        function actual_flow = calculateActualFlow(obj, theoretical_flow, resistance_results)
            % 计算实际流动
            switch obj.FlowModel
                case 'surface-water'
                    actual_flow = obj.calculateSurfaceWaterFlow(theoretical_flow, resistance_results);
                case 'sediment'
                    actual_flow = obj.calculateSedimentFlow(theoretical_flow, resistance_results);
                case 'line-of-sight'
                    actual_flow = obj.calculateLineOfSightFlow(theoretical_flow, resistance_results);
                case 'proximity'
                    actual_flow = obj.calculateProximityFlow(theoretical_flow, resistance_results);
                case 'carbon'
                    actual_flow = obj.calculateCarbonFlow(theoretical_flow, resistance_results);
                case 'flood-water'
                    actual_flow = obj.calculateFloodWaterFlow(theoretical_flow, resistance_results);
                case 'coastal-storm-protection'
                    actual_flow = obj.calculateCoastalStormProtectionFlow(theoretical_flow, resistance_results);
                case 'subsistence-fisheries'
                    actual_flow = obj.calculateSubsistenceFisheriesFlow(theoretical_flow, resistance_results);
                otherwise
                    error('不支持的流动模型类型');
            end
        end
        
        function flow = calculateSurfaceWaterFlow(obj, theoretical_flow, resistance_results)
            % 计算地表水流动
            % 1. 构建流向矩阵
            [flow_direction, flow_accumulation] = obj.calculateFlowDirection(obj.SpatialData);
            
            % 2. 计算上游贡献
            upstream_contribution = obj.calculateUpstreamContribution(flow_direction, theoretical_flow.source_distribution);
            
            % 3. 计算下游累积
            downstream_accumulation = obj.calculateDownstreamAccumulation(flow_direction, upstream_contribution);
            
            % 4. 应用阻力影响
            flow_with_resistance = downstream_accumulation .* exp(-resistance_results.accumulation.total);
            
            % 5. 计算最终流动
            flow = struct(...
                'direction', flow_direction, ...
                'accumulation', flow_accumulation, ...
                'upstream', upstream_contribution, ...
                'downstream', downstream_accumulation, ...
                'final', flow_with_resistance);
        end
        
        function [direction, accumulation] = calculateFlowDirection(obj, dem_data)
            % 计算流向和累积量
            % 使用D8算法计算流向
            [rows, cols] = size(dem_data);
            direction = zeros(rows, cols);
            accumulation = zeros(rows, cols);
            
            % 计算每个栅格的流向
            for i = 2:rows-1
                for j = 2:cols-1
                    % 获取3x3邻域
                    window = dem_data(i-1:i+1, j-1:j+1);
                    % 计算坡度
                    [~, idx] = max(window(:) - window(2,2));
                    % 设置流向（1-8，表示8个方向）
                    direction(i,j) = idx;
                end
            end
            
            % 计算累积流量
            visited = false(rows, cols);
            for i = 1:rows
                for j = 1:cols
                    if ~visited(i,j)
                        accumulation = obj.traceFlow(i, j, direction, accumulation, visited);
                    end
                end
            end
        end
        
        function accumulation = traceFlow(obj, i, j, direction, accumulation, visited)
            % 追踪流动路径并计算累积量
            if visited(i,j)
                return;
            end
            
            visited(i,j) = true;
            accumulation(i,j) = accumulation(i,j) + 1;
            
            % 获取下游栅格位置
            [next_i, next_j] = obj.getDownstreamCell(i, j, direction(i,j));
            
            % 如果下游栅格有效，继续追踪
            if obj.isValidCell(next_i, next_j, size(direction))
                accumulation = obj.traceFlow(next_i, next_j, direction, accumulation, visited);
            end
        end
        
        function [next_i, next_j] = getDownstreamCell(obj, i, j, direction)
            % 根据流向获取下游栅格位置
            switch direction
                case 1
                    next_i = i-1; next_j = j-1;
                case 2
                    next_i = i-1; next_j = j;
                case 3
                    next_i = i-1; next_j = j+1;
                case 4
                    next_i = i; next_j = j+1;
                case 5
                    next_i = i+1; next_j = j+1;
                case 6
                    next_i = i+1; next_j = j;
                case 7
                    next_i = i+1; next_j = j-1;
                case 8
                    next_i = i; next_j = j-1;
                otherwise
                    next_i = i; next_j = j;
            end
        end
        
        function valid = isValidCell(obj, i, j, matrix_size)
            % 检查栅格位置是否有效
            valid = i >= 1 && i <= matrix_size(1) && ...
                   j >= 1 && j <= matrix_size(2);
        end
        
        function upstream = calculateUpstreamContribution(obj, flow_direction, source_distribution)
            % 计算上游贡献
            [rows, cols] = size(flow_direction);
            upstream = zeros(rows, cols);
            
            % 从每个源点开始追踪
            [source_i, source_j] = find(source_distribution.pattern.clusters > 0);
            for k = 1:length(source_i)
                upstream = obj.traceUpstream(source_i(k), source_j(k), ...
                    flow_direction, upstream, source_distribution.pattern.magnitude);
            end
        end
        
        function downstream = calculateDownstreamAccumulation(obj, flow_direction, upstream_contribution)
            % 计算下游累积
            [rows, cols] = size(flow_direction);
            downstream = zeros(rows, cols);
            visited = false(rows, cols);
            
            % 从每个有上游贡献的点开始追踪
            [contrib_i, contrib_j] = find(upstream_contribution > 0);
            for k = 1:length(contrib_i)
                downstream = obj.traceDownstream(contrib_i(k), contrib_j(k), ...
                    flow_direction, downstream, upstream_contribution, visited);
            end
        end
        
        function flow = calculateSedimentFlow(obj, theoretical_flow, resistance_results)
            % 计算泥沙流动
            % 1. 计算坡度和坡向
            [slope, aspect] = obj.calculateSlopeAspect(obj.SpatialData);
            
            % 2. 计算泥沙侵蚀量
            erosion = obj.calculateErosion(slope, obj.SupplyData);
            
            % 3. 计算泥沙输移
            transport = obj.calculateSedimentTransport(erosion, slope, aspect);
            
            % 4. 计算泥沙沉积
            deposition = obj.calculateDeposition(transport, slope);
            
            % 5. 应用阻力影响
            flow_with_resistance = transport .* exp(-resistance_results.accumulation.total);
            
            % 保存结果
            flow = struct(...
                'slope', slope, ...
                'aspect', aspect, ...
                'erosion', erosion, ...
                'transport', transport, ...
                'deposition', deposition, ...
                'final', flow_with_resistance);
        end
        
        function [slope, aspect] = calculateSlopeAspect(obj, dem_data)
            % 计算坡度和坡向
            [rows, cols] = size(dem_data);
            slope = zeros(rows, cols);
            aspect = zeros(rows, cols);
            
            % 计算每个栅格的坡度和坡向
            for i = 2:rows-1
                for j = 2:cols-1
                    % 获取3x3邻域
                    window = dem_data(i-1:i+1, j-1:j+1);
                    
                    % 计算x和y方向的梯度
                    [fx, fy] = gradient(window);
                    
                    % 计算坡度（弧度）
                    slope(i,j) = atan(sqrt(fx(2,2)^2 + fy(2,2)^2));
                    
                    % 计算坡向（弧度）
                    aspect(i,j) = atan2(-fy(2,2), -fx(2,2));
                end
            end
        end
        
        function erosion = calculateErosion(obj, slope, supply_data)
            % 计算泥沙侵蚀量
            % 使用通用土壤流失方程(USLE)简化版
            R = 1.0;  % 降雨侵蚀力因子
            K = 0.5;  % 土壤可蚀性因子
            LS = sin(slope) .* (supply_data > mean(supply_data(:)));  % 坡长坡度因子
            C = 0.5;  % 植被覆盖因子
            P = 1.0;  % 水土保持措施因子
            
            erosion = R * K * LS * C * P;
        end
        
        function transport = calculateSedimentTransport(obj, erosion, slope, aspect)
            % 计算泥沙输移
            % 1. 计算输移能力
            transport_capacity = erosion .* sin(slope);
            
            % 2. 计算输移方向
            [fx, fy] = pol2cart(aspect, transport_capacity);
            
            % 3. 计算累积输移量
            transport = sqrt(fx.^2 + fy.^2);
        end
        
        function deposition = calculateDeposition(obj, transport, slope)
            % 计算泥沙沉积
            % 1. 计算沉积阈值
            threshold = mean(transport(:)) * (1 - sin(slope));
            
            % 2. 计算沉积量
            deposition = max(0, transport - threshold);
        end
        
        function flow = calculateLineOfSightFlow(obj, theoretical_flow, resistance_results)
            % 计算视线流动
            % 1. 获取观察点和目标点
            [observer_points, target_points] = obj.getViewPoints(theoretical_flow);
            
            % 2. 计算视线可见性
            visibility = obj.calculateVisibility(observer_points, target_points, obj.SpatialData);
            
            % 3. 计算视觉质量
            quality = obj.calculateViewQuality(visibility, obj.SpatialData);
            
            % 4. 应用阻力影响
            flow_with_resistance = quality .* exp(-resistance_results.accumulation.total);
            
            % 保存结果
            flow = struct(...
                'observer_points', observer_points, ...
                'target_points', target_points, ...
                'visibility', visibility, ...
                'quality', quality, ...
                'final', flow_with_resistance);
        end
        
        function [observer_points, target_points] = getViewPoints(obj, theoretical_flow)
            % 获取观察点和目标点
            % 1. 从供给分布中获取观察点
            [obs_i, obs_j] = find(theoretical_flow.source_distribution.hotspots);
            observer_points = [obs_i, obs_j];
            
            % 2. 从需求分布中获取目标点
            [tgt_i, tgt_j] = find(theoretical_flow.demand_distribution.hotspots);
            target_points = [tgt_i, tgt_j];
        end
        
        function visibility = calculateVisibility(obj, observer_points, target_points, dem_data)
            % 计算视线可见性
            [rows, cols] = size(dem_data);
            visibility = zeros(rows, cols);
            
            % 对每个观察点
            for i = 1:size(observer_points, 1)
                obs = observer_points(i,:);
                
                % 对每个目标点
                for j = 1:size(target_points, 1)
                    tgt = target_points(j,:);
                    
                    % 计算视线路径
                    line = obj.bresenham(obs(1), obs(2), tgt(1), tgt(2));
                    
                    % 检查视线是否被阻挡
                    if obj.isVisible(line, dem_data)
                        % 更新可见性矩阵
                        for k = 1:size(line, 1)
                            visibility(line(k,1), line(k,2)) = ...
                                visibility(line(k,1), line(k,2)) + 1;
                        end
                    end
                end
            end
            
            % 归一化可见性
            if max(visibility(:)) > 0
                visibility = visibility / max(visibility(:));
            end
        end
        
        function line = bresenham(obj, x1, y1, x2, y2)
            % Bresenham直线算法
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
            ystep = (y1 < y2) * 2 - 1;
            y = y1;
            points = zeros(dx + 1, 2);
            
            for x = x1:x2
                if steep
                    points(x-x1+1,:) = [y, x];
                else
                    points(x-x1+1,:) = [x, y];
                end
                
                error = error - dy;
                if error < 0
                    y = y + ystep;
                    error = error + dx;
                end
            end
            
            line = points;
        end
        
        function visible = isVisible(obj, line, dem_data)
            % 检查视线是否被阻挡
            if isempty(line)
                visible = false;
                return;
            end
            
            % 获取起点和终点
            start_point = line(1,:);
            end_point = line(end,:);
            
            % 计算视线方程
            dx = end_point(1) - start_point(1);
            dy = end_point(2) - start_point(2);
            dz = dem_data(end_point(1), end_point(2)) - dem_data(start_point(1), start_point(2));
            
            % 检查路径上的每个点
            visible = true;
            for i = 2:size(line,1)-1
                point = line(i,:);
                
                % 计算该点在视线上的理论高程
                t = ((point(1) - start_point(1)) * dx + (point(2) - start_point(2)) * dy) / ...
                    (dx^2 + dy^2);
                expected_height = dem_data(start_point(1), start_point(2)) + t * dz;
                
                % 如果实际高程高于理论高程，则视线被阻挡
                if dem_data(point(1), point(2)) > expected_height
                    visible = false;
                    break;
                end
            end
        end
        
        function quality = calculateViewQuality(obj, visibility, dem_data)
            % 计算视觉质量
            % 1. 计算地形起伏度
            [slope, ~] = obj.calculateSlopeAspect(dem_data);
            relief = std(dem_data(:));
            
            % 2. 计算视域范围
            viewshed_area = sum(visibility(:) > 0);
            
            % 3. 综合评价视觉质量
            quality = visibility .* (1 + sin(slope)) * (relief / max(relief, 1)) * ...
                     (viewshed_area / numel(visibility));
        end
        
        function flow = calculateProximityFlow(obj, theoretical_flow, resistance_results)
            % 计算邻近度流动
            % 1. 获取源点和目标点
            [source_points, target_points] = obj.getProximityPoints(theoretical_flow);
            
            % 2. 计算距离矩阵
            distance = obj.calculateDistanceMatrix(source_points, target_points, obj.SpatialData);
            
            % 3. 计算可达性
            accessibility = obj.calculateAccessibility(distance);
            
            % 4. 计算邻近度影响
            influence = obj.calculateProximityInfluence(accessibility, theoretical_flow);
            
            % 5. 应用阻力影响
            flow_with_resistance = influence .* exp(-resistance_results.accumulation.total);
            
            % 保存结果
            flow = struct(...
                'source_points', source_points, ...
                'target_points', target_points, ...
                'distance', distance, ...
                'accessibility', accessibility, ...
                'influence', influence, ...
                'final', flow_with_resistance);
        end
        
        function [source_points, target_points] = getProximityPoints(obj, theoretical_flow)
            % 获取源点和目标点
            % 1. 从供给分布中获取源点
            [src_i, src_j] = find(theoretical_flow.source_distribution.hotspots);
            source_points = [src_i, src_j];
            
            % 2. 从需求分布中获取目标点
            [tgt_i, tgt_j] = find(theoretical_flow.demand_distribution.hotspots);
            target_points = [tgt_i, tgt_j];
        end
        
        function distance = calculateDistanceMatrix(obj, source_points, target_points, dem_data)
            % 计算距离矩阵
            [rows, cols] = size(dem_data);
            distance = inf(rows, cols);
            
            % 对每个源点
            for i = 1:size(source_points, 1)
                src = source_points(i,:);
                
                % 计算到每个栅格的距离
                for x = 1:rows
                    for y = 1:cols
                        % 计算欧氏距离
                        d = sqrt((x - src(1))^2 + (y - src(2))^2);
                        
                        % 考虑地形因素
                        slope_factor = 1 + abs(dem_data(x,y) - dem_data(src(1),src(2))) / ...
                                     obj.Parameters.cell_height;
                        
                        % 更新最小距离
                        distance(x,y) = min(distance(x,y), d * slope_factor);
                    end
                end
            end
        end
        
        function accessibility = calculateAccessibility(obj, distance)
            % 计算可达性
            % 1. 标准化距离
            normalized_distance = distance / max(distance(:));
            
            % 2. 计算距离衰减
            decay = exp(-normalized_distance * obj.Parameters.distance_decay);
            
            % 3. 计算可达性指数
            accessibility = 1 ./ (1 + normalized_distance) .* decay;
        end
        
        function influence = calculateProximityInfluence(obj, accessibility, theoretical_flow)
            % 计算邻近度影响
            % 1. 计算源强度
            source_strength = theoretical_flow.source_distribution.pattern.magnitude;
            
            % 2. 计算需求强度
            demand_strength = theoretical_flow.demand_distribution.pattern.magnitude;
            
            % 3. 计算综合影响
            influence = accessibility .* ...
                       (source_strength / max(source_strength(:))) .* ...
                       (demand_strength / max(demand_strength(:)));
        end
        
        function results = analyzeSupply(obj, options)
            % 分析供给
            if isempty(obj.SupplyData)
                error('供给数据未设置');
            end
            
            % 1. 计算供给能力
            capacity = obj.calculateSupplyCapacity(obj.SupplyData);
            
            % 2. 评估供给质量
            quality = obj.evaluateSupplyQuality(obj.SupplyData);
            
            % 3. 分析供给空间分布
            distribution = obj.analyzeSupplyDistribution(obj.SupplyData);
            
            % 4. 计算供给潜力
            potential = obj.calculateSupplyPotential(capacity, quality);
            
            % 保存结果
            results = struct('capacity', capacity, ...
                           'quality', quality, ...
                           'distribution', distribution, ...
                           'potential', potential);
            obj.Results.supply = results;
        end
        
        function results = analyzeDemand(obj, options)
            % 分析需求
            if isempty(obj.DemandData)
                error('需求数据未设置');
            end
            
            % 1. 计算需求量
            quantity = obj.calculateDemandQuantity(obj.DemandData);
            
            % 2. 评估需求强度
            intensity = obj.evaluateDemandIntensity(obj.DemandData);
            
            % 3. 分析需求分布
            distribution = obj.analyzeDemandDistribution(obj.DemandData);
            
            % 4. 计算需求压力
            pressure = obj.calculateDemandPressure(quantity, intensity);
            
            % 保存结果
            results = struct('quantity', quantity, ...
                           'intensity', intensity, ...
                           'distribution', distribution, ...
                           'pressure', pressure);
            obj.Results.demand = results;
        end
        
        function results = analyzeResistance(obj, options)
            % 分析阻力
            if isempty(obj.ResistanceData)
                error('阻力数据未设置');
            end
            
            % 1. 计算阻力系数
            coefficient = obj.calculateResistanceCoefficient(obj.ResistanceData);
            
            % 2. 评估阻力影响
            impact = obj.evaluateResistanceImpact(obj.ResistanceData);
            
            % 3. 分析阻力分布
            distribution = obj.analyzeResistanceDistribution(obj.ResistanceData);
            
            % 4. 计算累积阻力
            accumulation = obj.calculateResistanceAccumulation(coefficient, impact);
            
            % 保存结果
            results = struct('coefficient', coefficient, ...
                           'impact', impact, ...
                           'distribution', distribution, ...
                           'accumulation', accumulation);
            obj.Results.resistance = results;
        end
        
        function results = analyzeSpatialFlow(obj, options)
            % 分析空间流动
            if any(isempty([obj.SupplyData, obj.DemandData, obj.ResistanceData]))
                error('数据不完整');
            end
            
            % 1. 计算流动路径
            paths = obj.calculateFlowPaths();
            
            % 2. 评估流动强度
            intensity = obj.evaluateFlowIntensity();
            
            % 3. 分析流动效率
            efficiency = obj.analyzeFlowEfficiency();
            
            % 4. 计算流动通量
            flux = obj.calculateFlowFlux(paths, intensity);
            
            % 保存结果
            results = struct('paths', paths, ...
                           'intensity', intensity, ...
                           'efficiency', efficiency, ...
                           'flux', flux);
            obj.Results.spatial_flow = results;
        end
        
        function results = getResults(obj)
            % 获取分析结果
            results = obj.Results;
        end
        
        function path = findMinCostPath(obj, cost, source, sink)
            % 使用Dijkstra算法找最小成本路径
            [rows, cols] = size(cost);
            
            % 初始化距离和前驱矩阵
            dist = inf(rows, cols);
            prev = zeros(rows, cols, 2);  % 存储前驱节点的坐标
            visited = false(rows, cols);
            
            % 设置源点距离为0
            dist(source(1), source(2)) = 0;
            
            % 主循环
            while true
                % 找到未访问的最小距离点
                min_dist = inf;
                current = [];
                for i = 1:rows
                    for j = 1:cols
                        if ~visited(i,j) && dist(i,j) < min_dist
                            min_dist = dist(i,j);
                            current = [i, j];
                        end
                    end
                end
                
                % 如果没有找到点或已到达终点，退出
                if isempty(current) || (current(1) == sink(1) && current(2) == sink(2))
                    break;
                end
                
                % 标记当前点为已访问
                visited(current(1), current(2)) = true;
                
                % 更新邻居点的距离
                neighbors = obj.getNeighbors(current, rows, cols);
                for k = 1:size(neighbors, 1)
                    neighbor = neighbors(k,:);
                    if ~visited(neighbor(1), neighbor(2))
                        % 计算通过当前点到邻居的距离
                        new_dist = dist(current(1), current(2)) + ...
                                 cost(neighbor(1), neighbor(2));
                        
                        % 如果找到更短路径，更新距离和前驱
                        if new_dist < dist(neighbor(1), neighbor(2))
                            dist(neighbor(1), neighbor(2)) = new_dist;
                            prev(neighbor(1), neighbor(2), :) = current;
                        end
                    end
                end
            end
            
            % 重建路径
            path = obj.reconstructPath(prev, source, sink);
        end
        
        function neighbors = getNeighbors(obj, point, rows, cols)
            % 获取点的8邻域邻居
            i = point(1);
            j = point(2);
            
            % 生成可能的邻居坐标
            potential_neighbors = [
                i-1, j-1;  % 左上
                i-1, j;    % 上
                i-1, j+1;  % 右上
                i, j+1;    % 右
                i+1, j+1;  % 右下
                i+1, j;    % 下
                i+1, j-1;  % 左下
                i, j-1     % 左
            ];
            
            % 过滤掉越界的点
            valid_idx = potential_neighbors(:,1) >= 1 & ...
                       potential_neighbors(:,1) <= rows & ...
                       potential_neighbors(:,2) >= 1 & ...
                       potential_neighbors(:,2) <= cols;
            
            neighbors = potential_neighbors(valid_idx, :);
        end
        
        function path = reconstructPath(obj, prev, source, sink)
            % 从前驱矩阵重建路径
            path = [];
            current = sink;
            
            % 从终点回溯到起点
            while ~isempty(current) && ...
                  (current(1) ~= source(1) || current(2) ~= source(2))
                path = [current; path];
                prev_point = squeeze(prev(current(1), current(2), :))';
                
                % 如果找不到前驱，说明路径不存在
                if all(prev_point == 0)
                    path = [];
                    return;
                end
                
                current = prev_point;
            end
            
            % 添加起点
            path = [source; path];
        end
        
        function flow = calculateCarbonFlow(obj, theoretical_flow, resistance_results)
            % 计算碳流动
            % 1. 计算碳储量和通量
            carbon_storage = obj.calculateCarbonStorage(obj.SupplyData);
            carbon_flux = obj.calculateCarbonFlux(carbon_storage, obj.SpatialData);
            
            % 2. 计算碳吸收和释放
            [sequestration, emission] = obj.calculateCarbonExchange(carbon_storage, obj.DemandData);
            
            % 3. 计算净碳流动
            net_flow = obj.calculateNetCarbonFlow(sequestration, emission);
            
            % 4. 应用阻力影响
            flow_with_resistance = net_flow .* exp(-resistance_results.accumulation.total);
            
            % 保存结果
            flow = struct(...
                'storage', carbon_storage, ...
                'flux', carbon_flux, ...
                'sequestration', sequestration, ...
                'emission', emission, ...
                'net_flow', net_flow, ...
                'final', flow_with_resistance);
        end
        
        function storage = calculateCarbonStorage(obj, supply_data)
            % 计算碳储量
            % 1. 计算生物量碳储量
            biomass_carbon = supply_data * 0.5;  % 假设生物量中碳含量为50%
            
            % 2. 计算土壤碳储量
            soil_carbon = supply_data * 0.3;     % 假设土壤碳储量为生物量的30%
            
            % 3. 计算总碳储量
            total_carbon = biomass_carbon + soil_carbon;
            
            storage = struct(...
                'biomass', biomass_carbon, ...
                'soil', soil_carbon, ...
                'total', total_carbon);
        end
        
        function flux = calculateCarbonFlux(obj, storage, dem_data)
            % 计算碳通量
            % 1. 计算光合作用固碳
            photosynthesis = storage.biomass .* (1 + sin(dem_data/max(dem_data(:)) * pi/2)) * 0.1;
            
            % 2. 计算呼吸作用排碳
            respiration = storage.total * 0.05;  % 假设呼吸损失为总储量的5%
            
            % 3. 计算净通量
            net_flux = photosynthesis - respiration;
            
            flux = struct(...
                'photosynthesis', photosynthesis, ...
                'respiration', respiration, ...
                'net', net_flux);
        end
        
        function [sequestration, emission] = calculateCarbonExchange(obj, storage, demand_data)
            % 计算碳交换
            % 1. 计算碳吸收
            sequestration = storage.biomass .* (demand_data / max(demand_data(:))) * 0.2;
            
            % 2. 计算碳释放
            emission = storage.total .* (demand_data / max(demand_data(:))) * 0.1;
            
            % 3. 应用阈值
            sequestration(sequestration < obj.Parameters.flow_threshold) = 0;
            emission(emission < obj.Parameters.flow_threshold) = 0;
        end
        
        function net_flow = calculateNetCarbonFlow(obj, sequestration, emission)
            % 计算净碳流动
            % 1. 计算净流动
            net_flow = sequestration - emission;
            
            % 2. 应用空间平滑
            kernel = fspecial('gaussian', [3 3], 0.5);
            net_flow = conv2(net_flow, kernel, 'same');
        end
        
        function flow = calculateFloodWaterFlow(obj, theoretical_flow, resistance_results)
            % 计算洪水流动
            % 1. 计算地形特征
            [slope, aspect] = obj.calculateSlopeAspect(obj.SpatialData);
            
            % 2. 计算汇流累积
            [flow_direction, accumulation] = obj.calculateFlowAccumulation(slope, aspect);
            
            % 3. 计算洪水深度
            depth = obj.calculateFloodDepth(accumulation, obj.SupplyData);
            
            % 4. 计算流速和流量
            [velocity, discharge] = obj.calculateFloodVelocity(depth, slope);
            
            % 5. 计算淹没范围
            inundation = obj.calculateInundationArea(depth, obj.DemandData);
            
            % 6. 应用阻力影响
            flow_with_resistance = discharge .* exp(-resistance_results.accumulation.total);
            
            % 保存结果
            flow = struct(...
                'direction', flow_direction, ...
                'accumulation', accumulation, ...
                'depth', depth, ...
                'velocity', velocity, ...
                'discharge', discharge, ...
                'inundation', inundation, ...
                'final', flow_with_resistance);
        end
        
        function [direction, accumulation] = calculateFlowAccumulation(obj, slope, aspect)
            % 计算汇流累积
            % 1. 计算流向
            direction = obj.calculateFlowDirection(slope, aspect);
            
            % 2. 计算累积流量
            accumulation = zeros(size(slope));
            visited = false(size(slope));
            
            % 从每个单元开始追踪
            for i = 1:size(slope,1)
                for j = 1:size(slope,2)
                    if ~visited(i,j)
                        accumulation = obj.traceFlow(i, j, direction, accumulation, visited);
                    end
                end
            end
        end
        
        function depth = calculateFloodDepth(obj, accumulation, supply_data)
            % 计算洪水深度
            % 1. 计算初始水深
            initial_depth = accumulation .* (supply_data / max(supply_data(:)));
            
            % 2. 应用最小深度阈值
            depth = initial_depth;
            depth(depth < obj.Parameters.flow_threshold) = 0;
            
            % 3. 应用空间平滑
            kernel = fspecial('gaussian', [3 3], 0.5);
            depth = conv2(depth, kernel, 'same');
        end
        
        function [velocity, discharge] = calculateFloodVelocity(obj, depth, slope)
            % 计算洪水流速和流量
            % 1. 计算流速（使用Manning公式简化版）
            n = 0.03;  % Manning粗糙系数
            velocity = (1/n) * (depth.^(2/3)) .* (sqrt(slope));
            
            % 2. 计算流量
            discharge = velocity .* depth;
            
            % 3. 应用阈值
            velocity(depth < obj.Parameters.flow_threshold) = 0;
            discharge(depth < obj.Parameters.flow_threshold) = 0;
        end
        
        function inundation = calculateInundationArea(obj, depth, demand_data)
            % 计算淹没范围
            % 1. 确定淹没区域
            is_inundated = depth > obj.Parameters.flow_threshold;
            
            % 2. 计算淹没风险
            risk = is_inundated .* demand_data;
            
            % 3. 计算影响范围
            distance = bwdist(is_inundated);
            influence = exp(-distance * obj.Parameters.distance_decay);
            
            inundation = struct(...
                'area', is_inundated, ...
                'risk', risk, ...
                'influence', influence);
        end
        
        function flow = calculateCoastalStormProtectionFlow(obj, theoretical_flow, resistance_results)
            % 计算海岸风暴防护流
            % 1. 识别海岸线和防护区
            [coastline, buffer_zone] = obj.identifyCoastalFeatures(obj.SpatialData);
            
            % 2. 计算防护能力
            protection = obj.calculateProtectionCapacity(obj.SupplyData, coastline);
            
            % 3. 计算暴露度
            exposure = obj.calculateStormExposure(obj.DemandData, buffer_zone);
            
            % 4. 计算防护效果
            effectiveness = obj.calculateProtectionEffectiveness(protection, exposure);
            
            % 5. 应用阻力影响
            flow_with_resistance = effectiveness .* exp(-resistance_results.accumulation.total);
            
            % 保存结果
            flow = struct(...
                'coastline', coastline, ...
                'buffer_zone', buffer_zone, ...
                'protection', protection, ...
                'exposure', exposure, ...
                'effectiveness', effectiveness, ...
                'final', flow_with_resistance);
        end
        
        function [coastline, buffer_zone] = identifyCoastalFeatures(obj, dem_data)
            % 识别海岸线和防护区
            % 1. 识别海岸线（假设高程接近海平面的区域）
            sea_level = min(dem_data(:)) + 1;
            coastline = abs(dem_data - sea_level) < 0.5;
            
            % 2. 创建缓冲区
            buffer_distance = 10;  % 假设缓冲区为10个栅格
            buffer_zone = bwdist(coastline) <= buffer_distance;
            
            % 3. 细化海岸线
            coastline = bwmorph(coastline, 'thin', Inf);
        end
        
        function protection = calculateProtectionCapacity(obj, supply_data, coastline)
            % 计算防护能力
            % 1. 计算基础防护能力
            base_protection = supply_data .* coastline;
            
            % 2. 计算防护强度
            strength = obj.calculateProtectionStrength(base_protection);
            
            % 3. 计算防护范围
            coverage = obj.calculateProtectionCoverage(base_protection);
            
            protection = struct(...
                'base', base_protection, ...
                'strength', strength, ...
                'coverage', coverage, ...
                'total', strength .* coverage);
        end
        
        function strength = calculateProtectionStrength(obj, base_protection)
            % 计算防护强度
            % 1. 计算局部强度
            kernel = fspecial('gaussian', [5 5], 1);
            local_strength = conv2(base_protection, kernel, 'same');
            
            % 2. 应用非线性变换
            strength = 1 - exp(-local_strength);
        end
        
        function coverage = calculateProtectionCoverage(obj, base_protection)
            % 计算防护范围
            % 1. 计算距离衰减
            distance = bwdist(base_protection > 0);
            
            % 2. 应用衰减函数
            coverage = exp(-distance * obj.Parameters.distance_decay);
        end
        
        function exposure = calculateStormExposure(obj, demand_data, buffer_zone)
            % 计算暴露度
            % 1. 计算基础暴露度
            base_exposure = demand_data .* buffer_zone;
            
            % 2. 计算暴露等级
            level = obj.calculateExposureLevel(base_exposure);
            
            % 3. 计算脆弱性
            vulnerability = obj.calculateVulnerability(base_exposure, buffer_zone);
            
            exposure = struct(...
                'base', base_exposure, ...
                'level', level, ...
                'vulnerability', vulnerability, ...
                'total', level .* vulnerability);
        end
        
        function level = calculateExposureLevel(obj, base_exposure)
            % 计算暴露等级
            % 1. 计算暴露强度
            mean_exposure = mean(base_exposure(:));
            std_exposure = std(base_exposure(:));
            
            % 2. 划分等级
            level = zeros(size(base_exposure));
            level(base_exposure > mean_exposure + std_exposure) = 1.0;  % 高暴露
            level(base_exposure > mean_exposure) = 0.7;                 % 中等暴露
            level(base_exposure > 0) = 0.3;                            % 低暴露
        end
        
        function vulnerability = calculateVulnerability(obj, base_exposure, buffer_zone)
            % 计算脆弱性
            % 1. 计算距离因子
            distance = bwdist(~buffer_zone);
            distance_factor = exp(-distance * obj.Parameters.distance_decay);
            
            % 2. 计算密度因子
            kernel = fspecial('gaussian', [5 5], 1);
            density = conv2(base_exposure > 0, kernel, 'same');
            density_factor = density / max(density(:));
            
            % 3. 综合评估脆弱性
            vulnerability = (distance_factor + density_factor) / 2;
        end
        
        function effectiveness = calculateProtectionEffectiveness(obj, protection, exposure)
            % 计算防护效果
            % 1. 计算防护减缓
            mitigation = protection.total .* (1 - exposure.total);
            
            % 2. 计算剩余风险
            residual_risk = exposure.total .* (1 - protection.total);
            
            % 3. 计算综合效果
            effectiveness = mitigation .* (1 - residual_risk);
            
            % 4. 应用空间平滑
            kernel = fspecial('gaussian', [3 3], 0.5);
            effectiveness = conv2(effectiveness, kernel, 'same');
        end
        
        function flow = calculateSubsistenceFisheriesFlow(obj, theoretical_flow, resistance_results)
            % 计算生计渔业流动
            % 1. 计算渔业资源分布
            resources = obj.calculateFisheryResources(obj.SupplyData);
            
            % 2. 计算捕捞压力
            pressure = obj.calculateFishingPressure(obj.DemandData);
            
            % 3. 计算可达性
            accessibility = obj.calculateFishingAccessibility(obj.SpatialData);
            
            % 4. 计算捕捞产出
            yield = obj.calculateFishingYield(resources, pressure, accessibility);
            
            % 5. 应用阻力影响
            flow_with_resistance = yield .* exp(-resistance_results.accumulation.total);
            
            % 保存结果
            flow = struct(...
                'resources', resources, ...
                'pressure', pressure, ...
                'accessibility', accessibility, ...
                'yield', yield, ...
                'final', flow_with_resistance);
        end
        
        function resources = calculateFisheryResources(obj, supply_data)
            % 计算渔业资源分布
            % 1. 计算资源密度
            density = obj.calculateResourceDensity(supply_data);
            
            % 2. 计算资源质量
            quality = obj.calculateResourceQuality(supply_data);
            
            % 3. 计算资源更新率
            renewal = obj.calculateResourceRenewal(density);
            
            resources = struct(...
                'density', density, ...
                'quality', quality, ...
                'renewal', renewal, ...
                'total', density .* quality .* renewal);
        end
        
        function density = calculateResourceDensity(obj, supply_data)
            % 计算资源密度
            % 1. 计算局部密度
            kernel = fspecial('gaussian', [5 5], 1);
            local_density = conv2(supply_data, kernel, 'same');
            
            % 2. 应用密度阈值
            density = local_density;
            density(density < obj.Parameters.flow_threshold) = 0;
        end
        
        function quality = calculateResourceQuality(obj, supply_data)
            % 计算资源质量
            % 1. 计算基础质量
            base_quality = supply_data / max(supply_data(:));
            
            % 2. 应用质量等级
            quality = zeros(size(supply_data));
            quality(base_quality > 0.7) = 1.0;  % 高质量
            quality(base_quality > 0.3) = 0.7;  % 中等质量
            quality(base_quality > 0) = 0.3;    % 低质量
        end
        
        function renewal = calculateResourceRenewal(obj, density)
            % 计算资源更新率
            % 1. 计算基础更新率
            base_renewal = 0.1 + 0.2 * (density / max(density(:)));  % 10-30%更新率
            
            % 2. 应用密度依赖
            carrying_capacity = 0.8;  % 假设环境容量为最大密度的80%
            density_effect = 1 - (density / max(density(:))) / carrying_capacity;
            
            renewal = base_renewal .* max(0, density_effect);
        end
        
        function pressure = calculateFishingPressure(obj, demand_data)
            % 计算捕捞压力
            % 1. 计算需求强度
            intensity = obj.calculateFishingIntensity(demand_data);
            
            % 2. 计算季节性
            seasonality = obj.calculateFishingSeasonality();
            
            % 3. 计算累积压力
            accumulation = obj.calculatePressureAccumulation(intensity);
            
            pressure = struct(...
                'intensity', intensity, ...
                'seasonality', seasonality, ...
                'accumulation', accumulation, ...
                'total', intensity .* seasonality .* accumulation);
        end
        
        function intensity = calculateFishingIntensity(obj, demand_data)
            % 计算捕捞强度
            % 1. 标准化需求
            normalized = demand_data / max(demand_data(:));
            
            % 2. 应用非线性变换
            intensity = 1 - exp(-2 * normalized);  % 快速增长然后趋于饱和
        end
        
        function seasonality = calculateFishingSeasonality(obj)
            % 计算季节性（示例：使用简单的周期函数）
            [rows, cols] = size(obj.DemandData);
            [X, Y] = meshgrid(1:cols, 1:rows);
            
            % 创建周期性变化（可以根据实际情况调整）
            seasonality = 0.5 + 0.5 * sin(2*pi*X/cols) .* sin(2*pi*Y/rows);
        end
        
        function accumulation = calculatePressureAccumulation(obj, intensity)
            % 计算压力累积
            % 1. 计算距离衰减
            [rows, cols] = size(intensity);
            [X, Y] = meshgrid(1:cols, 1:rows);
            center = [rows/2, cols/2];
            distance = sqrt((X - center(2)).^2 + (Y - center(1)).^2);
            
            % 2. 应用累积效应
            accumulation = conv2(intensity, fspecial('gaussian', [5 5], 1), 'same') .* ...
                         exp(-distance * obj.Parameters.distance_decay);
        end
        
        function accessibility = calculateFishingAccessibility(obj, spatial_data)
            % 计算捕捞可达性
            % 1. 计算地形可达性
            terrain = obj.calculateTerrainAccessibility(spatial_data);
            
            % 2. 计算距离可达性
            distance = obj.calculateDistanceAccessibility(spatial_data);
            
            % 3. 计算季节可达性
            season = obj.calculateSeasonalAccessibility();
            
            accessibility = struct(...
                'terrain', terrain, ...
                'distance', distance, ...
                'season', season, ...
                'total', terrain .* distance .* season);
        end
        
        function terrain = calculateTerrainAccessibility(obj, spatial_data)
            % 计算地形可达性
            % 1. 计算坡度
            [slope, ~] = obj.calculateSlopeAspect(spatial_data);
            
            % 2. 计算可达性
            terrain = exp(-slope * 0.1);  % 坡度越大可达性越低
        end
        
        function distance = calculateDistanceAccessibility(obj, spatial_data)
            % 计算距离可达性
            % 1. 识别可达点
            access_points = spatial_data < mean(spatial_data(:));
            
            % 2. 计算距离衰减
            distance = exp(-bwdist(access_points) * obj.Parameters.distance_decay);
        end
        
        function season = calculateSeasonalAccessibility(obj)
            % 计算季节可达性（示例：使用简单的空间变化）
            [rows, cols] = size(obj.SpatialData);
            [X, Y] = meshgrid(1:cols, 1:rows);
            
            % 创建空间变化的季节性可达性
            season = 0.7 + 0.3 * sin(2*pi*X/cols + 2*pi*Y/rows);
        end
        
        function yield = calculateFishingYield(obj, resources, pressure, accessibility)
            % 计算捕捞产出
            % 1. 计算基础产出
            base_yield = resources.total .* pressure.total .* accessibility.total;
            
            % 2. 应用可持续性约束
            sustainability = obj.calculateSustainabilityConstraint(resources, pressure);
            
            % 3. 计算最终产出
            yield = base_yield .* sustainability;
            
            % 4. 应用空间平滑
            kernel = fspecial('gaussian', [3 3], 0.5);
            yield = conv2(yield, kernel, 'same');
        end
        
        function sustainability = calculateSustainabilityConstraint(obj, resources, pressure)
            % 计算可持续性约束
            % 1. 计算开发强度
            exploitation = pressure.total ./ (resources.total + eps);
            
            % 2. 应用可持续性阈值
            threshold = 0.7;  % 假设70%为可持续开发上限
            sustainability = 1 - min(1, exploitation/threshold);
        end
    end
    
    methods (Access = private)
        function capacity = calculateSupplyCapacity(obj, data)
            % 计算供给能力
            % 1. 标准化数据
            normalized = (data - min(data(:))) ./ (max(data(:)) - min(data(:)));
            
            % 2. 应用权重
            weighted = normalized * obj.Parameters.supply_weight;
            
            % 3. 计算供给能力
            capacity = struct('raw', data, ...
                            'normalized', normalized, ...
                            'weighted', weighted, ...
                            'total', sum(weighted(:)));
        end
        
        function quality = evaluateSupplyQuality(obj, data)
            % 评估供给质量
            % 1. 计算基本统计量
            stats = struct('mean', mean(data(:)), ...
                         'std', std(data(:)), ...
                         'min', min(data(:)), ...
                         'max', max(data(:)));
            
            % 2. 计算空间自相关
            [r, lags] = xcorr2(data);
            spatial_correlation = struct('correlation', r, ...
                                      'lags', lags);
            
            % 3. 评估质量等级
            if stats.std / stats.mean < 0.1
                grade = 'high';
            elseif stats.std / stats.mean < 0.3
                grade = 'medium';
            else
                grade = 'low';
            end
            
            quality = struct('statistics', stats, ...
                           'spatial_correlation', spatial_correlation, ...
                           'grade', grade);
        end
        
        function distribution = analyzeSupplyDistribution(obj, data)
            % 分析供给空间分布
            % 1. 计算空间聚集度
            [clusters, num_clusters] = bwlabel(data > mean(data(:)));
            cluster_stats = regionprops(clusters, 'Area', 'Centroid');
            
            % 2. 计算方向性
            [gx, gy] = gradient(data);
            direction = atan2(gy, gx);
            magnitude = sqrt(gx.^2 + gy.^2);
            
            % 3. 分析空间格局
            pattern = struct('clusters', clusters, ...
                           'num_clusters', num_clusters, ...
                           'cluster_stats', cluster_stats, ...
                           'direction', direction, ...
                           'magnitude', magnitude);
            
            distribution = struct('pattern', pattern, ...
                                'hotspots', data > (mean(data(:)) + 2*std(data(:))), ...
                                'coldspots', data < (mean(data(:)) - 2*std(data(:))));
        end
        
        function potential = calculateSupplyPotential(obj, capacity, quality)
            % 计算供给潜力
            % 1. 基于容量和质量计算潜力
            base_potential = capacity.weighted .* (strcmp(quality.grade, 'high') * 1.2 + ...
                                                strcmp(quality.grade, 'medium') * 1.0 + ...
                                                strcmp(quality.grade, 'low') * 0.8);
            
            % 2. 考虑空间分布影响
            spatial_factor = quality.spatial_correlation.correlation(1);
            
            % 3. 计算最终潜力
            potential = struct('base', base_potential, ...
                             'spatial_factor', spatial_factor, ...
                             'final', base_potential .* spatial_factor);
        end
        
        function quantity = calculateDemandQuantity(obj, data)
            % 计算需求量
            % 1. 标准化数据
            normalized = (data - min(data(:))) ./ (max(data(:)) - min(data(:)));
            
            % 2. 应用权重
            weighted = normalized * obj.Parameters.demand_weight;
            
            % 3. 计算总需求量
            quantity = struct('raw', data, ...
                            'normalized', normalized, ...
                            'weighted', weighted, ...
                            'total', sum(weighted(:)));
        end
        
        function intensity = evaluateDemandIntensity(obj, data)
            % 评估需求强度
            % 1. 计算局部密度
            density = conv2(data, ones(3)/9, 'same');
            
            % 2. 计算时空变异性
            temporal_var = std(data, 0, 3);  % 假设数据包含时间维度
            spatial_var = std(reshape(data, [], size(data, 3)));
            
            % 3. 评估强度等级
            mean_density = mean(density(:));
            if mean_density > 0.7
                grade = 'high';
            elseif mean_density > 0.3
                grade = 'medium';
            else
                grade = 'low';
            end
            
            intensity = struct('density', density, ...
                             'temporal_variation', temporal_var, ...
                             'spatial_variation', spatial_var, ...
                             'grade', grade);
        end
        
        function distribution = analyzeDemandDistribution(obj, data)
            % 分析需求分布
            % 1. 计算空间聚集度
            [clusters, num_clusters] = bwlabel(data > mean(data(:)));
            cluster_stats = regionprops(clusters, 'Area', 'Centroid');
            
            % 2. 分析空间关联性
            [r, lags] = xcorr2(data);
            spatial_correlation = struct('correlation', r, ...
                                      'lags', lags);
            
            % 3. 识别需求热点
            hotspots = data > (mean(data(:)) + 2*std(data(:)));
            
            distribution = struct('clusters', clusters, ...
                                'num_clusters', num_clusters, ...
                                'cluster_stats', cluster_stats, ...
                                'spatial_correlation', spatial_correlation, ...
                                'hotspots', hotspots);
        end
        
        function pressure = calculateDemandPressure(obj, quantity, intensity)
            % 计算需求压力
            % 1. 计算基础压力
            base_pressure = quantity.weighted .* (strcmp(intensity.grade, 'high') * 1.5 + ...
                                               strcmp(intensity.grade, 'medium') * 1.0 + ...
                                               strcmp(intensity.grade, 'low') * 0.5);
            
            % 2. 考虑时空变异性
            variation_factor = mean(intensity.temporal_variation(:)) * ...
                             mean(intensity.spatial_variation(:));
            
            % 3. 计算最终压力
            pressure = struct('base', base_pressure, ...
                            'variation_factor', variation_factor, ...
                            'final', base_pressure .* (1 + variation_factor));
        end
        
        function coefficient = calculateResistanceCoefficient(obj, data)
            % 计算阻力系数
            % 1. 标准化阻力数据
            normalized = (data - min(data(:))) ./ (max(data(:)) - min(data(:)));
            
            % 2. 应用阻力因子
            weighted = normalized * obj.Parameters.resistance_factor;
            
            % 3. 计算累积阻力
            accumulated = cumsum(cumsum(weighted, 1), 2);
            
            coefficient = struct('raw', data, ...
                               'normalized', normalized, ...
                               'weighted', weighted, ...
                               'accumulated', accumulated);
        end
        
        function impact = evaluateResistanceImpact(obj, data)
            % 评估阻力影响
            % 1. 计算阻力梯度
            [gx, gy] = gradient(data);
            gradient_magnitude = sqrt(gx.^2 + gy.^2);
            
            % 2. 识别阻力障碍
            barriers = data > (mean(data(:)) + std(data(:)));
            
            % 3. 计算影响范围
            impact_range = bwdist(barriers);
            
            impact = struct('gradient', gradient_magnitude, ...
                          'barriers', barriers, ...
                          'impact_range', impact_range);
        end
        
        function distribution = analyzeResistanceDistribution(obj, data)
            % 分析阻力分布
            % 1. 计算空间自相关
            [r, lags] = xcorr2(data);
            
            % 2. 识别阻力集中区
            high_resistance = data > (mean(data(:)) + std(data(:)));
            [clusters, num_clusters] = bwlabel(high_resistance);
            
            % 3. 分析空间格局
            pattern = struct('clusters', clusters, ...
                           'num_clusters', num_clusters, ...
                           'correlation', r, ...
                           'lags', lags);
            
            distribution = struct('pattern', pattern, ...
                                'high_resistance_areas', high_resistance);
        end
        
        function accumulation = calculateResistanceAccumulation(obj, coefficient, impact)
            % 计算累积阻力
            % 1. 计算基础累积
            base_accumulation = coefficient.accumulated .* impact.gradient;
            
            % 2. 考虑障碍影响
            barrier_effect = exp(-impact.impact_range * obj.Parameters.distance_decay);
            
            % 3. 计算总累积阻力
            accumulation = struct('base', base_accumulation, ...
                                'barrier_effect', barrier_effect, ...
                                'total', base_accumulation .* barrier_effect);
        end
        
        function paths = calculateFlowPaths(obj)
            % 计算流动路径
            % 1. 构建成本矩阵
            cost = obj.Results.resistance.accumulation.total;
            
            % 2. 识别源点和汇点
            sources = obj.Results.supply.distribution.hotspots;
            sinks = obj.Results.demand.distribution.hotspots;
            
            % 3. 计算最小成本路径
            [source_points, ~] = find(sources);
            [sink_points, ~] = find(sinks);
            
            paths = cell(size(source_points, 1), size(sink_points, 1));
            for i = 1:size(source_points, 1)
                for j = 1:size(sink_points, 1)
                    paths{i,j} = obj.findMinCostPath(cost, ...
                                                   source_points(i,:), ...
                                                   sink_points(j,:));
                end
            end
        end
        
        function intensity = evaluateFlowIntensity(obj)
            % 评估流动强度
            % 1. 计算供需匹配度
            supply = obj.Results.supply.potential.final;
            demand = obj.Results.demand.pressure.final;
            matching = min(supply, demand) ./ max(supply, demand);
            
            % 2. 考虑阻力影响
            resistance = obj.Results.resistance.accumulation.total;
            resistance_effect = exp(-resistance * obj.Parameters.resistance_factor);
            
            % 3. 计算流动强度
            intensity = struct('matching', matching, ...
                             'resistance_effect', resistance_effect, ...
                             'final', matching .* resistance_effect);
        end
        
        function efficiency = analyzeFlowEfficiency(obj)
            % 分析流动效率
            % 1. 计算理论最大流动
            max_flow = min(obj.Results.supply.capacity.total, ...
                         obj.Results.demand.quantity.total);
            
            % 2. 计算实际流动
            actual_flow = sum(obj.Results.spatial_flow.intensity.final(:));
            
            % 3. 计算效率指标
            efficiency = struct('max_flow', max_flow, ...
                              'actual_flow', actual_flow, ...
                              'ratio', actual_flow / max_flow);
        end
        
        function flux = calculateFlowFlux(obj, paths, intensity)
            % 计算流动通量
            % 1. 初始化通量矩阵
            flux_matrix = zeros(size(obj.SupplyData));
            
            % 2. 累积路径上的流动量
            for i = 1:size(paths, 1)
                for j = 1:size(paths, 2)
                    path = paths{i,j};
                    if ~isempty(path)
                        for k = 1:size(path, 1)
                            flux_matrix(path(k,1), path(k,2)) = ...
                                flux_matrix(path(k,1), path(k,2)) + ...
                                intensity.final(path(k,1), path(k,2));
                        end
                    end
                end
            end
            
            % 3. 计算通量统计
            flux = struct('matrix', flux_matrix, ...
                         'total', sum(flux_matrix(:)), ...
                         'mean', mean(flux_matrix(:)), ...
                         'std', std(flux_matrix(:)));
        end
        
        function valid = checkBoundaryConsistency(obj)
            % 检查边界一致性
            % 获取所有数据的边界值
            supply_boundary = obj.SupplyData([1,end],:);
            supply_boundary = [supply_boundary; obj.SupplyData(:,[1,end])'];
            
            demand_boundary = obj.DemandData([1,end],:);
            demand_boundary = [demand_boundary; obj.DemandData(:,[1,end])'];
            
            resistance_boundary = obj.ResistanceData([1,end],:);
            resistance_boundary = [resistance_boundary; obj.ResistanceData(:,[1,end])'];
            
            % 检查边界值的一致性
            valid = all(abs(supply_boundary(:)) <= obj.Parameters.validation_threshold) && ...
                   all(abs(demand_boundary(:)) <= obj.Parameters.validation_threshold) && ...
                   all(abs(resistance_boundary(:)) <= obj.Parameters.validation_threshold);
        end
        
        function valid = validateElevationRange(obj)
            % 验证高程范围
            if ~isfield(obj.SpatialData, 'dem')
                valid = true;
                return;
            end
            
            dem = obj.SpatialData.dem;
            valid = all(dem(:) >= -500) && all(dem(:) <= 9000);  % 合理的高程范围
        end
        
        function valid = validateSlopeRange(obj)
            % 验证坡度范围
            if ~isfield(obj.SpatialData, 'slope')
                valid = true;
                return;
            end
            
            slope = obj.SpatialData.slope;
            valid = all(slope(:) >= 0) && all(slope(:) <= 90);  % 坡度范围0-90度
        end
        
        function valid = validateMassConservation(obj)
            % 验证质量守恒
            % 计算总供给量
            total_supply = sum(obj.SupplyData(:));
            
            % 计算总需求量
            total_demand = sum(obj.DemandData(:));
            
            % 检查质量守恒
            if strcmp(obj.Parameters.source_type, 'finite')
                valid = abs(total_supply - total_demand) / max(total_supply, total_demand) <= ...
                    obj.Parameters.validation_threshold;
            else
                valid = true;  % 无限源不需要检查质量守恒
            end
        end
        
        function valid = validateEnergyConservation(obj)
            % 验证能量守恒
            % 根据不同模型类型验证能量守恒
            switch obj.FlowModel
                case {'surface-water', 'flood-water'}
                    valid = obj.validateHydraulicEnergy();
                case 'sediment'
                    valid = obj.validateSedimentEnergy();
                otherwise
                    valid = true;  % 其他模型暂不验证能量守恒
            end
        end
        
        function valid = validateFlowConstraints(obj)
            % 验证流动约束
            valid = true;
            
            % 检查流动方向的物理合理性
            if isfield(obj.SpatialData, 'dem')
                [gx, gy] = gradient(obj.SpatialData.dem);
                flow_direction = atan2(gy, gx);
                
                % 检查流向是否符合重力方向
                valid = valid && all(flow_direction(:) >= -pi) && ...
                        all(flow_direction(:) <= pi);
            end
            
            % 检查流速限制
            if isfield(obj.SpatialData, 'velocity')
                valid = valid && all(obj.SpatialData.velocity(:) >= 0) && ...
                        all(obj.SpatialData.velocity(:) <= 30);  % 合理的流速范围
            end
        end
        
        function valid = validateHydraulicEnergy(obj)
            % 验证水力能量守恒
            if ~isfield(obj.SpatialData, 'dem') || ~isfield(obj.SpatialData, 'velocity')
                valid = true;
                return;
            end
            
            % 计算势能
            potential_energy = 9.81 * obj.SpatialData.dem;  % g*h
            
            % 计算动能
            kinetic_energy = 0.5 * obj.SpatialData.velocity.^2;  % 1/2*v^2
            
            % 检查总能量变化
            total_energy_upstream = sum(potential_energy(:) + kinetic_energy(:));
            total_energy_downstream = sum(potential_energy(end,:) + kinetic_energy(end,:));
            
            valid = total_energy_downstream <= total_energy_upstream;
        end
        
        function valid = validateSedimentEnergy(obj)
            % 验证泥沙输移能量守恒
            if ~isfield(obj.SpatialData, 'dem') || ~isfield(obj.SpatialData, 'sediment_concentration')
                valid = true;
                return;
            end
            
            % 计算泥沙势能
            sediment_potential = 9.81 * obj.SpatialData.dem .* obj.SpatialData.sediment_concentration;
            
            % 检查泥沙输移过程中的能量变化
            total_energy_upstream = sum(sediment_potential(:));
            total_energy_downstream = sum(sediment_potential(end,:));
            
            valid = total_energy_downstream <= total_energy_upstream;
        end
        
        function results = validateSurfaceWaterModel(obj)
            % 地表水模型特定验证
            results = struct();
            
            % 验证水文连续性
            results.hydrological_continuity = obj.validateHydrologicalContinuity();
            
            % 验证流向合理性
            results.flow_direction = obj.validateFlowDirection();
            
            % 验证流速范围
            results.velocity_range = obj.validateVelocityRange();
        end
        
        function results = validateSedimentModel(obj)
            % 泥沙模型特定验证
            results = struct();
            
            % 验证泥沙浓度范围
            results.concentration_range = obj.validateSedimentConcentration();
            
            % 验证输移能力
            results.transport_capacity = obj.validateTransportCapacity();
            
            % 验证沉积分布
            results.deposition_pattern = obj.validateDepositionPattern();
        end
        
        function results = validateLineOfSightModel(obj)
            % 视线模型特定验证
            results = struct();
            
            % 验证视点位置
            results.viewpoint_position = obj.validateViewpointPosition();
            
            % 验证视距范围
            results.visibility_range = obj.validateVisibilityRange();
            
            % 验证遮挡效应
            results.occlusion_effect = obj.validateOcclusionEffect();
        end
        
        % ... Add other model-specific validation methods ...
        
        function visualizeValidationResults(obj)
            % 可视化验证结果
            figure('Name', '验证结果可视化');
            
            % 1. 基础数据验证结果
            subplot(2,2,1);
            obj.plotBasicValidation();
            title('基础数据验证');
            
            % 2. 空间一致性验证结果
            subplot(2,2,2);
            obj.plotSpatialValidation();
            title('空间一致性验证');
            
            % 3. 物理约束验证结果
            subplot(2,2,3);
            obj.plotPhysicalValidation();
            title('物理约束验证');
            
            % 4. 模型特定验证结果
            subplot(2,2,4);
            obj.plotModelSpecificValidation();
            title('模型特定验证');
        end
        
        function plotBasicValidation(obj)
            % 绘制基础数据验证结果
            results = obj.ValidationResults.basic;
            categories = {'完整性', '数据类型', '数据质量'};
            data_types = {'供给', '需求', '阻力', '空间'};
            
            % 创建验证结果矩阵
            validation_matrix = [...
                structfun(@double, results.completeness);
                structfun(@double, results.data_type);
                structfun(@double, results.quality)];
            
            % 绘制热力图
            imagesc(validation_matrix);
            colormap('summer');
            colorbar;
            
            % 设置标签
            set(gca, 'XTickLabel', data_types);
            set(gca, 'YTickLabel', categories);
            xtickangle(45);
        end
        
        function plotSpatialValidation(obj)
            % 绘制空间一致性验证结果
            results = obj.ValidationResults.spatial;
            
            % 提取验证结果
            consistency = structfun(@double, results.size_consistency);
            reference = double(results.spatial_reference);
            boundary = double(results.boundary_consistency);
            
            % 创建条形图
            bar([consistency, reference, boundary]);
            
            % 设置标签
            categories = {'尺寸一致性', '空间参考', '边界一致性'};
            set(gca, 'XTickLabel', categories);
            xtickangle(45);
            ylim([0 1.2]);
        end
        
        function plotPhysicalValidation(obj)
            % 绘制物理约束验证结果
            results = obj.ValidationResults.physical;
            
            % 提取验证结果
            validation_results = [
                double(results.mass_conservation)
                double(results.energy_conservation)
                double(results.flow_constraints)
            ];
            
            % 创建条形图
            bar(validation_results);
            
            % 设置标签
            categories = {'质量守恒', '能量守恒', '流动约束'};
            set(gca, 'XTickLabel', categories);
            xtickangle(45);
            ylim([0 1.2]);
        end
        
        function plotModelSpecificValidation(obj)
            % 绘制模型特定验证结果
            results = obj.ValidationResults.model;
            
            % 根据不同模型类型绘制验证结果
            switch obj.FlowModel
                case 'surface-water'
                    obj.plotSurfaceWaterValidation(results);
                case 'sediment'
                    obj.plotSedimentValidation(results);
                case 'line-of-sight'
                    obj.plotLineOfSightValidation(results);
                otherwise
                    text(0.5, 0.5, '暂无特定验证结果', ...
                        'HorizontalAlignment', 'center');
            end
        end
        
        function plotSurfaceWaterValidation(obj, results)
            % 绘制地表水模型验证结果
            validation_results = [
                double(results.hydrological_continuity)
                double(results.flow_direction)
                double(results.velocity_range)
            ];
            
            % 创建条形图
            bar(validation_results);
            
            % 设置标签
            categories = {'水文连续性', '流向合理性', '流速范围'};
            set(gca, 'XTickLabel', categories);
            xtickangle(45);
            ylim([0 1.2]);
        end
        
        % ... Add other visualization methods ...
        
        function valid = validateHydrologicalContinuity(obj)
            % 验证水文连续性
            if ~isfield(obj.SpatialData, 'precipitation') || ...
               ~isfield(obj.SpatialData, 'runoff') || ...
               ~isfield(obj.SpatialData, 'infiltration') || ...
               ~isfield(obj.SpatialData, 'evaporation')
                valid = true;
                return;
            end
            
            % 计算水量平衡
            total_precipitation = sum(obj.SpatialData.precipitation(:));
            total_runoff = sum(obj.SpatialData.runoff(:));
            total_infiltration = sum(obj.SpatialData.infiltration(:));
            total_evaporation = sum(obj.SpatialData.evaporation(:));
            
            % 检查水量平衡误差
            water_balance_error = abs(total_precipitation - ...
                (total_runoff + total_infiltration + total_evaporation)) / total_precipitation;
            
            valid = water_balance_error <= obj.Parameters.validation_threshold;
        end
        
        function valid = validateFlowDirection(obj)
            % 验证流向合理性
            if ~isfield(obj.SpatialData, 'flow_direction') || ...
               ~isfield(obj.SpatialData, 'dem')
                valid = true;
                return;
            end
            
            % 检查流向编码是否合法(D8方法：1-8)
            flow_dir = obj.SpatialData.flow_direction;
            valid = all(flow_dir(:) >= 1 & flow_dir(:) <= 8);
            
            % 检查流向是否符合地形
            if valid
                [rows, cols] = size(flow_dir);
                dem = obj.SpatialData.dem;
                
                for i = 2:rows-1
                    for j = 2:cols-1
                        % 获取当前栅格的流向
                        direction = flow_dir(i,j);
                        
                        % 获取下游栅格位置
                        [next_i, next_j] = obj.getDownstreamCell(i, j, direction);
                        
                        % 检查是否符合地形
                        if dem(i,j) <= dem(next_i, next_j)
                            valid = false;
                            return;
                        end
                    end
                end
            end
        end
        
        function valid = validateVelocityRange(obj)
            % 验证流速范围
            if ~isfield(obj.SpatialData, 'velocity')
                valid = true;
                return;
            end
            
            velocity = obj.SpatialData.velocity;
            
            % 检查流速是否在合理范围内
            valid = all(velocity(:) >= 0) && all(velocity(:) <= 30);  % 单位：m/s
        end
        
        function valid = validateSedimentConcentration(obj)
            % 验证泥沙浓度范围
            if ~isfield(obj.SpatialData, 'sediment_concentration')
                valid = true;
                return;
            end
            
            concentration = obj.SpatialData.sediment_concentration;
            
            % 检查浓度是否在合理范围内(0-1000 kg/m³)
            valid = all(concentration(:) >= 0) && all(concentration(:) <= 1000);
        end
        
        function valid = validateTransportCapacity(obj)
            % 验证输移能力
            if ~isfield(obj.SpatialData, 'transport_capacity') || ...
               ~isfield(obj.SpatialData, 'sediment_load')
                valid = true;
                return;
            end
            
            capacity = obj.SpatialData.transport_capacity;
            load = obj.SpatialData.sediment_load;
            
            % 检查输移量是否不超过输移能力
            valid = all(load(:) <= capacity(:));
        end
        
        function valid = validateDepositionPattern(obj)
            % 验证沉积分布
            if ~isfield(obj.SpatialData, 'deposition') || ...
               ~isfield(obj.SpatialData, 'slope')
                valid = true;
                return;
            end
            
            deposition = obj.SpatialData.deposition;
            slope = obj.SpatialData.slope;
            
            % 检查沉积是否主要发生在坡度较小的区域
            low_slope_mask = slope <= 5;  % 坡度小于5度的区域
            total_deposition = sum(deposition(:));
            low_slope_deposition = sum(deposition(low_slope_mask));
            
            valid = low_slope_deposition / total_deposition >= 0.7;  % 70%的沉积应发生在缓坡区
        end
        
        function valid = validateViewpointPosition(obj)
            % 验证视点位置
            if ~isfield(obj.SpatialData, 'viewpoints') || ...
               ~isfield(obj.SpatialData, 'dem')
                valid = true;
                return;
            end
            
            viewpoints = obj.SpatialData.viewpoints;
            dem = obj.SpatialData.dem;
            
            % 检查视点是否在有效范围内
            [rows, cols] = size(dem);
            valid = all(viewpoints(:,1) >= 1 & viewpoints(:,1) <= rows & ...
                       viewpoints(:,2) >= 1 & viewpoints(:,2) <= cols);
        end
        
        function valid = validateVisibilityRange(obj)
            % 验证视距范围
            if ~isfield(obj.SpatialData, 'visibility_range')
                valid = true;
                return;
            end
            
            range = obj.SpatialData.visibility_range;
            
            % 检查视距是否在合理范围内(0-50km)
            valid = all(range(:) >= 0) && all(range(:) <= 50000);
        end
        
        function valid = validateOcclusionEffect(obj)
            % 验证遮挡效应
            if ~isfield(obj.SpatialData, 'visibility') || ...
               ~isfield(obj.SpatialData, 'dem')
                valid = true;
                return;
            end
            
            visibility = obj.SpatialData.visibility;
            dem = obj.SpatialData.dem;
            
            % 检查高程差异大的区域是否存在遮挡
            [gx, gy] = gradient(dem);
            steep_mask = sqrt(gx.^2 + gy.^2) > 1;  % 坡度大于45度的区域
            
            % 在陡峭区域后方应该存在遮挡
            valid = all(visibility(steep_mask) < 1);
        end
        
        function plotSedimentValidation(obj, results)
            % 绘制泥沙模型验证结果
            validation_results = [
                double(results.concentration_range)
                double(results.transport_capacity)
                double(results.deposition_pattern)
            ];
            
            % 创建条形图
            bar(validation_results);
            
            % 设置标签
            categories = {'浓度范围', '输移能力', '沉积分布'};
            set(gca, 'XTickLabel', categories);
            xtickangle(45);
            ylim([0 1.2]);
        end
        
        function plotLineOfSightValidation(obj, results)
            % 绘制视线模型验证结果
            validation_results = [
                double(results.viewpoint_position)
                double(results.visibility_range)
                double(results.occlusion_effect)
            ];
            
            % 创建条形图
            bar(validation_results);
            
            % 设置标签
            categories = {'视点位置', '视距范围', '遮挡效应'};
            set(gca, 'XTickLabel', categories);
            xtickangle(45);
            ylim([0 1.2]);
        end
        
        function visualizeUncertainty(obj)
            % 可视化不确定性分析结果
            if ~isfield(obj.Results, 'uncertainty')
                return;
            end
            
            uncertainty = obj.Results.uncertainty;
            figure('Name', '不确定性分析');
            
            % 1. 各组分不确定性
            subplot(2,2,1);
            components = {'供给', '需求', '阻力'};
            uncertainties = [uncertainty.supply, uncertainty.demand, uncertainty.resistance];
            bar(uncertainties);
            set(gca, 'XTickLabel', components);
            title('组分不确定性');
            ylim([0 1]);
            
            % 2. 空间分布不确定性
            subplot(2,2,2);
            if isfield(uncertainty, 'spatial_distribution')
                imagesc(uncertainty.spatial_distribution);
                colorbar;
                title('空间分布不确定性');
            end
            
            % 3. 时间变异不确定性
            subplot(2,2,3);
            if isfield(uncertainty, 'temporal_variation')
                plot(uncertainty.temporal_variation);
                title('时间变异不确定性');
                xlabel('时间步长');
                ylabel('不确定性');
            end
            
            % 4. 综合不确定性
            subplot(2,2,4);
            text(0.5, 0.5, sprintf('总体不确定性: %.2f%%', uncertainty.total * 100), ...
                'HorizontalAlignment', 'center');
            axis off;
        end
        
        function visualizeValidationSummary(obj)
            % 可视化验证结果总结
            figure('Name', '验证结果总结');
            
            % 1. 验证通过率
            subplot(2,2,1);
            obj.plotValidationPassRate();
            
            % 2. 验证错误分布
            subplot(2,2,2);
            obj.plotValidationErrorDistribution();
            
            % 3. 时间序列验证
            subplot(2,2,3);
            obj.plotTemporalValidation();
            
            % 4. 空间验证
            subplot(2,2,4);
            obj.plotSpatialValidationMap();
        end
        
        function plotValidationPassRate(obj)
            % 绘制验证通过率
            results = obj.ValidationResults;
            categories = {'基础', '空间', '物理', '模型特定'};
            
            % 计算各类验证的通过率
            pass_rates = [
                mean(structfun(@mean, results.basic))
                mean(structfun(@mean, results.spatial))
                mean([results.physical.mass_conservation, ...
                     results.physical.energy_conservation, ...
                     results.physical.flow_constraints])
                mean(structfun(@mean, results.model))
            ];
            
            % 创建饼图
            pie(pass_rates);
            legend(categories, 'Location', 'eastoutside');
            title('验证通过率');
        end
        
        function plotValidationErrorDistribution(obj)
            % 绘制验证错误分布
            results = obj.ValidationResults;
            
            % 统计各类错误
            error_counts = struct();
            error_counts.data_quality = sum(~structfun(@all, results.basic.quality));
            error_counts.spatial = sum(~structfun(@all, results.spatial.size_consistency));
            error_counts.physical = sum(~[results.physical.mass_conservation, ...
                                        results.physical.energy_conservation, ...
                                        results.physical.flow_constraints]);
            error_counts.model_specific = sum(~structfun(@all, results.model));
            
            % 创建帕累托图
            pareto(struct2array(error_counts));
            set(gca, 'XTickLabel', fieldnames(error_counts));
            title('验证错误分布');
        end
        
        function plotTemporalValidation(obj)
            % 绘制时间序列验证结果
            if ~isfield(obj.Results, 'temporal_validation')
                text(0.5, 0.5, '无时间序列验证数据', ...
                    'HorizontalAlignment', 'center');
                return;
            end
            
            temporal = obj.Results.temporal_validation;
            plot(temporal.time, temporal.validation_score);
            title('时间序列验证');
            xlabel('时间');
            ylabel('验证得分');
        end
        
        function plotSpatialValidationMap(obj)
            % 绘制空间验证地图
            if ~isfield(obj.Results, 'spatial_validation')
                text(0.5, 0.5, '无空间验证数据', ...
                    'HorizontalAlignment', 'center');
                return;
            end
            
            spatial = obj.Results.spatial_validation;
            imagesc(spatial.validation_map);
            colorbar;
            title('空间验证地图');
        end
    end
end 