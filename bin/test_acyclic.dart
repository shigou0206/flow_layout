import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/graph/alg/acyclic.dart';

void main() {
  print('测试无环化算法');
  
  testDFSFAS();
  testGreedyFAS();
  testUndo();
  
  print('测试完成');
}

/// 测试使用DFS算法找到反馈弧集
void testDFSFAS() {
  print('\n=== 测试DFS反馈弧集算法 ===');
  
  // 创建一个有环图
  final g = Graph();
  
  // 添加节点
  g.setNode('a', {});
  g.setNode('b', {});
  g.setNode('c', {});
  g.setNode('d', {});
  
  // 添加边，形成环: a -> b -> c -> a 和 c -> d -> c
  g.setEdge('a', 'b', {'weight': 1});
  g.setEdge('b', 'c', {'weight': 1});
  g.setEdge('c', 'a', {'weight': 1}); // 形成环
  g.setEdge('c', 'd', {'weight': 1});
  g.setEdge('d', 'c', {'weight': 1}); // 形成环
  
  print('原始图:');
  printGraph(g);
  
  // 运行无环化算法
  Acyclic.run(g);
  
  print('\n应用无环化算法后:');
  printGraph(g);
  
  // 验证环是否被移除
  final hasCycleAfter = detectCycle(g);
  if (hasCycleAfter) {
    print('\n❌ 图仍然包含环');
  } else {
    print('\n✅ 图已变为无环图');
  }
  
  // 验证反转的边
  final reversedEdges = g.edges().where((edge) {
    final edgeData = g.edge(edge);
    return edgeData != null && edgeData is Map && 
           edgeData.containsKey('reversed') && 
           edgeData['reversed'] == true;
  }).toList();
  
  print('\n反转的边:');
  for (final edge in reversedEdges) {
    print('  ${edge['v']} -> ${edge['w']}: ${g.edge(edge)}');
  }
}

/// 测试使用贪婪算法找到反馈弧集
void testGreedyFAS() {
  print('\n=== 测试贪婪反馈弧集算法 ===');
  
  // 创建一个有环图，并指定使用贪婪算法
  final g = Graph();
  g.setGraph({'acyclicer': 'greedy'});
  
  // 添加节点
  g.setNode('a', {});
  g.setNode('b', {});
  g.setNode('c', {});
  g.setNode('d', {});
  g.setNode('e', {});
  
  // 添加边，形成复杂环
  g.setEdge('a', 'b', {'weight': 3});
  g.setEdge('b', 'c', {'weight': 2});
  g.setEdge('c', 'd', {'weight': 1});
  g.setEdge('d', 'e', {'weight': 1});
  g.setEdge('e', 'a', {'weight': 1}); // 形成环
  g.setEdge('a', 'c', {'weight': 4}); // 跨边
  g.setEdge('c', 'e', {'weight': 5}); // 跨边
  
  print('原始图:');
  printGraph(g);
  
  // 运行无环化算法
  Acyclic.run(g);
  
  print('\n应用贪婪无环化算法后:');
  printGraph(g);
  
  // 验证环是否被移除
  final hasCycleAfter = detectCycle(g);
  if (hasCycleAfter) {
    print('\n❌ 图仍然包含环');
  } else {
    print('\n✅ 图已变为无环图');
  }
  
  // 验证反转的边
  final reversedEdges = g.edges().where((edge) {
    final edgeData = g.edge(edge);
    return edgeData != null && edgeData is Map && 
           edgeData.containsKey('reversed') && 
           edgeData['reversed'] == true;
  }).toList();
  
  print('\n反转的边(贪婪算法会尝试最小化反转边的权重总和):');
  for (final edge in reversedEdges) {
    print('  ${edge['v']} -> ${edge['w']}: ${g.edge(edge)}');
  }
}

/// 测试恢复原图
void testUndo() {
  print('\n=== 测试恢复原图 ===');
  
  // 创建一个有环图
  final g = Graph();
  
  // 添加节点
  g.setNode('a', {});
  g.setNode('b', {});
  g.setNode('c', {});
  
  // 添加边，形成环
  g.setEdge('a', 'b', {'weight': 1});
  g.setEdge('b', 'c', {'weight': 1});
  g.setEdge('c', 'a', {'weight': 1}); // 形成环
  
  print('原始图:');
  printGraph(g);
  
  // 保存原始边集
  final originalEdges = g.edges().map((e) => '${e['v']} -> ${e['w']}').toSet();
  
  // 运行无环化算法
  Acyclic.run(g);
  
  print('\n应用无环化算法后:');
  printGraph(g);
  
  // 恢复原图
  Acyclic.undo(g);
  
  print('\n恢复原图后:');
  printGraph(g);
  
  // 验证是否恢复了原始边
  final restoredEdges = g.edges().map((e) => '${e['v']} -> ${e['w']}').toSet();
  
  if (setEquals(originalEdges, restoredEdges)) {
    print('\n✅ 成功恢复到原始图');
  } else {
    print('\n❌ 未能恢复到原始图');
    print('原始边: $originalEdges');
    print('当前边: $restoredEdges');
    print('缺失边: ${originalEdges.difference(restoredEdges)}');
    print('多余边: ${restoredEdges.difference(originalEdges)}');
  }
}

/// 简单的环检测算法
bool detectCycle(Graph g) {
  final visited = <String, bool>{};
  final stack = <String, bool>{};
  
  bool hasCycle(String v) {
    if (!visited.containsKey(v)) {
      visited[v] = true;
      stack[v] = true;
      
      final successors = g.successors(v);
      if (successors != null) {
        for (final w in successors) {
          if (!visited.containsKey(w) && hasCycle(w)) {
            return true;
          } else if (stack.containsKey(w)) {
            return true;
          }
        }
      }
    }
    
    stack.remove(v);
    return false;
  }
  
  for (final v in g.getNodes()) {
    if (!visited.containsKey(v) && hasCycle(v)) {
      return true;
    }
  }
  
  return false;
}

void printGraph(Graph g) {
  print('  节点:');
  for (final node in g.getNodes()) {
    print('    $node: ${g.node(node)}');
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

/// 判断两个集合是否相等
bool setEquals<T>(Set<T> set1, Set<T> set2) {
  return set1.length == set2.length && 
         set1.every((element) => set2.contains(element));
} 