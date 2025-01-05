classdef RiverVisualizer < handle
    properties (Access = private)
        Figure              matlab.ui.Figure
        MapAxes            matlab.ui.control.UIAxes
        ProfileAxes        matlab.ui.control.UIAxes
        TimeSeriesAxes     matlab.ui.control.UIAxes
        
        % Control panels
        ReachPanel         matlab.ui.container.Panel
        FlowPanel          matlab.ui.container.Panel
        CrossSectionPanel  matlab.ui.container.Panel
        
        % Interactive controls
        ReachSelector      matlab.ui.control.DropDown
        TimeSlider         matlab.ui.control.Slider
        LayerControls      struct
    end
    
    methods
        function obj = RiverVisualizer()
            % Create visualization components
            obj.createComponents();
            obj.initializeControls();
        end
        
        function visualizeRiverNetwork(obj, dem, river_mask, flow_acc)
            % Visualize river network with flow accumulation
            cla(obj.MapAxes);
            hold(obj.MapAxes, 'on');
            
            % Plot DEM as background
            surface(obj.MapAxes, dem, 'EdgeColor', 'none');
            colormap(obj.MapAxes, 'terrain');
            
            % Plot river network
            river_network = extractRiverNetwork(flow_acc);
            plot(obj.MapAxes, river_network, 'b-', 'LineWidth', 2);
            
            % Add flow direction arrows
            flow_directions = calculateFlowDirections(flow_acc);
            quiver(obj.MapAxes, flow_directions.X, flow_directions.Y, ...
                flow_directions.U, flow_directions.V);
            
            hold(obj.MapAxes, 'off');
        end
        
        function visualizeCrossSection(obj, dem, points)
            % Visualize river cross-section
            cla(obj.ProfileAxes);
            
            % Extract elevation profile
            [distances, elevations] = extractProfile(dem, points);
            
            % Plot cross-section
            plot(obj.ProfileAxes, distances, elevations, 'k-', 'LineWidth', 1.5);
            xlabel(obj.ProfileAxes, '距离 (m)');
            ylabel(obj.ProfileAxes, '高程 (m)');
            grid(obj.ProfileAxes, 'on');
        end
        
        function visualizeTimeSeries(obj, time, data, events)
            % Visualize time series data with events
            cla(obj.TimeSeriesAxes);
            hold(obj.TimeSeriesAxes, 'on');
            
            % Plot time series
            plot(obj.TimeSeriesAxes, time, data, 'b-', 'LineWidth', 1);
            
            % Add event markers
            for i = 1:length(events)
                xline(obj.TimeSeriesAxes, events(i).time, '--', ...
                    'Label', events(i).label);
            end
            
            % Customize appearance
            grid(obj.TimeSeriesAxes, 'on');
            xlabel(obj.TimeSeriesAxes, '时间');
            ylabel(obj.TimeSeriesAxes, '流量 (m³/s)');
            
            hold(obj.TimeSeriesAxes, 'off');
        end
    end
end 