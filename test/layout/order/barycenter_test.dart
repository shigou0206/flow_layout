import 'package:flutter_test/flutter_test.dart';
import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/order/barycenter.dart';

void main() {
  group('order/barycenter', () {
    late Graph g;

    setUp(() {
      g = Graph()
        ..setDefaultNodeLabel((_) => {})
        ..setDefaultEdgeLabel((_, __, ___) => {'weight': 1});
    });

    test('assigns an undefined barycenter for a node with no predecessors', () {
      g.setNode('x', {});

      final results = barycenter(g, ['x']);
      expect(results.length, 1);
      expect(results[0], equals(BarycenterResult(v: 'x')));
    });

    test('assigns the position of the sole predecessor', () {
      g.setNode('a', {'order': 2});
      g.setEdge('a', 'x');

      final results = barycenter(g, ['x']);
      expect(results.length, 1);
      expect(results[0],
          equals(BarycenterResult(v: 'x', barycenter: 2, weight: 1)));
    });

    test('assigns the average of multiple predecessors', () {
      g.setNode('a', {'order': 2});
      g.setNode('b', {'order': 4});
      g.setEdge('a', 'x');
      g.setEdge('b', 'x');

      final results = barycenter(g, ['x']);
      expect(results.length, 1);
      expect(results[0],
          equals(BarycenterResult(v: 'x', barycenter: 3, weight: 2)));
    });

    test('takes into account the weight of edges', () {
      g.setNode('a', {'order': 2});
      g.setNode('b', {'order': 4});
      g.setEdge('a', 'x', {'weight': 3});
      g.setEdge('b', 'x');

      final results = barycenter(g, ['x']);
      expect(results.length, 1);
      expect(results[0],
          equals(BarycenterResult(v: 'x', barycenter: 2.5, weight: 4)));
    });

    test('calculates barycenters for all nodes in the movable layer', () {
      g.setNode('a', {'order': 1});
      g.setNode('b', {'order': 2});
      g.setNode('c', {'order': 4});
      g.setEdge('a', 'x');
      g.setEdge('b', 'x');
      g.setNode('y');
      g.setEdge('a', 'z', {'weight': 2});
      g.setEdge('c', 'z');

      final results = barycenter(g, ['x', 'y', 'z']);
      expect(results.length, 3);
      expect(results[0],
          equals(BarycenterResult(v: 'x', barycenter: 1.5, weight: 2)));
      expect(results[1], equals(BarycenterResult(v: 'y')));
      expect(results[2],
          equals(BarycenterResult(v: 'z', barycenter: 2, weight: 3)));
    });
  });
}
