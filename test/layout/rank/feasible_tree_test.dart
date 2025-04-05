import 'package:flutter_test/flutter_test.dart';
import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/rank/feasible_tree.dart';

void main() {
  group('feasibleTree', () {
    test('creates a tree for a trivial input graph', () {
      final g = Graph()
        ..setNode('a', { 'rank': 0 })
        ..setNode('b', { 'rank': 1 })
        ..setEdge('a', 'b', { 'minlen': 1 });

      final tree = feasibleTree(g);

      expect(g.node('b')['rank'], equals(g.node('a')['rank'] + 1));
      expect(tree.neighbors('a'), equals(['b']));
    });

    test('correctly shortens slack by pulling a node up', () {
      final g = Graph()
        ..setNode('a', { 'rank': 0 })
        ..setNode('b', { 'rank': 1 })
        ..setNode('c', { 'rank': 2 })
        ..setNode('d', { 'rank': 2 })
        // setPath(["a", "b", "c"], { minlen: 1 })
        // 相当于: setEdge("a","b"), setEdge("b","c")
        ..setEdge('a', 'b', { 'minlen': 1 })
        ..setEdge('b', 'c', { 'minlen': 1 })
        // setEdge("a","d")
        ..setEdge('a', 'd', { 'minlen': 1 });

      final tree = feasibleTree(g);

      expect(g.node('b')['rank'], equals(g.node('a')['rank'] + 1));
      expect(g.node('c')['rank'], equals(g.node('b')['rank'] + 1));
      expect(g.node('d')['rank'], equals(g.node('a')['rank'] + 1));

      // neighbors(...) 返回 List<String>?
      // JS 里测试中用 .sort() => 这里手动 sort 以保证顺序
      final aNeighbors = [...?tree.neighbors('a')]..sort();
      final bNeighbors = [...?tree.neighbors('b')]..sort();
      final cNeighbors = [...?tree.neighbors('c')]..sort();
      final dNeighbors = [...?tree.neighbors('d')]..sort();

      expect(aNeighbors, equals(['b', 'd']));
      expect(bNeighbors, equals(['a', 'c']));
      expect(cNeighbors, equals(['b']));
      expect(dNeighbors, equals(['a']));
    });

    test('correctly shortens slack by pulling a node down', () {
      final g = Graph()
        ..setNode('a', { 'rank': 2 })
        ..setNode('b', { 'rank': 0 })
        ..setNode('c', { 'rank': 2 })
        ..setEdge('b', 'a', { 'minlen': 1 })
        ..setEdge('b', 'c', { 'minlen': 1 });

      final tree = feasibleTree(g);

      expect(g.node('a')['rank'], equals(g.node('b')['rank'] + 1));
      expect(g.node('c')['rank'], equals(g.node('b')['rank'] + 1));

      final aNeighbors = [...?tree.neighbors('a')]..sort();
      final bNeighbors = [...?tree.neighbors('b')]..sort();
      final cNeighbors = [...?tree.neighbors('c')]..sort();

      expect(aNeighbors, equals(['b']));
      expect(bNeighbors, equals(['a', 'c']));
      expect(cNeighbors, equals(['b']));
    });
  });
}