            app.ChartPanel = uipanel(app.VisualizationTab);
            app.ChartPanel.Position = [600 380 580 340];
            app.ChartPanel.Title = '流动图表';
            
            % 图表类型选择
            uilabel(app.ChartPanel, 'Position', [10 290 100 22], 'Text', '图表类型:');
            uidropdown(app.ChartPanel, 'Position', [120 290 150 22], ...
                'Items', {'流动图', '网络图', '桑基图'}, ...
                'Value', '流动图');
            
            % 图表数据选择
            uilabel(app.ChartPanel, 'Position', [10 250 100 22], 'Text', '图表数据:');
            uibutton(app.ChartPanel, 'Position', [120 250 100 22], 'Text', '选择文件', ...
                'ButtonPushedFcn', @(btn,event) app.selectChartData);
            
            % 图表显示按钮
            uibutton(app.ChartPanel, 'Position', [10 210 100 22], 'Text', '显示图表', ...
                'ButtonPushedFcn', @(btn,event) app.showChart);
            
            % 创建统计分析面板
            app.StatsPanel = uipanel(app.VisualizationTab);
            app.StatsPanel.Position = [10 20 580 340];
            app.StatsPanel.Title = '统计分析';
            
            % 统计图类型选择
            uilabel(app.StatsPanel, 'Position', [10 290 100 22], 'Text', '统计图:');
            uidropdown(app.StatsPanel, 'Position', [120 290 150 22], ...
                'Items', {'柱状图', '箱线图', '散点图', '直方图'}, ...
                'Value', '柱状图');
            
            % 统计数据选择
            uilabel(app.StatsPanel, 'Position', [10 250 100 22], 'Text', '统计数据:');
            uibutton(app.StatsPanel, 'Position', [120 250 100 22], 'Text', '选择文件', ...
                'ButtonPushedFcn', @(btn,event) app.selectStatsData);
            
            % 统计图显示按钮
            uibutton(app.StatsPanel, 'Position', [10 210 100 22], 'Text', '显示统计', ...
                'ButtonPushedFcn', @(btn,event) app.showStats);
            
            % 创建动态展示面板
            app.AnimationPanel = uipanel(app.VisualizationTab);
            app.AnimationPanel.Position = [600 20 580 340];
            app.AnimationPanel.Title = '动态展示';
            
            % 动画类型选择
            uilabel(app.AnimationPanel, 'Position', [10 290 100 22], 'Text', '动画类型:');
            uidropdown(app.AnimationPanel, 'Position', [120 290 150 22], ...
                'Items', {'流动动画', '变化动画', '过程动画'}, ...
                'Value', '流动动画');
            
            % 动画数据选择
            uilabel(app.AnimationPanel, 'Position', [10 250 100 22], 'Text', '动画数据:');
            uibutton(app.AnimationPanel, 'Position', [120 250 100 22], 'Text', '选择文件', ...
                'ButtonPushedFcn', @(btn,event) app.selectAnimationData);
            
            % 动画控制
            uilabel(app.AnimationPanel, 'Position', [10 210 100 22], 'Text', '帧率(FPS):');
            uispinner(app.AnimationPanel, 'Position', [120 210 100 22], ...
                'Value', 30, 'Limits', [1 60]);
            
            % 动画播放按钮
            uibutton(app.AnimationPanel, 'Position', [10 170 100 22], 'Text', '播放动画', ...
                'ButtonPushedFcn', @(btn,event) app.playAnimation);
        end

        % 可视化回调函数
        function selectMapData(app)
            try
                [filename, pathname] = uigetfile({'*.tif;*.shp', '地图数据 (*.tif,*.shp)'});
                if isequal(filename, 0)
                    return;
                end
                
                fullpath = fullfile(pathname, filename);
                [data, meta] = app.DataProcessor.loadData(fullpath);
                app.VisManager.setMapData(data);
                app.StatusBar.Text = '地图数据已加载';
            catch e
                app.StatusBar.Text = ['地图数据加载失败: ' e.message];
            end
        end
        
        function selectChartData(app)
            try
                [filename, pathname] = uigetfile({'*.csv;*.xlsx', '图表数据 (*.csv,*.xlsx)'});
                if isequal(filename, 0)
                    return;
                end
                
                fullpath = fullfile(pathname, filename);
                [data, meta] = app.DataProcessor.loadData(fullpath);
                app.VisManager.setFlowData(data);
                app.StatusBar.Text = '图表数据已加载';
            catch e
                app.StatusBar.Text = ['图表数据加载失败: ' e.message];
            end
        end
        
        function selectStatsData(app)
            try
                [filename, pathname] = uigetfile({'*.csv;*.xlsx', '统计数据 (*.csv,*.xlsx)'});
                if isequal(filename, 0)
                    return;
                end
                
                fullpath = fullfile(pathname, filename);
                [data, meta] = app.DataProcessor.loadData(fullpath);
                app.VisManager.setFlowData(data);
                app.StatusBar.Text = '统计数据已加载';
            catch e
                app.StatusBar.Text = ['统计数据加载失败: ' e.message];
            end
        end
        
        function selectAnimationData(app)
            try
                [filename, pathname] = uigetfile({'*.avi;*.mp4', '动画文件 (*.avi,*.mp4)'});
                if isequal(filename, 0)
                    return;
                end
                
                fullpath = fullfile(pathname, filename);
                app.VisManager.setAnimationData(fullpath);
                app.StatusBar.Text = '动画数据已加载';
            catch e
                app.StatusBar.Text = ['动画数据加载失败: ' e.message];
            end
        end
        
        function playAnimation(app)
            try
                app.VisManager.playAnimation();
                app.StatusBar.Text = '动画播放中';
            catch e
                app.StatusBar.Text = ['动画播放失败: ' e.message];
            end
        end

        function createServiceFlowTab(app)
            % 服务流量化标签页
            app.ServiceFlowTab = uitab(app.MainTabGroup);
            app.ServiceFlowTab.Title = '服务流量化';
            
            % 创建供给面板
            app.SupplyPanel = uipanel(app.ServiceFlowTab);
            app.SupplyPanel.Position = [10 380 580 340];
            app.SupplyPanel.Title = '供给评估';
            
            % 供给数据选择
            uilabel(app.SupplyPanel, 'Position', [10 290 100 22], 'Text', '供给数据:');
            uibutton(app.SupplyPanel, 'Position', [120 290 100 22], 'Text', '选择文件', ...
                'ButtonPushedFcn', @(btn,event) app.selectSupplyData);
            
            % 供给评估方法
            uilabel(app.SupplyPanel, 'Position', [10 250 100 22], 'Text', '评估方法:');
            uidropdown(app.SupplyPanel, 'Position', [120 250 150 22], ...
                'Items', {'生物物理', '经济价值', '社会文化'}, ...
                'Value', '生物物理');
            
            % 供给分析按钮
            uibutton(app.SupplyPanel, 'Position', [10 210 100 22], 'Text', '开始分析', ...
                'ButtonPushedFcn', @(btn,event) app.analyzeSupply);
            
            % 创建需求面板
            app.DemandPanel = uipanel(app.ServiceFlowTab);
            app.DemandPanel.Position = [600 380 580 340];
            app.DemandPanel.Title = '需求评估';
            
            % 需求数据选择
            uilabel(app.DemandPanel, 'Position', [10 290 100 22], 'Text', '需求数据:');
            uibutton(app.DemandPanel, 'Position', [120 290 100 22], 'Text', '选择文件', ...
                'ButtonPushedFcn', @(btn,event) app.selectDemandData);
            
            % 需求评估方法
            uilabel(app.DemandPanel, 'Position', [10 250 100 22], 'Text', '评估方法:');
            uidropdown(app.DemandPanel, 'Position', [120 250 150 22], ...
                'Items', {'人口密度', '经济发展', '社会需求'}, ...
                'Value', '人口密度');
            
            % 需求分析按钮
            uibutton(app.DemandPanel, 'Position', [10 210 100 22], 'Text', '开始分析', ...
                'ButtonPushedFcn', @(btn,event) app.analyzeDemand);
            
            % 创建阻力面板
            app.ResistancePanel = uipanel(app.ServiceFlowTab);
            app.ResistancePanel.Position = [10 20 580 340];
            app.ResistancePanel.Title = '流动阻力分析';
            
            % 阻力数据选择
            uilabel(app.ResistancePanel, 'Position', [10 290 100 22], 'Text', '阻力数据:');
            uibutton(app.ResistancePanel, 'Position', [120 290 100 22], 'Text', '选择文件', ...
                'ButtonPushedFcn', @(btn,event) app.selectResistanceData);
            
            % 阻力计算方法
            uilabel(app.ResistancePanel, 'Position', [10 250 100 22], 'Text', '计算方法:');
            uidropdown(app.ResistancePanel, 'Position', [120 250 150 22], ...
                'Items', {'距离衰减', '地形阻力', '土地利用'}, ...
                'Value', '距离衰减');
            
            % 阻力分析按钮
            uibutton(app.ResistancePanel, 'Position', [10 210 100 22], 'Text', '开始分析', ...
                'ButtonPushedFcn', @(btn,event) app.analyzeResistance);
            
            % 创建空间关系面板
            app.SpatialPanel = uipanel(app.ServiceFlowTab);
            app.SpatialPanel.Position = [600 20 580 340];
            app.SpatialPanel.Title = '空间关系计算';
            
            % 空间数据选择
            uilabel(app.SpatialPanel, 'Position', [10 290 100 22], 'Text', '空间数据:');
            uibutton(app.SpatialPanel, 'Position', [120 290 100 22], 'Text', '选择文件', ...
                'ButtonPushedFcn', @(btn,event) app.selectSpatialData);
            
            % 空间分析方法
            uilabel(app.SpatialPanel, 'Position', [10 250 100 22], 'Text', '分析方法:');
            uidropdown(app.SpatialPanel, 'Position', [120 250 150 22], ...
                'Items', {'最短路径', '重力模型', '网络分析'}, ...
                'Value', '最短路径');
            
            % 空间分析按钮
            uibutton(app.SpatialPanel, 'Position', [10 210 100 22], 'Text', '开始分析', ...
                'ButtonPushedFcn', @(btn,event) app.analyzeSpatialFlow);
        end

        % 服务流量化回调函数
        function selectSupplyData(app)
            try
                [filename, pathname] = uigetfile({'*.tif;*.shp;*.csv;*.xlsx', '支持的文件格式'});
                if isequal(filename, 0)
                    return;
                end
                
                fullpath = fullfile(pathname, filename);
                [data, meta] = app.DataProcessor.loadData(fullpath);
                app.ServiceAnalyzer.setSupplyData(data);
                app.StatusBar.Text = '供给数据已加载';
            catch e
                app.StatusBar.Text = ['供给数据加载失败: ' e.message];
            end
        end
        
        function selectDemandData(app)
            try
                [filename, pathname] = uigetfile({'*.tif;*.shp;*.csv;*.xlsx', '支持的文件格式'});
                if isequal(filename, 0)
                    return;
                end
                
                fullpath = fullfile(pathname, filename);
                [data, meta] = app.DataProcessor.loadData(fullpath);
                app.ServiceAnalyzer.setDemandData(data);
                app.StatusBar.Text = '需求数据已加载';
            catch e
                app.StatusBar.Text = ['需求数据加载失败: ' e.message];
            end
        end
        
        function selectResistanceData(app)
            try
                [filename, pathname] = uigetfile({'*.tif;*.shp;*.csv;*.xlsx', '支持的文件格式'});
                if isequal(filename, 0)
                    return;
                end
                
                fullpath = fullfile(pathname, filename);
                [data, meta] = app.DataProcessor.loadData(fullpath);
                app.ServiceAnalyzer.setResistanceData(data);
                app.StatusBar.Text = '阻力数据已加载';
            catch e
                app.StatusBar.Text = ['阻力数据加载失败: ' e.message];
            end
        end
        
        function selectSpatialData(app)
            try
                [filename, pathname] = uigetfile({'*.tif;*.shp;*.csv;*.xlsx', '支持的文件格式'});
                if isequal(filename, 0)
                    return;
                end
                
                fullpath = fullfile(pathname, filename);
                [data, meta] = app.DataProcessor.loadData(fullpath);
                app.ServiceAnalyzer.setSpatialData(data);
                app.StatusBar.Text = '空间数据已加载';
            catch e
                app.StatusBar.Text = ['空间数据加载失败: ' e.message];
            end
        end
        
        function analyzeSupply(app)
            try
                options = struct();  % TODO: 从界面获取分析选项
                results = app.ServiceAnalyzer.analyzeSupply(options);
                app.visualizeResults('supply', results);
                app.StatusBar.Text = '供给分析完成';
            catch e
                app.StatusBar.Text = ['供给分析失败: ' e.message];
            end
        end
        
        function analyzeDemand(app)
            try
                options = struct();  % TODO: 从界面获取分析选项
                results = app.ServiceAnalyzer.analyzeDemand(options);
                app.visualizeResults('demand', results);
                app.StatusBar.Text = '需求分析完成';
            catch e
                app.StatusBar.Text = ['需求分析失败: ' e.message];
            end
        end
        
        function analyzeResistance(app)
            try
                options = struct();  % TODO: 从界面获取分析选项
                results = app.ServiceAnalyzer.analyzeResistance(options);
                app.visualizeResults('resistance', results);
                app.StatusBar.Text = '阻力分析完成';
            catch e
                app.StatusBar.Text = ['阻力分析失败: ' e.message];
            end
        end
        
        function analyzeSpatialFlow(app)
            try
                options = struct();  % TODO: 从界面获取分析选项
                results = app.ServiceAnalyzer.analyzeSpatialFlow(options);
                app.visualizeResults('flow', results);
                app.StatusBar.Text = '空间流动分析完成';
            catch e
                app.StatusBar.Text = ['空间流动分析失败: ' e.message];
            end
        end
        
        function visualizeResults(app, type, results)
            % 根据结果类型选择合适的可视化方法
            switch type
                case 'supply'
                    app.VisManager.setMapData(results.distribution);
                    app.VisManager.create2DMap(struct('type', 'supply'));
                case 'demand'
                    app.VisManager.setMapData(results.distribution);
                    app.VisManager.create2DMap(struct('type', 'demand'));
                case 'resistance'
                    app.VisManager.setMapData(results.distribution);
                    app.VisManager.create2DMap(struct('type', 'resistance'));
                case 'flow'
                    app.VisManager.setFlowData(results);
                    app.VisManager.createFlowChart(struct('type', 'flow'));
            end
        end

        function createSpatialAnalysisTab(app)
            % 空间分析标签页
            app.SpatialAnalysisTab = uitab(app.MainTabGroup);
            app.SpatialAnalysisTab.Title = '空间分析';
            
            % 创建GIS数据处理面板
            app.GISPanel = uipanel(app.SpatialAnalysisTab);
            app.GISPanel.Position = [10 380 580 340];
            app.GISPanel.Title = 'GIS数据处理';
            
            % GIS数据选择
            uilabel(app.GISPanel, 'Position', [10 290 100 22], 'Text', 'GIS数据:');
            uibutton(app.GISPanel, 'Position', [120 290 100 22], 'Text', '选择文件', ...
                'ButtonPushedFcn', @(btn,event) app.selectGISData);
            
            % 投影设置
            uilabel(app.GISPanel, 'Position', [10 250 100 22], 'Text', '投影设置:');
            uidropdown(app.GISPanel, 'Position', [120 250 150 22], ...
                'Items', {'WGS84', 'UTM', '自定义'}, ...
                'Value', 'WGS84');
            
            % GIS处理按钮
            uibutton(app.GISPanel, 'Position', [10 210 100 22], 'Text', '开始处理', ...
                'ButtonPushedFcn', @(btn,event) app.processGISData);
            
            % 创建空间插值面板
            app.InterpolationPanel = uipanel(app.SpatialAnalysisTab);
            app.InterpolationPanel.Position = [600 380 580 340];
            app.InterpolationPanel.Title = '空间插值';
            
            % 插值数据选择
            uilabel(app.InterpolationPanel, 'Position', [10 290 100 22], 'Text', '插值数据:');
            uibutton(app.InterpolationPanel, 'Position', [120 290 100 22], 'Text', '选择文件', ...
                'ButtonPushedFcn', @(btn,event) app.selectInterpolationData);
            
            % 插值方法
            uilabel(app.InterpolationPanel, 'Position', [10 250 100 22], 'Text', '插值方法:');
            uidropdown(app.InterpolationPanel, 'Position', [120 250 150 22], ...
                'Items', {'克里金', 'IDW', '样条'}, ...
                'Value', '克里金');
            
            % 插值参数
            uilabel(app.InterpolationPanel, 'Position', [10 210 100 22], 'Text', '搜索半径:');
            uispinner(app.InterpolationPanel, 'Position', [120 210 100 22], ...
                'Value', 1000, 'Step', 100);
            
            % 插值按钮
            uibutton(app.InterpolationPanel, 'Position', [10 170 100 22], 'Text', '开始插值', ...
                'ButtonPushedFcn', @(btn,event) app.performInterpolation);
            
            % 创建网络分析面板
            app.NetworkPanel = uipanel(app.SpatialAnalysisTab);
            app.NetworkPanel.Position = [10 20 580 340];
            app.NetworkPanel.Title = '网络分析';
            
            % 网络数据选择
            uilabel(app.NetworkPanel, 'Position', [10 290 100 22], 'Text', '网络数据:');
            uibutton(app.NetworkPanel, 'Position', [120 290 100 22], 'Text', '选择文件', ...
                'ButtonPushedFcn', @(btn,event) app.selectNetworkData);
            
            % 网络分析方法
            uilabel(app.NetworkPanel, 'Position', [10 250 100 22], 'Text', '分析方法:');
            uidropdown(app.NetworkPanel, 'Position', [120 250 150 22], ...
                'Items', {'最短路径', '连通性', '中心性'}, ...
                'Value', '最短路径');
            
            % 网络分析按钮
            uibutton(app.NetworkPanel, 'Position', [10 210 100 22], 'Text', '开始分析', ...
                'ButtonPushedFcn', @(btn,event) app.analyzeNetwork);
            
            % 创建距离计算面板
            app.DistancePanel = uipanel(app.SpatialAnalysisTab);
            app.DistancePanel.Position = [600 20 580 340];
            app.DistancePanel.Title = '距离计算';
            
            % 距离数据选择
            uilabel(app.DistancePanel, 'Position', [10 290 100 22], 'Text', '距离数据:');
            uibutton(app.DistancePanel, 'Position', [120 290 100 22], 'Text', '选择文件', ...
                'ButtonPushedFcn', @(btn,event) app.selectDistanceData);
            
            % 距离计算方法
            uilabel(app.DistancePanel, 'Position', [10 250 100 22], 'Text', '计算方法:');
            uidropdown(app.DistancePanel, 'Position', [120 250 150 22], ...
                'Items', {'欧氏距离', '曼哈顿', '成本距离'}, ...
                'Value', '欧氏距离');
            
            % 距离计算按钮
            uibutton(app.DistancePanel, 'Position', [10 210 100 22], 'Text', '开始计算', ...
                'ButtonPushedFcn', @(btn,event) app.calculateDistances);
        end

        % 空间分析回调函数
        function selectGISData(app)
            try
                [filename, pathname] = uigetfile({'*.shp;*.tif', 'GIS文件 (*.shp,*.tif)'});
                if isequal(filename, 0)
                    return;
                end
                
                fullpath = fullfile(pathname, filename);
                [data, meta] = app.DataProcessor.loadData(fullpath);
                app.SpatialAnalyzer.setGISData(data);
                app.StatusBar.Text = 'GIS数据已加载';
            catch e
                app.StatusBar.Text = ['GIS数据加载失败: ' e.message];
            end
        end
        
        function selectInterpolationData(app)
            try
                [filename, pathname] = uigetfile({'*.csv;*.xlsx', '数据文件 (*.csv,*.xlsx)'});
                if isequal(filename, 0)
                    return;
                end
                
                fullpath = fullfile(pathname, filename);
                [data, meta] = app.DataProcessor.loadData(fullpath);
                app.SpatialAnalyzer.setInterpolationData(data);
                app.StatusBar.Text = '插值数据已加载';
            catch e
                app.StatusBar.Text = ['插值数据加载失败: ' e.message];
            end
        end
        
        function selectNetworkData(app)
            try
                [filename, pathname] = uigetfile({'*.shp', '网络数据 (*.shp)'});
                if isequal(filename, 0)
                    return;
                end
                
                fullpath = fullfile(pathname, filename);
                [data, meta] = app.DataProcessor.loadData(fullpath);
                app.SpatialAnalyzer.setNetworkData(data);
                app.StatusBar.Text = '网络数据已加载';
            catch e
                app.StatusBar.Text = ['网络数据加载失败: ' e.message];
            end
        end
        
        function selectDistanceData(app)
            try
                [filename, pathname] = uigetfile({'*.shp;*.csv', '距离数据 (*.shp,*.csv)'});
                if isequal(filename, 0)
                    return;
                end
                
                fullpath = fullfile(pathname, filename);
                [data, meta] = app.DataProcessor.loadData(fullpath);
                app.SpatialAnalyzer.setDistanceData(data);
                app.StatusBar.Text = '距离数据已加载';
            catch e
                app.StatusBar.Text = ['距离数据加载失败: ' e.message];
            end
        end
        
        function processGISData(app)
            try
                options = struct();  % TODO: 从界面获取处理选项
                results = app.SpatialAnalyzer.processGISData(options);
                app.visualizeResults('gis', results);
                app.StatusBar.Text = 'GIS数据处理完成';
            catch e
                app.StatusBar.Text = ['GIS数据处理失败: ' e.message];
            end
        end
        
        function performInterpolation(app)
            try
                options = struct();  % TODO: 从界面获取插值选项
                results = app.SpatialAnalyzer.performInterpolation(options);
                app.visualizeResults('interpolation', results);
                app.StatusBar.Text = '空间插值完成';
            catch e
                app.StatusBar.Text = ['空间插值失败: ' e.message];
            end
        end
        
        function analyzeNetwork(app)
            try
                options = struct();  % TODO: 从界面获取网络分析选项
                results = app.SpatialAnalyzer.analyzeNetwork(options);
                app.visualizeResults('network', results);
                app.StatusBar.Text = '网络分析完成';
            catch e
                app.StatusBar.Text = ['网络分析失败: ' e.message];
            end
        end
        
        function calculateDistances(app)
            try
                options = struct();  % TODO: 从界面获取距离计算选项
                results = app.SpatialAnalyzer.calculateDistances(options);
                app.visualizeResults('distance', results);
                app.StatusBar.Text = '距离计算完成';
            catch e
                app.StatusBar.Text = ['距离计算失败: ' e.message];
            end
        end

        function createDecisionSupportTab(app)
            % 决策支持标签页
            app.DecisionSupportTab = uitab(app.MainTabGroup);
            app.DecisionSupportTab.Title = '决策支持';
            
            % 创建情景分析面板
            app.ScenarioPanel = uipanel(app.DecisionSupportTab);
            app.ScenarioPanel.Position = [10 380 580 340];
            app.ScenarioPanel.Title = '情景分析';
            
            % 情景类型选择
            uilabel(app.ScenarioPanel, 'Position', [10 290 100 22], 'Text', '情景类型:');
            uidropdown(app.ScenarioPanel, 'Position', [120 290 150 22], ...
                'Items', {'土地利用变化', '气候变化', '政策变化'}, ...
                'Value', '土地利用变化');
            
            % 情景参数设置
            uilabel(app.ScenarioPanel, 'Position', [10 250 100 22], 'Text', '变化率(%):');
            uispinner(app.ScenarioPanel, 'Position', [120 250 100 22], ...
                'Value', 10, 'Limits', [-100 100]);
            
            % 情景分析按钮
            uibutton(app.ScenarioPanel, 'Position', [10 210 100 22], 'Text', '开始分析', ...
                'ButtonPushedFcn', @(btn,event) app.analyzeScenario);
            
            % 创建敏感性分析面板
            app.SensitivityPanel = uipanel(app.DecisionSupportTab);
            app.SensitivityPanel.Position = [600 380 580 340];
            app.SensitivityPanel.Title = '敏感性分析';
            
            % 参数选择
            uilabel(app.SensitivityPanel, 'Position', [10 290 100 22], 'Text', '分析参数:');
            uidropdown(app.SensitivityPanel, 'Position', [120 290 150 22], ...
                'Items', {'供给系数', '需求系数', '阻力系数'}, ...
                'Value', '供给系数');
            
            % 参数范围设置
            uilabel(app.SensitivityPanel, 'Position', [10 250 100 22], 'Text', '变化范围:');
            uispinner(app.SensitivityPanel, 'Position', [120 250 100 22], ...
                'Value', 20, 'Limits', [0 100]);
            
            % 敏感性分析按钮
            uibutton(app.SensitivityPanel, 'Position', [10 210 100 22], 'Text', '开始分析', ...
                'ButtonPushedFcn', @(btn,event) app.analyzeSensitivity);
            
            % 创建优化建议面板
            app.OptimizationPanel = uipanel(app.DecisionSupportTab);
            app.OptimizationPanel.Position = [10 20 580 340];
            app.OptimizationPanel.Title = '优化建议';
            
            % 优化目标选择
            uilabel(app.OptimizationPanel, 'Position', [10 290 100 22], 'Text', '优化目标:');
            uidropdown(app.OptimizationPanel, 'Position', [120 290 150 22], ...
                'Items', {'服务效率', '空间均衡', '成本最小'}, ...
                'Value', '服务效率');
            
            % 约束条件设置
            uilabel(app.OptimizationPanel, 'Position', [10 250 100 22], 'Text', '约束条件:');
            uidropdown(app.OptimizationPanel, 'Position', [120 250 150 22], ...
                'Items', {'资源限制', '空间限制', '预算限制'}, ...
                'Value', '资源限制');
            
            % 优化分析按钮
            uibutton(app.OptimizationPanel, 'Position', [10 210 100 22], 'Text', '开始优化', ...
                'ButtonPushedFcn', @(btn,event) app.optimizeService);
            
            % 创建报告生成面板
            app.ReportPanel = uipanel(app.DecisionSupportTab);
            app.ReportPanel.Position = [600 20 580 340];
            app.ReportPanel.Title = '报告生成';
            
            % 报告类型选择
            uilabel(app.ReportPanel, 'Position', [10 290 100 22], 'Text', '报告类型:');
            uidropdown(app.ReportPanel, 'Position', [120 290 150 22], ...
                'Items', {'分析报告', '评估报告', '决策报告'}, ...
                'Value', '分析报告');
            
            % 报告格式选择
            uilabel(app.ReportPanel, 'Position', [10 250 100 22], 'Text', '报告格式:');
            uidropdown(app.ReportPanel, 'Position', [120 250 150 22], ...
                'Items', {'PDF', 'Word', 'HTML'}, ...
                'Value', 'PDF');
            
            % 报告生成按钮
            uibutton(app.ReportPanel, 'Position', [10 210 100 22], 'Text', '生成报告', ...
                'ButtonPushedFcn', @(btn,event) app.generateReport);
        end

        % 决策支持回调函数
        function analyzeScenario(app)
            try
                % 获取情景分析参数
                scenarioType = app.ScenarioPanel.Children(4).Value;  % 假设下拉框是第4个子组件
                changeRate = app.ScenarioPanel.Children(2).Value;    % 假设数字输入框是第2个子组件
                
                options = struct('type', scenarioType, 'rate', changeRate);
                results = app.DecisionAnalyzer.analyzeScenario(options);
                
                % 显示结果
                app.visualizeResults('scenario', results);
                app.StatusBar.Text = '情景分析完成';
            catch e
                app.StatusBar.Text = ['情景分析失败: ' e.message];
            end
        end
        
        function analyzeSensitivity(app)
            try
                % 获取敏感性分析参数
                parameter = app.SensitivityPanel.Children(4).Value;  % 假设下拉框是第4个子组件
                range = app.SensitivityPanel.Children(2).Value;      % 假设数字输入框是第2个子组件
                
                options = struct('parameter', parameter, 'range', range);
                results = app.DecisionAnalyzer.analyzeSensitivity(options);
                
                % 显示结果
                app.visualizeResults('sensitivity', results);
                app.StatusBar.Text = '敏感性分析完成';
            catch e
                app.StatusBar.Text = ['敏感性分析失败: ' e.message];
            end
        end
        
        function optimizeService(app)
            try
                % 获取优化参数
                objective = app.OptimizationPanel.Children(4).Value;  % 假设下拉框是第4个子组件
                constraint = app.OptimizationPanel.Children(2).Value; % 假设第二个下拉框是第2个子组件
                
                options = struct('objective', objective, 'constraint', constraint);
                results = app.DecisionAnalyzer.optimizeService(options);
                
                % 显示结果
                app.visualizeResults('optimization', results);
                app.StatusBar.Text = '优化分析完成';
            catch e
                app.StatusBar.Text = ['优化分析失败: ' e.message];
            end
        end
        
        function generateReport(app)
            try
                % 获取报告参数
                reportType = app.ReportPanel.Children(4).Value;  % 假设下拉框是第4个子组件
                format = app.ReportPanel.Children(2).Value;      % 假设第二个下拉框是第2个子组件
                
                % 选择保存位置
                [filename, pathname] = uiputfile({'*.pdf;*.docx;*.html', '支持的格式'});
                if isequal(filename, 0)
                    return;
                end
                
                options = struct('type', reportType, 'format', format);
                app.DecisionAnalyzer.generateReport(fullfile(pathname, filename), options);
                
                app.StatusBar.Text = '报告生成完成';
            catch e
                app.StatusBar.Text = ['报告生成失败: ' e.message];
            end
        end
    end

    % 回调方法
    methods (Access = private)
        function openData(app, ~)
            % TODO: 实现打开数据功能
            app.StatusBar.Text = '打开数据...';
        end
        
        function saveResults(app, ~)
            % TODO: 实现保存结果功能
            app.StatusBar.Text = '保存结果...';
        end
        
        function exitApp(app, ~)
            % 退出应用
            delete(app.UIFigure);
        end
        
        function showHelp(app, ~)
            % TODO: 显示帮助信息
            msgbox('使用说明', '帮助');
        end
        
        function showAbout(app, ~)
            % TODO: 显示关于信息
            msgbox('生态系统服务流分析系统 v1.0', '关于');
        end
    end

    % 公共方法
    methods (Access = public)
        function app = EcosystemServiceFlowApp
            % 创建UI组件
            createComponents(app)
            
            % 初始化分析对象
            app.DataProcessor = DataProcessor();
            app.ServiceAnalyzer = ServiceFlowAnalyzer();
            app.SpatialAnalyzer = SpatialAnalyzer();
            app.VisManager = VisualizationManager();
            
            % 显示UI
            app.UIFigure.Visible = 'on';
        end
    end
end 