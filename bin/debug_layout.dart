import 'dart:io';
import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/layout.dart' as layout;

void main() {
  // 创建一个简单的图用于测试自动布局
  final simpleGraph = createSimpleTestGraph();
  
  print('=== 图结构初始化完成 ===');
  printGraphStats(simpleGraph);
  
  // 尝试应用布局算法（带错误捕获）
  try {
    print('\n=== 开始应用布局算法 ===');
    layout.layout(simpleGraph);
    print('=== 布局算法应用完成 ===');
  } catch (e, stackTrace) {
    print('\n=== 布局算法出错 ===');
    print(e);
    print('\n堆栈信息:');
    print(stackTrace);
  }
  
  // 无论布局成功与否，尝试检查和打印节点位置
  print('\n=== 布局结果检查 ===');
  checkNodePositions(simpleGraph);
  
  // 生成可视化
  print('\n=== 生成SVG可视化 ===');
  final svgContent = generateSimpleSVG(simpleGraph);
  File('debug_layout.svg').writeAsStringSync(svgContent);
  
  print('生成的调试SVG文件已保存为 debug_layout.svg');
}

// 创建一个简单的测试图，避免复杂的嵌套
Graph createSimpleTestGraph() {
  final g = Graph();
  
  // 设置图的属性
  g.setGraph({
    'rankdir': 'TB',  // 从上到下的方向
    'marginx': 40,
    'marginy': 40,
    'ranksep': 60,    // 层级间距
    'nodesep': 50,    // 同层节点间距
    'acyclicer': 'greedy'
  });
  
  // 添加一些简单的节点
  g.setNode('A', {
    'label': 'Start',
    'width': 100,
    'height': 50,
    'shape': 'ellipse',
    'style': {'fill': '#e3f2fd', 'stroke': '#1976d2', 'strokeWidth': 2}
  });
  
  g.setNode('B', {
    'label': 'Process 1',
    'width': 120,
    'height': 60,
    'style': {'fill': '#e8f5e9', 'stroke': '#388e3c', 'strokeWidth': 2}
  });
  
  g.setNode('C', {
    'label': 'Process 2',
    'width': 120,
    'height': 60,
    'style': {'fill': '#fff3e0', 'stroke': '#e65100', 'strokeWidth': 2}
  });
  
  g.setNode('D', {
    'label': 'End',
    'width': 100,
    'height': 50,
    'shape': 'ellipse',
    'style': {'fill': '#ffebee', 'stroke': '#d32f2f', 'strokeWidth': 2}
  });
  
  // 添加边
  g.setEdge('A', 'B', {
    'label': 'Next',
    'weight': 2,
    'style': {'stroke': '#1976d2', 'strokeWidth': 2}
  });
  
  g.setEdge('B', 'C', {
    'label': 'Process',
    'weight': 2,
    'style': {'stroke': '#388e3c', 'strokeWidth': 2}
  });
  
  g.setEdge('C', 'D', {
    'label': 'Complete',
    'weight': 2,
    'style': {'stroke': '#e65100', 'strokeWidth': 2}
  });
  
  return g;
}

// 打印图的统计信息
void printGraphStats(Graph g) {
  print('节点数量: ${g.getNodes().length}');
  print('边数量: ${g.edges().length}');
  print('图属性: ${g.graph()}');
}

// 检查节点位置
void checkNodePositions(Graph g) {
  print('节点位置和尺寸信息:');
  for (final nodeId in g.getNodes()) {
    final node = g.node(nodeId);
    if (node != null) {
      final hasX = node.containsKey('x');
      final hasY = node.containsKey('y');
      final x = node['x'] is num ? (node['x'] as num).toDouble() : 'undefined';
      final y = node['y'] is num ? (node['y'] as num).toDouble() : 'undefined';
      final width = node['width'] is num ? (node['width'] as num).toDouble() : 'undefined';
      final height = node['height'] is num ? (node['height'] as num).toDouble() : 'undefined';
      
      print('节点 "$nodeId": ${node['label']}, 位置: $x, $y, 尺寸: $width x $height (坐标已计算: ${hasX && hasY})');
    }
  }
  
  print('\n边的路径点信息:');
  for (final edgeObj in g.edges()) {
    final edge = g.edge(edgeObj);
    if (edge != null) {
      final from = edgeObj['v'];
      final to = edgeObj['w'];
      final hasPoints = edge.containsKey('points') && edge['points'] is List && (edge['points'] as List).isNotEmpty;
      
      print('边 "$from" -> "$to": ${edge['label'] ?? ''}, 路径点已计算: $hasPoints, 点数: ${hasPoints ? (edge['points'] as List).length : 0}');
    }
  }
}

// 生成简单的SVG用于检查布局
String generateSimpleSVG(Graph g) {
  final graphData = g.graph() ?? {};
  // 如果没有计算好的宽高，使用默认值
  final svgWidth = (graphData['width'] is num) ? (graphData['width'] as num).toDouble() + 50 : 800.0;
  final svgHeight = (graphData['height'] is num) ? (graphData['height'] as num).toDouble() + 50 : 600.0;
  
  StringBuffer svg = StringBuffer();
  svg.writeln('<?xml version="1.0" encoding="UTF-8" standalone="no"?>');
  svg.writeln('<svg width="$svgWidth" height="$svgHeight" xmlns="http://www.w3.org/2000/svg">');
  
  // 添加简单的样式
  svg.writeln('<style type="text/css">');
  svg.writeln('.node rect, .node ellipse { stroke-width: 2px; }');
  svg.writeln('.edge path { fill: none; }');
  svg.writeln('.nodeLabel, .edgeLabel { font-family: sans-serif; font-size: 14px; }');
  svg.writeln('</style>');
  
  // 添加标准箭头
  svg.writeln('<marker id="arrowhead" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">');
  svg.writeln('  <polygon points="0 0, 10 3.5, 0 7" fill="#333" />');
  svg.writeln('</marker>');
  
  // 添加背景和坐标网格（用于调试）
  svg.writeln('<rect width="$svgWidth" height="$svgHeight" fill="#f8f8f8" />');
  
  // 绘制调试网格
  svg.writeln('<g class="grid" opacity="0.1">');
  for (int i = 0; i < svgWidth; i += 50) {
    svg.writeln('<line x1="$i" y1="0" x2="$i" y2="$svgHeight" stroke="#666" stroke-width="1" />');
    svg.writeln('<text x="${i+5}" y="15" font-size="10" fill="#666">$i</text>');
  }
  for (int i = 0; i < svgHeight; i += 50) {
    svg.writeln('<line x1="0" y1="$i" x2="$svgWidth" y2="$i" stroke="#666" stroke-width="1" />');
    svg.writeln('<text x="5" y="${i+15}" font-size="10" fill="#666">$i</text>');
  }
  svg.writeln('</g>');
  
  // 绘制边（如果有计算好的路径点）
  for (final edgeObj in g.edges()) {
    final edge = g.edge(edgeObj);
    if (edge == null) continue;
    
    final v = edgeObj['v'];
    final w = edgeObj['w'];
    final points = edge['points'];
    
    // 根据是否有计算好的路径点使用不同的绘制方式
    if (points != null && points is List && points.isNotEmpty) {
      // 标准绘制方式 - 使用计算好的路径点
      final pathData = StringBuffer();
      bool first = true;
      
      for (final point in points) {
        if (point is! Map) continue;
        final x = point['x'] is num ? (point['x'] as num).toDouble() : 0.0;
        final y = point['y'] is num ? (point['y'] as num).toDouble() : 0.0;
        
        if (first) {
          pathData.write('M$x,$y');
          first = false;
        } else {
          pathData.write(' L$x,$y');
        }
      }
      
      // 标准绘制
      final style = edge['style'] as Map<String, dynamic>? ?? {};
      final stroke = style['stroke'] as String? ?? '#333';
      final strokeWidth = style['strokeWidth'] as num? ?? 1.5;
      
      svg.writeln('<g class="edge">');
      svg.writeln('<path d="${pathData.toString()}" stroke="$stroke" stroke-width="$strokeWidth" marker-end="url(#arrowhead)" />');
      
      // 绘制标签（如果有）
      final label = edge['label'];
      if (label != null && points.length > 1) {
        final midIndex = (points.length ~/ 2).clamp(0, points.length - 1);
        final midPoint = points[midIndex];
        if (midPoint is Map) {
          final midX = midPoint['x'] is num ? (midPoint['x'] as num).toDouble() : 0.0;
          final midY = midPoint['y'] is num ? (midPoint['y'] as num).toDouble() : 0.0 - 10;
          
          svg.writeln('<rect x="${midX-40}" y="${midY-15}" width="80" height="20" rx="10" ry="10" fill="white" stroke="$stroke" stroke-width="1" opacity="0.8" />');
          svg.writeln('<text x="$midX" y="$midY" text-anchor="middle" dominant-baseline="middle" class="edgeLabel">$label</text>');
        }
      }
      
      svg.writeln('</g>');
    } else {
      // 备用绘制方式 - 直接连接节点中心
      final vNode = g.node(v);
      final wNode = g.node(w);
      
      if (vNode != null && wNode != null) {
        final vX = vNode['x'] is num ? (vNode['x'] as num).toDouble() : svgWidth / 4;
        final vY = vNode['y'] is num ? (vNode['y'] as num).toDouble() : svgHeight / 3;
        final wX = wNode['x'] is num ? (wNode['x'] as num).toDouble() : svgWidth * 3 / 4;
        final wY = wNode['y'] is num ? (wNode['y'] as num).toDouble() : svgHeight * 2 / 3;
        
        // 备用绘制 - 使用虚线表示未计算的路径
        svg.writeln('<g class="edge fallback">');
        svg.writeln('<path d="M$vX,$vY L$wX,$wY" stroke="#999" stroke-width="1.5" stroke-dasharray="5,5" marker-end="url(#arrowhead)" />');
        svg.writeln('<text x="${(vX+wX)/2}" y="${(vY+wY)/2-10}" text-anchor="middle" class="edgeLabel" fill="#999">${edge['label'] ?? ''}</text>');
        svg.writeln('</g>');
      }
    }
  }
  
  // 绘制节点
  for (final v in g.getNodes()) {
    final node = g.node(v);
    if (node == null) continue;
    
    // 确定节点位置 - 如果布局没有计算，则使用均匀分布的默认位置
    final hasCalculatedPosition = node['x'] is num && node['y'] is num;
    final x = node['x'] is num ? (node['x'] as num).toDouble() : svgWidth / 2;
    final y = node['y'] is num ? (node['y'] as num).toDouble() : svgHeight / 2;
    final nodeWidth = node['width'] is num ? (node['width'] as num).toDouble() : 100.0;
    final nodeHeight = node['height'] is num ? (node['height'] as num).toDouble() : 50.0;
    final label = node['label'] ?? v;
    final shape = node['shape'] ?? 'rect';
    
    // 节点样式
    final style = node['style'] as Map<String, dynamic>? ?? {};
    final fill = style['fill'] as String? ?? '#f5f5f5';
    final stroke = style['stroke'] as String? ?? '#333';
    final strokeWidth = style['strokeWidth'] as num? ?? 2.0;
    
    // 使用透明度区分计算位置和默认位置的节点
    final opacity = hasCalculatedPosition ? '1.0' : '0.7';
    
    svg.writeln('<g class="node" opacity="$opacity">');
    
    // 绘制形状
    if (shape == 'ellipse') {
      svg.writeln('<ellipse cx="$x" cy="$y" rx="${nodeWidth/2}" ry="${nodeHeight/2}" fill="$fill" stroke="$stroke" stroke-width="$strokeWidth" />');
    } else {
      // 默认为矩形
      svg.writeln('<rect x="${x - nodeWidth/2}" y="${y - nodeHeight/2}" width="$nodeWidth" height="$nodeHeight" rx="5" ry="5" fill="$fill" stroke="$stroke" stroke-width="$strokeWidth" />');
    }
    
    // 标签
    svg.writeln('<text x="$x" y="$y" text-anchor="middle" dominant-baseline="middle" class="nodeLabel">$label</text>');
    
    // 如果是默认位置，添加警告标记
    if (!hasCalculatedPosition) {
      svg.writeln('<text x="${x + nodeWidth/2 - 5}" y="${y - nodeHeight/2 + 15}" fill="red" font-size="12">?</text>');
    }
    
    svg.writeln('</g>');
    
    // 添加坐标标记（用于调试）
    svg.writeln('<text x="${x+5}" y="${y+5}" font-size="8" fill="#666">(${x.toInt()},${y.toInt()})</text>');
  }
  
  svg.writeln('</svg>');
  return svg.toString();
} 