import 'dart:io';
import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/layout.dart' as layout;

void main() {
  // 创建复杂图示例
  final complexGraph = createComplexGraph();
  
  // 应用布局算法
  layout.layout(complexGraph);
  
  // 生成可视化
  final svgContent = generateSVG(complexGraph);
  File('complex_graph_visualization.svg').writeAsStringSync(svgContent);
  
  print('生成的SVG文件已保存为 complex_graph_visualization.svg');
}

// 创建一个复杂的图，包含5层节点和嵌套结构
Graph createComplexGraph() {
  final g = Graph(isCompound: true);
  
  // 设置图的属性
  g.setGraph({
    'rankdir': 'TB', // 从上到下的方向
    'marginx': 80,
    'marginy': 60,
    'ranksep': 80, // 层级间距
    'nodesep': 60, // 同层节点间距
    'compound': true, // 启用复合图(支持父子节点)
    'edgesep': 50, // 边的间隔
    'acyclicer': 'greedy' // 使用贪心算法处理循环
  });
  
  // --- 层级1: 开始节点 ---
  g.setNode('start', {
    'label': 'Start',
    'width': 100,
    'height': 50,
    'shape': 'ellipse',
    'style': {'fill': '#e3f2fd', 'stroke': '#1976d2', 'strokeWidth': 2}
  });
  
  // --- 层级2: 系统模块 ---
  g.setNode('system', {
    'label': 'System',
    'width': 900,
    'height': 140,
    'clusterLabelPos': 'top',
    'style': {'fill': '#e8eaf6', 'stroke': '#3f51b5', 'strokeWidth': 2}
  });
  
  // 系统内的子模块
  g.setNode('input', {
    'label': 'Input Module',
    'width': 200,
    'height': 100,
    'clusterLabelPos': 'top',
    'style': {'fill': '#e3f2fd', 'stroke': '#1976d2', 'strokeWidth': 2}
  });
  g.setParent('input', 'system');
  
  g.setNode('process', {
    'label': 'Process Module',
    'width': 200,
    'height': 100,
    'clusterLabelPos': 'top',
    'style': {'fill': '#e8f5e9', 'stroke': '#388e3c', 'strokeWidth': 2}
  });
  g.setParent('process', 'system');
  
  g.setNode('output', {
    'label': 'Output Module',
    'width': 200,
    'height': 100,
    'clusterLabelPos': 'top',
    'style': {'fill': '#fff3e0', 'stroke': '#e65100', 'strokeWidth': 2}
  });
  g.setParent('output', 'system');
  
  // 输入模块内的组件
  g.setNode('parser', {
    'label': 'Parser',
    'width': 80,
    'height': 40,
    'style': {'fill': '#bbdefb', 'stroke': '#1565c0', 'strokeWidth': 2}
  });
  g.setParent('parser', 'input');
  
  g.setNode('validator', {
    'label': 'Validator',
    'width': 80,
    'height': 40,
    'style': {'fill': '#bbdefb', 'stroke': '#1565c0', 'strokeWidth': 2}
  });
  g.setParent('validator', 'input');
  
  // 处理模块内的组件
  g.setNode('analytics', {
    'label': 'Analytics',
    'width': 80,
    'height': 40,
    'style': {'fill': '#c8e6c9', 'stroke': '#2e7d32', 'strokeWidth': 2}
  });
  g.setParent('analytics', 'process');
  
  g.setNode('transformer', {
    'label': 'Transformer',
    'width': 80,
    'height': 40,
    'style': {'fill': '#c8e6c9', 'stroke': '#2e7d32', 'strokeWidth': 2}
  });
  g.setParent('transformer', 'process');
  
  // 输出模块内的组件
  g.setNode('formatter', {
    'label': 'Formatter',
    'width': 80,
    'height': 40,
    'style': {'fill': '#ffe0b2', 'stroke': '#e65100', 'strokeWidth': 2}
  });
  g.setParent('formatter', 'output');
  
  g.setNode('renderer', {
    'label': 'Renderer',
    'width': 80,
    'height': 40,
    'style': {'fill': '#ffe0b2', 'stroke': '#e65100', 'strokeWidth': 2}
  });
  g.setParent('renderer', 'output');
  
  // --- 层级3: 决策节点 ---
  g.setNode('decision', {
    'label': 'Data Valid?',
    'width': 160,
    'height': 80,
    'shape': 'diamond',
    'style': {'fill': '#fff3e0', 'stroke': '#ff6f00', 'strokeWidth': 2}
  });
  
  // --- 层级4: 处理路径 ---
  g.setNode('path1', {
    'label': 'Success Path',
    'width': 180,
    'height': 80,
    'style': {'fill': '#e8f5e9', 'stroke': '#4caf50', 'strokeWidth': 2}
  });
  
  g.setNode('path2', {
    'label': 'Error Path',
    'width': 180,
    'height': 80,
    'style': {'fill': '#ffebee', 'stroke': '#f44336', 'strokeWidth': 2}
  });
  
  // --- 层级5: 结果处理组 ---
  g.setNode('results', {
    'label': 'Results',
    'width': 800,
    'height': 140,
    'clusterLabelPos': 'top',
    'style': {'fill': '#f3e5f5', 'stroke': '#9c27b0', 'strokeWidth': 2}
  });
  
  // 结果组内的子模块
  g.setNode('storage', {
    'label': 'Data Storage',
    'width': 180,
    'height': 80,
    'clusterLabelPos': 'top',
    'style': {'fill': '#e1bee7', 'stroke': '#8e24aa', 'strokeWidth': 2}
  });
  g.setParent('storage', 'results');
  
  g.setNode('visualization', {
    'label': 'Visualization',
    'width': 180,
    'height': 80,
    'clusterLabelPos': 'top',
    'style': {'fill': '#e1bee7', 'stroke': '#8e24aa', 'strokeWidth': 2}
  });
  g.setParent('visualization', 'results');
  
  g.setNode('export', {
    'label': 'Export',
    'width': 180,
    'height': 80,
    'clusterLabelPos': 'top',
    'style': {'fill': '#e1bee7', 'stroke': '#8e24aa', 'strokeWidth': 2}
  });
  g.setParent('export', 'results');
  
  // 存储模块内的组件
  g.setNode('local', {
    'label': 'Local',
    'width': 70,
    'height': 35,
    'style': {'fill': '#d1c4e9', 'stroke': '#673ab7', 'strokeWidth': 2}
  });
  g.setParent('local', 'storage');
  
  g.setNode('cloud', {
    'label': 'Cloud',
    'width': 70,
    'height': 35,
    'style': {'fill': '#d1c4e9', 'stroke': '#673ab7', 'strokeWidth': 2}
  });
  g.setParent('cloud', 'storage');
  
  // 可视化模块内的组件
  g.setNode('charts', {
    'label': 'Charts',
    'width': 70,
    'height': 35,
    'style': {'fill': '#d1c4e9', 'stroke': '#673ab7', 'strokeWidth': 2}
  });
  g.setParent('charts', 'visualization');
  
  g.setNode('dashboard', {
    'label': 'Dashboard',
    'width': 70,
    'height': 35,
    'style': {'fill': '#d1c4e9', 'stroke': '#673ab7', 'strokeWidth': 2}
  });
  g.setParent('dashboard', 'visualization');
  
  // 导出模块内的组件
  g.setNode('pdf', {
    'label': 'PDF',
    'width': 70,
    'height': 35,
    'style': {'fill': '#d1c4e9', 'stroke': '#673ab7', 'strokeWidth': 2}
  });
  g.setParent('pdf', 'export');
  
  g.setNode('excel', {
    'label': 'Excel',
    'width': 70,
    'height': 35,
    'style': {'fill': '#d1c4e9', 'stroke': '#673ab7', 'strokeWidth': 2}
  });
  g.setParent('excel', 'export');
  
  // --- 层级6: 结束节点 ---
  g.setNode('end', {
    'label': 'End',
    'width': 100,
    'height': 50,
    'shape': 'ellipse',
    'style': {'fill': '#ffebee', 'stroke': '#d32f2f', 'strokeWidth': 2}
  });
  
  // 添加边 - 层级间主连接
  g.setEdge('start', 'system', {
    'label': 'init',
    'weight': 3,
    'style': {'stroke': '#1976d2', 'strokeWidth': 2}
  });
  
  g.setEdge('system', 'decision', {
    'label': 'validate',
    'weight': 3,
    'style': {'stroke': '#3f51b5', 'strokeWidth': 2}
  });
  
  g.setEdge('decision', 'path1', {
    'label': 'yes',
    'weight': 2,
    'style': {'stroke': '#ff6f00', 'strokeWidth': 2}
  });
  
  g.setEdge('decision', 'path2', {
    'label': 'no',
    'weight': 2,
    'style': {'stroke': '#ff6f00', 'strokeWidth': 2}
  });
  
  g.setEdge('path1', 'results', {
    'label': 'process',
    'weight': 2,
    'style': {'stroke': '#4caf50', 'strokeWidth': 2}
  });
  
  g.setEdge('path2', 'results', {
    'label': 'handle error',
    'weight': 2,
    'style': {'stroke': '#f44336', 'strokeWidth': 2}
  });
  
  g.setEdge('results', 'end', {
    'label': 'complete',
    'weight': 3,
    'style': {'stroke': '#9c27b0', 'strokeWidth': 2}
  });
  
  // 系统内模块连接
  g.setEdge('input', 'process', {
    'label': 'feed',
    'minlen': 1,
    'style': {'stroke': '#1976d2', 'strokeWidth': 1.5}
  });
  
  g.setEdge('process', 'output', {
    'label': 'result',
    'minlen': 1,
    'style': {'stroke': '#388e3c', 'strokeWidth': 1.5}
  });
  
  // 输入模块内连接
  g.setEdge('parser', 'validator', {
    'style': {'stroke': '#1565c0', 'strokeWidth': 1}
  });
  
  // 处理模块内连接
  g.setEdge('analytics', 'transformer', {
    'style': {'stroke': '#2e7d32', 'strokeWidth': 1}
  });
  
  // 输出模块内连接
  g.setEdge('formatter', 'renderer', {
    'style': {'stroke': '#e65100', 'strokeWidth': 1}
  });
  
  // 结果组内模块连接
  g.setEdge('storage', 'visualization', {
    'label': 'load',
    'minlen': 1,
    'style': {'stroke': '#8e24aa', 'strokeWidth': 1.5}
  });
  
  g.setEdge('visualization', 'export', {
    'label': 'select',
    'minlen': 1,
    'style': {'stroke': '#8e24aa', 'strokeWidth': 1.5}
  });
  
  // 存储模块内连接
  g.setEdge('local', 'cloud', {
    'label': 'sync',
    'style': {'stroke': '#673ab7', 'strokeWidth': 1}
  });
  
  // 可视化模块内连接
  g.setEdge('charts', 'dashboard', {
    'style': {'stroke': '#673ab7', 'strokeWidth': 1}
  });
  
  // 导出模块内连接
  g.setEdge('pdf', 'excel', {
    'style': {'stroke': '#673ab7', 'strokeWidth': 1}
  });

  return g;
}

String generateSVG(Graph g) {
  final graphData = g.graph() ?? {};
  final width = (graphData['width'] is num) ? (graphData['width'] as num).toDouble() + 50 : 1280.0;
  final height = (graphData['height'] is num) ? (graphData['height'] as num).toDouble() + 50 : 960.0;
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
  svg.writeln('.cluster { opacity: 0.8; }');
  svg.writeln('</style>');
  
  // 添加多种颜色的箭头标记
  svg.writeln('<marker id="arrowhead" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto" markerUnits="strokeWidth">');
  svg.writeln('  <polygon points="0 0, 10 3.5, 0 7" fill="#333" />');
  svg.writeln('</marker>');
  
  // 自定义颜色的箭头
  final arrowColors = [
    '#1976d2', '#388e3c', '#e65100', '#0288d1', '#9c27b0', '#d32f2f', 
    '#4caf50', '#8e24aa', '#ff6f00', '#f44336', '#3f51b5', '#1565c0',
    '#2e7d32', '#673ab7'
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
  
  // 添加光晕效果
  svg.writeln('<filter id="glow" x="-30%" y="-30%" width="160%" height="160%">');
  svg.writeln('  <feGaussianBlur stdDeviation="5" result="glow" />');
  svg.writeln('  <feMerge>');
  svg.writeln('    <feMergeNode in="glow" />');
  svg.writeln('    <feMergeNode in="SourceGraphic" />');
  svg.writeln('  </feMerge>');
  svg.writeln('</filter>');
  
  svg.writeln('</defs>');
  
  // 绘制背景
  svg.writeln('<rect width="$width" height="$height" fill="$bgcolor" />');
  
  // 绘制网格
  svg.writeln('<g class="grid" opacity="0.05">');
  for (int i = 0; i < width; i += 50) {
    svg.writeln('<line x1="$i" y1="0" x2="$i" y2="$height" stroke="#000" stroke-width="1" />');
  }
  for (int i = 0; i < height; i += 50) {
    svg.writeln('<line x1="0" y1="$i" x2="$width" y2="$i" stroke="#000" stroke-width="1" />');
  }
  svg.writeln('</g>');
  
  // 绘制集群（先绘制集群，这样节点和边会在上面）
  for (final v in g.getNodes()) {
    if ((g.children(v) ?? []).isNotEmpty) {
      final clusterNode = g.node(v);
      if (clusterNode == null) continue;
      
      final x = clusterNode['x'] is num ? (clusterNode['x'] as num).toDouble() : 0.0;
      final y = clusterNode['y'] is num ? (clusterNode['y'] as num).toDouble() : 0.0;
      final width = clusterNode['width'] is num ? (clusterNode['width'] as num).toDouble() : 100.0;
      final height = clusterNode['height'] is num ? (clusterNode['height'] as num).toDouble() : 100.0;
      final label = clusterNode['label'] ?? v;
      final nodeStyle = clusterNode['style'] as Map<String, dynamic>?;
      final fill = nodeStyle?['fill'] as String? ?? '#f5f5f5';
      final stroke = nodeStyle?['stroke'] as String? ?? '#333';
      
      svg.writeln('<g class="cluster" filter="url(#drop-shadow)">');
      svg.writeln('<rect x="${x - width/2}" y="${y - height/2}" width="$width" height="$height" rx="5" ry="5" fill="$fill" stroke="$stroke" stroke-width="2" />');
      
      // 集群标签位置
      final labelPos = clusterNode['clusterLabelPos'] ?? 'center';
      double labelX = x;
      double labelY = y;
      
      if (labelPos == 'top') {
        labelY = y - height/2 + 15;
      }
      
      svg.writeln('<text x="$labelX" y="$labelY" text-anchor="middle" dominant-baseline="middle" class="nodeLabel">$label</text>');
      svg.writeln('</g>');
    }
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
          final labelWidth = (label.toString().length * 6 + 20).clamp(40, 120);
          
          svg.writeln('<rect x="${midX-labelWidth/2}" y="${midY-15}" width="$labelWidth" height="20" rx="10" ry="10" fill="white" stroke="$strokeColor" stroke-width="1" opacity="0.9" />');
          svg.writeln('<text x="$midX" y="$midY" text-anchor="middle" dominant-baseline="middle" fill="$strokeColor" class="edgeLabel">$label</text>');
        }
      }
      
      svg.writeln('</g>');
    }
  }
  
  // 绘制节点
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
    
    // 特殊效果（开始和结束节点使用发光效果）
    final filter = (v == 'start' || v == 'end') ? 'filter="url(#glow)"' : 'filter="url(#drop-shadow)"';
    
    svg.writeln('<g class="node" $filter>');
    
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

