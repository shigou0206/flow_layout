import 'package:flutter_test/flutter_test.dart';
import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/order/init_order.dart';

void main() {
  group('order/initOrder', () {
    late Graph g;

    setUp(() {
      g = Graph(isCompound: true)..setDefaultEdgeLabel(() => {'weight': 1});
    });

    test('assigns non-overlapping orders for each rank in a tree', () {
      final nodes = {'a': 0, 'b': 1, 'c': 2, 'd': 2, 'e': 1};
      nodes.forEach((v, rank) {
        g.setNode(v, {'rank': rank});
      });

      g.setPath(['a', 'b', 'c']);
      g.setEdge('b', 'd');
      g.setEdge('a', 'e');

      final layering = initOrder(g);
      expect(layering[0], equals(['a']));
      expect(layering[1]..sort(), equals(['b', 'e']));
      expect(layering[2]..sort(), equals(['c', 'd']));
    });

    test('assigns non-overlapping orders for each rank in a DAG', () {
      final nodes = {'a': 0, 'b': 1, 'c': 1, 'd': 2};
      nodes.forEach((v, rank) {
        g.setNode(v, {'rank': rank});
      });

      g.setPath(['a', 'b', 'd']);
      g.setPath(['a', 'c', 'd']);

      final layering = initOrder(g);
      expect(layering[0], equals(['a']));
      expect(layering[1]..sort(), equals(['b', 'c']));
      expect(layering[2]..sort(), equals(['d']));
    });

    test('does not assign an order to subgraph nodes', () {
      g.setNode('a', {'rank': 0});
      g.setNode('sg1', {});
      g.setParent('a', 'sg1');

      final layering = initOrder(g);
      expect(
          layering,
          equals([
            ['a']
          ]));
    });
  });
}
