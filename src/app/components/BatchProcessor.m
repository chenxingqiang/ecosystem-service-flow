classdef BatchProcessor < handle
    properties (Access = private)
        MainFigure       matlab.ui.Figure
        BatchPanel       matlab.ui.container.Panel
        FileList         matlab.ui.control.Table
        ProgressPanel    matlab.ui.container.Panel
        
        % Processing settings
        Settings         struct
        Results         struct
        
        % Status tracking
        ProcessStatus    struct
    end
    
    methods
        function obj = BatchProcessor(parent)
            obj.MainFigure = parent;
            obj.createComponents();
            obj.initializeSettings();
        end
        
        function addFiles(obj)
            % Add files to batch process
            [files, path] = uigetfile({'*.mat;*.tif;*.nc', '数据文件'}, ...
                '选择数据文件', 'MultiSelect', 'on');
            
            if ~isequal(files, 0)
                if ~iscell(files)
                    files = {files};
                end
                
                % Add to file list
                current_data = obj.FileList.Data;
                for i = 1:length(files)
                    new_row = {fullfile(path, files{i}), '待处理', ''};
                    current_data(end+1,:) = new_row;
                end
                obj.FileList.Data = current_data;
            end
        end
        
        function startBatch(obj)
            % Start batch processing
            num_files = size(obj.FileList.Data, 1);
            
            for i = 1:num_files
                try
                    % Update status
                    obj.FileList.Data{i,2} = '处理中';
                    obj.updateProgress(i/num_files);
                    
                    % Load data
                    data = obj.loadData(obj.FileList.Data{i,1});
                    
                    % Process data
                    results = obj.processData(data);
                    
                    % Save results
                    obj.saveResults(results, obj.FileList.Data{i,1});
                    
                    % Update status
                    obj.FileList.Data{i,2} = '完成';
                    obj.FileList.Data{i,3} = '成功';
                    
                catch e
                    % Handle errors
                    obj.FileList.Data{i,2} = '失败';
                    obj.FileList.Data{i,3} = e.message;
                end
            end
        end
        
        function data = loadData(obj, filepath)
            % Load data based on file type
            [~,~,ext] = fileparts(filepath);
            switch lower(ext)
                case '.mat'
                    data = load(filepath);
                case '.tif'
                    data = geotiffread(filepath);
                case '.nc'
                    data = ncread(filepath);
                otherwise
                    error('不支持的文件格式');
            end
        end
        
        function results = processData(obj, data)
            % Process data according to settings
            results = struct();
            
            if obj.Settings.calculate_metrics
                results.metrics = LandscapeMetrics.calculateLandscapeMetrics(data);
            end
            
            if obj.Settings.analyze_flow
                results.flow = FlowAnalyzer.analyzeServiceFlow(data);
            end
            
            if obj.Settings.run_scenarios
                results.scenarios = ScenarioAnalyzer.analyzeScenarios(data);
            end
        end
    end
end 