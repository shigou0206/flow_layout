import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/layout.dart';

void main() {
  print('测试完整的布局功能\n');
  
  // 创建一个简单的图进行测试
  testSimpleGraph();
  
  // 测试一个更复杂的图
  testComplexGraph();
  
  print('\n测试完成');
}

void testSimpleGraph() {
  print('=== 测试简单图布局 ===');
  
  final g = Graph();
  
  // 添加节点
  g.setNode('1', {'label': 'Node 1', 'width': 30, 'height': 30});
  g.setNode('2', {'label': 'Node 2', 'width': 30, 'height': 30});
  g.setNode('3', {'label': 'Node 3', 'width': 30, 'height': 30});
  g.setNode('4', {'label': 'Node 4', 'width': 30, 'height': 30});
  
  // 添加边
  g.setEdge('1', '2');
  g.setEdge('1', '3');
  g.setEdge('2', '4');
  g.setEdge('3', '4');
  
  // 设置图形属性
  g.setGraph({
    'rankdir': 'TB',
    'nodesep': 50,
    'ranksep': 50,
    'marginx': 20,
    'marginy': 20
  });
  
  // 执行布局
  try {
    layout(g, {'debugTiming': true});
    
    // 输出布局结果
    print('\n布局结果:');
    for (final v in g.getNodes()) {
      final node = g.node(v);
      print('节点 $v: x=${node?['x']}, y=${node?['y']}, width=${node?['width']}, height=${node?['height']}');
    }
    
    print('\n边的路径点:');
    for (final e in g.edges()) {
      final edge = g.edge(e);
      print('边 ${e['v']} -> ${e['w']}:');
      if (edge != null && edge.containsKey('points')) {
        final points = edge['points'];
        if (points is List) {
          for (int i = 0; i < points.length; i++) {
            if (points[i] is Map) {
              final point = points[i] as Map;
              print('  点 $i: x=${point['x']}, y=${point['y']}');
            }
          }
        }
      }
    }
  } catch (e, stackTrace) {
    print('布局出错: $e');
    print(stackTrace);
  }
  
  print('=== 简单图布局测试完成 ===\n');
}

void testComplexGraph() {
  print('=== 测试复杂图布局 ===');
  
  final g = Graph();
  g.isCompound = true;
  
  // 添加节点和子节点
  g.setNode('A', {'label': 'A', 'width': 40, 'height': 40});
  g.setNode('B', {'label': 'B', 'width': 40, 'height': 40});
  g.setNode('C', {'label': 'C', 'width': 40, 'height': 40});
  g.setNode('D', {'label': 'D', 'width': 40, 'height': 40});
  g.setNode('E', {'label': 'E', 'width': 40, 'height': 40});
  g.setNode('F', {'label': 'F', 'width': 40, 'height': 40});
  g.setNode('G', {'label': 'G', 'width': 40, 'height': 40});
  
  // 创建子图
  g.setNode('subgraph1', {});
  g.setParent('B', 'subgraph1');
  g.setParent('C', 'subgraph1');
  
  // 添加边
  g.setEdge('A', 'B', {'weight': 2});
  g.setEdge('A', 'C');
  g.setEdge('B', 'D', {'minlen': 2});
  g.setEdge('C', 'D');
  g.setEdge('D', 'E');
  g.setEdge('D', 'F');
  g.setEdge('E', 'G');
  g.setEdge('F', 'G');
  
  // 设置图形属性
  g.setGraph({
    'rankdir': 'LR',  // 左到右布局
    'nodesep': 70,
    'ranksep': 50,
    'marginx': 20,
    'marginy': 20
  });
  
  // 执行布局
  try {
    layout(g, {'debugTiming': true});
    
    // 输出布局结果
    print('\n布局结果:');
    for (final v in g.getNodes()) {
      if (g.children(v)?.isNotEmpty != true) {  // 只显示非子图节点
        final node = g.node(v);
        print('节点 $v: x=${node?['x']}, y=${node?['y']}, ' 
              'width=${node?['width']}, height=${node?['height']}, '
              'rank=${node?['rank']}, order=${node?['order']}');
      }
    }
    
    // 显示子图信息
    print('\n子图信息:');
    for (final sg in g.getNodes()) {
      if (g.children(sg)?.isNotEmpty == true) {
        final node = g.node(sg);
        print('子图 $sg: x=${node?['x']}, y=${node?['y']}, ' 
              'width=${node?['width']}, height=${node?['height']}');
        print('  子节点: ${g.children(sg)}');
      }
    }
  } catch (e, stackTrace) {
    print('布局出错: $e');
    print(stackTrace);
  }
  
  print('=== 复杂图布局测试完成 ===');
} 