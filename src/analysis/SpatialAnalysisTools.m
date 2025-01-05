classdef SpatialAnalysisTools
    methods (Static)
        function [I, pValue] = calculateMoransI(data, W)
            % Calculate Moran's I spatial autocorrelation
            n = numel(data);
            z = data - mean(data(:));
            
            % Calculate Moran's I
            zW = W * z(:);
            S0 = sum(W(:));
            I = (n / S0) * (z(:)' * zW) / (z(:)' * z(:));
            
            % Calculate significance
            E_I = -1 / (n - 1);
            var_I = calculateMoransIVariance(W, z);
            Z = (I - E_I) / sqrt(var_I);
            pValue = 2 * (1 - normcdf(abs(Z)));
        end
        
        function [G, pValue] = calculateGetisOrd(data, W, d)
            % Calculate Getis-Ord G* statistic
            n = numel(data);
            x_bar = mean(data(:));
            S = std(data(:));
            
            G = zeros(size(data));
            pValue = zeros(size(data));
            
            for i = 1:n
                % Get neighbors within distance d
                neighbors = W(i,:) > 0;
                
                if sum(neighbors) > 0
                    Wx = sum(data(neighbors));
                    W_sum = sum(neighbors);
                    
                    % Calculate G* statistic
                    G(i) = (Wx - x_bar * W_sum) / ...
                        (S * sqrt((n * W_sum - W_sum^2) / (n - 1)));
                    
                    % Calculate p-value
                    pValue(i) = 2 * (1 - normcdf(abs(G(i))));
                end
            end
        end
        
        function path = optimizeFlowPath(source, sink, cost)
            % Optimize flow path using A* algorithm
            [rows, cols] = size(cost);
            goal = sink;
            
            % Initialize data structures
            openSet = {source};
            closedSet = {};
            cameFrom = containers.Map('KeyType', 'char', 'ValueType', 'char');
            
            % Cost from start to node
            gScore = containers.Map('KeyType', 'char', 'ValueType', 'double');
            gScore(pointToKey(source)) = 0;
            
            % Estimated total cost
            fScore = containers.Map('KeyType', 'char', 'ValueType', 'double');
            fScore(pointToKey(source)) = heuristic(source, goal);
            
            while ~isempty(openSet)
                % Get node with lowest fScore
                current = getLowestFScore(openSet, fScore);
                
                if isequal(current, goal)
                    path = reconstructPath(cameFrom, current);
                    return;
                end
                
                openSet = setdiff(openSet, {current});
                closedSet = [closedSet, {current}];
                
                % Check neighbors
                neighbors = getNeighbors(current, rows, cols);
                for i = 1:length(neighbors)
                    neighbor = neighbors{i};
                    if ismember(neighbor, closedSet)
                        continue;
                    end
                    
                    tentative_gScore = gScore(pointToKey(current)) + ...
                        cost(neighbor(1), neighbor(2));
                    
                    if ~ismember(neighbor, openSet)
                        openSet = [openSet, {neighbor}];
                    elseif tentative_gScore >= gScore(pointToKey(neighbor))
                        continue;
                    end
                    
                    % Record this path
                    cameFrom(pointToKey(neighbor)) = pointToKey(current);
                    gScore(pointToKey(neighbor)) = tentative_gScore;
                    fScore(pointToKey(neighbor)) = gScore(pointToKey(neighbor)) + ...
                        heuristic(neighbor, goal);
                end
            end
            
            path = [];  % No path found
        end
        
        function scores = evaluateMCDA(alternatives, criteria, weights)
            % Multi-criteria decision analysis using weighted sum method
            n_alt = size(alternatives, 1);
            n_crit = size(alternatives, 2);
            
            % Normalize criteria
            normalized = zeros(size(alternatives));
            for i = 1:n_crit
                range = max(alternatives(:,i)) - min(alternatives(:,i));
                if range > 0
                    normalized(:,i) = (alternatives(:,i) - min(alternatives(:,i))) / range;
                else
                    normalized(:,i) = ones(n_alt, 1);
                end
            end
            
            % Calculate weighted sum
            scores = normalized * weights(:);
        end
    end
end 