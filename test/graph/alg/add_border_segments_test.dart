import 'package:flutter_test/flutter_test.dart';
import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/graph/alg/add_border_segments.dart';

void main() {
  group('addBorderSegments', () {
    late Graph g;

    setUp(() {
      g = Graph(isCompound: true);
    });

    test('does not add border nodes for a non-compound graph', () {
      final g = Graph();
      g.setNode('a', {'rank': 0});
      addBorderSegments(g);
      expect(g.getNodes().length, equals(1));
      expect(g.node('a'), equals({'rank': 0}));
    });

    test('does not add border nodes for a graph with no clusters', () {
      g.setNode('a', {'rank': 0});
      addBorderSegments(g);
      expect(g.getNodes().length, equals(1));
      expect(g.node('a'), equals({'rank': 0}));
    });

    test('adds a border for a single-rank subgraph', () {
      g.setNode('sg', {'minRank': 1, 'maxRank': 1});
      addBorderSegments(g);

      final sgNode = g.node('sg') as Map<String, dynamic>;
      final bl = sgNode['borderLeft'][1];
      final br = sgNode['borderRight'][1];

      expect(
          g.node(bl),
          equals({
            'dummy': 'border',
            'borderType': 'borderLeft',
            'rank': 1,
            'width': 0,
            'height': 0
          }));
      expect(g.parent(bl), equals('sg'));

      expect(
          g.node(br),
          equals({
            'dummy': 'border',
            'borderType': 'borderRight',
            'rank': 1,
            'width': 0,
            'height': 0
          }));
      expect(g.parent(br), equals('sg'));
    });

    test('adds a border for a multi-rank subgraph', () {
      g.setNode('sg', {'minRank': 1, 'maxRank': 2});
      addBorderSegments(g);

      final sgNode = g.node('sg') as Map<String, dynamic>;
      final bl2 = sgNode['borderLeft'][1];
      final br2 = sgNode['borderRight'][1];

      expect(
          g.node(bl2),
          equals({
            'dummy': 'border',
            'borderType': 'borderLeft',
            'rank': 1,
            'width': 0,
            'height': 0
          }));
      expect(g.parent(bl2), equals('sg'));

      expect(
          g.node(br2),
          equals({
            'dummy': 'border',
            'borderType': 'borderRight',
            'rank': 1,
            'width': 0,
            'height': 0
          }));
      expect(g.parent(br2), equals('sg'));

      final bl1 = sgNode['borderLeft'][2];
      final br1 = sgNode['borderRight'][2];

      expect(
          g.node(bl1),
          equals({
            'dummy': 'border',
            'borderType': 'borderLeft',
            'rank': 2,
            'width': 0,
            'height': 0
          }));
      expect(g.parent(bl1), equals('sg'));

      expect(
          g.node(br1),
          equals({
            'dummy': 'border',
            'borderType': 'borderRight',
            'rank': 2,
            'width': 0,
            'height': 0
          }));
      expect(g.parent(br1), equals('sg'));

      expect(
          g.hasEdge(sgNode['borderLeft'][1], sgNode['borderLeft'][2]), isTrue);
      expect(g.hasEdge(sgNode['borderRight'][1], sgNode['borderRight'][2]),
          isTrue);
    });

    test('adds borders for nested subgraphs', () {
      g.setNode('sg1', {'minRank': 1, 'maxRank': 1});
      g.setNode('sg2', {'minRank': 1, 'maxRank': 1});
      g.setParent('sg2', 'sg1');
      addBorderSegments(g);

      final sg1Node = g.node('sg1') as Map<String, dynamic>;
      final bl1 = sg1Node['borderLeft'][1];
      final br1 = sg1Node['borderRight'][1];

      expect(
          g.node(bl1),
          equals({
            'dummy': 'border',
            'borderType': 'borderLeft',
            'rank': 1,
            'width': 0,
            'height': 0
          }));
      expect(g.parent(bl1), equals('sg1'));

      expect(
          g.node(br1),
          equals({
            'dummy': 'border',
            'borderType': 'borderRight',
            'rank': 1,
            'width': 0,
            'height': 0
          }));
      expect(g.parent(br1), equals('sg1'));

      final sg2Node = g.node('sg2') as Map<String, dynamic>;
      final bl2 = sg2Node['borderLeft'][1];
      final br2 = sg2Node['borderRight'][1];

      expect(
          g.node(bl2),
          equals({
            'dummy': 'border',
            'borderType': 'borderLeft',
            'rank': 1,
            'width': 0,
            'height': 0
          }));
      expect(g.parent(bl2), equals('sg2'));

      expect(
          g.node(br2),
          equals({
            'dummy': 'border',
            'borderType': 'borderRight',
            'rank': 1,
            'width': 0,
            'height': 0
          }));
      expect(g.parent(br2), equals('sg2'));
    });
  });
}
