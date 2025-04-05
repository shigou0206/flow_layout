import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/graph/alg/normalize.dart' as normalize;

void main() {
  print('测试normalize功能');
  
  // 测试规范化和逆规范化
  testNormalizeAndUndo();
  
  print('测试完成');
}

void testNormalizeAndUndo() {
  print('\n=== 测试规范化和逆规范化 ===');
  
  // 创建带有长边的图
  final g = Graph();
  
  // 添加节点并设置rank
  g.setNode('a', {'rank': 0});
  g.setNode('b', {'rank': 1});
  g.setNode('c', {'rank': 3});
  g.setNode('d', {'rank': 2});
  
  // 添加边，其中a->c跨越多层
  g.setEdge('a', 'b', {'weight': 1});     // 正常边
  g.setEdge('a', 'c', {'weight': 2});     // 长边，跨越3层
  g.setEdge('d', 'c', {'weight': 1});     // 普通边
  
  print('原始图:');
  printGraph(g);
  
  // 应用规范化
  normalize.run(g);
  
  print('\n规范化后的图:');
  printGraph(g);
  
  // 验证虚拟节点是否已添加
  final dummyNodes = g.getNodes().where((node) {
    final nodeData = g.node(node);
    return nodeData != null && nodeData.containsKey('dummy');
  }).toList();
  
  print('\n虚拟节点:');
  for (final dummy in dummyNodes) {
    final dummyData = g.node(dummy);
    print('  $dummy: $dummyData');
  }
  
  // 验证所有边现在都是短边（只跨一层）
  bool allEdgesAreShort = true;
  final edges = g.edges();
  if (edges != null) {
    for (final edge in edges) {
      final vRank = g.node(edge['v'])['rank'] as int;
      final wRank = g.node(edge['w'])['rank'] as int;
      
      if ((wRank - vRank).abs() != 1) {
        print('发现长边: ${edge['v']} -> ${edge['w']} (rank差: ${(wRank - vRank).abs()})');
        allEdgesAreShort = false;
      }
    }
  }
  
  if (allEdgesAreShort) {
    print('\n✅ 所有边现在都是短边（只跨一层）');
  } else {
    print('\n❌ 仍有边跨越多层');
  }
  
  // 验证是否创建了虚拟节点链
  final graphData = g.graph();
  if (graphData != null && graphData.containsKey('dummyChains')) {
    final dummyChains = graphData['dummyChains'] as List;
    print('\n虚拟节点链: ${dummyChains.length}个');
    
    for (final dummyChain in dummyChains) {
      print('  链起始于: $dummyChain');
    }
  }
  
  // 应用逆规范化
  normalize.undo(g);
  
  print('\n逆规范化后的图:');
  printGraph(g);
  
  // 验证虚拟节点是否被移除
  final remainingDummyNodes = g.getNodes().where((node) {
    final nodeData = g.node(node);
    return nodeData != null && nodeData.containsKey('dummy');
  }).toList();
  
  if (remainingDummyNodes.isEmpty) {
    print('\n✅ 所有虚拟节点都已移除');
  } else {
    print('\n❌ 仍有虚拟节点未移除:');
    for (final dummy in remainingDummyNodes) {
      print('  $dummy');
    }
  }
  
  // 验证原始边是否已恢复
  bool hasEdgeAC = false;
  final edgesAfterUndo = g.edges();
  if (edgesAfterUndo != null) {
    for (final edge in edgesAfterUndo) {
      if (edge['v'] == 'a' && edge['w'] == 'c') {
        hasEdgeAC = true;
        break;
      }
    }
  }
  
  if (hasEdgeAC) {
    print('\n✅ 原始长边(a->c)已恢复');
  } else {
    print('\n❌ 原始长边(a->c)未恢复');
  }
}

void printGraph(Graph g) {
  print('  节点:');
  for (final node in g.getNodes()) {
    print('    $node: ${g.node(node)}');
  }
  
  print('  边:');
  final edges = g.edges();
  if (edges != null) {
    for (final edge in edges) {
      print('    ${edge['v']} -> ${edge['w']}: ${g.edge(edge)}');
    }
  }
} 