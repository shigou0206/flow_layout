import 'dart:io';
import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/layout.dart' as layout;

void main() {
  // 创建复杂嵌套图示例
  final complexGraph = createComplexNestedGraph();
  
  // 应用布局算法
  layout.layout(complexGraph);
  
  // 生成可视化
  final svgContent = generateSVG(complexGraph);
  File('complex_nested_visualization.svg').writeAsStringSync(svgContent);
  
  print('生成的SVG文件已保存为 complex_nested_visualization.svg');
}

// 创建一个复杂的嵌套图，包含5层节点，多级嵌套关系
Graph createComplexNestedGraph() {
  final g = Graph(isCompound: true);
  
  // 设置图的属性
  g.setGraph({
    'rankdir': 'TB', // 从上到下的方向
    'marginx': 50,
    'marginy': 50,
    'ranksep': 80, // 层级间距
    'nodesep': 50, // 同层节点间距
    'compound': true // 启用复合图(支持父子节点)
  });
  
  // --- 第一层: 根节点 ---
  g.setNode('root', {
    'label': 'System',
    'width': 100,
    'height': 50,
    'shape': 'rect',
    'style': {'fill': '#e8eaf6', 'stroke': '#3f51b5'}
  });
  
  // --- 第二层: 主模块 ---
  // 模块A - 输入处理
  g.setNode('moduleA', {
    'label': 'Input',
    'width': 200,
    'height': 120,
    'clusterLabelPos': 'top',
    'style': {'fill': '#e3f2fd', 'stroke': '#1976d2'}
  });
  
  // 模块B - 处理引擎
  g.setNode('moduleB', {
    'label': 'Engine',
    'width': 260,
    'height': 180,
    'clusterLabelPos': 'top',
    'style': {'fill': '#e8f5e9', 'stroke': '#388e3c'}
  });
  
  // 模块C - 输出处理
  g.setNode('moduleC', {
    'label': 'Output',
    'width': 200,
    'height': 120,
    'clusterLabelPos': 'top',
    'style': {'fill': '#fff3e0', 'stroke': '#e65100'}
  });
  
  g.setParent('moduleA', 'root');
  g.setParent('moduleB', 'root');
  g.setParent('moduleC', 'root');
  
  // --- 第三层: 子模块 ---
  // 输入处理子模块
  g.setNode('inputParser', {
    'label': 'Parser',
    'width': 80,
    'height': 40,
    'style': {'fill': '#bbdefb', 'stroke': '#1565c0'}
  });
  
  g.setNode('inputValidator', {
    'label': 'Validator',
    'width': 80,
    'height': 40,
    'style': {'fill': '#bbdefb', 'stroke': '#1565c0'}
  });
  
  g.setParent('inputParser', 'moduleA');
  g.setParent('inputValidator', 'moduleA');
  
  // 处理引擎子模块
  g.setNode('engineCore', {
    'label': 'Core',
    'width': 150,
    'height': 100,
    'clusterLabelPos': 'top',
    'style': {'fill': '#c8e6c9', 'stroke': '#2e7d32'}
  });
  
  g.setNode('engineRules', {
    'label': 'Rules',
    'width': 80,
    'height': 40,
    'style': {'fill': '#c8e6c9', 'stroke': '#2e7d32'}
  });
  
  g.setParent('engineCore', 'moduleB');
  g.setParent('engineRules', 'moduleB');
  
  // 输出处理子模块
  g.setNode('outputFormatter', {
    'label': 'Formatter',
    'width': 90,
    'height': 40,
    'style': {'fill': '#ffe0b2', 'stroke': '#e65100'}
  });
  
  g.setNode('outputRenderer', {
    'label': 'Renderer',
    'width': 90,
    'height': 40,
    'style': {'fill': '#ffe0b2', 'stroke': '#e65100'}
  });
  
  g.setParent('outputFormatter', 'moduleC');
  g.setParent('outputRenderer', 'moduleC');
  
  // --- 第四层: 核心组件 ---
  g.setNode('processor1', {
    'label': 'Processor 1',
    'width': 70,
    'height': 35,
    'style': {'fill': '#a5d6a7', 'stroke': '#1b5e20'}
  });
  
  g.setNode('processor2', {
    'label': 'Processor 2',
    'width': 70,
    'height': 35,
    'style': {'fill': '#a5d6a7', 'stroke': '#1b5e20'}
  });
  
  g.setParent('processor1', 'engineCore');
  g.setParent('processor2', 'engineCore');
  
  // --- 第五层: 终端节点 ---
  g.setNode('endpoint1', {
    'label': 'API 1',
    'width': 60,
    'height': 30,
    'shape': 'ellipse',
    'style': {'fill': '#ffccbc', 'stroke': '#bf360c'}
  });
  
  g.setNode('endpoint2', {
    'label': 'API 2',
    'width': 60,
    'height': 30,
    'shape': 'ellipse',
    'style': {'fill': '#ffccbc', 'stroke': '#bf360c'}
  });
  
  g.setNode('endpoint3', {
    'label': 'API 3',
    'width': 60,
    'height': 30,
    'shape': 'ellipse',
    'style': {'fill': '#ffccbc', 'stroke': '#bf360c'}
  });
  
  // 添加边
  // 根节点连接
  g.setEdge('root', 'moduleA', {
    'style': {'stroke': '#3f51b5', 'strokeWidth': 2}
  });
  
  g.setEdge('root', 'moduleB', {
    'style': {'stroke': '#3f51b5', 'strokeWidth': 2}
  });
  
  g.setEdge('root', 'moduleC', {
    'style': {'stroke': '#3f51b5', 'strokeWidth': 2}
  });
  
  // 输入模块内部连接
  g.setEdge('inputParser', 'inputValidator', {
    'label': 'validate',
    'style': {'stroke': '#1565c0', 'strokeWidth': 1.5}
  });
  
  // 模块之间的连接
  g.setEdge('inputValidator', 'engineCore', {
    'label': 'process',
    'style': {'stroke': '#1976d2', 'strokeWidth': 2}
  });
  
  g.setEdge('engineRules', 'engineCore', {
    'label': 'apply',
    'style': {'stroke': '#2e7d32', 'strokeWidth': 1.5}
  });
  
  g.setEdge('engineCore', 'outputFormatter', {
    'label': 'format',
    'style': {'stroke': '#388e3c', 'strokeWidth': 2}
  });
  
  g.setEdge('outputFormatter', 'outputRenderer', {
    'label': 'render',
    'style': {'stroke': '#e65100', 'strokeWidth': 1.5}
  });
  
  // 处理器之间的连接
  g.setEdge('processor1', 'processor2', {
    'label': 'next',
    'style': {'stroke': '#1b5e20', 'strokeWidth': 1}
  });
  
  // 连接到终端节点
  g.setEdge('outputRenderer', 'endpoint1', {
    'style': {'stroke': '#bf360c', 'strokeWidth': 1.5}
  });
  
  g.setEdge('outputRenderer', 'endpoint2', {
    'style': {'stroke': '#bf360c', 'strokeWidth': 1.5}
  });
  
  g.setEdge('outputRenderer', 'endpoint3', {
    'style': {'stroke': '#bf360c', 'strokeWidth': 1.5}
  });

  return g;
}

String generateSVG(Graph g) {
  final graphData = g.graph() ?? {};
  final width = (graphData['width'] is num) ? (graphData['width'] as num).toDouble() : 1200.0;
  final height = (graphData['height'] is num) ? (graphData['height'] as num).toDouble() : 1000.0;
  final bgcolor = '#ffffff';
  
  StringBuffer svg = StringBuffer();
  svg.writeln('<?xml version="1.0" encoding="UTF-8" standalone="no"?>');
  svg.writeln('<svg width="$width" height="$height" xmlns="http://www.w3.org/2000/svg">');
  
  // 添加样式
  svg.writeln('<defs>');
  svg.writeln('<style type="text/css">');
  svg.writeln('.node rect, .node ellipse, .node diamond { stroke-width: 2px; }');
  svg.writeln('.edgePath path { fill: none; }');
  svg.writeln('.edgeLabel { font-family: "Helvetica Neue", Helvetica, Arial, sans-serif; font-size: 12px; font-weight: 500; }');
  svg.writeln('.nodeLabel { font-family: "Helvetica Neue", Helvetica, Arial, sans-serif; font-size: 14px; font-weight: 600; }');
  svg.writeln('.cluster { opacity: 0.9; }');
  svg.writeln('.cluster rect { rx: 5px; ry: 5px; }');
  svg.writeln('</style>');
  
  // 添加多种颜色的箭头标记
  svg.writeln('<marker id="arrowhead" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto" markerUnits="strokeWidth">');
  svg.writeln('  <polygon points="0 0, 10 3.5, 0 7" fill="#333" />');
  svg.writeln('</marker>');
  
  // 颜色列表
  final arrowColors = [
    '#3f51b5', '#1976d2', '#1565c0', '#388e3c', '#2e7d32', '#1b5e20', 
    '#e65100', '#bf360c', '#c62828'
  ];
  
  for (final color in arrowColors) {
    final id = 'arrowhead-${color.substring(1)}';
    svg.writeln('<marker id="$id" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto" markerUnits="strokeWidth">');
    svg.writeln('  <polygon points="0 0, 10 3.5, 0 7" fill="$color" />');
    svg.writeln('</marker>');
  }
  
  // 添加阴影效果
  svg.writeln('<filter id="drop-shadow" height="130%">');
  svg.writeln('  <feGaussianBlur in="SourceAlpha" stdDeviation="3" />'); 
  svg.writeln('  <feOffset dx="2" dy="2" result="offsetblur" />');
  svg.writeln('  <feComponentTransfer>');
  svg.writeln('    <feFuncA type="linear" slope="0.2" />');
  svg.writeln('  </feComponentTransfer>');
  svg.writeln('  <feMerge>');
  svg.writeln('    <feMergeNode />');
  svg.writeln('    <feMergeNode in="SourceGraphic" />');
  svg.writeln('  </feMerge>');
  svg.writeln('</filter>');
  
  svg.writeln('</defs>');
  
  // 绘制背景
  svg.writeln('<rect width="$width" height="$height" fill="$bgcolor" />');
  
  // 绘制网格参考线（可选）
  svg.writeln('<g class="grid" opacity="0.1">');
  for (int i = 0; i < width; i += 50) {
    svg.writeln('<line x1="$i" y1="0" x2="$i" y2="$height" stroke="#000" stroke-width="1" />');
  }
  for (int i = 0; i < height; i += 50) {
    svg.writeln('<line x1="0" y1="$i" x2="$width" y2="$i" stroke="#000" stroke-width="1" />');
  }
  svg.writeln('</g>');
  
  // 按照层级顺序绘制集群（从外到内）
  // 我们需要先收集所有的集群节点，并按照它们的嵌套级别进行排序
  final clusters = <String, Map<String, dynamic>>{};
  final clusterParents = <String, String>{};
  final clusterLevels = <String, int>{};
  
  for (final v in g.getNodes()) {
    if ((g.children(v) ?? []).isNotEmpty) {
      clusters[v] = g.node(v) ?? {};
      
      // 查找父集群
      final parent = g.parent(v);
      if (parent != null) {
        clusterParents[v] = parent;
      }
    }
  }
  
  // 计算每个集群的嵌套级别
  void calculateLevels(String clusterId, int level) {
    clusterLevels[clusterId] = level;
    
    for (final entry in clusterParents.entries) {
      if (entry.value == clusterId) {
        calculateLevels(entry.key, level + 1);
      }
    }
  }
  
  // 找到最顶层的集群（没有父节点的集群）
  for (final clusterId in clusters.keys) {
    if (!clusterParents.containsKey(clusterId) || 
        !clusters.containsKey(clusterParents[clusterId])) {
      calculateLevels(clusterId, 0);
    }
  }
  
  // 按照级别从低到高排序（先绘制外层集群）
  final sortedClusters = clusters.keys.toList()
    ..sort((a, b) => (clusterLevels[a] ?? 0).compareTo(clusterLevels[b] ?? 0));
  
  // 绘制集群
  for (final clusterId in sortedClusters) {
    final clusterNode = clusters[clusterId];
    if (clusterNode == null) continue;
    
    final x = clusterNode['x'] is num ? (clusterNode['x'] as num).toDouble() : 0.0;
    final y = clusterNode['y'] is num ? (clusterNode['y'] as num).toDouble() : 0.0;
    final width = clusterNode['width'] is num ? (clusterNode['width'] as num).toDouble() : 100.0;
    final height = clusterNode['height'] is num ? (clusterNode['height'] as num).toDouble() : 100.0;
    final label = clusterNode['label'] ?? clusterId;
    final nodeStyle = clusterNode['style'] as Map<String, dynamic>?;
    final fill = nodeStyle?['fill'] as String? ?? '#f5f5f5';
    final stroke = nodeStyle?['stroke'] as String? ?? '#333';
    
    svg.writeln('<g class="cluster" filter="url(#drop-shadow)">');
    svg.writeln('<rect x="${x - width/2}" y="${y - height/2}" width="$width" height="$height" fill="$fill" stroke="$stroke" stroke-width="2" rx="5" ry="5" />');
    
    // 集群标签位置
    final labelPos = clusterNode['clusterLabelPos'] ?? 'center';
    double labelX = x;
    double labelY = y;
    
    if (labelPos == 'top') {
      labelY = y - height/2 + 15;
    }
    
    svg.writeln('<text x="$labelX" y="$labelY" text-anchor="middle" dominant-baseline="middle" class="nodeLabel" fill="$stroke">$label</text>');
    svg.writeln('</g>');
  }
  
  // 绘制边
  for (final edgeObj in g.edges()) {
    final edgeData = g.edge(edgeObj);
    if (edgeData == null) continue;
    
    // 从edgeObj获取源和目标节点ID
    final v = edgeObj['v'] as String;
    final w = edgeObj['w'] as String;
    
    final points = edgeData['points'];
    final style = edgeData['style'] as Map<String, dynamic>?;
    final strokeColor = style?['stroke'] as String? ?? '#333';
    final strokeWidth = style?['strokeWidth'] as num? ?? 1.5;
    final arrowId = 'arrowhead-${strokeColor.substring(1)}';
    
    if (points != null && points is List && points.isNotEmpty) {
      // 绘制路径点
      final pointsPath = StringBuffer();
      bool first = true;
      
      for (final point in points) {
        if (point is! Map) continue;
        final x = point['x'] is num ? (point['x'] as num).toDouble() : 0.0;
        final y = point['y'] is num ? (point['y'] as num).toDouble() : 0.0;
        
        if (first) {
          pointsPath.write('M$x,$y');
          first = false;
        } else {
          pointsPath.write(' L$x,$y');
        }
      }
      
      svg.writeln('<g class="edgePath">');
      svg.writeln('<path d="$pointsPath" stroke="$strokeColor" stroke-width="$strokeWidth" marker-end="url(#$arrowId)" />');
      
      // 如果有标签，则在中间位置添加
      final label = edgeData['label'];
      if (label != null && points.length > 1) {
        final midIndex = (points.length ~/ 2).clamp(0, points.length - 1);
        final midPoint = points[midIndex];
        if (midPoint is Map) {
          final midX = midPoint['x'] is num ? (midPoint['x'] as num).toDouble() : 0.0;
          final midY = midPoint['y'] is num ? (midPoint['y'] as num).toDouble() : 0.0 - 10;
          
          // 文本背景
          svg.writeln('<rect x="${midX-30}" y="${midY-15}" width="60" height="20" rx="10" ry="10" fill="white" stroke="$strokeColor" stroke-width="1" opacity="0.9" />');
          svg.writeln('<text x="$midX" y="$midY" text-anchor="middle" dominant-baseline="middle" fill="$strokeColor" class="edgeLabel">$label</text>');
        }
      }
      
      svg.writeln('</g>');
    } else {
      // 如果没有路径点，则直接从源到目标绘制直线
      final sourceNode = g.node(v);
      final targetNode = g.node(w);
      if (sourceNode == null || targetNode == null) continue;
      
      final sourceX = sourceNode['x'] is num ? (sourceNode['x'] as num).toDouble() : 0.0;
      final sourceY = sourceNode['y'] is num ? (sourceNode['y'] as num).toDouble() : 0.0;
      final targetX = targetNode['x'] is num ? (targetNode['x'] as num).toDouble() : 0.0;
      final targetY = targetNode['y'] is num ? (targetNode['y'] as num).toDouble() : 0.0;
      
      svg.writeln('<g class="edgePath">');
      svg.writeln('<path d="M$sourceX,$sourceY L$targetX,$targetY" stroke="$strokeColor" stroke-width="$strokeWidth" marker-end="url(#$arrowId)" />');
      
      // 如果有标签，则在中间位置添加
      final label = edgeData['label'];
      if (label != null) {
        final midX = (sourceX + targetX) / 2;
        final midY = (sourceY + targetY) / 2 - 10;
        
        // 文本背景
        svg.writeln('<rect x="${midX-30}" y="${midY-15}" width="60" height="20" rx="10" ry="10" fill="white" stroke="$strokeColor" stroke-width="1" opacity="0.9" />');
        svg.writeln('<text x="$midX" y="$midY" text-anchor="middle" dominant-baseline="middle" fill="$strokeColor" class="edgeLabel">$label</text>');
      }
      
      svg.writeln('</g>');
    }
  }
  
  // 绘制节点（但跳过集群）
  for (final v in g.getNodes()) {
    // 跳过有子节点的节点（集群）
    if ((g.children(v) ?? []).isNotEmpty) continue;
    
    final node = g.node(v);
    if (node == null) continue;
    
    final x = node['x'] is num ? (node['x'] as num).toDouble() : 0.0;
    final y = node['y'] is num ? (node['y'] as num).toDouble() : 0.0;
    final width = node['width'] is num ? (node['width'] as num).toDouble() : 40.0;
    final height = node['height'] is num ? (node['height'] as num).toDouble() : 40.0;
    final label = node['label'] ?? v;
    final shape = node['shape'] ?? 'rect';
    final nodeStyle = node['style'] as Map<String, dynamic>?;
    final fill = nodeStyle?['fill'] as String? ?? '#f5f5f5';
    final stroke = nodeStyle?['stroke'] as String? ?? '#333';
    
    svg.writeln('<g class="node" filter="url(#drop-shadow)">');
    
    // 根据形状绘制不同的节点
    if (shape == 'ellipse') {
      svg.writeln('<ellipse cx="$x" cy="$y" rx="${width/2}" ry="${height/2}" fill="$fill" stroke="$stroke" stroke-width="2" />');
    } else if (shape == 'diamond') {
      final halfWidth = width / 2;
      final halfHeight = height / 2;
      final path = 'M$x,${y-halfHeight} L${x+halfWidth},$y L$x,${y+halfHeight} L${x-halfWidth},$y Z';
      svg.writeln('<path d="$path" fill="$fill" stroke="$stroke" stroke-width="2" />');
    } else {
      // 默认为矩形
      svg.writeln('<rect x="${x - width/2}" y="${y - height/2}" width="$width" height="$height" rx="5" ry="5" fill="$fill" stroke="$stroke" stroke-width="2" />');
    }
    
    svg.writeln('<text x="$x" y="$y" text-anchor="middle" dominant-baseline="middle" class="nodeLabel">$label</text>');
    
    svg.writeln('</g>');
  }
  
  svg.writeln('</svg>');
  return svg.toString();
} 