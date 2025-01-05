classdef ServiceFlowNetwork
    % ServiceFlowNetwork 生态系统服务流网络分析类
    
    properties
        nodes           % 网络节点
        connections     % 节点连接矩阵
        flow_paths     % 服务流动路径
        supply_points  % 供给点
        demand_points  % 需求点
        resistance     % 阻力面
    end
    
    methods
        function obj = ServiceFlowNetwork(supply_points, demand_points, flow_paths, resistance)
            % 构造函数
            obj.supply_points = supply_points;
            obj.demand_points = demand_points;
            obj.flow_paths = flow_paths;
            obj.resistance = resistance;
            
            % 初始化网络结构
            obj.nodes = obj.identifyNodes();
            obj.connections = obj.buildConnections();
        end
        
        function nodes = identifyNodes(obj)
            % 识别网络节点
            [supply_y, supply_x] = find(obj.supply_points);
            [demand_y, demand_x] = find(obj.demand_points);
            
            % 合并供给点和需求点，并标记类型（1=供给点，2=需求点）
            nodes = [supply_y, supply_x, ones(size(supply_y));
                    demand_y, demand_x, 2*ones(size(demand_y))];
        end
        
        function connections = buildConnections(obj)
            % 构建节点连接矩阵
            n_nodes = size(obj.nodes, 1);
            connections = zeros(n_nodes);
            
            for i = 1:n_nodes
                for j = 1:n_nodes
                    if obj.nodes(i,3) == 1 && obj.nodes(j,3) == 2  % 从供给点到需求点
                        % 检查两点间是否存在流动路径
                        path_value = obj.checkPathExistence(...
                            [obj.nodes(i,1), obj.nodes(i,2)], ...
                            [obj.nodes(j,1), obj.nodes(j,2)]);
                        connections(i,j) = path_value;
                    end
                end
            end
        end
        
        function path_value = checkPathExistence(obj, point1, point2)
            % 检查两点间是否存在流动路径
            [rows, cols] = size(obj.flow_paths);
            path_value = 0;
            
            % 创建路径掩码
            mask = zeros(rows, cols);
            mask(point1(1), point1(2)) = 1;
            mask(point2(1), point2(2)) = 1;
            
            % 检查路径是否连通
            path_region = obj.flow_paths .* mask;
            if any(path_region(:) > 0)
                % 计算路径强度
                path_value = mean(obj.flow_paths(path_region > 0));
            end
        end
        
        function metrics = calculateNetworkMetrics(obj)
            % 计算网络指标
            metrics = struct();
            
            % 网络密度
            n_nodes = size(obj.nodes, 1);
            metrics.density = sum(obj.connections(:) > 0) / (n_nodes * (n_nodes-1));
            
            % 平均路径长度
            path_lengths = obj.calculatePathLengths();
            metrics.avg_path_length = mean(path_lengths(path_lengths > 0));
            
            % 聚集系数
            metrics.clustering = obj.calculateClusteringCoefficient();
            
            % 连通性
            metrics.connectivity = obj.calculateNetworkConnectivity();
            
            % 中心性指标
            centrality = obj.calculateCentralityMetrics();
            metrics.degree_centrality = centrality.degree;
            metrics.betweenness_centrality = centrality.betweenness;
            metrics.eigenvector_centrality = centrality.eigenvector;
        end
        
        function path_lengths = calculatePathLengths(obj)
            % 计算所有节点对之间的最短路径长度
            n_nodes = size(obj.nodes, 1);
            path_lengths = zeros(n_nodes);
            
            % 使用Floyd-Warshall算法
            dist = obj.connections;
            dist(dist == 0) = inf;
            dist(1:n_nodes+1:end) = 0;
            
            for k = 1:n_nodes
                for i = 1:n_nodes
                    for j = 1:n_nodes
                        if dist(i,k) + dist(k,j) < dist(i,j)
                            dist(i,j) = dist(i,k) + dist(k,j);
                        end
                    end
                end
            end
            
            path_lengths = dist;
        end
        
        function clustering = calculateClusteringCoefficient(obj)
            % 计算网络的聚集系数
            n_nodes = size(obj.nodes, 1);
            node_clustering = zeros(n_nodes, 1);
            
            for i = 1:n_nodes
                neighbors = find(obj.connections(i,:) > 0);
                if length(neighbors) > 1
                    possible_connections = nchoosek(length(neighbors), 2);
                    actual_connections = sum(sum(obj.connections(neighbors, neighbors))) / 2;
                    node_clustering(i) = actual_connections / possible_connections;
                end
            end
            
            clustering = mean(node_clustering(~isnan(node_clustering)));
        end
        
        function connectivity = calculateNetworkConnectivity(obj)
            % 计算网络连通性
            n_nodes = size(obj.nodes, 1);
            
            % 计算连通分量
            [~, components] = graphconncomp(sparse(obj.connections));
            n_components = max(components);
            
            % 连通性 = 1 - (连通分量数 / 节点数)
            connectivity = 1 - (n_components / n_nodes);
        end
        
        function centrality = calculateCentralityMetrics(obj)
            % 计算中心性指标
            centrality = struct();
            
            % 度中心性
            out_degree = sum(obj.connections, 2);
            in_degree = sum(obj.connections, 1)';
            centrality.degree = (out_degree + in_degree) / (2 * (size(obj.nodes, 1) - 1));
            
            % 介数中心性
            centrality.betweenness = obj.calculateBetweennessCentrality();
            
            % 特征向量中心性
            [V, D] = eig(obj.connections);
            [~, idx] = max(diag(D));
            centrality.eigenvector = abs(V(:,idx));
            centrality.eigenvector = centrality.eigenvector / max(centrality.eigenvector);
        end
        
        function centrality = calculateBetweennessCentrality(obj)
            % 计算介数中心性
            n_nodes = size(obj.nodes, 1);
            centrality = zeros(n_nodes, 1);
            
            % 计算所有最短路径
            [~, paths] = graphshortestpath(sparse(obj.connections));
            
            % 统计每个节点在最短路径中出现的次数
            for s = 1:n_nodes
                for t = 1:n_nodes
                    if s ~= t
                        path = paths{s,t};
                        if ~isempty(path)
                            for i = 2:length(path)-1
                                centrality(path(i)) = centrality(path(i)) + 1;
                            end
                        end
                    end
                end
            end
            
            % 标准化
            centrality = centrality / ((n_nodes-1)*(n_nodes-2));
        end
        
        function visualizeNetwork(obj)
            % 可视化网络结构
            figure('Name', 'Service Flow Network');
            
            % 绘制节点
            subplot(2,2,1);
            gplot(obj.connections, [obj.nodes(:,2), obj.nodes(:,1)], '-*');
            hold on;
            plot(obj.nodes(obj.nodes(:,3)==1,2), obj.nodes(obj.nodes(:,3)==1,1), 'ro', 'MarkerSize', 10);  % 供给点
            plot(obj.nodes(obj.nodes(:,3)==2,2), obj.nodes(obj.nodes(:,3)==2,1), 'bo', 'MarkerSize', 10);  % 需求点
            title('网络结构');
            legend('连接', '供给点', '需求点');
            
            % 绘制中心性指标
            subplot(2,2,2);
            centrality = obj.calculateCentralityMetrics();
            bar([centrality.degree, centrality.betweenness, centrality.eigenvector]);
            title('节点中心性');
            xlabel('节点');
            ylabel('中心性值');
            legend('度中心性', '介数中心性', '特征向量中心性');
            
            % 绘制连接强度分布
            subplot(2,2,3);
            histogram(obj.connections(obj.connections > 0));
            title('连接强度分布');
            xlabel('连接强度');
            ylabel('频数');
            
            % 绘制路径长度分布
            subplot(2,2,4);
            path_lengths = obj.calculatePathLengths();
            histogram(path_lengths(path_lengths < inf & path_lengths > 0));
            title('路径长度分布');
            xlabel('路径长度');
            ylabel('频数');
        end
        
        function communities = detectCommunities(obj)
            % 社区检测分析
            communities = struct();
            
            % 使用Louvain算法进行社区检测
            [communities.membership, communities.modularity] = obj.louvainCommunityDetection();
            
            % 计算社区内部连接密度
            communities.internal_density = obj.calculateCommunityDensity(communities.membership);
            
            % 计算社区间连接强度
            communities.between_strength = obj.calculateCommunityConnections(communities.membership);
            
            % 计算社区稳定性
            communities.stability = obj.calculateCommunityStability(communities.membership);
        end
        
        function [membership, modularity] = louvainCommunityDetection(obj)
            % Louvain社区检测算法实现
            n_nodes = size(obj.nodes, 1);
            membership = 1:n_nodes;  % 初始时每个节点属于独立社区
            
            while true
                % 第一阶段：节点重分配
                [membership, improved1] = obj.nodeReassignment(membership);
                
                % 第二阶段：社区合并
                [membership, improved2] = obj.communityMerging(membership);
                
                % 如果没有改进则停止
                if ~(improved1 || improved2)
                    break;
                end
            end
            
            % 计算模块度
            modularity = obj.calculateModularity(membership);
        end
        
        function stability = analyzeNetworkStability(obj)
            % 网络稳定性分析
            stability = struct();
            
            % 计算网络抗干扰能力
            stability.robustness = obj.calculateNetworkRobustness();
            
            % 计算网络脆弱性
            stability.vulnerability = obj.calculateNetworkVulnerability();
            
            % 计算关键节点稳定性
            stability.node_stability = obj.calculateNodeStability();
            
            % 计算连接稳定性
            stability.link_stability = obj.calculateLinkStability();
        end
        
        function evolution = analyzeNetworkEvolution(obj, time_series_data)
            % 网络演化分析
            evolution = struct();
            
            % 计算网络拓扑变化
            evolution.topology_change = obj.calculateTopologyChange(time_series_data);
            
            % 计算节点动态特征
            evolution.node_dynamics = obj.calculateNodeDynamics(time_series_data);
            
            % 计算连接权重变化
            evolution.weight_change = obj.calculateWeightChange(time_series_data);
            
            % 计算网络增长特征
            evolution.growth_pattern = obj.calculateGrowthPattern(time_series_data);
        end
        
        function multilayer = analyzeMultilayerNetwork(obj, layer_data)
            % 多层网络分析
            multilayer = struct();
            
            % 构建多层网络结构
            multilayer.layers = obj.buildMultilayerStructure(layer_data);
            
            % 计算层间相关性
            multilayer.interlayer_correlation = obj.calculateInterlayerCorrelation(layer_data);
            
            % 计算多层中心性
            multilayer.multiplex_centrality = obj.calculateMultiplexCentrality(layer_data);
            
            % 分析层间信息流动
            multilayer.interlayer_flow = obj.calculateInterlayerFlow(layer_data);
        end
        
        % 辅助函数：社区检测
        function [membership, improved] = nodeReassignment(obj, current_membership)
            % 节点重分配过程
            improved = false;
            membership = current_membership;
            n_nodes = length(membership);
            
            for i = 1:n_nodes
                % 计算节点i移动到不同社区的增益
                current_community = membership(i);
                max_gain = 0;
                best_community = current_community;
                
                % 获取相邻社区
                neighbors = find(obj.connections(i,:) > 0 | obj.connections(:,i)' > 0);
                neighbor_communities = unique(membership(neighbors));
                
                for community = neighbor_communities'
                    if community ~= current_community
                        % 计算模块度增益
                        gain = obj.calculateModularityGain(i, current_community, community, membership);
                        if gain > max_gain
                            max_gain = gain;
                            best_community = community;
                        end
                    end
                end
                
                % 如果找到更好的社区，则移动节点
                if best_community ~= current_community
                    membership(i) = best_community;
                    improved = true;
                end
            end
        end
        
        function [membership, improved] = communityMerging(obj, current_membership)
            % 社区合并过程
            improved = false;
            membership = current_membership;
            communities = unique(membership);
            n_communities = length(communities);
            
            % 构建社区间连接矩阵
            community_connections = zeros(n_communities);
            for i = 1:n_communities
                for j = i+1:n_communities
                    % 计算社区间连接强度
                    nodes_i = find(membership == communities(i));
                    nodes_j = find(membership == communities(j));
                    connection_strength = sum(sum(obj.connections(nodes_i, nodes_j))) + ...
                                       sum(sum(obj.connections(nodes_j, nodes_i)));
                    community_connections(i,j) = connection_strength;
                    community_connections(j,i) = connection_strength;
                end
            end
            
            % 合并强连接的社区
            while true
                [max_strength, idx] = max(community_connections(:));
                if max_strength == 0
                    break;
                end
                
                [i, j] = ind2sub(size(community_connections), idx);
                
                % 计算合并增益
                gain = obj.calculateMergeGain(communities(i), communities(j), membership);
                
                if gain > 0
                    % 执行合并
                    membership(membership == communities(j)) = communities(i);
                    improved = true;
                    
                    % 更新连接矩阵
                    community_connections(i,:) = community_connections(i,:) + community_connections(j,:);
                    community_connections(:,i) = community_connections(:,i) + community_connections(:,j);
                    community_connections(j,:) = 0;
                    community_connections(:,j) = 0;
                else
                    community_connections(i,j) = 0;
                    community_connections(j,i) = 0;
                end
            end
        end
        
        function modularity = calculateModularity(obj, membership)
            % 计算网络模块度
            m = sum(obj.connections(:));  % 总连接权重
            n_nodes = size(obj.nodes, 1);
            modularity = 0;
            
            for i = 1:n_nodes
                for j = 1:n_nodes
                    if membership(i) == membership(j)
                        ki = sum(obj.connections(i,:));
                        kj = sum(obj.connections(:,j));
                        modularity = modularity + (obj.connections(i,j) - ki*kj/m);
                    end
                end
            end
            
            modularity = modularity / m;
        end
        
        % 辅助函数：网络稳定性分析
        function robustness = calculateNetworkRobustness(obj)
            % 计算网络抗干扰能力
            n_nodes = size(obj.nodes, 1);
            robustness = struct();
            
            % 节点移除实验
            remaining_size = zeros(n_nodes, 1);
            for i = 1:n_nodes
                % 移除i个节点后的最大连通分量大小
                temp_connections = obj.connections;
                [~, node_order] = sort(obj.calculateCentralityMetrics().degree, 'descend');
                removed_nodes = node_order(1:i);
                temp_connections(removed_nodes,:) = 0;
                temp_connections(:,removed_nodes) = 0;
                
                [~, components] = graphconncomp(sparse(temp_connections));
                remaining_size(i) = max(histcounts(components));
            end
            
            robustness.node_removal = remaining_size / n_nodes;
            robustness.critical_fraction = find(remaining_size/n_nodes < 0.5, 1) / n_nodes;
        end
        
        function vulnerability = calculateNetworkVulnerability(obj)
            % 计算网络脆弱性
            n_nodes = size(obj.nodes, 1);
            original_efficiency = obj.calculateNetworkEfficiency();
            vulnerability = zeros(n_nodes, 1);
            
            for i = 1:n_nodes
                % 移除节点i后的网络效率
                temp_connections = obj.connections;
                temp_connections(i,:) = 0;
                temp_connections(:,i) = 0;
                
                efficiency_i = obj.calculateNetworkEfficiency(temp_connections);
                vulnerability(i) = (original_efficiency - efficiency_i) / original_efficiency;
            end
        end
        
        function efficiency = calculateNetworkEfficiency(obj, connections)
            % 计算网络效率
            if nargin < 2
                connections = obj.connections;
            end
            
            n_nodes = size(connections, 1);
            distances = obj.calculatePathLengths(connections);
            distances(isinf(distances)) = n_nodes;  % 处理不连通的情况
            
            efficiency = mean(1./distances(distances > 0));
        end
        
        % 辅助函数：网络演化分析
        function topology_change = calculateTopologyChange(obj, time_series_data)
            % 计算网络拓扑变化
            n_timesteps = size(time_series_data, 3);
            topology_change = struct();
            
            % 计算每个时间步的网络指标
            metrics = zeros(n_timesteps, 4);  % [密度, 聚集系数, 平均路径长度, 连通性]
            for t = 1:n_timesteps
                temp_network = ServiceFlowNetwork(time_series_data.supply_points(:,:,t), ...
                    time_series_data.demand_points(:,:,t), ...
                    time_series_data.flow_paths(:,:,t), ...
                    time_series_data.resistance(:,:,t));
                
                temp_metrics = temp_network.calculateNetworkMetrics();
                metrics(t,:) = [temp_metrics.density, temp_metrics.clustering, ...
                              temp_metrics.avg_path_length, temp_metrics.connectivity];
            end
            
            topology_change.metrics_time_series = metrics;
            topology_change.rate_of_change = diff(metrics) ./ diff(1:n_timesteps)';
        end
        
        % 辅助函数：多层网络分析
        function layers = buildMultilayerStructure(obj, layer_data)
            % 构建多层网络结构
            n_layers = length(layer_data);
            layers = cell(n_layers, 1);
            
            for i = 1:n_layers
                layers{i} = ServiceFlowNetwork(layer_data(i).supply_points, ...
                    layer_data(i).demand_points, ...
                    layer_data(i).flow_paths, ...
                    layer_data(i).resistance);
            end
        end
        
        function correlation = calculateInterlayerCorrelation(obj, layer_data)
            % 计算层间相关性
            n_layers = length(layer_data);
            correlation = zeros(n_layers);
            
            for i = 1:n_layers
                for j = i+1:n_layers
                    % 计算两层网络的连接矩阵相关性
                    layer_i = ServiceFlowNetwork(layer_data(i).supply_points, ...
                        layer_data(i).demand_points, ...
                        layer_data(i).flow_paths, ...
                        layer_data(i).resistance);
                    
                    layer_j = ServiceFlowNetwork(layer_data(j).supply_points, ...
                        layer_data(j).demand_points, ...
                        layer_data(j).flow_paths, ...
                        layer_data(j).resistance);
                    
                    corr_matrix = corrcoef(layer_i.connections(:), layer_j.connections(:));
                    correlation(i,j) = corr_matrix(1,2);
                    correlation(j,i) = corr_matrix(1,2);
                end
            end
        end
        
        function visualizeMultilayerNetwork(obj, multilayer)
            % 可视化多层网络结构
            figure('Name', 'Multilayer Service Flow Network');
            
            % 绘制层间相关性热图
            subplot(2,2,1);
            imagesc(multilayer.interlayer_correlation);
            colormap(jet);
            colorbar;
            title('层间相关性');
            xlabel('层');
            ylabel('层');
            
            % 绘制多层中心性
            subplot(2,2,2);
            bar(multilayer.multiplex_centrality);
            title('多层中心性');
            xlabel('节点');
            ylabel('中心性值');
            
            % 绘制层间信息流动
            subplot(2,2,3);
            imagesc(multilayer.interlayer_flow);
            colormap(jet);
            colorbar;
            title('层间信息流动');
            xlabel('目标层');
            ylabel('源层');
            
            % 绘制多层网络整体结构
            subplot(2,2,4);
            n_layers = length(multilayer.layers);
            hold on;
            colors = jet(n_layers);
            for i = 1:n_layers
                layer = multilayer.layers{i};
                scatter3(layer.nodes(:,1), layer.nodes(:,2), i*ones(size(layer.nodes,1),1), ...
                    50, colors(i,:), 'filled');
            end
            title('多层网络结构');
            xlabel('X');
            ylabel('Y');
            zlabel('层');
            view(45, 30);
            grid on;
        end
    end
end 