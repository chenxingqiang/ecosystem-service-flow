classdef DataManager
    % DataManager 数据管理类
    % 用于处理数据的导入、导出和预处理
    
    properties (Access = private)
        % 数据存储
        Data = struct();
        
        % 支持的文件格式
        SupportedFormats = struct(...
            'import', {'.csv', '.xlsx', '.txt', '.mat', '.tif', '.asc'}, ...
            'export', {'.csv', '.xlsx', '.mat', '.tif', '.asc'});
        
        % 数据验证设置
        ValidationSettings = struct(...
            'check_dimensions', true, ...    % 检查维度一致性
            'check_data_type', true, ...     % 检查数据类型
            'check_range', true, ...         % 检查数据范围
            'allow_nan', false, ...          % 是否允许NaN
            'allow_inf', false);             % 是否允许Inf
    end
    
    methods
        function obj = DataManager()
            % 构造函数
            obj.initializeDataStore();
        end
        
        function data = importData(obj, filepath, data_type, options)
            % 导入数据
            % 参数:
            %   filepath - 文件路径
            %   data_type - 数据类型 (supply/demand/resistance/spatial)
            %   options - 导入选项
            
            if nargin < 4
                options = struct();
            end
            
            % 验证文件路径
            if ~exist(filepath, 'file')
                error('文件不存在: %s', filepath);
            end
            
            % 获取文件扩展名
            [~, ~, ext] = fileparts(filepath);
            if ~ismember(lower(ext), obj.SupportedFormats.import)
                error('不支持的文件格式: %s', ext);
            end
            
            % 根据文件类型导入数据
            try
                switch lower(ext)
                    case '.csv'
                        data = obj.importCSV(filepath, options);
                    case '.xlsx'
                        data = obj.importExcel(filepath, options);
                    case '.txt'
                        data = obj.importText(filepath, options);
                    case '.mat'
                        data = obj.importMAT(filepath, options);
                    case '.tif'
                        data = obj.importGeoTIFF(filepath, options);
                    case '.asc'
                        data = obj.importASCGrid(filepath, options);
                    otherwise
                        error('未实现的导入格式: %s', ext);
                end
                
                % 验证数据
                if obj.validateData(data)
                    % 存储数据
                    obj.Data.(data_type) = data;
                    fprintf('成功导入%s数据\n', data_type);
                end
                
            catch e
                error('导入数据失败: %s', e.message);
            end
        end
        
        function exportData(obj, data, filepath, options)
            % 导出数据
            % 参数:
            %   data - 要导出的数据
            %   filepath - 导出文件路径
            %   options - 导出选项
            
            if nargin < 4
                options = struct();
            end
            
            % 获取文件扩展名
            [path, name, ext] = fileparts(filepath);
            if ~ismember(lower(ext), obj.SupportedFormats.export)
                error('不支持的文件格式: %s', ext);
            end
            
            % 确保输出目录存在
            if ~exist(path, 'dir')
                mkdir(path);
            end
            
            % 根据文件类型导出数据
            try
                switch lower(ext)
                    case '.csv'
                        obj.exportCSV(data, filepath, options);
                    case '.xlsx'
                        obj.exportExcel(data, filepath, options);
                    case '.mat'
                        obj.exportMAT(data, filepath, options);
                    case '.tif'
                        obj.exportGeoTIFF(data, filepath, options);
                    case '.asc'
                        obj.exportASCGrid(data, filepath, options);
                    otherwise
                        error('未实现的导出格式: %s', ext);
                end
                
                fprintf('数据已成功导出至: %s\n', filepath);
                
            catch e
                error('导出数据失败: %s', e.message);
            end
        end
        
        function data = getData(obj, data_type)
            % 获取数据
            if isfield(obj.Data, data_type)
                data = obj.Data.(data_type);
            else
                error('数据类型不存在: %s', data_type);
            end
        end
        
        function setValidationSettings(obj, settings)
            % 设置数据验证参数
            fields = fieldnames(settings);
            for i = 1:length(fields)
                if isfield(obj.ValidationSettings, fields{i})
                    obj.ValidationSettings.(fields{i}) = settings.(fields{i});
                end
            end
        end
        
        function preprocessData(obj, data_type, operations)
            % 数据预处理
            % 参数:
            %   data_type - 要处理的数据类型
            %   operations - 预处理操作列表
            
            if ~isfield(obj.Data, data_type)
                error('数据类型不存在: %s', data_type);
            end
            
            data = obj.Data.(data_type);
            
            % 执行预处理操作
            for i = 1:length(operations)
                op = operations{i};
                switch op.type
                    case 'normalize'
                        data = obj.normalizeData(data, op.method);
                    case 'fillmissing'
                        data = obj.fillMissingValues(data, op.method);
                    case 'smooth'
                        data = obj.smoothData(data, op.window);
                    case 'removeoutliers'
                        data = obj.removeOutliers(data, op.threshold);
                    case 'resample'
                        data = obj.resampleData(data, op.scale);
                    otherwise
                        warning('未知的预处理操作: %s', op.type);
                end
            end
            
            % 更新数据
            obj.Data.(data_type) = data;
        end
    end
    
    methods (Access = private)
        function initializeDataStore(obj)
            % 初始化数据存储
            obj.Data = struct(...
                'supply', [], ...
                'demand', [], ...
                'resistance', [], ...
                'spatial', []);
        end
        
        function data = importCSV(obj, filepath, options)
            % 导入CSV文件
            try
                data = readmatrix(filepath);
            catch
                error('CSV文件读取失败');
            end
        end
        
        function data = importExcel(obj, filepath, options)
            % 导入Excel文件
            try
                data = readmatrix(filepath);
            catch
                error('Excel文件读取失败');
            end
        end
        
        function data = importText(obj, filepath, options)
            % 导入文本文件
            try
                data = readmatrix(filepath);
            catch
                error('文本文件读取失败');
            end
        end
        
        function data = importMAT(obj, filepath, options)
            % 导入MAT文件
            try
                data_struct = load(filepath);
                fields = fieldnames(data_struct);
                data = data_struct.(fields{1});
            catch
                error('MAT文件读取失败');
            end
        end
        
        function data = importGeoTIFF(obj, filepath, options)
            % 导入GeoTIFF文件
            try
                [data, ~] = geotiffread(filepath);
                if isa(data, 'uint8') || isa(data, 'uint16')
                    data = double(data);
                end
            catch
                error('GeoTIFF文件读取失败');
            end
        end
        
        function data = importASCGrid(obj, filepath, options)
            % 导入ASC格网文件
            try
                fid = fopen(filepath, 'r');
                % 读取头信息
                header = textscan(fid, '%s %f', 6);
                % 读取数据
                data = cell2mat(textscan(fid, '%f'));
                fclose(fid);
                
                % 重构网格
                ncols = header{2}(1);
                nrows = header{2}(2);
                data = reshape(data, ncols, nrows)';
            catch
                error('ASC文件读取失败');
            end
        end
        
        function exportCSV(obj, data, filepath, options)
            % 导出CSV文件
            try
                writematrix(data, filepath);
            catch
                error('CSV文件写入失败');
            end
        end
        
        function exportExcel(obj, data, filepath, options)
            % 导出Excel文件
            try
                writematrix(data, filepath);
            catch
                error('Excel文件写入失败');
            end
        end
        
        function exportMAT(obj, data, filepath, options)
            % 导出MAT文件
            try
                save(filepath, 'data');
            catch
                error('MAT文件写入失败');
            end
        end
        
        function exportGeoTIFF(obj, data, filepath, options)
            % 导出GeoTIFF文件
            try
                if ~isfield(options, 'RefMatrix')
                    error('需要提供空间参考矩阵');
                end
                geotiffwrite(filepath, data, options.RefMatrix);
            catch
                error('GeoTIFF文件写入失败');
            end
        end
        
        function exportASCGrid(obj, data, filepath, options)
            % 导出ASC格网文件
            try
                [nrows, ncols] = size(data);
                if ~isfield(options, 'cellsize')
                    options.cellsize = 1;
                end
                if ~isfield(options, 'xllcorner')
                    options.xllcorner = 0;
                end
                if ~isfield(options, 'yllcorner')
                    options.yllcorner = 0;
                end
                if ~isfield(options, 'NODATA_value')
                    options.NODATA_value = -9999;
                end
                
                % 写入文件
                fid = fopen(filepath, 'w');
                fprintf(fid, 'ncols %d\n', ncols);
                fprintf(fid, 'nrows %d\n', nrows);
                fprintf(fid, 'xllcorner %f\n', options.xllcorner);
                fprintf(fid, 'yllcorner %f\n', options.yllcorner);
                fprintf(fid, 'cellsize %f\n', options.cellsize);
                fprintf(fid, 'NODATA_value %d\n', options.NODATA_value);
                
                % 写入数据
                for i = 1:nrows
                    fprintf(fid, '%f ', data(i,:));
                    fprintf(fid, '\n');
                end
                fclose(fid);
            catch
                error('ASC文件写入失败');
            end
        end
        
        function valid = validateData(obj, data)
            % 验证数据
            valid = true;
            
            % 检查数据类型
            if obj.ValidationSettings.check_data_type && ~isnumeric(data)
                error('数据必须为数值型');
            end
            
            % 检查数据范围
            if obj.ValidationSettings.check_range
                if ~obj.ValidationSettings.allow_nan && any(isnan(data(:)))
                    error('数据包含NaN值');
                end
                if ~obj.ValidationSettings.allow_inf && any(isinf(data(:)))
                    error('数据包含Inf值');
                end
            end
        end
        
        function data_norm = normalizeData(obj, data, method)
            % 数据标准化
            switch method
                case 'minmax'
                    data_norm = (data - min(data(:))) / (max(data(:)) - min(data(:)));
                case 'zscore'
                    data_norm = (data - mean(data(:))) / std(data(:));
                case 'robust'
                    med = median(data(:));
                    mad = median(abs(data(:) - med));
                    data_norm = (data - med) / (1.4826 * mad);
                otherwise
                    error('未知的标准化方法: %s', method);
            end
        end
        
        function data_filled = fillMissingValues(obj, data, method)
            % 填充缺失值
            switch method
                case 'mean'
                    data_filled = fillmissing(data, 'constant', mean(data(:), 'omitnan'));
                case 'median'
                    data_filled = fillmissing(data, 'constant', median(data(:), 'omitnan'));
                case 'nearest'
                    data_filled = fillmissing(data, 'nearest');
                case 'linear'
                    data_filled = fillmissing(data, 'linear');
                case 'spline'
                    data_filled = fillmissing(data, 'spline');
                otherwise
                    error('未知的填充方法: %s', method);
            end
        end
        
        function data_smooth = smoothData(obj, data, window)
            % 数据平滑
            if ~exist('window', 'var')
                window = 3;
            end
            kernel = ones(window) / window^2;
            data_smooth = conv2(data, kernel, 'same');
        end
        
        function data_clean = removeOutliers(obj, data, threshold)
            % 去除异常值
            if ~exist('threshold', 'var')
                threshold = 3;
            end
            
            % 使用3σ准则
            mean_val = mean(data(:));
            std_val = std(data(:));
            outliers = abs(data - mean_val) > threshold * std_val;
            
            data_clean = data;
            data_clean(outliers) = mean_val;
        end
        
        function data_resampled = resampleData(obj, data, scale)
            % 重采样数据
            if scale > 1
                % 降采样
                data_resampled = imresize(data, 1/scale, 'bilinear');
            else
                % 升采样
                data_resampled = imresize(data, 1/scale, 'bicubic');
            end
        end
    end
end 