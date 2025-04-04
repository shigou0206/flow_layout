// Flutter unit tests for graph_utils.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/utils.dart';

void main() {
  group('graph_utils', () {
    group('simplify', () {
      late Graph g;

      setUp(() => g = Graph(isMultigraph: true));

      test('copies without change a graph with no multi-edges', () {
        g.setEdge('a', 'b', {'weight': 1, 'minlen': 1});
        final g2 = simplify(g);
        expect(g2.edge('a', 'b'), equals({'weight': 1, 'minlen': 1}));
        expect(g2.edgeCount, equals(1));
      });

      test('collapses multi-edges', () {
        g.setEdge('a', 'b', {'weight': 1, 'minlen': 1});
        g.setEdge('a', 'b', {'weight': 2, 'minlen': 2}, 'multi');
        final g2 = simplify(g);
        expect(g2.isMultigraph, isFalse);
        expect(g2.edge('a', 'b'), equals({'weight': 3, 'minlen': 2}));
        expect(g2.edgeCount, equals(1));
      });

      test('copies the graph object', () {
        g.setGraph({'foo': 'bar'});
        final g2 = simplify(g);
        expect(g2.graph(), equals({'foo': 'bar'}));
      });
    });

    group('asNonCompoundGraph', () {
      late Graph g;
      setUp(() => g = Graph(isCompound: true, isMultigraph: true));

      test('copies all nodes', () {
        g.setNode('a', {'foo': 'bar'});
        g.setNode('b');
        final g2 = asNonCompoundGraph(g);
        expect(g2.node('a'), equals({'foo': 'bar'}));
        expect(g2.hasNode('b'), isTrue);
      });

      test('copies all edges', () {
        g.setEdge('a', 'b', {'foo': 'bar'});
        g.setEdge('a', 'b', {'foo': 'baz'}, 'multi');
        final g2 = asNonCompoundGraph(g);
        expect(g2.edge('a', 'b'), equals({'foo': 'bar'}));
        expect(g2.edge('a', 'b', 'multi'), equals({'foo': 'baz'}));
      });

      test('does not copy compound structure', () {
        g.setParent('a', 'sg1');
        final g2 = asNonCompoundGraph(g);
        expect(g2.parent('a'), isNull);
        expect(g2.isCompound, isFalse);
      });

      test('copies the graph object', () {
        g.setGraph({'foo': 'bar'});
        final g2 = asNonCompoundGraph(g);
        expect(g2.graph(), equals({'foo': 'bar'}));
      });
    });

    group('successorWeights', () {
      test('maps a node to its successors with weights', () {
        final g = Graph(isMultigraph: true);
        g.setEdge('a', 'b', {'weight': 2});
        g.setEdge('b', 'c', {'weight': 1});
        g.setEdge('b', 'c', {'weight': 2}, 'multi');
        g.setEdge('b', 'd', {'weight': 1}, 'multi');

        final sw = successorWeights(g);
        expect(sw['a'], equals({'b': 2}));
        expect(sw['b'], equals({'c': 3, 'd': 1}));
        expect(sw['c'], equals({}));
        expect(sw['d'], equals({}));
      });
    });

    group('predecessorWeights', () {
      test('maps a node to its predecessors with weights', () {
        final g = Graph(isMultigraph: true);
        g.setEdge('a', 'b', {'weight': 2});
        g.setEdge('b', 'c', {'weight': 1});
        g.setEdge('b', 'c', {'weight': 2}, 'multi');
        g.setEdge('b', 'd', {'weight': 1}, 'multi');

        final pw = predecessorWeights(g);
        expect(pw['a'], equals({}));
        expect(pw['b'], equals({'a': 2}));
        expect(pw['c'], equals({'b': 3}));
        expect(pw['d'], equals({'b': 1}));
      });
    });

    group('intersectRect', () {
      final rect = {'x': 0.0, 'y': 0.0, 'width': 1.0, 'height': 1.0};

      void expectIntersects(Map<String, double> point) {
        final cross = intersectRect(
          x: rect['x']!,
          y: rect['y']!,
          width: rect['width']!,
          height: rect['height']!,
          point: point,
        );
        if (cross['x'] != point['x']) {
          final m = (cross['y']! - point['y']!) / (cross['x']! - point['x']!);
          expect(cross['y']! - rect['y']!,
              closeTo(m * (cross['x']! - rect['x']!), 1e-6));
        }
      }

      void expectTouchesBorder(Map<String, double> point) {
        final cross = intersectRect(
          x: rect['x']!,
          y: rect['y']!,
          width: rect['width']!,
          height: rect['height']!,
          point: point,
        );
        if ((rect['x']! - cross['x']!).abs() != rect['width']! / 2) {
          expect((rect['y']! - cross['y']!).abs(), rect['height']! / 2);
        }
      }

      test("intersects center", () {
        expectIntersects({'x': 2, 'y': 6});
        expectIntersects({'x': 2, 'y': -6});
        expectIntersects({'x': 6, 'y': 2});
        expectIntersects({'x': -6, 'y': 2});
        expectIntersects({'x': 5, 'y': 0});
        expectIntersects({'x': 0, 'y': 5});
      });

      test("touches border", () {
        expectTouchesBorder({'x': 2, 'y': 6});
        expectTouchesBorder({'x': 2, 'y': -6});
        expectTouchesBorder({'x': 6, 'y': 2});
        expectTouchesBorder({'x': -6, 'y': 2});
        expectTouchesBorder({'x': 5, 'y': 0});
        expectTouchesBorder({'x': 0, 'y': 5});
      });

      test("throws at center", () {
        expect(
          () => intersectRect(
            x: 0,
            y: 0,
            width: 1,
            height: 1,
            point: {'x': 0.0, 'y': 0.0},
          ),
          throwsArgumentError,
        );
      });
    });

    group('normalizeRanks', () {
      test('ranks are adjusted to be >= 0, with one at 0', () {
        final g = Graph()
          ..setNode('a', {'rank': 3})
          ..setNode('b', {'rank': 2})
          ..setNode('c', {'rank': 4});
        normalizeRanks(g);
        expect(g.node('a')['rank'], 1);
        expect(g.node('b')['rank'], 0);
        expect(g.node('c')['rank'], 2);
      });

      test('works with negative ranks', () {
        final g = Graph()
          ..setNode('a', {'rank': -3})
          ..setNode('b', {'rank': -2});
        normalizeRanks(g);
        expect(g.node('a')['rank'], 0);
        expect(g.node('b')['rank'], 1);
      });

      test('does not assign rank to subgraphs', () {
        final g = Graph(isCompound: true)
          ..setNode('a', {'rank': 0})
          ..setNode('sg', {})
          ..setParent('a', 'sg');
        normalizeRanks(g);
        expect(g.node('sg').containsKey('rank'), isFalse);
        expect(g.node('a')['rank'], 0);
      });
    });

    group('removeEmptyRanks', () {
      test('removes empty ranks if non-border', () {
        final g = Graph()
          ..setGraph({'nodeRankFactor': 4})
          ..setNode('a', {'rank': 0})
          ..setNode('b', {'rank': 4});
        removeEmptyRanks(g);
        expect(g.node('a')['rank'], 0);
        expect(g.node('b')['rank'], 1);
      });

      test('does not remove ranks that align with nodeRankFactor', () {
        final g = Graph()
          ..setGraph({'nodeRankFactor': 4})
          ..setNode('a', {'rank': 0})
          ..setNode('b', {'rank': 8});
        removeEmptyRanks(g);
        expect(g.node('a')['rank'], 0);
        expect(g.node('b')['rank'], 2);
      });
    });

    group('range', () {
      test('generates 0..n-1', () {
        final r = range(4);
        expect(r.length, 4);
        expect(r.reduce((a, b) => a + b), 6);
      });

      test('with start and end', () {
        final r = range(2, 4);
        expect(r.length, 2);
        expect(r.reduce((a, b) => a + b), 5);
      });

      test('with negative step', () {
        final r = range(5, -1, -1);
        expect(r[0], 5);
        expect(r[5], 0);
      });
    });

    group('mapValues', () {
      test('maps values from key to prop', () {
        final users = {
          'fred': {'user': 'fred', 'age': 40},
          'pebbles': {'user': 'pebbles', 'age': 1},
        };
        final ages = mapValues(users, (v, k) => v['age']);
        expect(ages['fred'], 40);
        expect(ages['pebbles'], 1);
      });
    });
  });
}
