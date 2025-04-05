import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/graph/alg/nesting_graph.dart';

void main() {
  print('测试嵌套图算法');
  
  testNestingGraph();
  
  print('测试完成');
}

void testNestingGraph() {
  print('\n=== 测试嵌套图算法 ===');
  
  // 创建一个复合图
  final g = Graph(isCompound: true);
  
  // 添加节点
  g.setNode('a', {'minlen': 1});
  g.setNode('b', {'minlen': 1});
  g.setNode('c', {'minlen': 1});
  g.setNode('d', {'minlen': 1});
  g.setNode('subgraph1', {});
  g.setNode('subgraph2', {});
  
  // 设置父节点关系
  g.setParent('a', 'subgraph1');
  g.setParent('b', 'subgraph1');
  g.setParent('c', 'subgraph2');
  g.setParent('d', 'subgraph2');
  
  // 添加边
  g.setEdge('a', 'b', {'weight': 1, 'minlen': 1});
  g.setEdge('b', 'c', {'weight': 1, 'minlen': 1});
  g.setEdge('c', 'd', {'weight': 1, 'minlen': 1});
  
  print('原始图:');
  printGraph(g);
  printEdges(g);
  
  // 运行嵌套图算法
  NestingGraph.run(g);
  
  print('\n应用嵌套图算法后:');
  printGraph(g);
  printEdges(g);
  
  // 验证边界节点和嵌套边是否已添加
  final borderNodes = g.getNodes().where((node) {
    final nodeData = g.node(node);
    return nodeData != null && nodeData is Map && 
           nodeData.containsKey('dummy') && 
           nodeData['dummy'] == 'border';
  }).toList();
  
  print('\n边界节点:');
  for (final border in borderNodes) {
    final borderData = g.node(border);
    final parent = g.parent(border);
    print('  $border: $borderData');
    print('  └─ 父节点: $parent');
  }
  
  final nestingEdges = g.edges().where((edge) {
    final edgeData = g.edge(edge);
    return edgeData != null && edgeData is Map && 
           edgeData.containsKey('nestingEdge') && 
           edgeData['nestingEdge'] == true;
  }).toList();
  
  print('\n嵌套边:');
  for (final edge in nestingEdges) {
    print('  ${edge['v']} -> ${edge['w']}: ${g.edge(edge)}');
  }
  
  // 验证每个子图是否都有顶部和底部边界节点
  bool allSubgraphsHaveBorders = true;
  for (final subgraph in ['subgraph1', 'subgraph2']) {
    final sgData = g.node(subgraph);
    if (sgData == null || !sgData.containsKey('borderTop') || !sgData.containsKey('borderBottom')) {
      print('\n❌ 子图 $subgraph 没有正确分配边界节点');
      allSubgraphsHaveBorders = false;
    }
  }
  
  if (allSubgraphsHaveBorders) {
    print('\n✅ 所有子图都被分配了边界节点');
  }
  
  // 检查nestingRoot是否已添加到图中
  final graphData = g.graph();
  if (graphData != null && graphData.containsKey('nestingRoot')) {
    print('\n✅ 嵌套根节点已添加: ${graphData['nestingRoot']}');
  } else {
    print('\n❌ 嵌套根节点未添加');
  }
  
  // 检查nodeRankFactor是否已设置
  if (graphData != null && graphData.containsKey('nodeRankFactor')) {
    print('\n✅ 节点等级因子已设置: ${graphData['nodeRankFactor']}');
  } else {
    print('\n❌ 节点等级因子未设置');
  }
  
  // 清理嵌套图
  NestingGraph.cleanup(g);
  
  print('\n清理嵌套图后:');
  printGraph(g);
  printEdges(g);
  
  // 验证所有嵌套边和嵌套根节点是否已移除
  final remainingNestingEdges = g.edges().where((edge) {
    final edgeData = g.edge(edge);
    return edgeData != null && edgeData is Map && 
           edgeData.containsKey('nestingEdge') && 
           edgeData['nestingEdge'] == true;
  }).toList();
  
  if (remainingNestingEdges.isEmpty) {
    print('\n✅ 所有嵌套边已移除');
  } else {
    print('\n❌ 仍有 ${remainingNestingEdges.length} 条嵌套边未移除');
  }
  
  final cleanedGraphData = g.graph();
  if (cleanedGraphData == null || !cleanedGraphData.containsKey('nestingRoot')) {
    print('\n✅ 嵌套根节点已移除');
  } else {
    print('\n❌ 嵌套根节点未被移除');
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
}

void printEdges(Graph g) {
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