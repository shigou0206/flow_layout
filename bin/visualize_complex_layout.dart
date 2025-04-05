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

// 创建一个复杂的图，包含5层节点，部分节点有子节点
Graph createComplexGraph() {
  final g = Graph(isCompound: true);
  
  // 设置图的属性
  g.setGraph({
    'rankdir': 'TB', // 从上到下的方向
    'marginx': 50,
    'marginy': 50,
    'ranksep': 60, // 层级间距
    'nodesep': 40, // 同层节点间距
    'compound': true // 启用复合图(支持父子节点)
  });
  
  // 第一层: 根节点
  g.setNode('A', {
    'label': 'Start',
    'width': 80,
    'height': 40,
    'shape': 'ellipse',
    'style': {'fill': '#e3f2fd', 'stroke': '#1976d2'}
  });
  
  // 第二层: 主处理节点和它的子节点
  g.setNode('B', {
    'label': 'Process',
    'width': 120,
    'height': 60,
    'style': {'fill': '#e8f5e9', 'stroke': '#388e3c'}
  });
  
  // B的子节点
  g.setNode('B1', {
    'label': 'Sub-1',
    'width': 60,
    'height': 30,
    'style': {'fill': '#c8e6c9', 'stroke': '#4caf50'}
  });
  g.setNode('B2', {
    'label': 'Sub-2',
    'width': 60,
    'height': 30,
    'style': {'fill': '#c8e6c9', 'stroke': '#4caf50'}
  });
  g.setParent('B1', 'B');
  g.setParent('B2', 'B');
  
  // 第三层: 分支节点
  g.setNode('C', {
    'label': 'Decision',
    'width': 90,
    'height': 40,
    'shape': 'diamond',
    'style': {'fill': '#fff3e0', 'stroke': '#e65100'}
  });
  
  // 第四层: 多个处理节点
  g.setNode('D1', {
    'label': 'Task 1',
    'width': 80,
    'height': 40,
    'style': {'fill': '#e1f5fe', 'stroke': '#0288d1'}
  });
  
  g.setNode('D2', {
    'label': 'Task 2',
    'width': 80,
    'height': 40,
    'style': {'fill': '#e1f5fe', 'stroke': '#0288d1'}
  });
  
  g.setNode('D3', {
    'label': 'Task 3',
    'width': 80,
    'height': 40,
    'style': {'fill': '#e1f5fe', 'stroke': '#0288d1'}
  });
  
  // 任务组及其子任务
  g.setNode('E', {
    'label': 'Task Group',
    'width': 160,
    'height': 100,
    'clusterLabelPos': 'top',
    'style': {'fill': '#f3e5f5', 'stroke': '#9c27b0'}
  });
  
  g.setNode('E1', {
    'label': 'Task 4',
    'width': 70,
    'height': 35,
    'style': {'fill': '#e1bee7', 'stroke': '#8e24aa'}
  });
  
  g.setNode('E2', {
    'label': 'Task 5',
    'width': 70,
    'height': 35,
    'style': {'fill': '#e1bee7', 'stroke': '#8e24aa'}
  });
  
  g.setParent('E1', 'E');
  g.setParent('E2', 'E');
  
  // 第五层: 终点节点
  g.setNode('F', {
    'label': 'End',
    'width': 80,
    'height': 40,
    'shape': 'ellipse',
    'style': {'fill': '#ffebee', 'stroke': '#d32f2f'}
  });
  
  // 添加边
  // 从起点到处理
  g.setEdge('A', 'B', {
    'label': 'init',
    'weight': 2,
    'style': {'stroke': '#1976d2', 'strokeWidth': 2}
  });
  
  // 处理到决策
  g.setEdge('B', 'C', {
    'label': 'evaluate',
    'weight': 2,
    'style': {'stroke': '#388e3c', 'strokeWidth': 2}
  });
  
  // 决策到任务
  g.setEdge('C', 'D1', {
    'label': 'yes',
    'style': {'stroke': '#e65100', 'strokeWidth': 2}
  });
  g.setEdge('C', 'D2', {
    'label': 'maybe',
    'style': {'stroke': '#e65100', 'strokeWidth': 2}
  });
  g.setEdge('C', 'D3', {
    'label': 'no',
    'style': {'stroke': '#e65100', 'strokeWidth': 2}
  });
  
  // 任务到任务组
  g.setEdge('D1', 'E', {
    'style': {'stroke': '#0288d1', 'strokeWidth': 2}
  });
  g.setEdge('D2', 'E', {
    'style': {'stroke': '#0288d1', 'strokeWidth': 2}
  });
  g.setEdge('D3', 'E', {
    'style': {'stroke': '#0288d1', 'strokeWidth': 2}
  });
  
  // 子任务之间的连接
  g.setEdge('B1', 'B2', {
    'style': {'stroke': '#4caf50', 'strokeWidth': 1}
  });
  
  g.setEdge('E1', 'E2', {
    'style': {'stroke': '#8e24aa', 'strokeWidth': 1}
  });
  
  // 任务组到终点
  g.setEdge('E', 'F', {
    'label': 'complete',
    'weight': 2,
    'style': {'stroke': '#9c27b0', 'strokeWidth': 2}
  });

  return g;
}

String generateSVG(Graph g) {
  final graphData = g.graph() ?? {};
  final width = (graphData['width'] is num) ? (graphData['width'] as num).toDouble() : 1000.0;
  final height = (graphData['height'] is num) ? (graphData['height'] as num).toDouble() : 800.0;
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
  final arrowColors = ['#1976d2', '#388e3c', '#e65100', '#0288d1', '#9c27b0', '#d32f2f', '#4caf50', '#8e24aa'];
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
    final strokeWidth = style?['strokeWidth'] as int? ?? 1.5;
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
          
          svg.writeln('<rect x="${midX-25}" y="${midY-15}" width="50" height="20" rx="10" ry="10" fill="white" stroke="$strokeColor" stroke-width="1" opacity="0.9" />');
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
        
        svg.writeln('<rect x="${midX-25}" y="${midY-15}" width="50" height="20" rx="10" ry="10" fill="white" stroke="$strokeColor" stroke-width="1" opacity="0.9" />');
        svg.writeln('<text x="$midX" y="$midY" text-anchor="middle" dominant-baseline="middle" fill="$strokeColor" class="edgeLabel">$label</text>');
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