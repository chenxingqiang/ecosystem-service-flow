classdef FloodServiceAnalyzer < ModelIntegrationTools
    properties (Access = private)
        FloodMetrics     FloodEcosystemMetrics
        FloodVisualizer  FloodVisualizer
        ServiceAnalyzer  ServiceFlowAnalyzer
    end
    
    methods
        function obj = FloodServiceAnalyzer(parent)
            obj@ModelIntegrationTools(parent);
            obj.initializeAnalyzers();
        end
        
        function results = analyzeFloodServiceInteraction(obj, data)
            % Analyze flood-service interactions
            try
                % Calculate metrics
                metrics = obj.FloodMetrics.analyzeFloodEcosystemInteraction(...
                    data.flood, data.ecosystem);
                
                % Analyze service flows
                flows = obj.ServiceAnalyzer.analyzeServiceFlows(data);
                
                % Integrate results
                results = obj.integrateResults(metrics, flows);
                
                % Visualize results
                obj.FloodVisualizer.visualizeResults(results);
                
            catch e
                uialert(obj.MainFigure, e.message, '分析错误');
            end
        end
        
        function compareScenarios(obj, baseline, scenarios)
            % Compare different flood-service scenarios
            try
                % Run scenario analysis
                results = obj.runScenarioAnalysis(baseline, scenarios);
                
                % Calculate differences
                differences = obj.calculateScenarioDifferences(results);
                
                % Generate comparison report
                report = obj.generateComparisonReport(differences);
                
                % Display results
                obj.displayScenarioComparison(report);
                
            catch e
                uialert(obj.MainFigure, e.message, '情景对比错误');
            end
        end
    end
    
    methods (Access = private)
        function initializeAnalyzers(obj)
            % Initialize analysis components
            obj.FloodMetrics = FloodEcosystemMetrics();
            obj.FloodVisualizer = FloodVisualizer();
            obj.ServiceAnalyzer = ServiceFlowAnalyzer();
        end
        
        function results = integrateResults(obj, metrics, flows)
            % Integrate analysis results
            results = struct();
            results.metrics = metrics;
            results.flows = flows;
            results.integrated = obj.calculateIntegratedMetrics(metrics, flows);
        end
    end
end 