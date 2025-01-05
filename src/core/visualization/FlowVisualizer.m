classdef FlowVisualizer
    % FlowVisualizer 生态系统服务流可视化类
    % 用于生成各种可视化结果
    
    properties (Access = private)
        % 颜色方案
        ColorMaps = struct(...
            'flow', turbo(256), ...
            'terrain', terrain(256), ...
            'supply', summer(256), ...
            'demand', autumn(256), ...
            'resistance', hot(256));
        
        % 图形设置
        PlotSettings = struct(...
            'FontSize', 12, ...
            'LineWidth', 1.5, ...
            'MarkerSize', 8);
    end
    
    methods
        function obj = FlowVisualizer()
            % 构造函数
        end
        
        function visualizeSupplyDemand(obj, supply_data, demand_data, title_str)
            % 可视化供需分布
            figure('Name', title_str, 'Position', [100 100 1200 400]);
            
            % 供给分布
            subplot(1,2,1);
            imagesc(supply_data);
            colormap(gca, obj.ColorMaps.supply);
            colorbar;
            title('供给分布');
            axis equal tight;
            
            % 需求分布
            subplot(1,2,2);
            imagesc(demand_data);
            colormap(gca, obj.ColorMaps.demand);
            colorbar;
            title('需求分布');
            axis equal tight;
            
            sgtitle(title_str);
        end
        
        function visualizeFlowPaths(obj, paths, dem_data, title_str)
            % 可视化流动路径
            figure('Name', title_str);
            
            % 绘制地形背景
            imagesc(dem_data);
            colormap(obj.ColorMaps.terrain);
            hold on;
            
            % 绘制所有路径
            for i = 1:size(paths, 1)
                for j = 1:size(paths, 2)
                    path = paths{i,j};
                    if ~isempty(path)
                        plot(path(:,2), path(:,1), 'r-', ...
                             'LineWidth', obj.PlotSettings.LineWidth);
                    end
                end
            end
            
            colorbar;
            title(title_str);
            axis equal tight;
            hold off;
        end
        
        function visualizeFlowIntensity(obj, intensity_data, title_str)
            % 可视化流动强度
            figure('Name', title_str);
            
            imagesc(intensity_data);
            colormap(obj.ColorMaps.flow);
            colorbar;
            
            title(title_str);
            axis equal tight;
        end
        
        function visualizeResistance(obj, resistance_data, barriers, title_str)
            % 可视化阻力分布
            figure('Name', title_str);
            
            % 绘制阻力背景
            imagesc(resistance_data);
            colormap(obj.ColorMaps.resistance);
            hold on;
            
            % 标记障碍位置
            [barrier_i, barrier_j] = find(barriers);
            plot(barrier_j, barrier_i, 'k.', ...
                 'MarkerSize', obj.PlotSettings.MarkerSize);
            
            colorbar;
            title(title_str);
            axis equal tight;
            hold off;
        end
        
        function visualizeFlowEfficiency(obj, efficiency_data, title_str)
            % 可视化流动效率
            figure('Name', title_str);
            
            % 创建饼图
            pie([efficiency_data.actual_flow, ...
                 efficiency_data.max_flow - efficiency_data.actual_flow]);
            
            % 添加标签
            labels = {sprintf('实际流动 (%.1f%%)', efficiency_data.ratio * 100), ...
                     sprintf('未实现流动 (%.1f%%)', (1 - efficiency_data.ratio) * 100)};
            legend(labels, 'Location', 'eastoutside');
            
            title(title_str);
        end
        
        function visualize3DFlow(obj, dem_data, flow_data, title_str)
            % 3D可视化流动
            figure('Name', title_str);
            
            % 创建网格
            [X, Y] = meshgrid(1:size(dem_data,2), 1:size(dem_data,1));
            
            % 绘制3D表面
            surf(X, Y, dem_data, flow_data, ...
                 'EdgeColor', 'none', ...
                 'FaceAlpha', 0.8);
            
            colormap(obj.ColorMaps.flow);
            colorbar;
            
            % 设置视角
            view(45, 30);
            
            % 设置标签
            xlabel('X');
            ylabel('Y');
            zlabel('高程');
            title(title_str);
            
            % 添加光照效果
            lighting gouraud;
            camlight;
        end
        
        function visualizeTimeSeriesFlow(obj, time_series_data, time_points, title_str)
            % 可视化时间序列流动
            figure('Name', title_str);
            
            % 绘制时间序列
            plot(time_points, time_series_data, '-o', ...
                 'LineWidth', obj.PlotSettings.LineWidth, ...
                 'MarkerSize', obj.PlotSettings.MarkerSize);
            
            % 设置标签
            xlabel('时间');
            ylabel('流动量');
            title(title_str);
            grid on;
        end
        
        function visualizeFlowNetwork(obj, nodes, edges, weights, title_str)
            % 可视化流动网络
            figure('Name', title_str);
            
            % 创建有向图
            G = digraph(edges(:,1), edges(:,2), weights);
            
            % 绘制网络
            plot(G, 'LineWidth', weights/max(weights)*3, ...
                    'MarkerSize', obj.PlotSettings.MarkerSize, ...
                    'NodeColor', 'b', ...
                    'EdgeColor', 'r', ...
                    'NodeLabel', '');
            
            title(title_str);
            axis equal;
        end
        
        function visualizeFlowComparison(obj, flow_results, model_names, title_str)
            % 可视化不同流动模型的比较
            figure('Name', title_str, 'Position', [100 100 1200 400]);
            
            % 提取比较指标
            max_flows = cellfun(@(x) max(x.actual_flow.final(:)), flow_results);
            mean_flows = cellfun(@(x) mean(x.actual_flow.final(:)), flow_results);
            efficiencies = cellfun(@(x) x.efficiency.ratio, flow_results);
            
            % 创建子图
            subplot(1,3,1);
            bar(max_flows);
            title('最大流量');
            set(gca, 'XTickLabel', model_names);
            xtickangle(45);
            
            subplot(1,3,2);
            bar(mean_flows);
            title('平均流量');
            set(gca, 'XTickLabel', model_names);
            xtickangle(45);
            
            subplot(1,3,3);
            bar(efficiencies);
            title('流动效率');
            set(gca, 'XTickLabel', model_names);
            xtickangle(45);
            
            sgtitle(title_str);
        end
        
        function visualizeUncertainty(obj, uncertainty_data, title_str)
            % 可视化不确定性
            figure('Name', title_str);
            
            % 提取不确定性数据
            categories = {'供给', '需求', '阻力', '总体'};
            values = [uncertainty_data.supply, ...
                     uncertainty_data.demand, ...
                     uncertainty_data.resistance, ...
                     uncertainty_data.total];
            
            % 创建条形图
            bar(values);
            set(gca, 'XTickLabel', categories);
            
            % 添加标签
            ylabel('不确定性');
            title(title_str);
            grid on;
        end
        
        function exportVisualization(obj, fig_handle, filename, format)
            % 导出可视化结果
            if nargin < 4
                format = 'png';
            end
            
            % 确保输出目录存在
            output_dir = './output/plots';
            if ~exist(output_dir, 'dir')
                mkdir(output_dir);
            end
            
            % 构建完整文件路径
            filepath = fullfile(output_dir, [filename '.' format]);
            
            % 导出图形
            saveas(fig_handle, filepath, format);
            fprintf('可视化结果已保存至: %s\n', filepath);
        end
    end
    
    methods (Access = private)
        function customizePlot(obj, ax)
            % 自定义绘图设置
            set(ax, 'FontSize', obj.PlotSettings.FontSize);
            set(ax, 'LineWidth', obj.PlotSettings.LineWidth);
            grid(ax, 'on');
            box(ax, 'on');
        end
    end
end 