classdef EnhancedVisualizationPanel < matlab.ui.container.Panel
    properties (Access = private)
        % 3D Visualization
        TerrainPanel       matlab.ui.container.Panel
        TerrainAxes       matlab.ui.control.UIAxes
        ElevationSlider   matlab.ui.control.Slider
        
        % Flow Network
        FlowPanel         matlab.ui.container.Panel
        FlowAxes          matlab.ui.control.UIAxes
        FlowControls      matlab.ui.container.Panel
        
        % Interactive Time Series
        TimeSeriesPanel   matlab.ui.container.Panel
        TSAxes            matlab.ui.control.UIAxes
        TimeRangeSlider   matlab.ui.control.Slider
        
        % Comparison
        ComparisonPanel   matlab.ui.container.Panel
        CompAxes         matlab.ui.control.UIAxes
        ScenarioList     matlab.ui.control.ListBox
    end
    
    methods
        function obj = EnhancedVisualizationPanel(parent)
            obj@matlab.ui.container.Panel(parent);
            obj.Title = '增强可视化';
            createComponents(obj);
        end
        
        function visualize3DTerrain(obj, dem, data)
            % 3D terrain visualization
            surf(obj.TerrainAxes, dem, data);
            colormap(obj.TerrainAxes, 'terrain');
            colorbar(obj.TerrainAxes);
            view(obj.TerrainAxes, 3);
            
            % Add interaction
            rotate3d(obj.TerrainAxes, 'on');
            obj.ElevationSlider.ValueChangedFcn = @(~,~) updateElevation(obj);
        end
        
        function visualizeFlowNetwork(obj, nodes, edges, weights)
            % Flow network visualization
            G = digraph(edges(:,1), edges(:,2), weights);
            p = plot(obj.FlowAxes, G, 'EdgeLabel', G.Edges.Weight);
            p.EdgeCData = weights;
            colormap(obj.FlowAxes, 'jet');
            colorbar(obj.FlowAxes);
        end
        
        function visualizeTimeSeries(obj, time, data, events)
            % Interactive time series plot
            plot(obj.TSAxes, time, data);
            hold(obj.TSAxes, 'on');
            
            % Add event markers
            for i = 1:length(events)
                xline(obj.TSAxes, events(i).time, '--', events(i).label);
            end
            
            % Add range selection
            obj.TimeRangeSlider.ValueChangedFcn = @(~,~) updateTimeRange(obj);
        end
        
        function compareScenarios(obj, scenarios)
            % Scenario comparison visualization
            hold(obj.CompAxes, 'off');
            colors = lines(length(scenarios));
            
            for i = 1:length(scenarios)
                plot(obj.CompAxes, scenarios(i).time, scenarios(i).data, ...
                    'Color', colors(i,:), 'DisplayName', scenarios(i).name);
                hold(obj.CompAxes, 'on');
            end
            
            legend(obj.CompAxes, 'show');
            grid(obj.CompAxes, 'on');
        end
    end
end 