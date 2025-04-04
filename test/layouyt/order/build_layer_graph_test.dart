import 'package:flutter_test/flutter_test.dart';
import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/order/build_layer_graph.dart';

void main() {
  group('buildLayerGraph', () {
    late Graph g;

    setUp(() {
      g = Graph(isCompound: true, isMultigraph: true);
    });

    test('places movable nodes with no parents under the root node', () {
      g.setNode('a', {'rank': 1});
      g.setNode('b', {'rank': 1});
      g.setNode('c', {'rank': 2});
      g.setNode('d', {'rank': 3});

      final lg = buildLayerGraph(g, 1, 'inEdges');
      final root = lg.graph()['root'];
      expect(lg.hasNode(root), isTrue);
      expect(lg.children(), equals([root]));
      expect(lg.children(root), equals(['a', 'b']));
    });

    test('copies flat nodes from the layer to the graph', () {
      g.setNode('a', {'rank': 1});
      g.setNode('b', {'rank': 1});
      g.setNode('c', {'rank': 2});
      g.setNode('d', {'rank': 3});

      expect(
          buildLayerGraph(g, 1, 'inEdges').getNodes(), containsAll(['a', 'b']));
      expect(buildLayerGraph(g, 2, 'inEdges').getNodes(), contains('c'));
      expect(buildLayerGraph(g, 3, 'inEdges').getNodes(), contains('d'));
    });

    test('uses the original node label for copied nodes', () {
      g.setNode('a', <String, dynamic>{'foo': 1, 'rank': 1});
      g.setNode('b', <String, dynamic>{'foo': 2, 'rank': 2});
      g.setEdge('a', 'b', {'weight': 1});

      final lg = buildLayerGraph(g, 2, 'inEdges');

      expect(lg.node('a')['foo'], equals(1));
      g.node('a')['foo'] = 'updated';
      expect(lg.node('a')['foo'], equals('updated'));

      expect(lg.node('b')['foo'], equals(2));
      g.node('b')['foo'] = 'updated';
      expect(lg.node('b')['foo'], equals('updated'));
    });

    test('copies edges incident on rank nodes to the graph (inEdges)', () {
      g.setNode('a', {'rank': 1});
      g.setNode('b', {'rank': 1});
      g.setNode('c', {'rank': 2});
      g.setNode('d', {'rank': 3});
      g.setEdge('a', 'c', {'weight': 2});
      g.setEdge('b', 'c', {'weight': 3});
      g.setEdge('c', 'd', {'weight': 4});

      expect(buildLayerGraph(g, 1, 'inEdges').edgeCount, equals(0));
      final lg2 = buildLayerGraph(g, 2, 'inEdges');
      expect(lg2.edgeCount, equals(2));
      expect(lg2.edge('a', 'c'), equals({'weight': 2}));
      expect(lg2.edge('b', 'c'), equals({'weight': 3}));

      final lg3 = buildLayerGraph(g, 3, 'inEdges');
      expect(lg3.edgeCount, equals(1));
      expect(lg3.edge('c', 'd'), equals({'weight': 4}));
    });

    test('copies edges incident on rank nodes to the graph (outEdges)', () {
      g.setNode('a', {'rank': 1});
      g.setNode('b', {'rank': 1});
      g.setNode('c', {'rank': 2});
      g.setNode('d', {'rank': 3});
      g.setEdge('a', 'c', {'weight': 2});
      g.setEdge('b', 'c', {'weight': 3});
      g.setEdge('c', 'd', {'weight': 4});

      final lg1 = buildLayerGraph(g, 1, 'outEdges');
      expect(lg1.edgeCount, equals(2));
      expect(lg1.edge('c', 'a'), equals({'weight': 2}));
      expect(lg1.edge('c', 'b'), equals({'weight': 3}));

      final lg2 = buildLayerGraph(g, 2, 'outEdges');
      expect(lg2.edgeCount, equals(1));
      expect(lg2.edge('d', 'c'), equals({'weight': 4}));

      final lg3 = buildLayerGraph(g, 3, 'outEdges');
      expect(lg3.edgeCount, equals(0));
    });

    test('collapses multi-edges', () {
      g.setNode('a', {'rank': 1});
      g.setNode('b', {'rank': 2});
      g.setEdge('a', 'b', {'weight': 2});
      g.setEdge('a', 'b', {'weight': 3}, 'multi');

      final lg = buildLayerGraph(g, 2, 'inEdges');
      expect(lg.edge('a', 'b'), equals({'weight': 5}));
    });

    test('preserves hierarchy for the movable layer', () {
      g.setNode('a', {'rank': 0});
      g.setNode('b', {'rank': 0});
      g.setNode('c', {'rank': 0});
      g.setNode('sg', {
        'minRank': 0,
        'maxRank': 0,
        'borderLeft': ['bl'],
        'borderRight': ['br']
      });
      for (var v in ['a', 'b']) {
        g.setParent(v, 'sg');
      }

      final lg = buildLayerGraph(g, 0, 'inEdges');
      final root = lg.graph()['root'];
      final children = lg.children(root);
      children?.sort();
      expect(children, equals(['c', 'sg']));
      expect(lg.parent('a'), equals('sg'));
      expect(lg.parent('b'), equals('sg'));
    });
  });
}
