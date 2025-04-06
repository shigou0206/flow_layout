import 'dart:io';
import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/layout.dart';

// Edge类型定义，与Graph中保持一致
class Edge {
  final String v;
  final String w;
  final String? name;
  final bool isDirected;

  Edge(this.v, this.w, {this.name, this.isDirected = true});
}

void main() {
  // 创建简单图示例
  final simpleGraph = createSimpleGraph();
  visualizeGraphWithFallback(simpleGraph, 'simple_graph.svg');

  // 创建层级图示例
  final hierarchyGraph = createHierarchyGraph();
  visualizeGraphWithFallback(hierarchyGraph, 'hierarchy_graph.svg');

  // 创建复杂图示例
  final complexGraph = createComplexGraph();
  visualizeGraphWithFallback(complexGraph, 'complex_graph.svg');
  
  // 创建环状图示例
  final circularGraph = createCircularGraph();
  visualizeGraphWithFallback(circularGraph, 'circular_graph.svg');

  print('生成的SVG文件已保存在项目根目录');
}

Graph createSimpleGraph() {
  final g = Graph();
  
  // 添加节点
  g.setNode('A', {'label': 'A', 'width': 40, 'height': 40});
  g.setNode('B', {'label': 'B', 'width': 40, 'height': 40});
  g.setNode('C', {'label': 'C', 'width': 40, 'height': 40});
  g.setNode('D', {'label': 'D', 'width': 40, 'height': 40});
  
  // 添加有向边
  g.setEdge('A', 'B', {'arrowhead': 'normal'});
  g.setEdge('A', 'C', {'arrowhead': 'normal'});
  g.setEdge('B', 'D', {'arrowhead': 'normal'});
  g.setEdge('C', 'D', {'arrowhead': 'normal'});

  // 设置图的属性
  g.setGraph({
    'rankdir': 'TB', // 从上到下的方向
    'marginx': 20,
    'marginy': 20,
    'ranker': 'network-simplex'
  });

  return g;
}

Graph createHierarchyGraph() {
  final g = Graph();
  
  // 添加节点
  g.setNode('A', {'label': 'Root', 'width': 60, 'height': 40});
  g.setNode('B', {'label': 'B', 'width': 40, 'height': 40});
  g.setNode('C', {'label': 'C', 'width': 40, 'height': 40});
  g.setNode('D', {'label': 'D', 'width': 40, 'height': 40});
  g.setNode('E', {'label': 'E', 'width': 40, 'height': 40});
  g.setNode('F', {'label': 'F', 'width': 40, 'height': 40});
  
  // 添加有向边
  g.setEdge('A', 'B', {'arrowhead': 'normal'});
  g.setEdge('A', 'C', {'arrowhead': 'normal'});
  g.setEdge('B', 'D', {'arrowhead': 'normal'});
  g.setEdge('B', 'E', {'arrowhead': 'normal'});
  g.setEdge('C', 'F', {'arrowhead': 'normal'});

  // 设置图的属性
  g.setGraph({
    'rankdir': 'TB', // 从上到下的方向
    'marginx': 20,
    'marginy': 20,
    'ranker': 'network-simplex'
  });

  return g;
}

Graph createComplexGraph() {
  final g = Graph(isCompound: true);
  
  // 添加节点
  g.setNode('A', {'label': 'Start', 'width': 60, 'height': 40, 'shape': 'ellipse'});
  g.setNode('B', {'label': 'Process 1', 'width': 80, 'height': 40, 'shape': 'rect'});
  g.setNode('C', {'label': 'Process 2', 'width': 80, 'height': 40, 'shape': 'rect'});
  g.setNode('D', {'label': 'Decision', 'width': 70, 'height': 70, 'shape': 'diamond'});
  g.setNode('E', {'label': 'Process 3', 'width': 80, 'height': 40, 'shape': 'rect'});
  g.setNode('F', {'label': 'Process 4', 'width': 80, 'height': 40, 'shape': 'rect'});
  g.setNode('G', {'label': 'End', 'width': 60, 'height': 40, 'shape': 'ellipse'});
  
  // 添加子图
  g.setNode('subgraph1', {'label': 'Subprocess', 'clusterLabelPos': 'top'});
  g.setParent('B', 'subgraph1');
  g.setParent('C', 'subgraph1');
  
  // 添加边
  g.setEdge('A', 'B', {'label': 'start'});
  g.setEdge('A', 'C', {'label': 'alternate'});
  g.setEdge('B', 'D', {'label': 'process'});
  g.setEdge('C', 'D', {'label': 'process'});
  g.setEdge('D', 'E', {'label': 'yes'});
  g.setEdge('D', 'F', {'label': 'no'});
  g.setEdge('E', 'G', {'label': 'complete'});
  g.setEdge('F', 'G', {'label': 'complete'});

  // 设置图的属性
  g.setGraph({
    'rankdir': 'TB', // 从上到下的方向
    'marginx': 40,
    'marginy': 40,
    'ranker': 'network-simplex'
  });

  return g;
}

Graph createCircularGraph() {
  final g = Graph();
  
  // 自定义节点颜色
  final colors = {
    'center': '#6A98F0', // 中心节点 - 蓝色
    'mid': ['#FF7676', '#76D7FF', '#FFD876'], // 中间层节点 - 红、青、黄
    'outer': '#A5E8AD', // 外层节点 - 浅绿
  };
  
  // 添加中心节点
  g.setNode('Center', {
    'label': 'Hub', 
    'width': 70, 
    'height': 70, 
    'shape': 'circle',
    'style': 'fill: ${colors['center']!}; stroke: #335599; stroke-width: 2px;',
    'labelStyle': 'font-weight: bold; font-size: 16px; fill: white;'
  });
  
  // 添加中间层节点
  final midLayerCount = 3;
  for (int i = 0; i < midLayerCount; i++) {
    final nodeId = 'M${i+1}';
    g.setNode(nodeId, {
      'label': nodeId, 
      'width': 60, 
      'height': 60, 
      'shape': 'circle',
      'style': 'fill: ${(colors['mid'] as List)[i]}; stroke: #555; stroke-width: 1.5px;',
      'labelStyle': 'font-weight: bold; fill: white;'
    });
    
    // 连接中心到中间层 - 添加有向边，更粗的线
    g.setEdge('Center', nodeId, {
      'label': 'link', 
      'arrowhead': 'normal',
      'style': 'stroke-width: 2px; stroke: #666;',
      'weight': 2 // 增加权重，使这些边在布局时优先考虑
    });
  }
  
  // 添加外环节点 - 均匀分布
  final outerCount = 6;
  for (int i = 0; i < outerCount; i++) {
    final nodeId = String.fromCharCode('A'.codeUnitAt(0) + i);
    g.setNode(nodeId, {
      'label': nodeId, 
      'width': 50, 
      'height': 50,
      'shape': 'circle',
      'style': 'fill: ${colors['outer']!}; stroke: #188D2F; stroke-width: 1px;'
    });
    
    // 连接到对应的中间层节点
    final midLayerId = 'M${(i % midLayerCount) + 1}';
    g.setEdge(midLayerId, nodeId, {
      'label': '${i+1}', 
      'arrowhead': 'normal',
      'labelStyle': 'font-size: 10px;'
    });
  }
  
  // 添加外环连接 - 形成有向环，更优雅的连接
  for (int i = 0; i < outerCount; i++) {
    final sourceId = String.fromCharCode('A'.codeUnitAt(0) + i);
    final targetId = String.fromCharCode('A'.codeUnitAt(0) + ((i + 1) % outerCount));
    g.setEdge(sourceId, targetId, {
      'arrowhead': 'normal',
      'style': 'stroke: #75B798; stroke-width: 1.5px;',
      'weight': 1.5 // 增加权重，确保环形美观
    });
  }

  // 只选择性地添加一些反向连接，避免过于复杂
  g.setEdge('A', 'M1', {
    'label': 'back', 
    'arrowhead': 'normal', 
    'style': 'stroke-dasharray: 5,3; stroke: #FF7676;',
    'weight': 0.5
  });
  g.setEdge('D', 'M2', {
    'label': 'back', 
    'arrowhead': 'normal', 
    'style': 'stroke-dasharray: 5,3; stroke: #76D7FF;',
    'weight': 0.5
  });

  // 设置图的属性 - 改进布局参数
  g.setGraph({
    'rankdir': 'TB',    // 从上到下的方向
    'marginx': 50,
    'marginy': 50,
    'ranker': 'network-simplex',
    'edgesep': 40,      // 增加边之间的间距
    'nodesep': 70,      // 增加同一层节点之间的间距
    'ranksep': 90,      // 增加不同层之间的间距
    'acyclicer': 'greedy',  // 处理环状结构
    'align': 'DL',      // 尝试对齐节点
  });

  return g;
}

void visualizeGraphWithFallback(Graph g, String filename) {
  try {
    print('对图形应用布局算法...');
    try {
      // 尝试应用布局算法
      layout(g);
    } catch (e) {
      print('布局过程中出现错误，应用默认网格布局: $e');
      // 应用备用网格布局
      // applyGridLayout(g);
    }
    
    print('生成 SVG 文件: $filename');
    final svgContent = generateSVG(g);
    File(filename).writeAsStringSync(svgContent);
  } catch (e) {
    print('可视化过程中出错: $e');
  }
}

// 备用网格布局算法
// void applyGridLayout(Graph g) {
//   const double nodeWidth = 60;
//   const double nodeHeight = 40;
//   const double marginX = 40;
//   const double marginY = 40;
//   const double spacingX = 40; // 节点间水平距离
//   const double spacingY = 80; // 节点间垂直距离
//   int nodesPerRow = 3; // 每行最多放置的节点数

//   // 获取节点列表，不包括子图节点
//   final nodes = g.getNodes().where((v) {
//     if (g.isCompound) {
//       return g.parent(v) == null || g.parent(v) == '\u0000';
//     }
//     return true;
//   }).toList();

//   // 获取子图和子图中的节点
//   final subgraphs = <String, Set<String>>{};
//   if (g.isCompound) {
//     for (final v in g.getNodes()) {
//       final children = g.children(v);
//       if (children != null && children.isNotEmpty) {
//         subgraphs[v] = Set<String>.from(children);
//       }
//     }
//   }

//   // 调整每行节点数
//   if (nodes.length < nodesPerRow) {
//     nodesPerRow = nodes.length;
//   }

//   // 计算行数
//   int rows = (nodes.length / nodesPerRow).ceil();

//   // 为普通节点分配位置
//   Map<String, Map<String, double>> nodePositions = {};
//   for (int i = 0; i < nodes.length; i++) {
//     final node = nodes[i];
//     // 跳过子图
//     if (subgraphs.containsKey(node)) continue;
    
//     // 计算行列位置
//     int row = i ~/ nodesPerRow;
//     int col = i % nodesPerRow;
    
//     // 计算坐标
//     double x = marginX + col * (nodeWidth + spacingX) + nodeWidth / 2;
//     double y = marginY + row * (nodeHeight + spacingY) + nodeHeight / 2;
    
//     nodePositions[node] = {'x': x, 'y': y};
//   }

//   // 处理子图
//   if (g.isCompound) {
//     for (final entry in subgraphs.entries) {
//       final subgraphId = entry.key;
//       final children = entry.value;
      
//       // 为子图中的节点分配位置
//       double minX = double.infinity;
//       double minY = double.infinity;
//       double maxX = -double.infinity;
//       double maxY = -double.infinity;
      
//       int i = 0;
//       for (final childId in children) {
//         int row = i ~/ 2; // 子图中每行最多2个节点
//         int col = i % 2;
        
//         double x = marginX + col * (nodeWidth + 20) + nodeWidth / 2;
//         double y = marginY + row * (nodeHeight + 20) + nodeHeight / 2;
        
//         // 获取节点大小
//         final nodeData = g.node(childId) ?? {};
//         final width = (nodeData['width'] is num) ? (nodeData['width'] as num).toDouble() : nodeWidth;
//         final height = (nodeData['height'] is num) ? (nodeData['height'] as num).toDouble() : nodeHeight;
        
//         // 更新子图边界
//         if (x - width/2 < minX) minX = x - width/2;
//         if (x + width/2 > maxX) maxX = x + width/2;
//         if (y - height/2 < minY) minY = y - height/2;
//         if (y + height/2 > maxY) maxY = y + height/2;
        
//         // 保存节点位置
//         nodePositions[childId] = {'x': x, 'y': y};
//         i++;
//       }
      
//       // 为子图计算位置和大小
//       final subgraphWidth = maxX - minX + 40; // 额外的padding
//       final subgraphHeight = maxY - minY + 40;
//       final subgraphX = minX + subgraphWidth/2 - 20;
//       final subgraphY = minY + subgraphHeight/2 - 20;
      
//       // 保存子图位置
//       nodePositions[subgraphId] = {
//         'x': subgraphX, 
//         'y': subgraphY,
//         'width': subgraphWidth,
//         'height': subgraphHeight
//       };
//     }
//   }

//   // 应用计算好的位置到图中
//   for (final entry in nodePositions.entries) {
//     final nodeId = entry.key;
//     final pos = entry.value;
    
//     final nodeData = g.node(nodeId) ?? {};
//     for (final posKey in pos.keys) {
//       nodeData[posKey] = pos[posKey];
//     }
    
//     // 确保节点有宽高
//     if (!nodeData.containsKey('width') || nodeData['width'] == null) {
//       nodeData['width'] = nodeWidth;
//     }
//     if (!nodeData.containsKey('height') || nodeData['height'] == null) {
//       nodeData['height'] = nodeHeight;
//     }
    
//     g.setNode(nodeId, nodeData);
//   }
  
//   // 设置图的整体尺寸
//   final graphWidth = marginX * 2 + nodesPerRow * (nodeWidth + spacingX);
//   final graphHeight = marginY * 2 + rows * (nodeHeight + spacingY);
  
//   g.setGraph({
//     'width': graphWidth,
//     'height': graphHeight,
//     'rankdir': g.graph()?['rankdir'] ?? 'TB',
//     'marginx': marginX,
//     'marginy': marginY
//   });
// }

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
  svg.writeln('.node rect, .node ellipse, .node circle, .node diamond { fill: #f5f5f5; stroke: #333; stroke-width: 1px; }');
  svg.writeln('.edgePath path { stroke: #333; stroke-width: 1.5px; fill: none; }');
  svg.writeln('.edgePath path.dashed { stroke-dasharray: 5,5; }');
  svg.writeln('.edgeLabel { fill: #333; font-family: sans-serif; font-size: 12px; }');
  svg.writeln('.cluster { fill: #f0f0f0; stroke: #ddd; stroke-width: 1px; }');
  svg.writeln('.nodeLabel { font-family: sans-serif; font-size: 14px; }');
  svg.writeln('</style>');
  
  // 为每种可能的边样式定义不同颜色的箭头标记
  // 默认黑色箭头
  svg.writeln('<marker id="arrowhead" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">');
  svg.writeln('  <polygon points="0 0, 10 3.5, 0 7" fill="#333" />');
  svg.writeln('</marker>');
  
  // 蓝色箭头
  svg.writeln('<marker id="arrowhead-blue" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">');
  svg.writeln('  <polygon points="0 0, 10 3.5, 0 7" fill="#6A98F0" />');
  svg.writeln('</marker>');
  
  // 红色箭头
  svg.writeln('<marker id="arrowhead-red" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">');
  svg.writeln('  <polygon points="0 0, 10 3.5, 0 7" fill="#FF7676" />');
  svg.writeln('</marker>');
  
  // 绿色箭头
  svg.writeln('<marker id="arrowhead-green" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">');
  svg.writeln('  <polygon points="0 0, 10 3.5, 0 7" fill="#75B798" />');
  svg.writeln('</marker>');
  svg.writeln('</defs>');

  // 绘制子图/集群
  if (g.isCompound) {
    for (final cluster in g.getNodes()) {
      final children = g.children(cluster);
      if (children != null && children.isNotEmpty) {
        final clusterNode = g.node(cluster);
        if (clusterNode == null) continue;
        
        final x = clusterNode['x'] is num ? (clusterNode['x'] as num).toDouble() : 0.0;
        final y = clusterNode['y'] is num ? (clusterNode['y'] as num).toDouble() : 0.0;
        final width = clusterNode['width'] is num ? (clusterNode['width'] as num).toDouble() : 100.0;
        final height = clusterNode['height'] is num ? (clusterNode['height'] as num).toDouble() : 100.0;
        final label = clusterNode['label'] ?? cluster;
        final style = clusterNode['style'] as String? ?? '';
        
        svg.writeln('<g class="cluster" style="$style">');
        svg.writeln('<rect x="${x - width/2}" y="${y - height/2}" width="$width" height="$height" rx="5" ry="5" />');
        svg.writeln('<text x="$x" y="${y - height/2 + 15}" text-anchor="middle" class="nodeLabel"'
            '${clusterNode['labelStyle'] != null ? ' style="${clusterNode['labelStyle']}"' : ''}>$label</text>');
        svg.writeln('</g>');
      }
    }
  }
  
  // 绘制边
  for (final edgeObj in g.edges()) {
    final edgeData = g.edge(edgeObj);
    if (edgeData == null) continue;
    
    // 从edgeObj获取源和目标节点ID
    final v = edgeObj['v'] as String;
    final w = edgeObj['w'] as String;
    
    // 获取边的样式属性
    final style = edgeData['style'] as String? ?? '';
    final styleAttr = style.isNotEmpty ? ' style="$style"' : '';
    final labelStyle = edgeData['labelStyle'] as String? ?? '';
    
    // 确定箭头样式
    String arrowheadId = "arrowhead";
    if (style.contains("stroke: #6A98F0") || style.contains("stroke:#6A98F0")) {
      arrowheadId = "arrowhead-blue";
    } else if (style.contains("stroke: #FF7676") || style.contains("stroke:#FF7676")) {
      arrowheadId = "arrowhead-red";
    } else if (style.contains("stroke: #75B798") || style.contains("stroke:#75B798")) {
      arrowheadId = "arrowhead-green";
    }
    
    final points = edgeData['points'];
    if (points == null || !(points is List) || points.isEmpty) {
      // 如果没有路径点，则直接从源到目标绘制直线
      final sourceNode = g.node(v);
      final targetNode = g.node(w);
      if (sourceNode == null || targetNode == null) continue;
      
      final sourceX = sourceNode['x'] is num ? (sourceNode['x'] as num).toDouble() : 0.0;
      final sourceY = sourceNode['y'] is num ? (sourceNode['y'] as num).toDouble() : 0.0;
      final targetX = targetNode['x'] is num ? (targetNode['x'] as num).toDouble() : 0.0;
      final targetY = targetNode['y'] is num ? (targetNode['y'] as num).toDouble() : 0.0;
      
      svg.writeln('<g class="edgePath">');
      svg.writeln('<path d="M$sourceX,$sourceY L$targetX,$targetY"$styleAttr marker-end="url(#$arrowheadId)" />');
      
      // 如果有标签，则在中间位置添加
      final label = edgeData['label'];
      if (label != null) {
        final midX = (sourceX + targetX) / 2;
        final midY = (sourceY + targetY) / 2 - 5;
        svg.writeln('<text x="$midX" y="$midY" text-anchor="middle" class="edgeLabel"'
            '${labelStyle.isNotEmpty ? ' style="$labelStyle"' : ''}>$label</text>');
      }
      
      svg.writeln('</g>');
    } else {
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
      svg.writeln('<path d="$pointsPath"$styleAttr marker-end="url(#$arrowheadId)" />');
      
      // 如果有标签，则在中间位置添加
      final label = edgeData['label'];
      if (label != null && points.length > 1) {
        final midIndex = (points.length ~/ 2).clamp(0, points.length - 1);
        final midPoint = points[midIndex];
        if (midPoint is Map) {
          final midX = midPoint['x'] is num ? (midPoint['x'] as num).toDouble() : 0.0;
          final midY = midPoint['y'] is num ? (midPoint['y'] as num).toDouble() : 0.0 - 5;
          svg.writeln('<text x="$midX" y="$midY" text-anchor="middle" class="edgeLabel"'
              '${labelStyle.isNotEmpty ? ' style="$labelStyle"' : ''}>$label</text>');
        }
      }
      
      svg.writeln('</g>');
    }
  }
  
  // 绘制节点
  for (final v in g.getNodes()) {
    // 跳过子图
    if (g.isCompound && (g.children(v)?.isNotEmpty ?? false)) continue;
    
    final node = g.node(v);
    if (node == null) continue;
    
    final x = node['x'] is num ? (node['x'] as num).toDouble() : 0.0;
    final y = node['y'] is num ? (node['y'] as num).toDouble() : 0.0;
    final width = node['width'] is num ? (node['width'] as num).toDouble() : 40.0;
    final height = node['height'] is num ? (node['height'] as num).toDouble() : 40.0;
    final label = node['label'] ?? v;
    final shape = node['shape'] ?? 'rect';
    final style = node['style'] as String? ?? '';
    final labelStyle = node['labelStyle'] as String? ?? '';
    
    svg.writeln('<g class="node">');
    
    // 根据形状绘制不同的节点
    if (shape == 'ellipse') {
      svg.writeln('<ellipse cx="$x" cy="$y" rx="${width/2}" ry="${height/2}" '
          '${style.isNotEmpty ? 'style="$style"' : ''} />');
    } else if (shape == 'circle') {
      final radius = width / 2; // 假设宽高相等
      svg.writeln('<circle cx="$x" cy="$y" r="$radius" '
          '${style.isNotEmpty ? 'style="$style"' : ''} />');
    } else if (shape == 'diamond') {
      final halfWidth = width / 2;
      final halfHeight = height / 2;
      final path = 'M$x,${y-halfHeight} L${x+halfWidth},$y L$x,${y+halfHeight} L${x-halfWidth},$y Z';
      svg.writeln('<path d="$path" ${style.isNotEmpty ? 'style="$style"' : ''} />');
    } else {
      // 默认为矩形
      svg.writeln('<rect x="${x - width/2}" y="${y - height/2}" width="$width" height="$height" rx="3" ry="3" '
          '${style.isNotEmpty ? 'style="$style"' : ''} />');
    }
    
    svg.writeln('<text x="$x" y="$y" text-anchor="middle" dominant-baseline="middle" class="nodeLabel"'
        '${labelStyle.isNotEmpty ? ' style="$labelStyle"' : ''}>$label</text>');
    svg.writeln('</g>');
  }
  
  svg.writeln('</svg>');
  return svg.toString();
} 