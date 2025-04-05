import 'dart:io';
import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/layout.dart' as layout;

void main() {
  // 创建一个示例图并尝试应用修复后的布局
  final testGraph = createTestGraph();
  
  print('=== 应用修复后的布局算法 ===');
  
  try {
    // 先手动应用基本排序和位置
    applyManualLayout(testGraph);
    
    // 导出可视化
    final svgContent = generateSVG(testGraph);
    File('fixed_layout.svg').writeAsStringSync(svgContent);
    
    print('成功生成布局图，已保存为 fixed_layout.svg');
  } catch (e, stack) {
    print('布局错误: $e');
    print(stack);
  }
}

// 创建测试图
Graph createTestGraph() {
  final g = Graph(isCompound: true);
  
  // 设置图的属性
  g.setGraph({
    'rankdir': 'TB',    // 从上到下
    'marginx': 50,
    'marginy': 50,
    'ranksep': 70,      // 层级间距
    'nodesep': 50,      // 节点间距
  });
  
  // 添加节点：每层两个，共5层
  // 第一层
  g.setNode('start', {
    'label': 'Start',
    'width': 100,
    'height': 50,
    'shape': 'ellipse',
    'style': {'fill': '#e3f2fd', 'stroke': '#1976d2', 'strokeWidth': 2},
    'rank': 0  // 明确指定rank
  });
  
  // 第二层
  g.setNode('parse', {
    'label': 'Parse Data',
    'width': 120,
    'height': 60,
    'style': {'fill': '#e8f5e9', 'stroke': '#388e3c', 'strokeWidth': 2},
    'rank': 1
  });
  
  g.setNode('validate', {
    'label': 'Validate',
    'width': 120,
    'height': 60,
    'style': {'fill': '#fff3e0', 'stroke': '#e65100', 'strokeWidth': 2},
    'rank': 1
  });
  
  // 第三层
  g.setNode('process', {
    'label': 'Process',
    'width': 120,
    'height': 60,
    'style': {'fill': '#e1f5fe', 'stroke': '#0288d1', 'strokeWidth': 2},
    'rank': 2
  });
  
  g.setNode('store', {
    'label': 'Store Data',
    'width': 120,
    'height': 60, 
    'style': {'fill': '#f3e5f5', 'stroke': '#7b1fa2', 'strokeWidth': 2},
    'rank': 2
  });
  
  // 第四层
  g.setNode('display', {
    'label': 'Display Results',
    'width': 140,
    'height': 60,
    'style': {'fill': '#fff8e1', 'stroke': '#ffa000', 'strokeWidth': 2},
    'rank': 3
  });
  
  g.setNode('export', {
    'label': 'Export Data',
    'width': 120,
    'height': 60,
    'style': {'fill': '#e8eaf6', 'stroke': '#3f51b5', 'strokeWidth': 2},
    'rank': 3
  });
  
  // 第五层
  g.setNode('end', {
    'label': 'End',
    'width': 100,
    'height': 50,
    'shape': 'ellipse',
    'style': {'fill': '#ffebee', 'stroke': '#d32f2f', 'strokeWidth': 2},
    'rank': 4
  });
  
  // 添加边
  g.setEdge('start', 'parse', {
    'label': 'input',
    'style': {'stroke': '#1976d2', 'strokeWidth': 1.5}
  });
  
  g.setEdge('start', 'validate', {
    'label': 'check',
    'style': {'stroke': '#1976d2', 'strokeWidth': 1.5}
  });
  
  g.setEdge('parse', 'process', {
    'style': {'stroke': '#388e3c', 'strokeWidth': 1.5}
  });
  
  g.setEdge('validate', 'process', {
    'style': {'stroke': '#e65100', 'strokeWidth': 1.5}
  });
  
  g.setEdge('validate', 'store', {
    'style': {'stroke': '#e65100', 'strokeWidth': 1.5}
  });
  
  g.setEdge('process', 'display', {
    'style': {'stroke': '#0288d1', 'strokeWidth': 1.5}
  });
  
  g.setEdge('store', 'export', {
    'style': {'stroke': '#7b1fa2', 'strokeWidth': 1.5}
  });
  
  g.setEdge('display', 'end', {
    'style': {'stroke': '#ffa000', 'strokeWidth': 1.5}
  });
  
  g.setEdge('export', 'end', {
    'style': {'stroke': '#3f51b5', 'strokeWidth': 1.5}
  });
  
  return g;
}

// 手动应用布局 - 解决translateGraph方法中的问题
void applyManualLayout(Graph g) {
  final graphAttrs = g.graph() ?? {};
  final dir = graphAttrs['rankdir'] ?? 'TB';
  final marginX = (graphAttrs['marginx'] is num) ? graphAttrs['marginx'] as num : 40;
  final marginY = (graphAttrs['marginy'] is num) ? graphAttrs['marginy'] as num : 40;
  final rankSep = (graphAttrs['ranksep'] is num) ? graphAttrs['ranksep'] as num : 50;
  final nodeSep = (graphAttrs['nodesep'] is num) ? graphAttrs['nodesep'] as num : 30;
  
  // 按rank对节点分组
  final Map<int, List<String>> rankGroups = {};
  
  // 收集每个rank的节点
  for (final nodeId in g.getNodes()) {
    final nodeData = g.node(nodeId);
    if (nodeData == null) continue;
    
    final rank = nodeData['rank'] is int ? nodeData['rank'] as int : 0;
    if (!rankGroups.containsKey(rank)) {
      rankGroups[rank] = [];
    }
    rankGroups[rank]!.add(nodeId);
  }
  
  // 对每个rank的节点计算x/y坐标
  final ranks = rankGroups.keys.toList()..sort();
  
  for (int rankIdx = 0; rankIdx < ranks.length; rankIdx++) {
    final rank = ranks[rankIdx];
    final nodesInRank = rankGroups[rank]!;
    
    // 计算同一层节点的水平位置
    final totalWidth = nodesInRank.fold<double>(0, (sum, nodeId) {
      final node = g.node(nodeId);
      if (node == null) return sum;
      final width = node['width'] is num ? (node['width'] as num).toDouble() : 50;
      return sum + width + (sum > 0 ? nodeSep.toDouble() : 0);
    });
    
    // 计算此层的起始位置，使节点居中
    double startX = marginX.toDouble();
    
    // 计算y位置，基于rank
    final y = marginY + rank * (rankSep + 60); // 60是节点高度的粗略估计
    
    // 设置此rank中每个节点的位置
    double currentX = startX;
    
    for (int i = 0; i < nodesInRank.length; i++) {
      final nodeId = nodesInRank[i];
      final node = g.node(nodeId);
      if (node == null) continue;
      
      final width = node['width'] is num ? (node['width'] as num).toDouble() : 50.0;
      
      // 水平均匀分布
      final spacing = (nodesInRank.length > 1) ? 
         (800 - 2 * marginX.toDouble() - totalWidth) / (nodesInRank.length - 1) : 0.0;
      
      // 计算x位置
      if (i == 0) {
        currentX = marginX.toDouble();
      } else {
        // 添加上一个节点的宽度和间距
        final prevNodeId = nodesInRank[i-1];
        final prevNode = g.node(prevNodeId);
        if (prevNode != null) {
          final prevWidth = prevNode['width'] is num ? (prevNode['width'] as num).toDouble() : 50.0;
          currentX += prevWidth + nodeSep.toDouble() + spacing;
        }
      }
      
      // 设置节点位置
      node['x'] = currentX + width / 2;
      node['y'] = y;
    }
  }
  
  // 为边创建路径点
  for (final edgeObj in g.edges()) {
    final edge = g.edge(edgeObj);
    if (edge == null) continue;
    
    final v = edgeObj['v'] as String;
    final w = edgeObj['w'] as String;
    
    final vNode = g.node(v);
    final wNode = g.node(w);
    
    if (vNode != null && wNode != null && 
        vNode['x'] is num && vNode['y'] is num && 
        wNode['x'] is num && wNode['y'] is num) {
      
      final vx = (vNode['x'] as num).toDouble();
      final vy = (vNode['y'] as num).toDouble();
      final wx = (wNode['x'] as num).toDouble();
      final wy = (wNode['y'] as num).toDouble();
      
      // 使用简单直线连接，避免复杂路径点结构
      edge['sourceX'] = vx;
      edge['sourceY'] = vy + (vNode['height'] is num ? (vNode['height'] as num) / 2 : 25);
      edge['targetX'] = wx;
      edge['targetY'] = wy - (wNode['height'] is num ? (wNode['height'] as num) / 2 : 25);
      
      // 添加中点用于标签位置
      edge['labelX'] = (vx + wx) / 2;
      edge['labelY'] = (vy + wy) / 2 - 10;
    }
  }
  
  // 设置图的整体尺寸
  double maxX = 0;
  double maxY = 0;
  
  for (final nodeId in g.getNodes()) {
    final node = g.node(nodeId);
    if (node == null) continue;
    
    if (node['x'] is num && node['y'] is num) {
      final x = (node['x'] as num).toDouble();
      final y = (node['y'] as num).toDouble();
      final width = node['width'] is num ? (node['width'] as num).toDouble() : 50;
      final height = node['height'] is num ? (node['height'] as num).toDouble() : 50;
      
      maxX = maxX.compareTo(x + width / 2) < 0 ? x + width / 2 : maxX;
      maxY = maxY.compareTo(y + height / 2) < 0 ? y + height / 2 : maxY;
    }
  }
  
  // 设置图的整体尺寸
  graphAttrs['width'] = maxX + marginX;
  graphAttrs['height'] = maxY + marginY;
  
  g.setGraph(graphAttrs);
}

// 生成SVG
String generateSVG(Graph g) {
  final graphData = g.graph() ?? {};
  final width = (graphData['width'] is num) ? (graphData['width'] as num).toDouble() + 50 : 800.0;
  final height = (graphData['height'] is num) ? (graphData['height'] as num).toDouble() + 50 : 600.0;
  
  StringBuffer svg = StringBuffer();
  svg.writeln('<?xml version="1.0" encoding="UTF-8" standalone="no"?>');
  svg.writeln('<svg width="$width" height="$height" xmlns="http://www.w3.org/2000/svg">');
  
  // 添加样式
  svg.writeln('<defs>');
  svg.writeln('<style type="text/css">');
  svg.writeln('.node rect, .node ellipse { stroke-width: 2px; }');
  svg.writeln('.edge path { fill: none; }');
  svg.writeln('.nodeLabel, .edgeLabel { font-family: "Helvetica Neue", Helvetica, Arial, sans-serif; font-size: 14px; font-weight: bold; }');
  svg.writeln('</style>');
  
  // 添加箭头和滤镜
  svg.writeln('<marker id="arrowhead" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">');
  svg.writeln('  <polygon points="0 0, 10 3.5, 0 7" fill="#333" />');
  svg.writeln('</marker>');
  
  // 添加多种颜色的箭头
  final arrowColors = [
    '#1976d2', '#388e3c', '#e65100', '#0288d1', '#7b1fa2', '#d32f2f', '#ffa000', '#3f51b5'
  ];
  
  for (final color in arrowColors) {
    final id = 'arrowhead-${color.substring(1)}';
    svg.writeln('<marker id="$id" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">');
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
  svg.writeln('<rect width="$width" height="$height" fill="#fafafa" />');
  
  // 绘制边
  for (final edgeObj in g.edges()) {
    final edge = g.edge(edgeObj);
    if (edge == null) continue;
    
    // 使用简化的直线路径
    if (edge['sourceX'] is num && edge['sourceY'] is num && 
        edge['targetX'] is num && edge['targetY'] is num) {
      
      final sourceX = (edge['sourceX'] as num).toDouble();
      final sourceY = (edge['sourceY'] as num).toDouble();
      final targetX = (edge['targetX'] as num).toDouble();
      final targetY = (edge['targetY'] as num).toDouble();
      
      final style = edge['style'] as Map<String, dynamic>? ?? {};
      final strokeColor = style['stroke'] as String? ?? '#333';
      final strokeWidth = style['strokeWidth'] as num? ?? 1.5;
      final arrowId = 'arrowhead-${strokeColor.substring(1)}';
      
      // 创建三次贝塞尔曲线而不是直线
      final controlPoint1X = sourceX;
      final controlPoint1Y = sourceY + (targetY - sourceY) / 3;
      final controlPoint2X = targetX;
      final controlPoint2Y = sourceY + 2 * (targetY - sourceY) / 3;
      
      final path = 'M$sourceX,$sourceY C$controlPoint1X,$controlPoint1Y $controlPoint2X,$controlPoint2Y $targetX,$targetY';
      
      svg.writeln('<g class="edge">');
      svg.writeln('<path d="$path" stroke="$strokeColor" stroke-width="$strokeWidth" marker-end="url(#$arrowId)" />');
      
      // 如果有标签，在中间位置添加
      final label = edge['label'];
      if (label != null) {
        final midX = edge['labelX'] is num ? (edge['labelX'] as num).toDouble() : (sourceX + targetX) / 2;
        final midY = edge['labelY'] is num ? (edge['labelY'] as num).toDouble() : (sourceY + targetY) / 2 - 10;
        
        final labelWidth = (label.toString().length * 7).clamp(30, 100);
        
        svg.writeln('<rect x="${midX - labelWidth/2}" y="${midY - 10}" width="$labelWidth" height="20" rx="10" ry="10" fill="white" stroke="$strokeColor" stroke-width="1" opacity="0.8" />');
        svg.writeln('<text x="$midX" y="$midY" text-anchor="middle" dominant-baseline="middle" class="edgeLabel">$label</text>');
      }
      
      svg.writeln('</g>');
    }
  }
  
  // 绘制节点
  for (final v in g.getNodes()) {
    final node = g.node(v);
    if (node == null) continue;
    
    if (!(node['x'] is num) || !(node['y'] is num)) continue;
    
    final x = (node['x'] as num).toDouble();
    final y = (node['y'] as num).toDouble();
    final nodeWidth = node['width'] is num ? (node['width'] as num).toDouble() : 100.0;
    final nodeHeight = node['height'] is num ? (node['height'] as num).toDouble() : 50.0;
    final label = node['label'] ?? v;
    final shape = node['shape'] ?? 'rect';
    
    final style = node['style'] as Map<String, dynamic>? ?? {};
    final fill = style['fill'] as String? ?? '#f5f5f5';
    final stroke = style['stroke'] as String? ?? '#333';
    final strokeWidth = style['strokeWidth'] as num? ?? 2.0;
    
    // 特殊效果（开始和结束节点）
    final filter = (v == 'start' || v == 'end') ? 'filter="url(#drop-shadow)"' : 'filter="url(#drop-shadow)"';
    
    svg.writeln('<g class="node" $filter>');
    
    // 绘制形状
    if (shape == 'ellipse') {
      svg.writeln('<ellipse cx="$x" cy="$y" rx="${nodeWidth/2}" ry="${nodeHeight/2}" fill="$fill" stroke="$stroke" stroke-width="$strokeWidth" />');
    } else if (shape == 'diamond') {
      final halfWidth = nodeWidth / 2;
      final halfHeight = nodeHeight / 2;
      final path = 'M$x,${y-halfHeight} L${x+halfWidth},$y L$x,${y+halfHeight} L${x-halfWidth},$y Z';
      svg.writeln('<path d="$path" fill="$fill" stroke="$stroke" stroke-width="$strokeWidth" />');
    } else {
      // 默认为矩形
      svg.writeln('<rect x="${x - nodeWidth/2}" y="${y - nodeHeight/2}" width="$nodeWidth" height="$nodeHeight" rx="5" ry="5" fill="$fill" stroke="$stroke" stroke-width="$strokeWidth" />');
    }
    
    // 标签
    svg.writeln('<text x="$x" y="$y" text-anchor="middle" dominant-baseline="middle" class="nodeLabel">$label</text>');
    
    svg.writeln('</g>');
  }
  
  svg.writeln('</svg>');
  return svg.toString();
} 