import 'dart:io';
import 'dart:math' as math;

void main() {
  // 创建一个简单的流程图并生成SVG
  final svgContent = generateFlowchartSVG();
  File('manual_flowchart.svg').writeAsStringSync(svgContent);
  
  print('生成的SVG文件已保存为 manual_flowchart.svg');
}

String generateFlowchartSVG() {
  // 设置SVG图表尺寸
  final int width = 1000;
  final int height = 700;
  
  // 定义节点
  final nodes = [
    // --- 第一层 ---
    {'id': 'start', 'label': 'Start', 'x': 500, 'y': 50, 'width': 100, 'height': 50, 
     'shape': 'ellipse', 'fill': '#e3f2fd', 'stroke': '#1976d2'},
    
    // --- 第二层 ---
    {'id': 'parse', 'label': 'Parse Data', 'x': 350, 'y': 150, 'width': 120, 'height': 60, 
     'shape': 'rect', 'fill': '#e8f5e9', 'stroke': '#388e3c'},
    {'id': 'validate', 'label': 'Validate', 'x': 650, 'y': 150, 'width': 120, 'height': 60, 
     'shape': 'rect', 'fill': '#fff3e0', 'stroke': '#e65100'},
    
    // --- 第三层 ---
    {'id': 'process', 'label': 'Process', 'x': 350, 'y': 300, 'width': 120, 'height': 60, 
     'shape': 'rect', 'fill': '#e1f5fe', 'stroke': '#0288d1'},
    {'id': 'store', 'label': 'Store Data', 'x': 650, 'y': 300, 'width': 120, 'height': 60, 
     'shape': 'rect', 'fill': '#f3e5f5', 'stroke': '#9c27b0'},
    
    // --- 第四层 ---
    {'id': 'display', 'label': 'Display Results', 'x': 350, 'y': 450, 'width': 140, 'height': 60, 
     'shape': 'rect', 'fill': '#fff8e1', 'stroke': '#ffa000'},
    {'id': 'export', 'label': 'Export Data', 'x': 650, 'y': 450, 'width': 120, 'height': 60, 
     'shape': 'rect', 'fill': '#e8eaf6', 'stroke': '#3f51b5'},
    
    // --- 第五层 ---
    {'id': 'end', 'label': 'End', 'x': 500, 'y': 600, 'width': 100, 'height': 50, 
     'shape': 'ellipse', 'fill': '#ffebee', 'stroke': '#d32f2f'},
  ];
  
  // 定义连接边
  final edges = [
    {'from': 'start', 'to': 'parse', 'label': 'input', 'stroke': '#1976d2', 'strokeWidth': 2},
    {'from': 'start', 'to': 'validate', 'label': 'check', 'stroke': '#1976d2', 'strokeWidth': 2},
    
    {'from': 'parse', 'to': 'process', 'stroke': '#388e3c', 'strokeWidth': 2},
    {'from': 'validate', 'to': 'process', 'stroke': '#e65100', 'strokeWidth': 2},
    {'from': 'validate', 'to': 'store', 'stroke': '#e65100', 'strokeWidth': 2},
    
    {'from': 'process', 'to': 'display', 'stroke': '#0288d1', 'strokeWidth': 2},
    {'from': 'store', 'to': 'export', 'stroke': '#9c27b0', 'strokeWidth': 2},
    
    {'from': 'display', 'to': 'end', 'stroke': '#ffa000', 'strokeWidth': 2},
    {'from': 'export', 'to': 'end', 'stroke': '#3f51b5', 'strokeWidth': 2},
  ];
  
  // 创建映射表以便通过ID快速查找节点
  final nodeMap = <String, Map<String, dynamic>>{};
  for (final node in nodes) {
    nodeMap[node['id'] as String] = node;
  }
  
  // 生成SVG内容
  final StringBuffer svg = StringBuffer();
  svg.writeln('<?xml version="1.0" encoding="UTF-8" standalone="no"?>');
  svg.writeln('<svg width="$width" height="$height" xmlns="http://www.w3.org/2000/svg">');
  
  // 添加样式和定义
  svg.writeln('<defs>');
  
  // 添加CSS样式
  svg.writeln('<style type="text/css">');
  svg.writeln('.node rect, .node ellipse { stroke-width: 2px; }');
  svg.writeln('.edge path { fill: none; }');
  svg.writeln('.nodeLabel { font-family: "Helvetica Neue", Helvetica, Arial, sans-serif; font-size: 14px; font-weight: bold; }');
  svg.writeln('.edgeLabel { font-family: "Helvetica Neue", Helvetica, Arial, sans-serif; font-size: 12px; font-weight: 500; }');
  svg.writeln('</style>');
  
  // 添加箭头标记
  svg.writeln('<marker id="arrowhead" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">');
  svg.writeln('  <polygon points="0 0, 10 3.5, 0 7" fill="#333" />');
  svg.writeln('</marker>');
  
  // 添加多种颜色的箭头
  final arrowColors = [
    '#1976d2', '#388e3c', '#e65100', '#0288d1', '#9c27b0', '#d32f2f', '#ffa000', '#3f51b5'
  ];
  
  for (final color in arrowColors) {
    final id = 'arrowhead-${color.substring(1)}';
    svg.writeln('<marker id="$id" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">');
    svg.writeln('  <polygon points="0 0, 10 3.5, 0 7" fill="$color" />');
    svg.writeln('</marker>');
  }
  
  // 添加阴影滤镜
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
  svg.writeln('<rect width="$width" height="$height" fill="#fafafa" />');
  
  // 绘制网格（用于辅助设计，可以在最终版本中移除）
  svg.writeln('<g class="grid" opacity="0.05">');
  for (int i = 0; i < width; i += 50) {
    svg.writeln('<line x1="$i" y1="0" x2="$i" y2="$height" stroke="#000" stroke-width="1" />');
  }
  for (int i = 0; i < height; i += 50) {
    svg.writeln('<line x1="0" y1="$i" x2="$width" y2="$i" stroke="#000" stroke-width="1" />');
  }
  svg.writeln('</g>');
  
  // 绘制边
  for (final edge in edges) {
    final fromNode = nodeMap[edge['from'] as String];
    final toNode = nodeMap[edge['to'] as String];
    
    if (fromNode == null || toNode == null) continue;
    
    final fromX = fromNode['x'] as int;
    final fromY = fromNode['y'] as int;
    final toX = toNode['x'] as int;
    final toY = toNode['y'] as int;
    
    final fromHeight = fromNode['height'] as int;
    final toHeight = toNode['height'] as int;
    
    // 计算连接点（从节点底部出发，到节点顶部结束）
    final startX = fromX;
    final startY = fromY + fromHeight / 2;
    final endX = toX;
    final endY = toY - toHeight / 2;
    
    // 生成三次贝塞尔曲线路径
    final controlPoint1X = startX;
    final controlPoint1Y = startY + (endY - startY) / 3;
    final controlPoint2X = endX;
    final controlPoint2Y = startY + 2 * (endY - startY) / 3;
    
    final pathData = 'M$startX,$startY C$controlPoint1X,$controlPoint1Y $controlPoint2X,$controlPoint2Y $endX,$endY';
    
    // 设置边的样式
    final stroke = edge['stroke'] as String;
    final strokeWidth = edge['strokeWidth'] as int;
    final arrowId = 'arrowhead-${stroke.substring(1)}';
    
    svg.writeln('<g class="edge">');
    svg.writeln('<path d="$pathData" stroke="$stroke" stroke-width="$strokeWidth" marker-end="url(#$arrowId)" />');
    
    // 如果有标签，在曲线中间位置添加
    if (edge.containsKey('label')) {
      final label = edge['label'] as String;
      final midX = (startX + endX) / 2;
      final midY = startY + (endY - startY) / 2 - 15; // 向上偏移一点
      
      final labelWidth = math.max(label.length * 7 + 10, 40);
      
      svg.writeln('<rect x="${midX - labelWidth/2}" y="${midY-10}" width="$labelWidth" height="20" rx="10" ry="10" fill="white" stroke="$stroke" stroke-width="1" opacity="0.9" />');
      svg.writeln('<text x="$midX" y="$midY" text-anchor="middle" dominant-baseline="middle" class="edgeLabel" fill="$stroke">$label</text>');
    }
    
    svg.writeln('</g>');
  }
  
  // 绘制节点
  for (final node in nodes) {
    final x = node['x'] as int;
    final y = node['y'] as int;
    final width = node['width'] as int;
    final height = node['height'] as int;
    final shape = node['shape'] as String;
    final fill = node['fill'] as String;
    final stroke = node['stroke'] as String;
    final label = node['label'] as String;
    
    // 特殊效果（开始和结束节点使用发光效果）
    final filter = (node['id'] == 'start' || node['id'] == 'end') ? 'filter="url(#glow)"' : 'filter="url(#drop-shadow)"';
    
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