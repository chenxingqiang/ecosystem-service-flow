classdef DataManager < handle
    % DataManager 数据管理类
    % 用于处理数据的导入、导出和预处理
    
    properties (Access = private)
        % 数据存储
        Data = struct('supply', [], 'demand', [], 'resistance', [], 'spatial', []);
        
        % 支持的文件格式
        SupportedFormats = struct(...
            'import', {{'.csv', '.xlsx', '.txt', '.mat', '.tif', '.asc'}}, ...
            'export', {{'.csv', '.xlsx', '.mat', '.tif', '.asc'}});
        
        % 数据验证设置
        ValidationSettings = struct(...
            'check_dimensions', true, ...    % 检查维度一致性
            'check_data_type', true, ...     % 检查数据类型
            'check_range', true, ...         % 检查数据范围
            'allow_nan', true, ...          % 是否允许NaN
            'allow_inf', false);             % 是否允许Inf
    end
    
    methods
        function obj = DataManager()
            % 构造函数
            % 数据存储已在属性定义时初始化
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
            if ~ismember(lower(ext), obj.SupportedFormats.import{1})
                error('不支持的文件格式: %s', ext);
            end
            
            % 根据文件类型导入数据
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
            end
            
            % 预处理：处理无效值
            if isfield(options, 'nodata_value')
                data(data == options.nodata_value) = NaN;
            end
            
            % 验证数据
            if obj.validateData(data, data_type)
                obj.Data.(data_type) = data;
            end
        end
        
        function success = exportData(obj, data, filepath, format, options)
            % 导出数据
            if nargin < 5
                options = struct();
            end
            
            % 验证格式
            if ~ismember(lower(format), obj.SupportedFormats.export{1})
                error('不支持的导出格式: %s', format);
            end
            
            try
                switch lower(format)
                    case '.csv'
                        success = obj.exportCSV(data, filepath, options);
                    case '.xlsx'
                        success = obj.exportExcel(data, filepath, options);
                    case '.mat'
                        success = obj.exportMAT(data, filepath, options);
                    case '.tif'
                        success = obj.exportGeoTIFF(data, filepath, options);
                    case '.asc'
                        success = obj.exportASCGrid(data, filepath, options);
                end
            catch e
                error('数据导出失败: %s', e.message);
            end
        end
        
        function preprocessData(obj, data_type, operations)
            % 数据预处理
            if ~isfield(obj.Data, data_type)
                error('数据类型不存在: %s', data_type);
            end
            
            data = obj.Data.(data_type);
            if isempty(data)
                error('数据为空: %s', data_type);
            end
            
            for i = 1:length(operations)
                op = operations{i};
                switch op.type
                    case 'normalize'
                        % 处理NaN值
                        valid_data = data(~isnan(data));
                        if isempty(valid_data)
                            data = zeros(size(data));
                        else
                            min_val = min(valid_data);
                            max_val = max(valid_data);
                            if max_val == min_val
                                data(~isnan(data)) = 0;
                            else
                                data = (data - min_val) / (max_val - min_val);
                            end
                        end
                    case 'standardize'
                        % 处理NaN值
                        valid_data = data(~isnan(data));
                        if isempty(valid_data)
                            data = zeros(size(data));
                        else
                            data = (data - mean(valid_data)) / std(valid_data);
                        end
                    case 'fillmissing'
                        data = fillmissing(data, op.method);
                    case 'smooth'
                        % 先填充NaN值，再平滑
                        temp_data = fillmissing(data, 'nearest');
                        data = imgaussfilt(temp_data, op.sigma);
                end
            end
            
            obj.Data.(data_type) = data;
        end
        
        function setSupplyData(obj, data)
            % 设置供给数据
            if obj.validateData(data, 'supply')
                obj.Data.supply = data;
            end
        end
        
        function setDemandData(obj, data)
            % 设置需求数据
            if obj.validateData(data, 'demand')
                obj.Data.demand = data;
            end
        end
        
        function setResistanceData(obj, data)
            % 设置阻力数据
            if obj.validateData(data, 'resistance')
                obj.Data.resistance = data;
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
    end
    
    methods (Access = private)
        function valid = validateData(obj, data, data_type)
            % 数据验证
            valid = true;
            
            % 检查数据类型
            if obj.ValidationSettings.check_data_type && ~isnumeric(data)
                error('数据必须是数值类型');
            end
            
            % 检查维度
            if obj.ValidationSettings.check_dimensions && ~isempty(obj.Data.supply)
                expected_size = size(obj.Data.supply);
                if ~isempty(expected_size) && ~isequal(size(data), expected_size)
                    error('数据维度不一致');
                end
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
        
        % 导入方法
        function data = importCSV(obj, filepath, options)
            data = readmatrix(filepath);
        end
        
        function data = importExcel(obj, filepath, options)
            data = readmatrix(filepath);
        end
        
        function data = importText(obj, filepath, options)
            data = readmatrix(filepath);
        end
        
        function data = importMAT(obj, filepath, options)
            loaded = load(filepath);
            data = loaded.(char(fieldnames(loaded)));
        end
        
        function data = importGeoTIFF(obj, filepath, options)
            data = double(imread(filepath));
        end
        
        function data = importASCGrid(obj, filepath, options)
            % 读取头信息
            fid = fopen(filepath, 'r');
            header = cell(6,2);
            for i = 1:6
                line = fgetl(fid);
                parts = strsplit(strtrim(line));  % 先去除首尾空格
                header{i,1} = parts{1};
                header{i,2} = str2double(parts{2});
            end
            
            % 读取数据
            data = zeros(header{2,2}, header{1,2}); % nrows x ncols
            for i = 1:header{2,2}
                line = fgetl(fid);
                if ~ischar(line)
                    break;
                end
                % 先去除首尾空格，再按空格分割
                values = str2double(strsplit(strtrim(line)));
                % 确保数据维度正确
                if length(values) > header{1,2}
                    values = values(1:header{1,2});
                end
                data(i,1:length(values)) = values;
            end
            fclose(fid);
            
            % 设置nodata值为NaN
            if isfield(options, 'nodata_value')
                data(data == options.nodata_value) = NaN;
            elseif any(strcmp(header{6,1}, {'nodata_value', 'NODATA_value'}))
                data(data == header{6,2}) = NaN;
            end
        end
        
        % 导出方法
        function success = exportCSV(obj, data, filepath, options)
            writematrix(data, filepath);
            success = true;
        end
        
        function success = exportExcel(obj, data, filepath, options)
            writematrix(data, filepath);
            success = true;
        end
        
        function success = exportMAT(obj, data, filepath, options)
            save(filepath, 'data');
            success = true;
        end
        
        function success = exportGeoTIFF(obj, data, filepath, options)
            % 处理NaN值
            data_copy = data;
            if any(isnan(data(:)))
                data_copy(isnan(data)) = 0;
            end
            imwrite(uint8(data_copy * 255), filepath);
            success = true;
        end
        
        function success = exportASCGrid(obj, data, filepath, options)
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
                if ~isfield(options, 'nodata_value')
                    options.nodata_value = -9999;
                end
                
                % 处理NaN值
                data_copy = data;
                if any(isnan(data(:)))
                    data_copy(isnan(data)) = options.nodata_value;
                end
                
                fid = fopen(filepath, 'w');
                fprintf(fid, 'ncols %d\n', ncols);
                fprintf(fid, 'nrows %d\n', nrows);
                fprintf(fid, 'xllcorner %f\n', options.xllcorner);
                fprintf(fid, 'yllcorner %f\n', options.yllcorner);
                fprintf(fid, 'cellsize %f\n', options.cellsize);
                fprintf(fid, 'nodata_value %d\n', options.nodata_value);
                
                for i = 1:nrows
                    fprintf(fid, '%.6f ', data_copy(i,:));
                    fprintf(fid, '\n');
                end
                
                fclose(fid);
                success = true;
            catch
                success = false;
            end
        end
    end
end