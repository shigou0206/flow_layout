import 'package:flutter_test/flutter_test.dart';
import 'package:flow_layout/layout/order/sort_subgraph.dart';
import 'package:flow_layout/graph/graph.dart';

void main() {
  late Graph g, cg;

  setUp(() {
    g = Graph(isCompound: true);
    for (var v in [0, 1, 2, 3, 4]) {
      g.setNode('$v', {'order': v});
    }
    cg = Graph();
  });

  group('sortSubgraph', () {
    test('sorts a flat subgraph based on barycenter', () {
      g.setEdge('3', 'x');
      g.setEdge('1', 'y', {'weight': 2});
      g.setEdge('4', 'y');
      for (var v in ['x', 'y']) {
        g.setParent(v, 'movable');
      }

      expect(sortSubgraph(g, 'movable', cg).vs, equals(['y', 'x']));
    });

    test('preserves node pos w/o neighbors in a flat subgraph', () {
      g.setEdge('3', 'x');
      g.setNode('y');
      g.setEdge('1', 'z', {'weight': 2});
      g.setEdge('4', 'z');
      for (var v in ['x', 'y', 'z']) {
        g.setParent(v, 'movable');
      }

      expect(sortSubgraph(g, 'movable', cg).vs, equals(['z', 'y', 'x']));
    });

    test('biases to the left without reverse bias', () {
      g.setEdge('1', 'x');
      g.setEdge('1', 'y');
      for (var v in ['x', 'y']) {
        g.setParent(v, 'movable');
      }

      expect(sortSubgraph(g, 'movable', cg).vs, equals(['x', 'y']));
    });

    test('biases to the right with reverse bias', () {
      g.setEdge('1', 'x');
      g.setEdge('1', 'y');
      for (var v in ['x', 'y']) {
        g.setParent(v, 'movable');
      }

      expect(sortSubgraph(g, 'movable', cg, true).vs, equals(['y', 'x']));
    });

    test('aggregates stats about the subgraph', () {
      g.setEdge('3', 'x');
      g.setEdge('1', 'y', {'weight': 2});
      g.setEdge('4', 'y');
      for (var v in ['x', 'y']) {
        g.setParent(v, 'movable');
      }

      final results = sortSubgraph(g, 'movable', cg);
      expect(results.barycenter, equals(2.25));
      expect(results.weight, equals(4));
    });

    test('can sort a nested subgraph with no barycenter', () {
      ['a', 'b', 'c'].forEach(g.setNode);
      for (var v in ['a', 'b', 'c']) {
        g.setParent(v, 'y');
      }
      g.setEdge('0', 'x');
      g.setEdge('1', 'z');
      g.setEdge('2', 'y');
      for (var v in ['x', 'y', 'z']) {
        g.setParent(v, 'movable');
      }

      expect(
          sortSubgraph(g, 'movable', cg).vs, equals(['x', 'z', 'a', 'b', 'c']));
    });

    test('can sort a nested subgraph with a barycenter', () {
      ['a', 'b', 'c'].forEach(g.setNode);
      for (var v in ['a', 'b', 'c']) {
        g.setParent(v, 'y');
      }
      g.setEdge('0', 'a', {'weight': 3});
      g.setEdge('0', 'x');
      g.setEdge('1', 'z');
      g.setEdge('2', 'y');
      for (var v in ['x', 'y', 'z']) {
        g.setParent(v, 'movable');
      }

      expect(
          sortSubgraph(g, 'movable', cg).vs, equals(['x', 'a', 'b', 'c', 'z']));
    });

    test('sorts border nodes to the extremes of the subgraph', () {
      g.setEdge('0', 'x');
      g.setEdge('1', 'y');
      g.setEdge('2', 'z');
      g.setNode('sg1', {'borderLeft': 'bl', 'borderRight': 'br'});
      for (var v in ['x', 'y', 'z', 'bl', 'br']) {
        g.setParent(v, 'sg1');
      }
      expect(
          sortSubgraph(g, 'sg1', cg).vs, equals(['bl', 'x', 'y', 'z', 'br']));
    });

    test('assigns barycenter based on previous border nodes', () {
      g.setNode('bl1', {'order': 0});
      g.setNode('br1', {'order': 1});
      g.setEdge('bl1', 'bl2');
      g.setEdge('br1', 'br2');
      for (var v in ['bl2', 'br2']) {
        g.setParent(v, 'sg');
      }
      g.setNode('sg', {'borderLeft': 'bl2', 'borderRight': 'br2'});

      final results = sortSubgraph(g, 'sg', cg);
      expect(results.barycenter, equals(0.5));
      expect(results.weight, equals(2));
      expect(results.vs, equals(['bl2', 'br2']));
    });
  });
}
