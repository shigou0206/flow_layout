import 'dart:io';
import 'dart:math' as math;

void main() {
  // 生成一个简单的五层流程图SVG
  final svgContent = generateFlowchartSVG();
  File('manual_flowchart.svg').writeAsStringSync(svgContent);
  
  print('生成的SVG文件已保存为 manual_flowchart.svg');
}

// 直接生成SVG，不依赖Graph库
String generateFlowchartSVG() {
  // 定义节点
  final nodes = [
    // 层次1
    {'id': 'A', 'label': 'Start', 'x': 500, 'y': 50, 'width': 80, 'height': 40, 
     'shape': 'ellipse', 'fill': '#e3f2fd', 'stroke': '#1976d2'},
    
    // 层次2 - 包括容器和子节点
    {'id': 'B', 'label': 'Process', 'x': 500, 'y': 150, 'width': 160, 'height': 120, 
     'shape': 'rect', 'fill': '#e8f5e9', 'stroke': '#388e3c', 'isContainer': true},
    {'id': 'B1', 'label': 'Sub-1', 'x': 450, 'y': 140, 'width': 60, 'height': 30, 
     'shape': 'rect', 'fill': '#c8e6c9', 'stroke': '#4caf50', 'parent': 'B'},
    {'id': 'B2', 'label': 'Sub-2', 'x': 550, 'y': 160, 'width': 60, 'height': 30, 
     'shape': 'rect', 'fill': '#c8e6c9', 'stroke': '#4caf50', 'parent': 'B'},
    
    // 层次3
    {'id': 'C', 'label': 'Decision', 'x': 500, 'y': 270, 'width': 90, 'height': 40, 
     'shape': 'diamond', 'fill': '#fff3e0', 'stroke': '#e65100'},
    
    // 层次4
    {'id': 'D1', 'label': 'Task 1', 'x': 300, 'y': 370, 'width': 80, 'height': 40, 
     'shape': 'rect', 'fill': '#e1f5fe', 'stroke': '#0288d1'},
    {'id': 'D2', 'label': 'Task 2', 'x': 500, 'y': 370, 'width': 80, 'height': 40, 
     'shape': 'rect', 'fill': '#e1f5fe', 'stroke': '#0288d1'},
    {'id': 'D3', 'label': 'Task 3', 'x': 700, 'y': 370, 'width': 80, 'height': 40, 
     'shape': 'rect', 'fill': '#e1f5fe', 'stroke': '#0288d1'},
    
    // 层次5 - 包括容器和子节点
    {'id': 'E', 'label': 'Task Group', 'x': 500, 'y': 480, 'width': 280, 'height': 100, 
     'shape': 'rect', 'fill': '#f3e5f5', 'stroke': '#9c27b0', 'isContainer': true, 'labelPos': 'top'},
    {'id': 'E1', 'label': 'Task 4', 'x': 430, 'y': 480, 'width': 70, 'height': 35, 
     'shape': 'rect', 'fill': '#e1bee7', 'stroke': '#8e24aa', 'parent': 'E'},
    {'id': 'E2', 'label': 'Task 5', 'x': 570, 'y': 480, 'width': 70, 'height': 35, 
     'shape': 'rect', 'fill': '#e1bee7', 'stroke': '#8e24aa', 'parent': 'E'},
    
    // 层次6
    {'id': 'F', 'label': 'End', 'x': 500, 'y': 570, 'width': 80, 'height': 40, 
     'shape': 'ellipse', 'fill': '#ffebee', 'stroke': '#d32f2f'},
  ];
  
  // 定义边
  final edges = [
    // 层次间连接
    {'from': 'A', 'to': 'B', 'label': 'init', 'stroke': '#1976d2', 'strokeWidth': 2},
    {'from': 'B', 'to': 'C', 'label': 'evaluate', 'stroke': '#388e3c', 'strokeWidth': 2},
    {'from': 'C', 'to': 'D1', 'label': 'yes', 'stroke': '#e65100', 'strokeWidth': 2},
    {'from': 'C', 'to': 'D2', 'label': 'maybe', 'stroke': '#e65100', 'strokeWidth': 2},
    {'from': 'C', 'to': 'D3', 'label': 'no', 'stroke': '#e65100', 'strokeWidth': 2},
    {'from': 'D1', 'to': 'E', 'stroke': '#0288d1', 'strokeWidth': 2},
    {'from': 'D2', 'to': 'E', 'stroke': '#0288d1', 'strokeWidth': 2},
    {'from': 'D3', 'to': 'E', 'stroke': '#0288d1', 'strokeWidth': 2},
    {'from': 'E', 'to': 'F', 'label': 'complete', 'stroke': '#9c27b0', 'strokeWidth': 2},
    
    // 子节点间连接
    {'from': 'B1', 'to': 'B2', 'stroke': '#4caf50', 'strokeWidth': 1},
    {'from': 'E1', 'to': 'E2', 'stroke': '#8e24aa', 'strokeWidth': 1},
  ];
  
  // 图表尺寸
  final int width = 1000;
  final int height = 800;
  
  // 生成SVG
  StringBuffer svg = StringBuffer();
  svg.writeln('<?xml version="1.0" encoding="UTF-8" standalone="no"?>');
  svg.writeln('<svg width="$width" height="$height" xmlns="http://www.w3.org/2000/svg">');
  
  // 添加样式
  svg.writeln('<defs>');
  svg.writeln('<style type="text/css">');
  svg.writeln('.node rect, .node ellipse, .node path { stroke-width: 2px; }');
  svg.writeln('.edgePath path { fill: none; }');
  svg.writeln('.edgeLabel { font-family: "Helvetica Neue", Helvetica, Arial, sans-serif; font-size: 12px; font-weight: 500; }');
  svg.writeln('.nodeLabel { font-family: "Helvetica Neue", Helvetica, Arial, sans-serif; font-size: 14px; font-weight: 600; }');
  svg.writeln('.container { opacity: 0.8; }');
  svg.writeln('</style>');
  
  // 添加箭头
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
  
  // 添加阴影
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
  svg.writeln('<rect width="$width" height="$height" fill="#ffffff" />');
  
  // 绘制网格（可选）
  svg.writeln('<g class="grid" opacity="0.1">');
  for (int i = 0; i < width; i += 50) {
    svg.writeln('<line x1="$i" y1="0" x2="$i" y2="$height" stroke="#000" stroke-width="1" />');
  }
  for (int i = 0; i < height; i += 50) {
    svg.writeln('<line x1="0" y1="$i" x2="$width" y2="$i" stroke="#000" stroke-width="1" />');
  }
  svg.writeln('</g>');
  
  // 绘制容器（先绘制，这样节点和边会在上层）
  final containers = nodes.where((node) => node['isContainer'] == true);
  for (final container in containers) {
    final x = container['x'] as int;
    final y = container['y'] as int;
    final width = container['width'] as int;
    final height = container['height'] as int;
    final fill = container['fill'] as String;
    final stroke = container['stroke'] as String;
    final label = container['label'] as String;
    
    svg.writeln('<g class="container" filter="url(#drop-shadow)">');
    svg.writeln('<rect x="${x - width/2}" y="${y - height/2}" width="$width" height="$height" rx="5" ry="5" fill="$fill" stroke="$stroke" stroke-width="2" />');
    
    // 标签位置
    double labelX = x.toDouble();
    double labelY = y.toDouble();
    if (container['labelPos'] == 'top') {
      labelY = y - height/2 + 15;
    }
    
    svg.writeln('<text x="$labelX" y="$labelY" text-anchor="middle" dominant-baseline="middle" class="nodeLabel">$label</text>');
    svg.writeln('</g>');
  }
  
  // 绘制边
  for (final edge in edges) {
    final fromNode = nodes.firstWhere((node) => node['id'] == edge['from']);
    final toNode = nodes.firstWhere((node) => node['id'] == edge['to']);
    
    final fromX = fromNode['x'] as int;
    final fromY = fromNode['y'] as int;
    final toX = toNode['x'] as int;
    final toY = toNode['y'] as int;
    
    final fromShape = fromNode['shape'] as String;
    final toShape = toNode['shape'] as String;
    
    final stroke = edge['stroke'] as String;
    final strokeWidth = edge['strokeWidth'] as int;
    final arrowId = 'arrowhead-${stroke.substring(1)}';
    
    // 计算路径
    if (fromY == toY) {
      // 水平路径（如子节点之间的连接）
      final points = [
        {'x': fromX, 'y': fromY},
        {'x': (fromX + toX) / 2, 'y': fromY},
        {'x': (fromX + toX) / 2, 'y': toY},
        {'x': toX, 'y': toY}
      ];
      
      // 绘制路径
      final pathData = _generatePathData(points);
      svg.writeln('<g class="edgePath">');
      svg.writeln('<path d="$pathData" stroke="$stroke" stroke-width="$strokeWidth" marker-end="url(#$arrowId)" />');
      
      // 如果有标签，则在中间添加
      if (edge.containsKey('label')) {
        final label = edge['label'] as String;
        final midX = (fromX + toX) / 2;
        final midY = fromY - 10;
        
        svg.writeln('<rect x="${midX-30}" y="${midY-10}" width="60" height="20" rx="10" ry="10" fill="white" stroke="$stroke" stroke-width="1" opacity="0.9" />');
        svg.writeln('<text x="$midX" y="$midY" text-anchor="middle" dominant-baseline="middle" fill="$stroke" class="edgeLabel">$label</text>');
      }
      
      svg.writeln('</g>');
    } else if (fromNode['id'] == 'C' && (toNode['id'] == 'D1' || toNode['id'] == 'D2' || toNode['id'] == 'D3')) {
      // 决策点到任务的特殊路径
      final midX = toNode['id'] == 'D1' ? fromX - 20 : toNode['id'] == 'D3' ? fromX + 20 : fromX;
      
      final points = [
        {'x': fromX, 'y': fromY},
        {'x': midX, 'y': fromY + 30},
        {'x': toX, 'y': toY - 20},
        {'x': toX, 'y': toY}
      ];
      
      // 绘制路径
      final pathData = _generatePathData(points);
      svg.writeln('<g class="edgePath">');
      svg.writeln('<path d="$pathData" stroke="$stroke" stroke-width="$strokeWidth" marker-end="url(#$arrowId)" />');
      
      // 如果有标签，则在中间添加
      if (edge.containsKey('label')) {
        final label = edge['label'] as String;
        final midX = (fromX + toX) / 2;
        final midY = (fromY + toY) / 2 - 20;
        
        svg.writeln('<rect x="${midX-30}" y="${midY-10}" width="60" height="20" rx="10" ry="10" fill="white" stroke="$stroke" stroke-width="1" opacity="0.9" />');
        svg.writeln('<text x="$midX" y="$midY" text-anchor="middle" dominant-baseline="middle" fill="$stroke" class="edgeLabel">$label</text>');
      }
      
      svg.writeln('</g>');
    } else {
      // 垂直贝塞尔曲线
      final points = [
        {'x': fromX, 'y': fromY},
        {'x': fromX, 'y': fromY + (toY - fromY) * 0.4},
        {'x': toX, 'y': toY - (toY - fromY) * 0.4},
        {'x': toX, 'y': toY}
      ];
      
      // 生成贝塞尔曲线
      final p0 = points[0];
      final p1 = points[1];
      final p2 = points[2];
      final p3 = points[3];
      
      final x0 = p0['x'] as num;
      final y0 = p0['y'] as num;
      final x1 = p1['x'] as num;
      final y1 = p1['y'] as num;
      final x2 = p2['x'] as num;
      final y2 = p2['y'] as num;
      final x3 = p3['x'] as num;
      final y3 = p3['y'] as num;
      
      svg.writeln('<g class="edgePath">');
      svg.writeln('<path d="M$x0,$y0 C$x1,$y1 $x2,$y2 $x3,$y3" stroke="$stroke" stroke-width="$strokeWidth" marker-end="url(#$arrowId)" />');
      
      // 如果有标签，则在中间添加
      if (edge.containsKey('label')) {
        final label = edge['label'] as String;
        // 计算贝塞尔曲线的中点位置（近似）
        final midX = (x0 + x1 + x2 + x3) / 4;
        final midY = (y0 + y1 + y2 + y3) / 4 - 10;
        
        svg.writeln('<rect x="${midX-30}" y="${midY-10}" width="60" height="20" rx="10" ry="10" fill="white" stroke="$stroke" stroke-width="1" opacity="0.9" />');
        svg.writeln('<text x="$midX" y="$midY" text-anchor="middle" dominant-baseline="middle" fill="$stroke" class="edgeLabel">$label</text>');
      }
      
      svg.writeln('</g>');
    }
  }
  
  // 绘制节点（非容器）
  final regularNodes = nodes.where((node) => node['isContainer'] != true);
  for (final node in regularNodes) {
    final x = node['x'] as int;
    final y = node['y'] as int;
    final width = node['width'] as int;
    final height = node['height'] as int;
    final shape = node['shape'] as String;
    final fill = node['fill'] as String;
    final stroke = node['stroke'] as String;
    final label = node['label'] as String;
    
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

// 生成路径数据
String _generatePathData(List<Map<String, dynamic>> points) {
  final path = StringBuffer();
  bool first = true;
  
  for (final point in points) {
    final x = point['x'] as num;
    final y = point['y'] as num;
    
    if (first) {
      path.write('M$x,$y');
      first = false;
    } else {
      path.write(' L$x,$y');
    }
  }
  
  return path.toString();
} 