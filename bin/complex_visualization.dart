import 'dart:io';
import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/layout.dart';

void main() {
  final complexFlowchartGraph = createComplexFlowchartGraph();
  visualizeGraphWithFallback(complexFlowchartGraph, 'complex_flowchart.svg');
  print('生成的SVG文件已保存为 complex_flowchart.svg');
}

Graph createComplexFlowchartGraph() {
  final g = Graph(isCompound: true);

  // 添加节点（仅示意部分节点，你可以逐步扩展）
  g.setNode('start', {'label': 'Start', 'shape': 'ellipse', 'width': 100, 'height': 50});
  g.setNode('system', {'label': 'System', 'width': 400, 'height': 140});
  g.setNode('decision', {'label': 'Data Valid?', 'shape': 'diamond', 'width': 160, 'height': 80});
  g.setNode('path1', {'label': 'Success Path', 'width': 180, 'height': 80});
  g.setNode('path2', {'label': 'Error Path', 'width': 180, 'height': 80});
  g.setNode('end', {'label': 'End', 'shape': 'ellipse', 'width': 100, 'height': 50});

  // 添加子图容器
  g.setNode('systemContainer', {'label': 'System', 'clusterLabelPos': 'top'});
  g.setParent('system', 'systemContainer');

  // 添加边
  g.setEdge('start', 'system', {'label': 'init'});
  g.setEdge('system', 'decision', {'label': 'validate'});
  g.setEdge('decision', 'path1', {'label': 'yes'});
  g.setEdge('decision', 'path2', {'label': 'no'});
  g.setEdge('path1', 'end', {'label': 'process'});
  g.setEdge('path2', 'end', {'label': 'handle error'});

  // 设置图的布局属性
  g.setGraph({
    'rankdir': 'TB',
    'marginx': 50,
    'marginy': 50,
    'ranker': 'network-simplex',
    'edgesep': 40,
    'nodesep': 70,
    'ranksep': 90,
    'acyclicer': 'greedy',
  });

  return g;
}

void visualizeGraphWithFallback(Graph g, String filename) {
  try {
    print('应用布局算法到复杂流程图...');
    layout(g);
    final svgContent = generateSVG(g);
    File(filename).writeAsStringSync(svgContent);
  } catch (e) {
    print('布局过程中出错，使用备用布局: $e');
    // applyGridLayout(g);
    // final svgContent = generateSVG(g);
    // File(filename).writeAsStringSync(svgContent);
  }
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
