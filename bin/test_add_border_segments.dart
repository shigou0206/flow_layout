import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/graph/alg/add_border_segments.dart';

void main() {
  print('测试添加边界段功能');
  
  testAddBorderSegments();
  
  print('测试完成');
}

void testAddBorderSegments() {
  print('\n=== 测试添加边界段 ===');
  
  // 创建一个复合图
  final g = Graph(isCompound: true);
  
  // 添加节点
  g.setNode('root', {'minRank': 0, 'maxRank': 3});
  g.setNode('a', {'rank': 0});
  g.setNode('b', {'rank': 1});
  g.setNode('c', {'rank': 2});
  g.setNode('d', {'rank': 3});
  g.setNode('subgraph1', {'minRank': 1, 'maxRank': 2});
  g.setNode('subgraph2', {'minRank': 0, 'maxRank': 3});
  
  // 设置父节点关系
  g.setParent('a', 'root');
  g.setParent('d', 'root');
  g.setParent('b', 'subgraph1');
  g.setParent('c', 'subgraph1');
  g.setParent('subgraph1', 'subgraph2');
  g.setParent('subgraph2', 'root');
  
  // 添加边
  g.setEdge('a', 'b', {'weight': 1});
  g.setEdge('b', 'c', {'weight': 1});
  g.setEdge('c', 'd', {'weight': 1});
  
  print('原始图:');
  printGraph(g);
  
  // 应用添加边界段算法
  addBorderSegments(g);
  
  print('\n应用添加边界段算法后:');
  printGraph(g);
  
  // 验证是否为所有有minRank和maxRank的节点添加了边界节点
  for (final node in ['root', 'subgraph1', 'subgraph2']) {
    final nodeData = g.node(node);
    print('\n节点 $node 的边界节点:');
    if (nodeData is Map && 
        nodeData.containsKey('borderLeft') && 
        nodeData.containsKey('borderRight')) {
      
      final borderLeft = nodeData['borderLeft'] as List;
      final borderRight = nodeData['borderRight'] as List;
      
      print('  左边界节点:');
      for (int i = 0; i < borderLeft.length; i++) {
        if (borderLeft[i] != null) {
          final borderData = g.node(borderLeft[i]);
          print('    Rank $i: ${borderLeft[i]} - $borderData');
        }
      }
      
      print('  右边界节点:');
      for (int i = 0; i < borderRight.length; i++) {
        if (borderRight[i] != null) {
          final borderData = g.node(borderRight[i]);
          print('    Rank $i: ${borderRight[i]} - $borderData');
        }
      }
      
      // 验证边界节点之间是否有边连接
      print('  边界节点边:');
      for (int i = 1; i < borderLeft.length; i++) {
        if (borderLeft[i] != null && borderLeft[i-1] != null) {
          final hasEdge = g.hasEdge(borderLeft[i-1], borderLeft[i]);
          print('    ${borderLeft[i-1]} -> ${borderLeft[i]}: ${hasEdge ? '✅' : '❌'}');
        }
      }
      for (int i = 1; i < borderRight.length; i++) {
        if (borderRight[i] != null && borderRight[i-1] != null) {
          final hasEdge = g.hasEdge(borderRight[i-1], borderRight[i]);
          print('    ${borderRight[i-1]} -> ${borderRight[i]}: ${hasEdge ? '✅' : '❌'}');
        }
      }
    } else {
      print('  ❌ 节点没有边界节点');
    }
  }
  
  // 验证边界节点是否有正确的父节点
  final allBorderNodes = g.getNodes().where((node) {
    final nodeData = g.node(node);
    return nodeData != null && nodeData is Map && 
           nodeData.containsKey('dummy') && 
           nodeData['dummy'] == 'border';
  }).toList();
  
  print('\n验证边界节点的父节点:');
  for (final borderNode in allBorderNodes) {
    final parent = g.parent(borderNode);
    final borderData = g.node(borderNode);
    print('  $borderNode (${borderData?['borderType']}, rank: ${borderData?['rank']}): 父节点 = $parent');
  }
  
  // 检查是否为每个层级都添加了边界节点
  bool allRanksHaveBorders = true;
  for (final node in ['root', 'subgraph1', 'subgraph2']) {
    final nodeData = g.node(node);
    if (nodeData is Map && 
        nodeData.containsKey('minRank') && 
        nodeData.containsKey('maxRank')) {
      
      final minRank = nodeData['minRank'] as int;
      final maxRank = nodeData['maxRank'] as int;
      
      for (int rank = minRank; rank <= maxRank; rank++) {
        final borderLeft = nodeData['borderLeft'] as List;
        final borderRight = nodeData['borderRight'] as List;
        
        if (borderLeft.length <= rank || borderLeft[rank] == null ||
            borderRight.length <= rank || borderRight[rank] == null) {
          print('\n❌ 节点 $node 在rank $rank 缺少边界节点');
          allRanksHaveBorders = false;
        }
      }
    }
  }
  
  if (allRanksHaveBorders) {
    print('\n✅ 所有需要边界节点的层级都有边界节点');
  }
}

void printGraph(Graph g) {
  print('  节点:');
  for (final node in g.getNodes()) {
    print('    $node: ${g.node(node)}');
    if (g.isCompound) {
      final parent = g.parent(node);
      if (parent != null) {
        print('      父节点: $parent');
      }
    }
  }
  
  print('  边:');
  final edges = g.edges();
  if (edges.isNotEmpty) {
    for (final edge in edges) {
      print('    ${edge['v']} -> ${edge['w']}: ${g.edge(edge)}');
    }
  } else {
    print('    没有边');
  }
} 