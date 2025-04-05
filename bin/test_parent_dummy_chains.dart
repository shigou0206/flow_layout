import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/graph/alg/normalize.dart' as normalize;
import 'package:flow_layout/graph/alg/parent_dummy_chains.dart' as pdc;

void main() {
  print('测试parent_dummy_chains功能');
  
  // 测试为虚拟节点链设置父节点
  testParentDummyChains();
  
  print('测试完成');
}

void testParentDummyChains() {
  print('\n=== 测试为虚拟节点链设置父节点 ===');
  
  // 创建一个compound图
  final g = Graph(isCompound: true);
  
  // 添加节点并设置rank
  g.setNode('root', {'rank': 0, 'minRank': 0, 'maxRank': 4});
  g.setNode('a', {'rank': 1, 'minRank': 1, 'maxRank': 1});
  g.setNode('b', {'rank': 2, 'minRank': 2, 'maxRank': 2});
  g.setNode('c', {'rank': 3, 'minRank': 3, 'maxRank': 3});
  g.setNode('d', {'rank': 4, 'minRank': 4, 'maxRank': 4});
  
  // 设置父节点关系
  g.setParent('a', 'root');
  g.setParent('b', 'root');
  g.setParent('c', 'root');
  g.setParent('d', 'root');
  
  // 添加边，包含一条跨越多层的长边
  g.setEdge('a', 'b', {'weight': 1});  // 短边
  g.setEdge('a', 'd', {'weight': 2});  // 长边，跨越3层
  g.setEdge('c', 'd', {'weight': 1});  // 短边
  
  print('原始图:');
  printGraph(g);
  
  // 应用规范化，创建虚拟节点
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
    
    // 显示当前父节点
    final parent = g.parent(dummy);
    print('  └─ 父节点: $parent');
  }
  
  // 应用parentDummyChains
  pdc.parentDummyChains(g);
  
  print('\n应用parentDummyChains后:');
  
  print('\n虚拟节点及其父节点:');
  for (final dummy in dummyNodes) {
    final dummyData = g.node(dummy);
    print('  $dummy: $dummyData');
    
    // 显示当前父节点
    final parent = g.parent(dummy);
    print('  └─ 父节点: $parent');
  }
  
  // 验证虚拟节点是否分配了正确的父节点
  bool allDummyNodesHaveParents = true;
  for (final dummy in dummyNodes) {
    final parent = g.parent(dummy);
    if (parent == null) {
      print('\n❌ 虚拟节点 $dummy 没有分配父节点');
      allDummyNodesHaveParents = false;
    }
  }
  
  if (allDummyNodesHaveParents) {
    print('\n✅ 所有虚拟节点都被分配了父节点');
  }
  
  // 应用逆规范化，移除虚拟节点
  normalize.undo(g);
  
  print('\n逆规范化后的图:');
  printGraph(g);
}

void printGraph(Graph g) {
  print('  节点:');
  for (final node in g.getNodes()) {
    print('    $node: ${g.node(node)}');
    if (g.isCompound) {
      final parent = g.parent(node);
      print('      父节点: $parent');
    }
  }
  
  print('  边:');
  final edges = g.edges();
  if (edges != null) {
    for (final edge in edges) {
      print('    ${edge['v']} -> ${edge['w']}: ${g.edge(edge)}');
    }
  }
} 