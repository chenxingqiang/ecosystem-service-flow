classdef GEEDataFetcher < handle
    % GEEDataFetcher 从Google Earth Engine获取研究数据
    
    properties (Access = private)
        pyEE  % Earth Engine Python API实例
        initialized = false
    end
    
    methods
        function obj = GEEDataFetcher()
            % 构造函数
            try
                % 初始化Python环境
                if count(py.sys.path, '') == 0
                    insert(py.sys.path, int32(0), '');
                end
                
                % 导入Earth Engine
                py.importlib.import_module('ee');
                
                % 初始化Earth Engine
                py.ee.Initialize();
                obj.initialized = true;
                fprintf('Google Earth Engine初始化成功\n');
            catch e
                fprintf('Google Earth Engine初始化失败: %s\n', e.message);
                fprintf('请确保已安装earthengine-api并完成身份验证\n');
            end
        end
        
        function [dem, success] = getDEM(obj, region, resolution)
            % 获取数字高程模型(DEM)数据
            % 参数:
            %   region - [minLon, minLat, maxLon, maxLat]
            %   resolution - 空间分辨率(米)
            
            success = false;
            dem = [];
            
            if ~obj.initialized
                fprintf('Earth Engine未初始化\n');
                return;
            end
            
            try
                % 创建感兴趣区域
                geometry = py.ee.Geometry.Rectangle(region);
                
                % 获取SRTM数据
                dataset = py.ee.Image('USGS/SRTMGL1_003');
                elevation = dataset.select('elevation');
                
                % 设置导出参数
                params = py.dict(pyargs(...
                    'region', geometry, ...
                    'scale', resolution, ...
                    'crs', 'EPSG:4326'));
                
                % 获取数据
                data = elevation.getRegion(geometry, resolution).getInfo();
                
                % 转换为MATLAB格式
                dem = obj.convertToMatrix(data);
                success = true;
                fprintf('DEM数据获取成功\n');
                
            catch e
                fprintf('DEM数据获取失败: %s\n', e.message);
            end
        end
        
        function [landcover, success] = getLandCover(obj, region, year, resolution)
            % 获取土地覆盖数据
            % 参数:
            %   region - [minLon, minLat, maxLon, maxLat]
            %   year - 年份
            %   resolution - 空间分辨率(米)
            
            success = false;
            landcover = [];
            
            if ~obj.initialized
                fprintf('Earth Engine未初始化\n');
                return;
            end
            
            try
                % 创建感兴趣区域
                geometry = py.ee.Geometry.Rectangle(region);
                
                % 获取ESA WorldCover数据
                dataset = py.ee.ImageCollection('ESA/WorldCover/v100').first();
                
                % 设置导出参数
                params = py.dict(pyargs(...
                    'region', geometry, ...
                    'scale', resolution, ...
                    'crs', 'EPSG:4326'));
                
                % 获取数据
                data = dataset.getRegion(geometry, resolution).getInfo();
                
                % 转换为MATLAB格式
                landcover = obj.convertToMatrix(data);
                success = true;
                fprintf('土地覆盖数据获取成功\n');
                
            catch e
                fprintf('土地覆盖数据获取失败: %s\n', e.message);
            end
        end
        
        function [ndvi, success] = getNDVI(obj, region, startDate, endDate, resolution)
            % 获取NDVI数据
            % 参数:
            %   region - [minLon, minLat, maxLon, maxLat]
            %   startDate - 起始日期 ('YYYY-MM-DD')
            %   endDate - 结束日期 ('YYYY-MM-DD')
            %   resolution - 空间分辨率(米)
            
            success = false;
            ndvi = [];
            
            if ~obj.initialized
                fprintf('Earth Engine未初始化\n');
                return;
            end
            
            try
                % 创建感兴趣区域
                geometry = py.ee.Geometry.Rectangle(region);
                
                % 获取Landsat 8数据
                dataset = py.ee.ImageCollection('LANDSAT/LC08/C01/T1_TOA')...
                    .filterDate(startDate, endDate)...
                    .filterBounds(geometry);
                
                % 计算NDVI
                ndviFunction = py.ee.Image(dataset.first()).normalizedDifference({'B5', 'B4'});
                
                % 设置导出参数
                params = py.dict(pyargs(...
                    'region', geometry, ...
                    'scale', resolution, ...
                    'crs', 'EPSG:4326'));
                
                % 获取数据
                data = ndviFunction.getRegion(geometry, resolution).getInfo();
                
                % 转换为MATLAB格式
                ndvi = obj.convertToMatrix(data);
                success = true;
                fprintf('NDVI数据获取成功\n');
                
            catch e
                fprintf('NDVI数据获取失败: %s\n', e.message);
            end
        end
        
        function [precipitation, success] = getPrecipitation(obj, region, startDate, endDate, resolution)
            % 获取降水数据
            % 参数:
            %   region - [minLon, minLat, maxLon, maxLat]
            %   startDate - 起始日期 ('YYYY-MM-DD')
            %   endDate - 结束日期 ('YYYY-MM-DD')
            %   resolution - 空间分辨率(米)
            
            success = false;
            precipitation = [];
            
            if ~obj.initialized
                fprintf('Earth Engine未初始化\n');
                return;
            end
            
            try
                % 创建感兴趣区域
                geometry = py.ee.Geometry.Rectangle(region);
                
                % 获取CHIRPS降水数据
                dataset = py.ee.ImageCollection('UCSB-CHG/CHIRPS/DAILY')...
                    .filterDate(startDate, endDate)...
                    .filterBounds(geometry);
                
                % 计算平均降水
                precipitation_img = dataset.mean();
                
                % 设置导出参数
                params = py.dict(pyargs(...
                    'region', geometry, ...
                    'scale', resolution, ...
                    'crs', 'EPSG:4326'));
                
                % 获取数据
                data = precipitation_img.getRegion(geometry, resolution).getInfo();
                
                % 转换为MATLAB格式
                precipitation = obj.convertToMatrix(data);
                success = true;
                fprintf('降水数据获取成功\n');
                
            catch e
                fprintf('降水数据获取失败: %s\n', e.message);
            end
        end
    end
    
    methods (Access = private)
        function matrix = convertToMatrix(obj, data)
            % 将GEE数据转换为MATLAB矩阵
            % 移除头部信息
            data = data(2:end);
            
            % 提取坐标和值
            coords = cellfun(@(x) [x{2}, x{3}], data, 'UniformOutput', false);
            values = cellfun(@(x) x{4}, data);
            
            % 获取唯一的经纬度值
            lons = unique(cellfun(@(x) x(1), coords));
            lats = unique(cellfun(@(x) x(2), coords));
            
            % 创建网格
            [nrows, ncols] = size(meshgrid(lons, lats));
            matrix = reshape(values, [nrows, ncols]);
        end
    end
end 