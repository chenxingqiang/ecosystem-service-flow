classdef DataProcessor
    % DataProcessor 数据处理类
    % 用于处理各种类型的生态系统服务数据
    
    properties (Access = private)
        CurrentData
        DataType
        MetaData
    end
    
    methods
        function obj = DataProcessor()
            % 构造函数
            obj.CurrentData = [];
            obj.DataType = '';
            obj.MetaData = struct();
        end
        
        function [data, meta] = loadData(obj, filepath)
            % 加载数据文件
            [~, ~, ext] = fileparts(filepath);
            
            switch lower(ext)
                case '.tif'
                    [data, meta] = obj.loadRasterData(filepath);
                    obj.DataType = 'raster';
                case '.shp'
                    [data, meta] = obj.loadVectorData(filepath);
                    obj.DataType = 'vector';
                case '.csv'
                    [data, meta] = obj.loadTableData(filepath, 'csv');
                    obj.DataType = 'table';
                case '.xlsx'
                    [data, meta] = obj.loadTableData(filepath, 'excel');
                    obj.DataType = 'table';
                otherwise
                    error('不支持的文件格式');
            end
            
            obj.CurrentData = data;
            obj.MetaData = meta;
        end
        
        function saveData(obj, filepath, data, format)
            % 保存数据到文件
            if nargin < 3
                data = obj.CurrentData;
            end
            
            [~, ~, ext] = fileparts(filepath);
            
            switch lower(ext)
                case '.tif'
                    obj.saveRasterData(filepath, data);
                case '.shp'
                    obj.saveVectorData(filepath, data);
                case '.csv'
                    obj.saveTableData(filepath, data, 'csv');
                case '.xlsx'
                    obj.saveTableData(filepath, data, 'excel');
                otherwise
                    error('不支持的文件格式');
            end
        end
        
        function data = preprocess(obj, data, options)
            % 数据预处理
            if nargin < 2
                data = obj.CurrentData;
            end
            
            % 根据数据类型进行预处理
            switch obj.DataType
                case 'raster'
                    data = obj.preprocessRaster(data, options);
                case 'vector'
                    data = obj.preprocessVector(data, options);
                case 'table'
                    data = obj.preprocessTable(data, options);
            end
            
            obj.CurrentData = data;
        end
        
        function [result, issues] = checkQuality(obj, data)
            % 数据质量检查
            if nargin < 2
                data = obj.CurrentData;
            end
            
            issues = {};
            
            % 检查数据完整性
            if isempty(data)
                issues{end+1} = '数据为空';
            end
            
            % 根据数据类型进行特定检查
            switch obj.DataType
                case 'raster'
                    [result, rasterIssues] = obj.checkRasterQuality(data);
                    issues = [issues rasterIssues];
                case 'vector'
                    [result, vectorIssues] = obj.checkVectorQuality(data);
                    issues = [issues vectorIssues];
                case 'table'
                    [result, tableIssues] = obj.checkTableQuality(data);
                    issues = [issues tableIssues];
            end
        end
    end
    
    methods (Access = private)
        function [data, meta] = loadRasterData(obj, filepath)
            % 加载栅格数据
            [data, R] = geotiffread(filepath);
            meta.spatial_reference = R;
            meta.size = size(data);
            meta.type = class(data);
        end
        
        function [data, meta] = loadVectorData(obj, filepath)
            % 加载矢量数据
            data = shaperead(filepath);
            meta.attributes = fieldnames(data);
            meta.count = length(data);
        end
        
        function [data, meta] = loadTableData(obj, filepath, format)
            % 加载表格数据
            switch format
                case 'csv'
                    data = readtable(filepath, 'FileType', 'text');
                case 'excel'
                    data = readtable(filepath, 'FileType', 'spreadsheet');
            end
            meta.variables = data.Properties.VariableNames;
            meta.rows = height(data);
            meta.columns = width(data);
        end
        
        function data = preprocessRaster(obj, data, options)
            % 栅格数据预处理
            % 1. 去除无效值
            data(isnan(data)) = 0;
            
            % 2. 数据归一化
            if isfield(options, 'normalize') && options.normalize
                data = (data - min(data(:))) / (max(data(:)) - min(data(:)));
            end
            
            % 3. 重采样
            if isfield(options, 'resample') && options.resample
                data = imresize(data, options.scale);
            end
        end
        
        function data = preprocessVector(obj, data, options)
            % 矢量数据预处理
            % TODO: 实现矢量数据预处理逻辑
        end
        
        function data = preprocessTable(obj, data, options)
            % 表格数据预处理
            % 1. 处理缺失值
            if isfield(options, 'fillna')
                data = fillmissing(data, options.fillna);
            end
            
            % 2. 数据标准化
            if isfield(options, 'standardize') && options.standardize
                numericVars = varfun(@isnumeric, data, 'OutputFormat', 'uniform');
                data{:, numericVars} = normalize(data{:, numericVars});
            end
        end
        
        function [result, issues] = checkRasterQuality(obj, data)
            % 检查栅格数据质量
            issues = {};
            result = true;
            
            % 检查无效值
            nanCount = sum(isnan(data(:)));
            if nanCount > 0
                issues{end+1} = sprintf('发现 %d 个无效值', nanCount);
                result = false;
            end
            
            % 检查数据范围
            if any(isinf(data(:)))
                issues{end+1} = '数据包含无穷值';
                result = false;
            end
        end
        
        function [result, issues] = checkVectorQuality(obj, data)
            % 检查矢量数据质量
            % TODO: 实现矢量数据质量检查逻辑
            result = true;
            issues = {};
        end
        
        function [result, issues] = checkTableQuality(obj, data)
            % 检查表格数据质量
            issues = {};
            result = true;
            
            % 检查缺失值
            missingCount = sum(ismissing(data), 'all');
            if missingCount > 0
                issues{end+1} = sprintf('发现 %d 个缺失值', missingCount);
                result = false;
            end
            
            % 检查重复行
            if height(data) > height(unique(data))
                issues{end+1} = '数据包含重复行';
                result = false;
            end
        end
    end
end 