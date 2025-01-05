classdef FloodVisualizer < IntegratedVisualizer
    methods
        function visualizeFloodExtent(obj, flood_data, ecosystem_data)
            % Visualize flood extent and ecosystem impacts
            figure('Name', '洪水范围与生态影响');
            
            % Create main display
            obj.MapAxes = subplot(1,2,1);
            obj.plotFloodExtent(flood_data);
            hold(obj.MapAxes, 'on');
            obj.plotEcosystemOverlay(ecosystem_data);
            hold(obj.MapAxes, 'off');
            
            % Create impact analysis
            obj.ImpactAxes = subplot(1,2,2);
            obj.plotImpactAnalysis(flood_data, ecosystem_data);
            
            % Add interactive controls
            obj.addInteractiveControls();
        end
        
        function animateFloodProgression(obj, flood_timeseries)
            % Animate flood progression over time
            figure('Name', '洪水演进动画');
            
            % Setup animation
            obj.setupAnimation();
            
            % Create animation frames
            for t = 1:length(flood_timeseries)
                obj.updateFloodFrame(flood_timeseries(t));
                obj.updateImpactAnalysis(flood_timeseries(t));
                pause(0.1);
            end
        end
        
        function visualizeServiceFlow(obj, service_data, flood_data)
            % Visualize ecosystem service flows under flood conditions
            figure('Name', '生态系统服务流动分析');
            
            % Plot service flow network
            obj.plotServiceNetwork(service_data);
            
            % Overlay flood impact
            obj.overlayFloodImpact(flood_data);
            
            % Add flow indicators
            obj.addFlowIndicators(service_data, flood_data);
        end
    end
    
    methods (Access = private)
        function plotFloodExtent(obj, flood_data)
            % Plot flood extent
            contourf(flood_data.depth);
            colormap('blues');
            colorbar;
            title('洪水范围');
        end
        
        function plotImpactAnalysis(obj, flood_data, ecosystem_data)
            % Plot impact analysis
            impacts = calculateImpacts(flood_data, ecosystem_data);
            obj.visualizeImpacts(impacts);
        end
        
        function setupAnimation(obj)
            % Setup animation parameters
            obj.AnimationAxes = gca;
            obj.ColorMap = colormap('blues');
            obj.AnimationControls = struct();
            obj.setupPlaybackControls();
        end
    end
end 