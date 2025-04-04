import 'package:flutter_test/flutter_test.dart';
import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/utils.dart';

void main() {
  group('order/addSubgraphConstraints', () {
    late Graph g, cg;

    setUp(() {
      g = Graph(isCompound: true);
      cg = Graph();
    });

    test('does not change CG for a flat set of nodes', () {
      final vs = ['a', 'b', 'c', 'd'];
      for (var v in vs) {
        g.setNode(v);
      }
      addSubgraphConstraints(g, cg, vs);
      expect(cg.nodeCount, equals(0));
      expect(cg.edgeCount, equals(0));
    });

    test("doesn't create a constraint for contiguous subgraph nodes", () {
      final vs = ['a', 'b', 'c'];
      for (var v in vs) {
        g.setParent(v, 'sg');
      }
      addSubgraphConstraints(g, cg, vs);
      expect(cg.nodeCount, equals(0));
      expect(cg.edgeCount, equals(0));
    });

    test('adds a constraint when the parents for adjacent nodes are different',
        () {
      final vs = ['a', 'b'];
      g.setParent('a', 'sg1');
      g.setParent('b', 'sg2');
      addSubgraphConstraints(g, cg, vs);
      expect(
        cg.edges().map((e) => {'v': e.v, 'w': e.w}).toList(),
        equals([
          {'v': 'sg1', 'w': 'sg2'},
        ]),
      );
    });

    test('works for multiple levels', () {
      final vs = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
      for (var v in vs) {
        g.setNode(v);
      }
      g.setParent('b', 'sg2');
      g.setParent('sg2', 'sg1');
      g.setParent('c', 'sg1');
      g.setParent('d', 'sg3');
      g.setParent('sg3', 'sg1');
      g.setParent('f', 'sg4');
      g.setParent('g', 'sg5');
      g.setParent('sg5', 'sg4');
      addSubgraphConstraints(g, cg, vs);

      final edges = cg.edges()..sort((a, b) => a.v.compareTo(b.v));

      expect(
        edges.map((e) => {'v': e.v, 'w': e.w}).toList(),
        equals([
          {'v': 'sg1', 'w': 'sg4'},
          {'v': 'sg2', 'w': 'sg3'},
        ]),
      );
    });
  });
}
