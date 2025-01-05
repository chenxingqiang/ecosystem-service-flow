classdef IntegratedVisualizer < YellowRiverVisualizer
    methods
        function visualizeIntegratedResults(obj, model_results)
            % Visualize integrated model results
            figure('Name', '综合模型结果');
            
            % Create multi-panel display
            subplot(2,2,1);
            obj.visualizeFisheriesResults(model_results.fisheries);
            
            subplot(2,2,2);
            obj.visualizeFloodResults(model_results.flood);
            
            subplot(2,2,3);
            obj.visualizeVisibilityResults(model_results.visibility);
            
            subplot(2,2,4);
            obj.visualizeGEEData(model_results.gee_data);
            
            % Add integrated legend
            obj.createIntegratedLegend(model_results);
        end
        
        function visualizeModelComparison(obj, results1, results2, parameters)
            % Visualize model comparison
            figure('Name', '模型对比');
            
            % Plot comparison
            subplot(1,2,1);
            obj.plotModelResults(results1, '模型1');
            
            subplot(1,2,2);
            obj.plotModelResults(results2, '模型2');
            
            % Add comparison metrics
            obj.addComparisonMetrics(results1, results2, parameters);
        end
        
        function visualizeTemporalChanges(obj, time_series_data)
            % Visualize temporal changes
            figure('Name', '时间序列变化');
            
            % Create interactive time series plot
            obj.createTimeSeriesPlot(time_series_data);
            
            % Add time slider
            obj.addTimeControls();
            
            % Add change indicators
            obj.addChangeIndicators(time_series_data);
        end
    end
    
    methods (Access = private)
        function createTimeSeriesPlot(obj, data)
            % Create interactive time series plot
            plot(data.time, data.values, 'LineWidth', 2);
            grid on;
            xlabel('时间');
            ylabel('值');
            
            % Add interaction handlers
            obj.setupInteraction();
        end
        
        function addChangeIndicators(obj, data)
            % Add change indicators
            hold on;
            changes = detectChanges(data);
            plot(changes.time, changes.values, 'r*');
            hold off;
        end
    end
end 