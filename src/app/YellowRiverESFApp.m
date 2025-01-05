classdef YellowRiverESFApp < matlab.apps.AppBase
    % YellowRiverESFApp 黄河流域生态系统服务流分析系统

    properties (Access = private)
        % UI Components
        MainFigure          matlab.ui.Figure
        FileMenu           matlab.ui.container.Menu
        AnalysisMenu       matlab.ui.container.Menu
        HelpMenu          matlab.ui.container.Menu
        
        % Tabs
        MainTabGroup       matlab.ui.container.TabGroup
        DataTab           matlab.ui.container.Tab
        AnalysisTab       matlab.ui.container.Tab
        ResultsTab        matlab.ui.container.Tab
        
        % Data Panel Components
        DataPanel         matlab.ui.container.Panel
        LoadDataButton    matlab.ui.control.Button
        DataTable         matlab.ui.control.Table
        
        % Analysis Panel Components
        AnalysisPanel     matlab.ui.container.Panel
        RegionDropDown    matlab.ui.control.DropDown
        ServiceTypeList   matlab.ui.control.ListBox
        RunButton         matlab.ui.control.Button
        
        % Results Panel Components
        MapAxes           matlab.ui.control.UIAxes
        ResultsTable      matlab.ui.control.Table
        ExportButton      matlab.ui.control.Button
        
        % Analysis Objects
        PolicyAnalyzer    YellowRiverPolicy
        RegionalAnalyzer  YellowRiverRegionalAnalyzer
        DataManager       DataManager
        
        % Data
        CurrentData       struct
        Results          struct
        
        % Additional UI Components
        StatusBar          matlab.ui.control.Label
        ProgressBar        matlab.ui.control.ProgressBar
        MessagePanel       matlab.ui.container.Panel
        HelpButton         matlab.ui.control.Button
        
        % New Panels
        VisualizationPanel  VisualizationPanel
        
        % Help System
        TooltipManager     TooltipManager
    end
    
    methods (Access = private)
        function createComponents(app)
            % Create UI components
            
            % Create main figure
            app.MainFigure = uifigure('Visible', 'off');
            app.MainFigure.Position = [100 100 1200 800];
            app.MainFigure.Name = '黄河流域生态系统服务流分析系统';
            
            % Create menus
            app.FileMenu = uimenu(app.MainFigure);
            app.FileMenu.Text = '文件';
            uimenu(app.FileMenu, 'Text', '打开数据...', ...
                'MenuSelectedFcn', @(~,~) app.loadData);
            uimenu(app.FileMenu, 'Text', '保存结果...', ...
                'MenuSelectedFcn', @(~,~) app.saveResults);
            
            % Create tab group
            app.MainTabGroup = uitabgroup(app.MainFigure);
            app.MainTabGroup.Position = [0 0 1200 800];
            
            % Create Data Tab
            app.DataTab = uitab(app.MainTabGroup);
            app.DataTab.Title = '数据管理';
            app.createDataPanel();
            
            % Create Analysis Tab
            app.AnalysisTab = uitab(app.MainTabGroup);
            app.AnalysisTab.Title = '分析';
            app.createAnalysisPanel();
            
            % Create Results Tab
            app.ResultsTab = uitab(app.MainTabGroup);
            app.ResultsTab.Title = '结果';
            app.createResultsPanel();
            
            % Initialize analysis objects
            app.initializeAnalyzers();
            
            % Add status bar
            app.StatusBar = uilabel(app.MainFigure);
            app.StatusBar.Position = [10 0 800 20];
            app.StatusBar.Text = '就绪';
            
            % Add progress bar
            app.ProgressBar = uiprogressbar(app.MainFigure);
            app.ProgressBar.Position = [820 5 300 10];
            
            % Add help button
            app.HelpButton = uibutton(app.MainFigure);
            app.HelpButton.Position = [1130 0 60 20];
            app.HelpButton.Text = '帮助';
            app.HelpButton.ButtonPushedFcn = @(~,~) app.showHelp;
            
            % Create visualization panel
            app.VisualizationPanel = VisualizationPanel(app.ResultsTab);
            
            % Create analysis panel
            app.AnalysisPanel = AnalysisPanel(app.AnalysisTab);
            
            % Initialize tooltip manager
            app.TooltipManager = TooltipManager(app.MainFigure);
            app.addTooltips();
        end
        
        function createDataPanel(app)
            % Create data management panel
            app.DataPanel = uipanel(app.DataTab);
            app.DataPanel.Position = [10 10 1180 780];
            app.DataPanel.Title = '数据管理';
            
            % Add data loading controls
            app.LoadDataButton = uibutton(app.DataPanel);
            app.LoadDataButton.Position = [10 730 100 30];
            app.LoadDataButton.Text = '加载数据';
            app.LoadDataButton.ButtonPushedFcn = @(~,~) app.loadData;
            
            % Add data table
            app.DataTable = uitable(app.DataPanel);
            app.DataTable.Position = [10 50 1160 670];
        end
        
        function createAnalysisPanel(app)
            % Create analysis panel
            app.AnalysisPanel = uipanel(app.AnalysisTab);
            app.AnalysisPanel.Position = [10 10 1180 780];
            app.AnalysisPanel.Title = '分析设置';
            
            % Add region selection
            app.RegionDropDown = uidropdown(app.AnalysisPanel);
            app.RegionDropDown.Position = [10 730 200 30];
            app.RegionDropDown.Items = {'上游', '中游', '下游', '全流域'};
            
            % Add service type selection
            app.ServiceTypeList = uilistbox(app.AnalysisPanel);
            app.ServiceTypeList.Position = [10 400 200 300];
            app.ServiceTypeList.Items = {'供给服务', '调节服务', '文化服务', '支持服务'};
            app.ServiceTypeList.Multiselect = 'on';
            
            % Add run button
            app.RunButton = uibutton(app.AnalysisPanel);
            app.RunButton.Position = [10 350 100 30];
            app.RunButton.Text = '运行分析';
            app.RunButton.ButtonPushedFcn = @(~,~) app.runAnalysis;
        end
        
        function createResultsPanel(app)
            % Create results panel
            app.MapAxes = uiaxes(app.ResultsTab);
            app.MapAxes.Position = [10 400 780 390];
            title(app.MapAxes, '空间分布');
            
            app.ResultsTable = uitable(app.ResultsTab);
            app.ResultsTable.Position = [10 50 780 300];
            
            app.ExportButton = uibutton(app.ResultsTab);
            app.ExportButton.Position = [10 10 100 30];
            app.ExportButton.Text = '导出结果';
            app.ExportButton.ButtonPushedFcn = @(~,~) app.exportResults;
        end
        
        function initializeAnalyzers(app)
            % Initialize analysis objects
            app.PolicyAnalyzer = YellowRiverPolicy();
            app.RegionalAnalyzer = YellowRiverRegionalAnalyzer();
            app.DataManager = DataManager();
        end
        
        function loadData(app)
            % Load data
            try
                [file, path] = uigetfile({'*.mat;*.csv;*.xlsx', '数据文件'});
                if file ~= 0
                    filepath = fullfile(path, file);
                    app.CurrentData = app.DataManager.importData(filepath);
                    app.updateDataTable();
                end
            catch e
                uialert(app.MainFigure, e.message, '错误', 'Icon', 'error');
            end
        end
        
        function runAnalysis(app)
            % Run analysis
            try
                % Get selected region and services
                region = app.RegionDropDown.Value;
                services = app.ServiceTypeList.Value;
                
                % Run regional analysis
                app.RegionalAnalyzer.analyzeRegionalCharacteristics();
                regional_results = app.RegionalAnalyzer.evaluateRegionalService();
                
                % Check policy compliance
                compliance = app.PolicyAnalyzer.checkPolicyCompliance(regional_results);
                
                % Generate optimization plan
                optimization_plan = app.generateOptimizationPlan(regional_results, compliance);
                
                % Store results
                app.Results = struct();
                app.Results.regional = regional_results;
                app.Results.compliance = compliance;
                app.Results.optimization = optimization_plan;
                
                % Update display
                app.updateResultsDisplay();
                
            catch e
                uialert(app.MainFigure, e.message, '错误', 'Icon', 'error');
            end
        end
        
        function updateDataTable(app)
            % Update data table display
            if ~isempty(app.CurrentData)
                app.DataTable.Data = struct2table(app.CurrentData);
            end
        end
        
        function updateResultsDisplay(app)
            % Update results display
            if isfield(app.Results, 'regional')
                % Update map
                imagesc(app.MapAxes, app.Results.regional.spatial_distribution);
                colorbar(app.MapAxes);
                
                % Update table
                app.ResultsTable.Data = struct2table(app.Results.regional);
            end
        end
        
        function exportResults(app)
            % Export results
            try
                [file, path] = uiputfile({'*.xlsx', 'Excel文件'; '*.mat', 'MAT文件'});
                if file ~= 0
                    filepath = fullfile(path, file);
                    app.DataManager.exportData(app.Results, filepath);
                end
            catch e
                uialert(app.MainFigure, e.message, '错误', 'Icon', 'error');
            end
        end
        
        function showHelp(app)
            % Show help dialog
            helpDialog = HelpDialog(app.MainFigure);
            helpDialog.show();
        end
        
        function addTooltips(app)
            % Add tooltips to UI components
            app.TooltipManager.addTooltip(app.LoadDataButton, '加载数据文件');
            app.TooltipManager.addTooltip(app.RunButton, '运行选定的分析');
            app.TooltipManager.addTooltip(app.ExportButton, '导出分析结果');
        end
        
        function updateStatus(app, message)
            % Update status bar message
            app.StatusBar.Text = message;
        end
        
        function updateProgress(app, value)
            % Update progress bar
            app.ProgressBar.Value = value;
        end
    end
    
    methods (Access = public)
        function app = YellowRiverESFApp
            % Constructor
            
            % Create components
            createComponents(app)
            
            % Show the figure
            app.MainFigure.Visible = 'on';
        end
    end
end 