import 'package:test/test.dart';
import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/graph/alg/acyclic.dart';
import 'dart:math' as math;

void main() {
  const ACYCLICERS = [
    "greedy",
    "dfs",
    "unknown-should-still-work"
  ];
  
  late Graph g;

  setUp(() {
    g = Graph(isMultigraph: true) // 与JS版本一致，使用多边图模式
      ..setDefaultEdgeLabel((_) => {'minlen': 1, 'weight': 1});
  });

  for (final acyclicer in ACYCLICERS) {
    group(acyclicer, () {
      setUp(() {
        g.setGraph({'acyclicer': acyclicer});
      });

      group('run', () {
        test('does not change an already acyclic graph', () {
          g.setPath(['a', 'b', 'd']);
          g.setPath(['a', 'c', 'd']);
          Acyclic.run(g);
          
          // 与JS版本一致，通过排序边列表比较
          final results = sortedEdgeList(g);
          
          // 注意：我们只关心边的源和目标节点，不关心方向
          expect(results.map((e) => '${e['v']}-${e['w']}').toSet(), 
                 equals({'a-b', 'a-c', 'b-d', 'c-d'}.toSet()));
        });

        test('breaks cycles in the input graph', () {
          g.setPath(['a', 'b', 'c', 'd', 'a']);
          Acyclic.run(g);
          
          // 确认图中没有环
          expect(findCycles(g), isEmpty);
        });

        test('creates a multi-edge where necessary', () {
          g.setPath(['a', 'b', 'a']);
          Acyclic.run(g);
          
          // 确认图中没有环
          expect(findCycles(g), isEmpty);
          
          // 检查边的总数
          expect(g.edges().length, equals(2));
          
          // 检查是否保留了多重边
          final hasMultiEdge = (g.outEdges('a', 'b')?.length ?? 0) >= 2 || 
                              (g.outEdges('b', 'a')?.length ?? 0) >= 2;
          expect(hasMultiEdge, isTrue);
        });
      });

      group('undo', () {
        test('does not change edges where the original graph was acyclic', () {
          g.setEdge('a', 'b', {'minlen': 2, 'weight': 3});
          Acyclic.run(g);
          Acyclic.undo(g);
          
          expect(g.edge('a', 'b'), equals({'minlen': 2, 'weight': 3}));
          expect(g.edges().length, equals(1));
        });

        test('can restore previously reversed edges', () {
          g.setEdge('a', 'b', {'minlen': 2, 'weight': 3});
          g.setEdge('b', 'a', {'minlen': 3, 'weight': 4});
          
          Acyclic.run(g);
          Acyclic.undo(g);
          
          // 确认两条边都恢复了
          expect(g.hasEdge('a', 'b'), isTrue);
          expect(g.hasEdge('b', 'a'), isTrue);
          
          // 检查边的属性是否正确
          expect(g.edge('a', 'b')?['minlen'], equals(2));
          expect(g.edge('a', 'b')?['weight'], equals(3));
          expect(g.edge('b', 'a')?['minlen'], equals(3));
          expect(g.edge('b', 'a')?['weight'], equals(4));
          
          // 检查边的数量
          expect(g.edges().length, equals(2));
        });
      });
    });
  }

  group('greedy-specific functionality', () {
    test('prefers to break cycles at low-weight edges', () {
      // 使用新的图实例，确保状态干净
      g = Graph(isMultigraph: true);
      g.setGraph({'acyclicer': 'greedy'});
      
      // 创建一个简单的三节点环路
      g.setEdge('a', 'b', {'weight': 3});
      g.setEdge('b', 'c', {'weight': 2});
      g.setEdge('c', 'a', {'weight': 1}); // 最低权重的边
      
      print('Before run: ${g.edges().map((e) => '${e['v']}->${e['w']}').join(', ')}');
      print('Before run: c->a exists: ${g.hasEdge('c', 'a')}');
      
      expect(g.edges().length, equals(3));
      
      Acyclic.run(g);
      
      print('After run: ${g.edges().map((e) => '${e['v']}->${e['w']}').join(', ')}');
      print('After run: c->a exists: ${g.hasEdge('c', 'a')}');
      print('After run: a->c exists: ${g.hasEdge('a', 'c')}');
      
      // 确认图中没有环
      expect(findCycles(g), isEmpty);
      
      // 低权重的边应该被反转
      expect(g.hasEdge('c', 'a'), isFalse, reason: 'The lowest weight edge c->a should be reversed');
      expect(g.hasEdge('a', 'c'), isTrue, reason: 'The reversed direction a->c should exist');
      
      // 其他边应保持原样
      expect(g.hasEdge('a', 'b'), isTrue, reason: 'Edge a->b should remain');
      expect(g.hasEdge('b', 'c'), isTrue, reason: 'Edge b->c should remain');
    });
  });
}

/// 获取排序后的边列表（不包含标签）
List<Map<String, dynamic>> sortedEdgeList(Graph g) {
  final results = g.edges().map(stripLabel).toList();
  results.sort(sortEdges);
  return results;
}

/// 移除边的标签，保留源节点和目标节点
Map<String, dynamic> stripLabel(Map<String, dynamic> edge) {
  final result = Map<String, dynamic>.from(edge);
  result.remove('label');
  result.remove('isDirected');
  result.remove('name');
  return result;
}

/// 用于比较边的排序函数
int sortEdges(Map<String, dynamic> a, Map<String, dynamic> b) {
  if (a.containsKey('name') && b.containsKey('name')) {
    return (a['name'] as String).compareTo(b['name'] as String);
  }
  
  final order = (a['v'] as String).compareTo(b['v'] as String);
  if (order != 0) {
    return order;
  }
  
  return (a['w'] as String).compareTo(b['w'] as String);
}

/// 查找图中的所有环
List<List<String>> findCycles(Graph g) {
  final visited = <String>{};
  final cycles = <List<String>>[];
  
  void dfs(String node, List<String> path, Set<String> onStack) {
    if (onStack.contains(node)) {
      // 找到环
      final cycleStart = path.indexOf(node);
      final cycle = path.sublist(cycleStart);
      cycles.add(cycle);
      return;
    }
    
    if (visited.contains(node)) return;
    
    visited.add(node);
    onStack.add(node);
    path.add(node);
    
    final successors = g.successors(node) ?? [];
    for (final next in successors) {
      dfs(next, [...path], {...onStack});
    }
    
    onStack.remove(node);
  }
  
  for (final node in g.getNodes()) {
    if (!visited.contains(node)) {
      dfs(node, [], {});
    }
  }
  
  return cycles;
}
