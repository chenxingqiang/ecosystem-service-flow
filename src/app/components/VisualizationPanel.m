classdef VisualizationPanel < matlab.ui.container.Panel
    properties (Access = private)
        MapPanel            matlab.ui.container.Panel
        ChartPanel         matlab.ui.container.Panel
        StatisticsPanel    matlab.ui.container.Panel
        TimeSeriesPanel    matlab.ui.container.Panel
        
        % Map Components
        MapAxes            matlab.ui.control.UIAxes
        LayerList          matlab.ui.control.ListBox
        MapToolbar         matlab.ui.container.Toolbar
        
        % Chart Components
        ChartAxes         matlab.ui.control.UIAxes
        ChartTypeDropDown matlab.ui.control.DropDown
        
        % Statistics Components
        StatsTable        matlab.ui.control.Table
        StatsPlot         matlab.ui.control.UIAxes
        
        % Time Series Components
        TimeSeriesAxes    matlab.ui.control.UIAxes
        TimeRangeSlider   matlab.ui.control.Slider
    end
    
    methods
        function obj = VisualizationPanel(parent)
            % Constructor
            obj@matlab.ui.container.Panel(parent);
            obj.Title = '可视化';
            
            % Create components
            createComponents(obj);
        end
        
        function createComponents(obj)
            % Create map panel
            obj.MapPanel = uipanel(obj);
            obj.MapPanel.Title = '空间分布';
            obj.MapPanel.Position = [10 400 580 380];
            
            % Create map axes
            obj.MapAxes = uiaxes(obj.MapPanel);
            obj.MapAxes.Position = [10 40 560 310];
            
            % Create layer list
            obj.LayerList = uilistbox(obj.MapPanel);
            obj.LayerList.Position = [10 10 150 30];
            obj.LayerList.Items = {'地形', '土地利用', '服务流', '政策区划'};
            
            % Create chart panel
            obj.ChartPanel = uipanel(obj);
            obj.ChartPanel.Title = '统计图表';
            obj.ChartPanel.Position = [600 400 580 380];
            
            % Create chart controls
            obj.ChartTypeDropDown = uidropdown(obj.ChartPanel);
            obj.ChartTypeDropDown.Position = [10 340 150 30];
            obj.ChartTypeDropDown.Items = {'柱状图', '饼图', '雷达图', '散点图'};
            
            % Create statistics panel
            obj.StatisticsPanel = uipanel(obj);
            obj.StatisticsPanel.Title = '统计分析';
            obj.StatisticsPanel.Position = [10 10 580 380];
            
            % Create time series panel
            obj.TimeSeriesPanel = uipanel(obj);
            obj.TimeSeriesPanel.Title = '时间序列';
            obj.TimeSeriesPanel.Position = [600 10 580 380];
        end
        
        function updateMap(obj, data)
            % Update map display
            imagesc(obj.MapAxes, data);
            colorbar(obj.MapAxes);
            axis(obj.MapAxes, 'equal');
            title(obj.MapAxes, '空间分布');
        end
        
        function updateChart(obj, data, type)
            % Update chart display
            switch type
                case '柱状图'
                    bar(obj.ChartAxes, data);
                case '饼图'
                    pie(obj.ChartAxes, data);
                case '雷达图'
                    polarplot(obj.ChartAxes, data);
                case '散点图'
                    scatter(obj.ChartAxes, data(:,1), data(:,2));
            end
        end
    end
end 