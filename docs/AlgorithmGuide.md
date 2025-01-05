# 算法实现指南

## 1. 空间分析算法

### 1.1 空间自相关分析

Moran's I 统计量计算:

```matlab
function [I, pValue] = calculateMoransI(data, W)
    % 计算 Moran's I
    n = numel(data);
    z = data - mean(data(:));
    zW = W * z(:);
    S0 = sum(W(:));
    I = (n / S0) * (z(:)' * zW) / (z(:)' * z(:));
    
    % 计算显著性
    E_I = -1 / (n - 1);
    var_I = calculateMoransIVariance(W, z);
    Z = (I - E_I) / sqrt(var_I);
    pValue = 2 * (1 - normcdf(abs(Z)));
end
```

### 1.2 热点分析

使用 Getis-Ord G* 统计量:

```matlab
function [G, pValue] = calculateGetisOrd(data, W, d)
    % 计算 G* 统计量
    n = numel(data);
    Wx = W * data(:);
    S1 = sum(W.^2, 'all');
    
    % 计算统计量
    xbar = mean(data(:));
    s = std(data(:));
    G = Wx ./ (s * sqrt((n*S1 - 1)/(n-1)));
    
    % 计算显著性
    pValue = 2 * (1 - normcdf(abs(G)));
end
```

## 2. 流动路径优化

### 2.1 A*算法实现

```matlab
function path = findOptimalPath(start, goal, cost_map)
    % A*路径搜索
    open_set = PriorityQueue();
    closed_set = Set();
    came_from = containers.Map();
    
    % 初始化
    open_set.push(start, 0);
    g_score = containers.Map();
    g_score(start) = 0;
    
    while ~open_set.isEmpty()
        current = open_set.pop();
        if current == goal
            return reconstructPath(came_from, current);
        end
        % 继续搜索...
    end
end
```

## 3. 多准则决策分析

### 3.1 加权求和法

```matlab
function scores = calculateWeightedSum(data, weights)
    % 标准化数据
    normalized = normalize(data);
    
    % 计算加权和
    scores = normalized * weights(:);
end
```

## 4. 参数设置指南

### 4.1 空间权重矩阵

- 邻接定义：Queen/Rook 方式
- 距离阈值：建议使用研究区域平均最近邻距离
- 权重标准化：行标准化

### 4.2 热点分析参数

- 置信水平：95% (α = 0.05)
- 距离阈值：基于空间自相关分析结果
- 权重矩阵：基于距离衰减函数

### 4.3 路径优化参数

- 成本函数：考虑地形、土地利用等因素
- 启发式函数：欧氏距离或曼哈顿距离
- 搜索范围：根据计算资源调整

## 5. 最佳实践

### 5.1 数据预处理

1. 异常值检测与处理
2. 空间插值方法选择
3. 标准化处理方法

### 5.2 结果验证

1. 统计显著性检验
2. 空间自相关检验
3. 敏感性分析方法
