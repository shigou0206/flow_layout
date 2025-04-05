import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/graph/alg/coordinate_system.dart';

void main() {
  print('测试坐标系统调整功能\n');
  
  testLRLayout();
  testRLLayout();
  testBTLayout();
  testTBLayout();
  
  print('\n测试完成');
}

void testLRLayout() {
  print('=== 测试 LR 布局 ===');
  final g = createTestGraph('lr');
  print('原始图:');
  printGraphCoordinates(g);
  
  CoordinateSystem.adjust(g);
  print('\n调整后:');
  printGraphCoordinates(g);
  
  CoordinateSystem.undo(g);
  print('\n恢复后:');
  printGraphCoordinates(g);
  
  print('\n=== LR 布局测试完成 ===\n');
}

void testRLLayout() {
  print('=== 测试 RL 布局 ===');
  final g = createTestGraph('rl');
  print('原始图:');
  printGraphCoordinates(g);
  
  CoordinateSystem.adjust(g);
  print('\n调整后:');
  printGraphCoordinates(g);
  
  CoordinateSystem.undo(g);
  print('\n恢复后:');
  printGraphCoordinates(g);
  
  print('\n=== RL 布局测试完成 ===\n');
}

void testBTLayout() {
  print('=== 测试 BT 布局 ===');
  final g = createTestGraph('bt');
  print('原始图:');
  printGraphCoordinates(g);
  
  CoordinateSystem.adjust(g);
  print('\n调整后:');
  printGraphCoordinates(g);
  
  CoordinateSystem.undo(g);
  print('\n恢复后:');
  printGraphCoordinates(g);
  
  print('\n=== BT 布局测试完成 ===\n');
}

void testTBLayout() {
  print('=== 测试 TB 布局 ===');
  final g = createTestGraph('tb');
  print('原始图:');
  printGraphCoordinates(g);
  
  CoordinateSystem.adjust(g);
  print('\n调整后:');
  printGraphCoordinates(g);
  
  CoordinateSystem.undo(g);
  print('\n恢复后:');
  printGraphCoordinates(g);
  
  print('\n=== TB 布局测试完成 ===\n');
}

Graph createTestGraph(String rankdir) {
  final g = Graph();
  
  // 设置图的方向
  g.setGraph({'rankdir': rankdir});
  
  // 添加节点
  g.setNode('A', {'x': 10, 'y': 20, 'width': 30, 'height': 40});
  g.setNode('B', {'x': 50, 'y': 60, 'width': 35, 'height': 45});
  g.setNode('C', {'x': 100, 'y': 120, 'width': 25, 'height': 35});
  
  // 添加边
  g.setEdge('A', 'B', {
    'x': 30, 
    'y': 40,
    'width': 5, 
    'height': 2,
    'points': [
      {'x': 10, 'y': 20},
      {'x': 30, 'y': 40},
      {'x': 50, 'y': 60}
    ]
  });
  
  g.setEdge('B', 'C', {
    'x': 75, 
    'y': 90,
    'width': 5, 
    'height': 2,
    'points': [
      {'x': 50, 'y': 60},
      {'x': 75, 'y': 90},
      {'x': 100, 'y': 120}
    ]
  });
  
  return g;
}

void printGraphCoordinates(Graph g) {
  print('  图配置: ${g.graph()}');
  
  print('  节点坐标:');
  for (final node in g.getNodes()) {
    final nodeData = g.node(node);
    print('    $node: x=${nodeData?['x']}, y=${nodeData?['y']}, '
          'width=${nodeData?['width']}, height=${nodeData?['height']}');
  }
  
  print('  边坐标和点:');
  for (final edge in g.edges()) {
    final edgeData = g.edge(edge);
    print('    ${edge['v']} -> ${edge['w']}: '
          'x=${edgeData?['x']}, y=${edgeData?['y']}, '
          'width=${edgeData?['width']}, height=${edgeData?['height']}');
    
    if (edgeData != null && edgeData.containsKey('points')) {
      print('      点:');
      final points = edgeData['points'] as List;
      for (int i = 0; i < points.length; i++) {
        final point = points[i];
        print('        $i: x=${point['x']}, y=${point['y']}');
      }
    }
  }
} 