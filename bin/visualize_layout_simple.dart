import 'dart:io';
import 'package:flow_layout/graph/graph.dart';

void main() {
  // 创建简单图示例
  final simpleGraph = createSimpleGraph();
  
  // 应用手动布局
  applySimpleLayout(simpleGraph);
  
  // 生成可视化
  final svgContent = generateSVG(simpleGraph);
  File('simple_graph_visualization.svg').writeAsStringSync(svgContent);
  
  print('生成的SVG文件已保存为 simple_graph_visualization.svg');
}

// 创建一个简单的图
Graph createSimpleGraph() {
  final g = Graph();
  
  // 添加节点
  g.setNode('A', {'label': 'A', 'width': 40, 'height': 40});
  g.setNode('B', {'label': 'B', 'width': 40, 'height': 40});
  g.setNode('C', {'label': 'C', 'width': 40, 'height': 40});
  g.setNode('D', {'label': 'D', 'width': 40, 'height': 40});
  
  // 添加边
  g.setEdge('A', 'B');
  g.setEdge('A', 'C');
  g.setEdge('B', 'D');
  g.setEdge('C', 'D');

  // 设置图的属性
  g.setGraph({
    'rankdir': 'TB', // 从上到下的方向
    'marginx': 20,
    'marginy': 20
  });

  return g;
}

// 手动布局算法，不依赖复杂的排序和排名算法
void applySimpleLayout(Graph g) {
  // 设置层级布局
  final Map<String, int> ranks = {
    'A': 0,
    'B': 1,
    'C': 1,
    'D': 2
  };
  
  // 设置每一层的节点数量
  final Map<int, List<String>> rankNodes = {};
  for (final entry in ranks.entries) {
    final rank = entry.value;
    final nodeId = entry.key;
    rankNodes[rank] = rankNodes[rank] ?? [];
    rankNodes[rank]!.add(nodeId);
  }
  
  // 布局参数
  const int nodeWidth = 40;
  const int nodeHeight = 40;
  const int marginX = 20;
  const int marginY = 20;
  const int paddingX = 60;
  const int paddingY = 80;
  
  // 计算节点位置
  for (final rankEntry in rankNodes.entries) {
    final rank = rankEntry.key;
    final nodes = rankEntry.value;
    
    // 计算这一层的总宽度
    final layerWidth = nodes.length * nodeWidth + (nodes.length - 1) * paddingX;
    
    // 开始X坐标 (居中)
    double startX = marginX + (paddingX - nodeWidth) / 2;
    if (nodes.length > 1) {
      startX = marginX + (300 - layerWidth) / 2;
    }
    
    // 设置节点位置
    for (int i = 0; i < nodes.length; i++) {
      final nodeId = nodes[i];
      final node = g.node(nodeId);
      if (node == null) continue;
      
      // 计算坐标
      final x = startX + i * (nodeWidth + paddingX) + nodeWidth / 2;
      final y = marginY + rank * (nodeHeight + paddingY) + nodeHeight / 2;
      
      // 更新节点属性
      node['x'] = x;
      node['y'] = y;
      node['rank'] = rank;
      node['order'] = i;
    }
  }
  
  // 为边添加路径点
  for (final edgeObj in g.edges()) {
    final v = edgeObj['v'] as String;
    final w = edgeObj['w'] as String;
    
    final sourceNode = g.node(v);
    final targetNode = g.node(w);
    if (sourceNode == null || targetNode == null) continue;
    
    final sourceX = sourceNode['x'] as double;
    final sourceY = sourceNode['y'] as double;
    final targetX = targetNode['x'] as double;
    final targetY = targetNode['y'] as double;
    
    // 源节点和目标节点之间的路径点
    final midY = (sourceY + targetY) / 2;
    
    final points = [
      {'x': sourceX, 'y': sourceY},
      {'x': sourceX, 'y': midY},
      {'x': targetX, 'y': midY},
      {'x': targetX, 'y': targetY}
    ];
    
    final edge = g.edge(edgeObj);
    if (edge != null) {
      edge['points'] = points;
    }
  }
  
  // 设置图的整体尺寸
  g.setGraph({
    'width': 340,
    'height': 260,
    'rankdir': 'TB',
    'marginx': marginX,
    'marginy': marginY
  });
}

String generateSVG(Graph g) {
  final graphData = g.graph() ?? {};
  final width = (graphData['width'] is num) ? (graphData['width'] as num).toDouble() : 800.0;
  final height = (graphData['height'] is num) ? (graphData['height'] as num).toDouble() : 600.0;
  
  StringBuffer svg = StringBuffer();
  svg.writeln('<?xml version="1.0" encoding="UTF-8" standalone="no"?>');
  svg.writeln('<svg width="$width" height="$height" xmlns="http://www.w3.org/2000/svg">');
  
  // 添加样式
  svg.writeln('<defs>');
  svg.writeln('<style type="text/css">');
  svg.writeln('.node rect, .node ellipse, .node diamond { fill: #f5f5f5; stroke: #333; stroke-width: 1px; }');
  svg.writeln('.edgePath path { stroke: #333; stroke-width: 1.5px; fill: none; marker-end: url(#arrowhead); }');
  svg.writeln('.edgeLabel { fill: #333; font-family: sans-serif; font-size: 12px; }');
  svg.writeln('.nodeLabel { font-family: sans-serif; font-size: 14px; }');
  svg.writeln('</style>');
  svg.writeln('<marker id="arrowhead" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">');
  svg.writeln('  <polygon points="0 0, 10 3.5, 0 7" fill="#333" />');
  svg.writeln('</marker>');
  svg.writeln('</defs>');
  
  // 绘制网格背景（可选）
  svg.writeln('<g class="grid">');
  svg.writeln('<rect width="$width" height="$height" fill="#f9f9f9" />');
  for (int i = 0; i < width; i += 20) {
    svg.writeln('<line x1="$i" y1="0" x2="$i" y2="$height" stroke="#eee" stroke-width="1" />');
  }
  for (int i = 0; i < height; i += 20) {
    svg.writeln('<line x1="0" y1="$i" x2="$width" y2="$i" stroke="#eee" stroke-width="1" />');
  }
  svg.writeln('</g>');
  
  // 绘制边（先绘制边，这样它们会在节点下面）
  for (final edgeObj in g.edges()) {
    final edgeData = g.edge(edgeObj);
    if (edgeData == null) continue;
    
    // 从edgeObj获取源和目标节点ID
    final v = edgeObj['v'] as String;
    final w = edgeObj['w'] as String;
    
    final points = edgeData['points'];
    if (points != null && points is List && points.isNotEmpty) {
      // 如果有路径点，则绘制路径
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
      svg.writeln('<path d="$pointsPath" />');
      
      // 如果有标签，则在中间位置添加
      final label = edgeData['label'];
      if (label != null && points.length > 1) {
        final midIndex = (points.length ~/ 2).clamp(0, points.length - 1);
        final midPoint = points[midIndex];
        if (midPoint is Map) {
          final midX = midPoint['x'] is num ? (midPoint['x'] as num).toDouble() : 0.0;
          final midY = midPoint['y'] is num ? (midPoint['y'] as num).toDouble() : 0.0 - 5;
          svg.writeln('<text x="$midX" y="$midY" text-anchor="middle" class="edgeLabel">$label</text>');
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
      svg.writeln('<path d="M$sourceX,$sourceY L$targetX,$targetY" />');
      
      // 如果有标签，则在中间位置添加
      final label = edgeData['label'];
      if (label != null) {
        final midX = (sourceX + targetX) / 2;
        final midY = (sourceY + targetY) / 2 - 5;
        svg.writeln('<text x="$midX" y="$midY" text-anchor="middle" class="edgeLabel">$label</text>');
      }
      
      svg.writeln('</g>');
    }
  }
  
  // 绘制节点
  for (final v in g.getNodes()) {
    final node = g.node(v);
    if (node == null) continue;
    
    final x = node['x'] is num ? (node['x'] as num).toDouble() : 0.0;
    final y = node['y'] is num ? (node['y'] as num).toDouble() : 0.0;
    final width = node['width'] is num ? (node['width'] as num).toDouble() : 40.0;
    final height = node['height'] is num ? (node['height'] as num).toDouble() : 40.0;
    final label = node['label'] ?? v;
    final shape = node['shape'] ?? 'rect';
    
    svg.writeln('<g class="node">');
    
    // 根据形状绘制不同的节点
    if (shape == 'ellipse') {
      svg.writeln('<ellipse cx="$x" cy="$y" rx="${width/2}" ry="${height/2}" />');
    } else if (shape == 'diamond') {
      final halfWidth = width / 2;
      final halfHeight = height / 2;
      final path = 'M$x,${y-halfHeight} L${x+halfWidth},$y L$x,${y+halfHeight} L${x-halfWidth},$y Z';
      svg.writeln('<path d="$path" />');
    } else {
      // 默认为矩形
      svg.writeln('<rect x="${x - width/2}" y="${y - height/2}" width="$width" height="$height" rx="3" ry="3" />');
    }
    
    svg.writeln('<text x="$x" y="$y" text-anchor="middle" dominant-baseline="middle" class="nodeLabel">$label</text>');
    
    // 显示节点的排名和顺序（可选）
    if (node.containsKey('rank') && node.containsKey('order')) {
      final infoY = y + height / 2 + 15;
      svg.writeln('<text x="$x" y="$infoY" text-anchor="middle" font-size="10" fill="#999">rank: ${node['rank']}, order: ${node['order']}</text>');
    }
    
    svg.writeln('</g>');
  }
  
  svg.writeln('</svg>');
  return svg.toString();
} 