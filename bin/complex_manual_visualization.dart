import 'dart:io';
import 'dart:math' as math;

void main() {
  // 生成一个复杂的五层流程图SVG
  final svgContent = generateComplexFlowchartSVG();
  File('complex_manual_flowchart.svg').writeAsStringSync(svgContent);
  
  print('生成的SVG文件已保存为 complex_manual_flowchart.svg');
}

// 直接生成SVG，不依赖Graph库
String generateComplexFlowchartSVG() {
  // 图表尺寸
  final int width = 1200;
  final int height = 900;
  
  // 定义节点
  final nodes = [
    // --- 层级1: 开始节点 ---
    {'id': 'start', 'label': 'Start', 'x': 600, 'y': 60, 'width': 100, 'height': 50, 
     'shape': 'ellipse', 'fill': '#e3f2fd', 'stroke': '#1976d2'},
    
    // --- 层级2: 系统模块 ---
    {'id': 'system', 'label': 'System', 'x': 600, 'y': 180, 'width': 900, 'height': 140, 
     'shape': 'rect', 'fill': '#e8eaf6', 'stroke': '#3f51b5', 'isContainer': true, 'labelPos': 'top'},
    
    // 系统内的子模块
    {'id': 'input', 'label': 'Input Module', 'x': 300, 'y': 180, 'width': 200, 'height': 100, 
     'shape': 'rect', 'fill': '#e3f2fd', 'stroke': '#1976d2', 'isContainer': true, 'parent': 'system'},
    {'id': 'process', 'label': 'Process Module', 'x': 600, 'y': 180, 'width': 200, 'height': 100, 
     'shape': 'rect', 'fill': '#e8f5e9', 'stroke': '#388e3c', 'isContainer': true, 'parent': 'system'},
    {'id': 'output', 'label': 'Output Module', 'x': 900, 'y': 180, 'width': 200, 'height': 100, 
     'shape': 'rect', 'fill': '#fff3e0', 'stroke': '#e65100', 'isContainer': true, 'parent': 'system'},
    
    // 输入模块内的组件
    {'id': 'parser', 'label': 'Parser', 'x': 250, 'y': 180, 'width': 80, 'height': 40, 
     'shape': 'rect', 'fill': '#bbdefb', 'stroke': '#1565c0', 'parent': 'input'},
    {'id': 'validator', 'label': 'Validator', 'x': 350, 'y': 180, 'width': 80, 'height': 40, 
     'shape': 'rect', 'fill': '#bbdefb', 'stroke': '#1565c0', 'parent': 'input'},
    
    // 处理模块内的组件
    {'id': 'analytics', 'label': 'Analytics', 'x': 550, 'y': 180, 'width': 80, 'height': 40, 
     'shape': 'rect', 'fill': '#c8e6c9', 'stroke': '#2e7d32', 'parent': 'process'},
    {'id': 'transformer', 'label': 'Transformer', 'x': 650, 'y': 180, 'width': 80, 'height': 40, 
     'shape': 'rect', 'fill': '#c8e6c9', 'stroke': '#2e7d32', 'parent': 'process'},
    
    // 输出模块内的组件
    {'id': 'formatter', 'label': 'Formatter', 'x': 850, 'y': 180, 'width': 80, 'height': 40, 
     'shape': 'rect', 'fill': '#ffe0b2', 'stroke': '#e65100', 'parent': 'output'},
    {'id': 'renderer', 'label': 'Renderer', 'x': 950, 'y': 180, 'width': 80, 'height': 40, 
     'shape': 'rect', 'fill': '#ffe0b2', 'stroke': '#e65100', 'parent': 'output'},
    
    // --- 层级3: 决策节点 ---
    {'id': 'decision', 'label': 'Data Valid?', 'x': 600, 'y': 330, 'width': 160, 'height': 80, 
     'shape': 'diamond', 'fill': '#fff3e0', 'stroke': '#ff6f00'},
    
    // --- 层级4: 处理路径 ---
    {'id': 'path1', 'label': 'Success Path', 'x': 400, 'y': 450, 'width': 180, 'height': 80, 
     'shape': 'rect', 'fill': '#e8f5e9', 'stroke': '#4caf50'},
    {'id': 'path2', 'label': 'Error Path', 'x': 800, 'y': 450, 'width': 180, 'height': 80, 
     'shape': 'rect', 'fill': '#ffebee', 'stroke': '#f44336'},
    
    // --- 层级5: 结果处理组 ---
    {'id': 'results', 'label': 'Results', 'x': 600, 'y': 580, 'width': 800, 'height': 140, 
     'shape': 'rect', 'fill': '#f3e5f5', 'stroke': '#9c27b0', 'isContainer': true, 'labelPos': 'top'},
    
    // 结果组内的子模块
    {'id': 'storage', 'label': 'Data Storage', 'x': 350, 'y': 580, 'width': 180, 'height': 80, 
     'shape': 'rect', 'fill': '#e1bee7', 'stroke': '#8e24aa', 'isContainer': true, 'parent': 'results'},
    {'id': 'visualization', 'label': 'Visualization', 'x': 600, 'y': 580, 'width': 180, 'height': 80, 
     'shape': 'rect', 'fill': '#e1bee7', 'stroke': '#8e24aa', 'isContainer': true, 'parent': 'results'},
    {'id': 'export', 'label': 'Export', 'x': 850, 'y': 580, 'width': 180, 'height': 80, 
     'shape': 'rect', 'fill': '#e1bee7', 'stroke': '#8e24aa', 'isContainer': true, 'parent': 'results'},
    
    // 存储模块内的组件
    {'id': 'local', 'label': 'Local', 'x': 300, 'y': 580, 'width': 70, 'height': 35, 
     'shape': 'rect', 'fill': '#d1c4e9', 'stroke': '#673ab7', 'parent': 'storage'},
    {'id': 'cloud', 'label': 'Cloud', 'x': 400, 'y': 580, 'width': 70, 'height': 35, 
     'shape': 'rect', 'fill': '#d1c4e9', 'stroke': '#673ab7', 'parent': 'storage'},
    
    // 可视化模块内的组件
    {'id': 'charts', 'label': 'Charts', 'x': 550, 'y': 580, 'width': 70, 'height': 35, 
     'shape': 'rect', 'fill': '#d1c4e9', 'stroke': '#673ab7', 'parent': 'visualization'},
    {'id': 'dashboard', 'label': 'Dashboard', 'x': 650, 'y': 580, 'width': 70, 'height': 35, 
     'shape': 'rect', 'fill': '#d1c4e9', 'stroke': '#673ab7', 'parent': 'visualization'},
    
    // 导出模块内的组件
    {'id': 'pdf', 'label': 'PDF', 'x': 800, 'y': 580, 'width': 70, 'height': 35, 
     'shape': 'rect', 'fill': '#d1c4e9', 'stroke': '#673ab7', 'parent': 'export'},
    {'id': 'excel', 'label': 'Excel', 'x': 900, 'y': 580, 'width': 70, 'height': 35, 
     'shape': 'rect', 'fill': '#d1c4e9', 'stroke': '#673ab7', 'parent': 'export'},
    
    // --- 层级6: 结束节点 ---
    {'id': 'end', 'label': 'End', 'x': 600, 'y': 730, 'width': 100, 'height': 50, 
     'shape': 'ellipse', 'fill': '#ffebee', 'stroke': '#d32f2f'},
  ];
  
  // 定义连接边
  final edges = [
    // 层级间主连接
    {'from': 'start', 'to': 'system', 'label': 'init', 'stroke': '#1976d2', 'strokeWidth': 2},
    {'from': 'system', 'to': 'decision', 'label': 'validate', 'stroke': '#3f51b5', 'strokeWidth': 2},
    {'from': 'decision', 'to': 'path1', 'label': 'yes', 'stroke': '#ff6f00', 'strokeWidth': 2},
    {'from': 'decision', 'to': 'path2', 'label': 'no', 'stroke': '#ff6f00', 'strokeWidth': 2},
    {'from': 'path1', 'to': 'results', 'label': 'process', 'stroke': '#4caf50', 'strokeWidth': 2},
    {'from': 'path2', 'to': 'results', 'label': 'handle error', 'stroke': '#f44336', 'strokeWidth': 2},
    {'from': 'results', 'to': 'end', 'label': 'complete', 'stroke': '#9c27b0', 'strokeWidth': 2},
    
    // 系统内模块连接
    {'from': 'input', 'to': 'process', 'label': 'feed', 'stroke': '#1976d2', 'strokeWidth': 1.5},
    {'from': 'process', 'to': 'output', 'label': 'result', 'stroke': '#388e3c', 'strokeWidth': 1.5},
    
    // 输入模块内连接
    {'from': 'parser', 'to': 'validator', 'stroke': '#1565c0', 'strokeWidth': 1},
    
    // 处理模块内连接
    {'from': 'analytics', 'to': 'transformer', 'stroke': '#2e7d32', 'strokeWidth': 1},
    
    // 输出模块内连接
    {'from': 'formatter', 'to': 'renderer', 'stroke': '#e65100', 'strokeWidth': 1},
    
    // 结果组内模块连接
    {'from': 'storage', 'to': 'visualization', 'label': 'load', 'stroke': '#8e24aa', 'strokeWidth': 1.5},
    {'from': 'visualization', 'to': 'export', 'label': 'select', 'stroke': '#8e24aa', 'strokeWidth': 1.5},
    
    // 存储模块内连接
    {'from': 'local', 'to': 'cloud', 'label': 'sync', 'stroke': '#673ab7', 'strokeWidth': 1},
    
    // 可视化模块内连接
    {'from': 'charts', 'to': 'dashboard', 'stroke': '#673ab7', 'strokeWidth': 1},
    
    // 导出模块内连接
    {'from': 'pdf', 'to': 'excel', 'stroke': '#673ab7', 'strokeWidth': 1},
  ];
  
  // 生成SVG
  StringBuffer svg = StringBuffer();
  svg.writeln('<?xml version="1.0" encoding="UTF-8" standalone="no"?>');
  svg.writeln('<svg width="$width" height="$height" xmlns="http://www.w3.org/2000/svg">');
  
  // 添加样式和滤镜
  svg.writeln('<defs>');
  svg.writeln('<style type="text/css">');
  svg.writeln('.node rect, .node ellipse, .node path { stroke-width: 2px; }');
  svg.writeln('.edgePath path { fill: none; }');
  svg.writeln('.edgeLabel { font-family: "Helvetica Neue", Helvetica, Arial, sans-serif; font-size: 12px; font-weight: 500; }');
  svg.writeln('.nodeLabel { font-family: "Helvetica Neue", Helvetica, Arial, sans-serif; font-size: 14px; font-weight: 600; }');
  svg.writeln('.container { opacity: 0.9; }');
  svg.writeln('</style>');
  
  // 添加箭头标记
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
  
  // 绘制网格
  svg.writeln('<g class="grid" opacity="0.05">');
  for (int i = 0; i < width; i += 50) {
    svg.writeln('<line x1="$i" y1="0" x2="$i" y2="$height" stroke="#000" stroke-width="1" />');
  }
  for (int i = 0; i < height; i += 50) {
    svg.writeln('<line x1="0" y1="$i" x2="$width" y2="$i" stroke="#000" stroke-width="1" />');
  }
  svg.writeln('</g>');
  
  // 首先按层级对容器排序（从外到内）
  final Map<String, Map<String, dynamic>> nodeMap = {};
  for (final node in nodes) {
    nodeMap[node['id'] as String] = node;
  }
  
  // 计算容器深度
  Map<String, int> containerDepth = {};
  void calculateDepth(String nodeId, int depth) {
    final node = nodeMap[nodeId];
    if (node != null && node['isContainer'] == true) {
      containerDepth[nodeId] = depth;
      
      // 查找所有以该节点为父节点的容器
      for (final n in nodes) {
        if (n['parent'] == nodeId && n['isContainer'] == true) {
          calculateDepth(n['id'] as String, depth + 1);
        }
      }
    }
  }
  
  // 计算所有顶级容器的深度
  for (final node in nodes) {
    if (node['isContainer'] == true && !node.containsKey('parent')) {
      calculateDepth(node['id'] as String, 0);
    }
  }
  
  // 按深度排序容器（从外到内）
  final containers = nodes.where((node) => node['isContainer'] == true).toList()
    ..sort((a, b) {
      final depthA = containerDepth[a['id']] ?? 0;
      final depthB = containerDepth[b['id']] ?? 0;
      return depthA.compareTo(depthB);
    });
  
  // 绘制容器（从外到内）
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
  
  // 绘制边（使用贝塞尔曲线或折线，取决于连接类型）
  for (final edge in edges) {
    final fromNode = nodeMap[edge['from'] as String]!;
    final toNode = nodeMap[edge['to'] as String]!;
    
    final fromX = fromNode['x'] as int;
    final fromY = fromNode['y'] as int;
    final toX = toNode['x'] as int;
    final toY = toNode['y'] as int;
    
    final fromShape = fromNode['shape'] as String;
    final toShape = toNode['shape'] as String;
    
    final stroke = edge['stroke'] as String;
    final strokeWidth = edge['strokeWidth'] as num;
    final arrowId = 'arrowhead-${stroke.substring(1)}';
    
    // 根据节点类型和位置关系决定路径类型
    String pathData;
    List<Map<String, num>> pathPoints = [];
    
    // 检查是否从父节点到子节点或从子节点到父节点
    bool isParentChildEdge = 
      (fromNode.containsKey('parent') && fromNode['parent'] == toNode['id']) ||
      (toNode.containsKey('parent') && toNode['parent'] == fromNode['id']);
    
    // 检查是否为同一个容器内的节点
    bool isSiblingEdge = 
      fromNode.containsKey('parent') && 
      toNode.containsKey('parent') && 
      fromNode['parent'] == toNode['parent'];
    
    // 检查是否为主路径的边（层级间连接）
    bool isMainPathEdge = !isParentChildEdge && !isSiblingEdge;
    
    if (isMainPathEdge && (fromY - toY).abs() > 100) {
      // 主路径使用贝塞尔曲线
      pathPoints = [
        {'x': fromX, 'y': fromY},
        {'x': fromX, 'y': fromY + (toY - fromY) * 0.4},
        {'x': toX, 'y': toY - (toY - fromY) * 0.4},
        {'x': toX, 'y': toY}
      ];
      
      final x0 = pathPoints[0]['x']!;
      final y0 = pathPoints[0]['y']!;
      final x1 = pathPoints[1]['x']!;
      final y1 = pathPoints[1]['y']!;
      final x2 = pathPoints[2]['x']!;
      final y2 = pathPoints[2]['y']!;
      final x3 = pathPoints[3]['x']!;
      final y3 = pathPoints[3]['y']!;
      
      pathData = 'M$x0,$y0 C$x1,$y1 $x2,$y2 $x3,$y3';
    } else if (fromNode['id'] == 'decision') {
      // 决策节点的特殊路径
      final midX = toNode['id'] == 'path1' ? fromX - 50 : fromX + 50;
      pathPoints = [
        {'x': fromX, 'y': fromY},
        {'x': midX, 'y': fromY + 30},
        {'x': toX, 'y': toY - 20},
        {'x': toX, 'y': toY}
      ];
      pathData = _generatePathData(pathPoints);
    } else if (isSiblingEdge) {
      // 兄弟节点间使用直线或弧线
      if ((fromX - toX).abs() > (fromY - toY).abs()) {
        // 水平方向的连接
        pathPoints = [
          {'x': fromX, 'y': fromY},
          {'x': (fromX + toX) / 2, 'y': fromY},
          {'x': (fromX + toX) / 2, 'y': toY},
          {'x': toX, 'y': toY}
        ];
      } else {
        // 垂直方向的连接
        pathPoints = [
          {'x': fromX, 'y': fromY},
          {'x': fromX, 'y': (fromY + toY) / 2},
          {'x': toX, 'y': (fromY + toY) / 2},
          {'x': toX, 'y': toY}
        ];
      }
      pathData = _generatePathData(pathPoints);
    } else {
      // 其他类型的边使用直线
      pathData = 'M$fromX,$fromY L$toX,$toY';
      pathPoints = [
        {'x': fromX, 'y': fromY},
        {'x': toX, 'y': toY}
      ];
    }
    
    // 绘制路径
    svg.writeln('<g class="edgePath">');
    svg.writeln('<path d="$pathData" stroke="$stroke" stroke-width="$strokeWidth" marker-end="url(#$arrowId)" />');
    
    // 如果有标签，则在中间添加
    if (edge.containsKey('label')) {
      final label = edge['label'] as String;
      
      // 计算标签位置
      double midX, midY;
      if (pathPoints.length >= 4) {
        // 贝塞尔曲线或复杂路径
        midX = 0;
        midY = 0;
        for (final point in pathPoints) {
          midX += point['x']!;
          midY += point['y']!;
        }
        midX /= pathPoints.length;
        midY /= pathPoints.length;
        midY -= 10; // 向上偏移一点
      } else {
        // 简单路径
        midX = (fromX + toX) / 2;
        midY = (fromY + toY) / 2 - 10;
      }
      
      final labelWidth = math.max(label.length * 6 + 10, 40);
      
      svg.writeln('<rect x="${midX - labelWidth/2}" y="${midY-10}" width="$labelWidth" height="20" rx="10" ry="10" fill="white" stroke="$stroke" stroke-width="1" opacity="0.9" />');
      svg.writeln('<text x="$midX" y="$midY" text-anchor="middle" dominant-baseline="middle" fill="$stroke" class="edgeLabel">$label</text>');
    }
    
    svg.writeln('</g>');
  }
  
  // 绘制节点（非容器）
  final regularNodes = nodes.where((node) => node['isContainer'] != true).toList();
  for (final node in regularNodes) {
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

// 生成路径数据
String _generatePathData(List<Map<String, num>> points) {
  final path = StringBuffer();
  bool first = true;
  
  for (final point in points) {
    final x = point['x']!;
    final y = point['y']!;
    
    if (first) {
      path.write('M$x,$y');
      first = false;
    } else {
      path.write(' L$x,$y');
    }
  }
  
  return path.toString();
} 