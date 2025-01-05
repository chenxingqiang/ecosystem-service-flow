classdef AnalysisPanel < matlab.ui.container.Panel
    properties (Access = private)
        ScenarioPanel      matlab.ui.container.Panel
        SensitivityPanel   matlab.ui.container.Panel
        EvaluationPanel    matlab.ui.container.Panel
        TrendPanel         matlab.ui.container.Panel
        
        % Scenario Components
        ScenarioList       matlab.ui.control.ListBox
        ScenarioTable      matlab.ui.control.Table
        CompareButton      matlab.ui.control.Button
        
        % Sensitivity Components
        ParameterList      matlab.ui.control.ListBox
        SensitivityPlot    matlab.ui.control.UIAxes
        
        % Evaluation Components
        CriteriaTable      matlab.ui.control.Table
        WeightSliders      matlab.ui.control.Slider
        
        % Trend Components
        TrendPlot         matlab.ui.control.UIAxes
        TimeRangeSlider   matlab.ui.control.Slider
    end
    
    methods
        function obj = AnalysisPanel(parent)
            % Constructor
            obj@matlab.ui.container.Panel(parent);
            obj.Title = '分析工具';
            
            % Create components
            createComponents(obj);
        end
        
        function createComponents(obj)
            % Create scenario panel
            obj.ScenarioPanel = uipanel(obj);
            obj.ScenarioPanel.Title = '情景分析';
            obj.ScenarioPanel.Position = [10 400 580 380];
            
            % Create sensitivity panel
            obj.SensitivityPanel = uipanel(obj);
            obj.SensitivityPanel.Title = '敏感性分析';
            obj.SensitivityPanel.Position = [600 400 580 380];
            
            % Create evaluation panel
            obj.EvaluationPanel = uipanel(obj);
            obj.EvaluationPanel.Title = '多准则评价';
            obj.EvaluationPanel.Position = [10 10 580 380];
            
            % Create trend panel
            obj.TrendPanel = uipanel(obj);
            obj.TrendPanel.Title = '趋势分析';
            obj.TrendPanel.Position = [600 10 580 380];
        end
    end
end 