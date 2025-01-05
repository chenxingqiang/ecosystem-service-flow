classdef InteractiveVisualizer < handle
    properties (Access = private)
        Figure          matlab.ui.Figure
        MapAxes         matlab.ui.control.UIAxes
        LegendPanel     matlab.ui.container.Panel
        ColorPanel      matlab.ui.container.Panel
        AnimationPanel  matlab.ui.container.Panel
        
        % Interactive controls
        LayerControls   struct
        ColorControls   struct
        AnimControls    struct
        
        % Data
        CurrentData     struct
        ColorMaps       struct
        TimeSteps       double
    end
    
    methods
        function obj = InteractiveVisualizer()
            % Create main figure and components
            obj.createComponents();
            
            % Initialize colormaps
            obj.initializeColorMaps();
        end
        
        function createComponents(obj)
            % Create main figure
            obj.Figure = uifigure('Name', '交互式可视化');
            
            % Create map axes
            obj.MapAxes = uiaxes(obj.Figure);
            obj.MapAxes.Position = [50 100 600 500];
            
            % Create legend panel
            obj.LegendPanel = uipanel(obj.Figure);
            obj.LegendPanel.Position = [670 400 200 200];
            obj.LegendPanel.Title = '图例';
            
            % Create layer controls
            obj.createLayerControls();
            
            % Create color controls
            obj.createColorControls();
            
            % Create animation controls
            obj.createAnimationControls();
        end
        
        function createLayerControls(obj)
            % Create layer visibility toggles
            layers = {'地形', '土地利用', '服务流', '热点'};
            for i = 1:length(layers)
                obj.LayerControls.(matlab.lang.makeValidName(layers{i})) = ...
                    uicheckbox(obj.LegendPanel, ...
                    'Text', layers{i}, ...
                    'Position', [10 180-i*30 100 20], ...
                    'ValueChangedFcn', @(~,~) obj.updateDisplay());
            end
        end
        
        function createColorControls(obj)
            % Create colormap selector
            obj.ColorControls.MapSelect = uidropdown(obj.ColorPanel, ...
                'Items', {'jet', 'parula', 'turbo', 'terrain'}, ...
                'ValueChangedFcn', @(~,~) obj.updateColorMap());
                
            % Create color range controls
            obj.ColorControls.RangeSlider = uislider(obj.ColorPanel, ...
                'Limits', [0 1], ...
                'Value', [0 1], ...
                'ValueChangedFcn', @(~,~) obj.updateColorRange());
        end
        
        function createAnimationControls(obj)
            % Create animation controls
            obj.AnimControls.PlayButton = uibutton(obj.AnimationPanel, ...
                'Text', '播放', ...
                'ButtonPushedFcn', @(~,~) obj.playAnimation());
                
            obj.AnimControls.TimeSlider = uislider(obj.AnimationPanel, ...
                'ValueChangedFcn', @(~,~) obj.updateTimeStep());
        end
        
        function updateDisplay(obj)
            % Update display based on layer visibility
            cla(obj.MapAxes);
            hold(obj.MapAxes, 'on');
            
            % Plot visible layers
            if obj.LayerControls.terrain.Value
                obj.plotTerrain();
            end
            if obj.LayerControls.landuse.Value
                obj.plotLandUse();
            end
            if obj.LayerControls.serviceFlow.Value
                obj.plotServiceFlow();
            end
            if obj.LayerControls.hotspots.Value
                obj.plotHotspots();
            end
            
            hold(obj.MapAxes, 'off');
        end
        
        function updateColorMap(obj)
            % Update colormap
            colormap(obj.MapAxes, obj.ColorControls.MapSelect.Value);
        end
        
        function playAnimation(obj)
            % Play time series animation
            for t = 1:obj.TimeSteps
                obj.AnimControls.TimeSlider.Value = t;
                obj.updateTimeStep();
                pause(0.1);
            end
        end
    end
end 