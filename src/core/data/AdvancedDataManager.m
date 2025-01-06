classdef AdvancedDataManager < DataManager
    % AdvancedDataManager 高级数据管理类
    % 扩展基本数据管理功能，提供更高级的数据处理和分析能力
    
    properties (Access = private)
        % 空间参考系统设置
        SpatialReference
        
        % 数据质量控制参数
        QualityControlParams = struct(...
            'outlier_threshold', 3, ...     % 异常值检测阈值（标准差）
            'completeness_threshold', 0.95, ... % 完整性阈值
            'accuracy_threshold', 0.9, ...   % 精度阈值
            'interpolation_method', 'cubic'); % 默认插值方法
    end
    
    methods
        function obj = AdvancedDataManager()
            % 构造函数
            obj@DataManager();
            obj.initializeSpatialReference();
        end
        
        function [cleaned_data, outliers] = detectOutliers(obj, data)
            % 异常值检测
            % 使用改进的Z-score方法
            z_scores = abs((data - median(data(:))) ./ mad(data(:), 1));
            outliers = z_scores > obj.QualityControlParams.outlier_threshold;
            cleaned_data = data;
            cleaned_data(outliers) = NaN;
        end
        
        function normalized_data = normalizeData(obj, data)
            % 数据标准化
            % 使用Min-Max标准化方法
            min_val = min(data(:));
            max_val = max(data(:));
            normalized_data = (data - min_val) / (max_val - min_val);
        end
        
        function interpolated_data = interpolateData(obj, data)
            % 数据插值
            % 支持多种插值方法
            [rows, cols] = size(data);
            [X, Y] = meshgrid(1:cols, 1:rows);
            valid = ~isnan(data);
            interpolated_data = griddata(X(valid), Y(valid), data(valid), ...
                X, Y, obj.QualityControlParams.interpolation_method);
        end
        
        function vector_data = rasterToVector(obj, raster_data)
            % 栅格转矢量
            % 使用等值线提取方法
            [c, h] = contour(raster_data);
            vector_data = struct('contours', c, 'handles', h);
        end
        
        function raster_data = vectorToRaster(obj, vector_data, grid_size)
            % 矢量转栅格
            % 使用栅格化算法
            raster_data = zeros(grid_size);
            contours = vector_data.contours;
            for i = 1:size(contours, 2)
                x = round(contours(1,i));
                y = round(contours(2,i));
                if x > 0 && x <= grid_size(2) && y > 0 && y <= grid_size(1)
                    raster_data(y,x) = 1;
                end
            end
        end
        
        function projected_data = reprojectData(obj, data, source_proj, target_proj)
            % 投影转换
            % 使用MATLAB Mapping Toolbox进行投影转换
            [rows, cols] = size(data);
            [x, y] = meshgrid(1:cols, 1:rows);
            [lat, lon] = projinv(source_proj, x, y);
            [proj_x, proj_y] = projfwd(target_proj, lat, lon);
            projected_data = griddata(proj_x, proj_y, data, x, y);
        end
        
        function [completeness, missing_ratio] = checkCompleteness(obj, data)
            % 完整性检查
            total_elements = numel(data);
            missing_elements = sum(isnan(data(:)));
            missing_ratio = missing_elements / total_elements;
            completeness = missing_ratio <= (1 - obj.QualityControlParams.completeness_threshold);
        end
        
        function [consistency, error_fields] = checkConsistency(obj, data)
            % 一致性检查
            consistency = true;
            error_fields = {};
            
            % 检查数据范围
            if any(data(:) < 0) || any(data(:) > 1)
                consistency = false;
                error_fields{end+1} = 'data_range';
            end
            
            % 检查空间连续性
            gradient_threshold = 0.5;
            [gx, gy] = gradient(data);
            if any(abs(gx(:)) > gradient_threshold) || any(abs(gy(:)) > gradient_threshold)
                consistency = false;
                error_fields{end+1} = 'spatial_continuity';
            end
        end
        
        function [accuracy, rmse] = assessAccuracy(obj, predicted, actual)
            % 精度评估
            diff = predicted - actual;
            rmse = sqrt(mean(diff(:).^2));
            accuracy = 1 - rmse / std(actual(:));
        end
    end
    
    methods (Access = private)
        function initializeSpatialReference(obj)
            % 初始化空间参考系统
            obj.SpatialReference = struct(...
                'projection', 'UTM', ...
                'zone', 50, ...
                'datum', 'WGS84', ...
                'units', 'meters');
        end
    end
end
