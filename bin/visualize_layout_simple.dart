import 'dart:io';
import 'dart:math' as math;
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
  const int nodeWidth = 50;
  const int nodeHeight = 50;
  const int marginX = 40;
  const int marginY = 40;
  const int paddingX = 80;
  const int paddingY = 100;
  
  // 计算节点位置
  for (final rankEntry in rankNodes.entries) {
    final rank = rankEntry.key;
    final nodes = rankEntry.value;
    
    // 计算这一层的总宽度
    final layerWidth = nodes.length * nodeWidth + (nodes.length - 1) * paddingX;
    
    // 开始X坐标 (居中)
    double startX = marginX + (paddingX - nodeWidth) / 2;
    if (nodes.length > 1) {
      startX = marginX + (400 - layerWidth) / 2;
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
      node['width'] = nodeWidth;
      node['height'] = nodeHeight;
      
      // 设置样式
      if (nodeId == 'A') {
        node['shape'] = 'ellipse';
        node['style'] = {'fill': '#e1f5fe', 'stroke': '#0288d1'};
      } else if (nodeId == 'D') {
        node['shape'] = 'ellipse';
        node['style'] = {'fill': '#e8f5e9', 'stroke': '#388e3c'};
      } else {
        node['style'] = {'fill': '#f3e5f5', 'stroke': '#8e24aa'};
      }
    }
  }
  
  // 为边添加路径点，创建贝塞尔曲线
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
    
    // 源节点和目标节点之间的控制点
    final midY = (sourceY + targetY) / 2;
    final sourceRank = sourceNode['rank'] as int;
    final targetRank = targetNode['rank'] as int;
    
    // 如果源和目标在不同层级上，使用贝塞尔曲线
    if (targetRank - sourceRank > 0) {
      final edge = g.edge(edgeObj);
      if (edge == null) continue;
      
      edge['curve'] = 'bezier';
      edge['points'] = [
        {'x': sourceX, 'y': sourceY},
        {'x': sourceX, 'y': sourceY + (targetY - sourceY) * 0.4},
        {'x': targetX, 'y': targetY - (targetY - sourceY) * 0.4},
        {'x': targetX, 'y': targetY}
      ];

      // 设置边的样式
      edge['style'] = {
        'stroke': (v == 'A' && w == 'B') || (v == 'B' && w == 'D') ? '#2196f3' : '#9c27b0',
        'strokeWidth': 2
      };
      
      // 设置边的标签
      if (v == 'A' && w == 'B') {
        edge['label'] = 'primary';
      } else if (v == 'A' && w == 'C') {
        edge['label'] = 'alternate';
      } else if (v == 'B' && w == 'D' || v == 'C' && w == 'D') {
        edge['label'] = 'process';
      }
    }
  }
  
  // 设置图的整体尺寸
  g.setGraph({
    'width': 500,
    'height': 380,
    'rankdir': 'TB',
    'marginx': marginX,
    'marginy': marginY,
    'bgcolor': '#ffffff'
  });
}

String generateSVG(Graph g) {
  final graphData = g.graph() ?? {};
  final width = (graphData['width'] is num) ? (graphData['width'] as num).toDouble() : 800.0;
  final height = (graphData['height'] is num) ? (graphData['height'] as num).toDouble() : 600.0;
  final bgcolor = graphData['bgcolor'] as String? ?? '#ffffff';
  
  StringBuffer svg = StringBuffer();
  svg.writeln('<?xml version="1.0" encoding="UTF-8" standalone="no"?>');
  svg.writeln('<svg width="$width" height="$height" xmlns="http://www.w3.org/2000/svg">');
  
  // 添加样式
  svg.writeln('<defs>');
  svg.writeln('<style type="text/css">');
  svg.writeln('.node rect, .node ellipse, .node diamond { stroke-width: 2px; }');
  svg.writeln('.edgePath path { fill: none; marker-end: url(#arrowhead); }');
  svg.writeln('.edgeLabel { font-family: "Helvetica Neue", Helvetica, Arial, sans-serif; font-size: 12px; font-weight: 500; }');
  svg.writeln('.nodeLabel { font-family: "Helvetica Neue", Helvetica, Arial, sans-serif; font-size: 14px; font-weight: 600; }');
  svg.writeln('</style>');
  
  // 添加多种颜色的箭头标记
  svg.writeln('<marker id="arrowhead" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto" markerUnits="strokeWidth">');
  svg.writeln('  <polygon points="0 0, 10 3.5, 0 7" fill="#333" />');
  svg.writeln('</marker>');
  svg.writeln('<marker id="arrowhead-blue" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto" markerUnits="strokeWidth">');
  svg.writeln('  <polygon points="0 0, 10 3.5, 0 7" fill="#2196f3" />');
  svg.writeln('</marker>');
  svg.writeln('<marker id="arrowhead-purple" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto" markerUnits="strokeWidth">');
  svg.writeln('  <polygon points="0 0, 10 3.5, 0 7" fill="#9c27b0" />');
  svg.writeln('</marker>');
  
  // 添加阴影和光晕效果
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
  
  // 添加发光效果
  svg.writeln('<filter id="glow" x="-30%" y="-30%" width="160%" height="160%">');
  svg.writeln('  <feGaussianBlur stdDeviation="5" result="glow" />');
  svg.writeln('  <feMerge>');
  svg.writeln('    <feMergeNode in="glow" />');
  svg.writeln('    <feMergeNode in="glow" />');
  svg.writeln('    <feMergeNode in="SourceGraphic" />');
  svg.writeln('  </feMerge>');
  svg.writeln('</filter>');
  
  svg.writeln('</defs>');
  
  // 绘制背景
  svg.writeln('<rect width="$width" height="$height" fill="$bgcolor" />');
  
  // 绘制网格背景（可选）
  svg.writeln('<g class="grid">');
  for (int i = 0; i < width; i += 20) {
    svg.writeln('<line x1="$i" y1="0" x2="$i" y2="$height" stroke="#f0f0f0" stroke-width="1" />');
  }
  for (int i = 0; i < height; i += 20) {
    svg.writeln('<line x1="0" y1="$i" x2="$width" y2="$i" stroke="#f0f0f0" stroke-width="1" />');
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
    final style = edgeData['style'] as Map<String, dynamic>?;
    final strokeColor = style?['stroke'] as String? ?? '#333';
    final strokeWidth = style?['strokeWidth'] as int? ?? 1.5;
    final arrowId = strokeColor == '#2196f3' ? 'arrowhead-blue' : 
                    strokeColor == '#9c27b0' ? 'arrowhead-purple' : 
                    'arrowhead';
    
    if (points != null && points is List && points.isNotEmpty) {
      // 如果有路径点且指定为贝塞尔曲线
      if (edgeData['curve'] == 'bezier' && points.length >= 4) {
        final p0 = points[0] as Map;
        final p1 = points[1] as Map;
        final p2 = points[2] as Map;
        final p3 = points[3] as Map;
        
        final x0 = p0['x'] is num ? (p0['x'] as num).toDouble() : 0.0;
        final y0 = p0['y'] is num ? (p0['y'] as num).toDouble() : 0.0;
        final x1 = p1['x'] is num ? (p1['x'] as num).toDouble() : 0.0;
        final y1 = p1['y'] is num ? (p1['y'] as num).toDouble() : 0.0;
        final x2 = p2['x'] is num ? (p2['x'] as num).toDouble() : 0.0;
        final y2 = p2['y'] is num ? (p2['y'] as num).toDouble() : 0.0;
        final x3 = p3['x'] is num ? (p3['x'] as num).toDouble() : 0.0;
        final y3 = p3['y'] is num ? (p3['y'] as num).toDouble() : 0.0;
        
        svg.writeln('<g class="edgePath">');
        svg.writeln('<path d="M$x0,$y0 C$x1,$y1 $x2,$y2 $x3,$y3" stroke="$strokeColor" stroke-width="$strokeWidth" marker-end="url(#$arrowId)" />');
        
        // 如果有标签，则在路径的中间位置添加
        final label = edgeData['label'];
        if (label != null) {
          // 计算贝塞尔曲线的中点位置
          final midT = 0.5; // 参数 t=0.5 表示曲线的中点
          final midX = math.pow(1-midT, 3)*x0 + 3*math.pow(1-midT, 2)*midT*x1 + 3*(1-midT)*math.pow(midT, 2)*x2 + math.pow(midT, 3)*x3;
          final midY = math.pow(1-midT, 3)*y0 + 3*math.pow(1-midT, 2)*midT*y1 + 3*(1-midT)*math.pow(midT, 2)*y2 + math.pow(midT, 3)*y3;
          
          svg.writeln('<rect x="${midX-25}" y="${midY-15}" width="50" height="20" rx="10" ry="10" fill="white" stroke="$strokeColor" stroke-width="1" opacity="0.9" />');
          svg.writeln('<text x="$midX" y="$midY" text-anchor="middle" dominant-baseline="middle" fill="$strokeColor" class="edgeLabel">$label</text>');
        }
        
        svg.writeln('</g>');
      } else {
        // 如果有路径点，则绘制折线路径
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
      }
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