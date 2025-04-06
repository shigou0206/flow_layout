import 'package:flutter_test/flutter_test.dart';
import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/graph/alg/normalize.dart' as normalize;

void main() {
  group('normalize', () {
    late Graph g;

    setUp(() {
      g = Graph();
      g.isMultigraph = true;
      g.isCompound = true;
      g.setGraph({});
    });

    group('run', () {
      test('does not change a short edge', () {
        g.setNode('a', {'rank': 0});
        g.setNode('b', {'rank': 1});
        g.setEdge('a', 'b', {});

        normalize.run(g);

        final edges = g.edges().map((e) => {'v': e['v'], 'w': e['w']}).toList();
        expect(
            edges,
            equals([
              {'v': 'a', 'w': 'b'}
            ]));
        expect(g.node('a')?['rank'], equals(0));
        expect(g.node('b')?['rank'], equals(1));
      });

      test('splits a two layer edge into two segments', () {
        g.setNode('a', {'rank': 0});
        g.setNode('b', {'rank': 2});
        g.setEdge('a', 'b', {});

        normalize.run(g);

        final successors = g.successors('a') ?? [];
        expect(successors.length, equals(1));

        final successor = successors[0];
        expect(g.node(successor)?['dummy'], equals('edge'));
        expect(g.node(successor)?['rank'], equals(1));
        expect(g.successors(successor), equals(['b']));
        expect(g.node('a')?['rank'], equals(0));
        expect(g.node('b')?['rank'], equals(2));

        final dummyChains = g.graph()?['dummyChains'] as List?;
        expect(dummyChains?.length, equals(1));
        expect(dummyChains?[0], equals(successor));
      });

      test('assigns width = 0, height = 0 to dummy nodes by default', () {
        g.setNode('a', {'rank': 0});
        g.setNode('b', {'rank': 2});
        g.setEdge('a', 'b', {'width': 10, 'height': 10});

        normalize.run(g);

        final successors = g.successors('a') ?? [];
        expect(successors.length, equals(1));

        final successor = successors[0];
        expect(g.node(successor)?['width'], equals(0));
        expect(g.node(successor)?['height'], equals(0));
      });

      test('assigns width and height from the edge for the node on labelRank',
          () {
        g.setNode('a', {'rank': 0});
        g.setNode('b', {'rank': 4});
        g.setEdge('a', 'b', {'width': 20, 'height': 10, 'labelRank': 2});

        normalize.run(g);

        final aSuc = g.successors('a')?[0];
        final aSucSuc = g.successors(aSuc)?[0];
        final labelNode = g.node(aSucSuc);

        expect(labelNode?['width'], equals(20));
        expect(labelNode?['height'], equals(10));
      });

      test('preserves the weight for the edge', () {
        g.setNode('a', {'rank': 0});
        g.setNode('b', {'rank': 2});
        g.setEdge('a', 'b', {'weight': 2});

        normalize.run(g);

        final successors = g.successors('a') ?? [];
        expect(successors.length, equals(1));

        final edgeData = g.edge({'v': 'a', 'w': successors[0]});
        expect(edgeData?['weight'], equals(2));
      });
    });

    group('undo', () {
      test('reverses the run operation', () {
        g.setNode('a', {'rank': 0});
        g.setNode('b', {'rank': 2});
        g.setEdge('a', 'b', {});

        normalize.run(g);
        normalize.undo(g);

        final edges = g.edges().map((e) => {'v': e['v'], 'w': e['w']}).toList();
        expect(
            edges,
            equals([
              {'v': 'a', 'w': 'b'}
            ]));
        expect(g.node('a')?['rank'], equals(0));
        expect(g.node('b')?['rank'], equals(2));
      });

      test('restores previous edge labels', () {
        g.setNode('a', {'rank': 0});
        g.setNode('b', {'rank': 2});
        g.setEdge('a', 'b', {'foo': 'bar'});

        normalize.run(g);
        normalize.undo(g);

        expect(g.edge({'v': 'a', 'w': 'b'})?['foo'], equals('bar'));
      });

      test('collects assigned coordinates into the points attribute', () {
        g.setNode('a', {'rank': 0});
        g.setNode('b', {'rank': 2});
        g.setEdge('a', 'b', {});

        normalize.run(g);

        final neighbors = g.neighbors('a') ?? [];
        final dummyNode = g.node(neighbors[0]);
        if (dummyNode != null) {
          dummyNode['x'] = 5;
          dummyNode['y'] = 10;
        }

        normalize.undo(g);

        final points = g.edge({'v': 'a', 'w': 'b'})?['points'] as List?;
        expect(
            points,
            equals([
              {'x': 5, 'y': 10}
            ]));
      });

      test('merges assigned coordinates into the points attribute', () {
        g.setNode('a', {'rank': 0});
        g.setNode('b', {'rank': 4});
        g.setEdge('a', 'b', {});

        normalize.run(g);

        final aSuccessors = g.successors('a') ?? [];
        final aSucNode = g.node(aSuccessors[0]);
        if (aSucNode != null) {
          aSucNode['x'] = 5;
          aSucNode['y'] = 10;
        }

        final midSuccessors = g.successors(aSuccessors[0]) ?? [];
        final midNode = g.node(midSuccessors[0]);
        if (midNode != null) {
          midNode['x'] = 20;
          midNode['y'] = 25;
        }

        final bNeighbors = g.neighbors('b') ?? [];
        final bPredNode = g.node(bNeighbors[0]);
        if (bPredNode != null) {
          bPredNode['x'] = 100;
          bPredNode['y'] = 200;
        }

        normalize.undo(g);

        final points = g.edge({'v': 'a', 'w': 'b'})?['points'] as List?;
        expect(
            points,
            equals([
              {'x': 5, 'y': 10},
              {'x': 20, 'y': 25},
              {'x': 100, 'y': 200}
            ]));
      });

      test('sets coords and dims for the label, if the edge has one', () {
        g.setNode('a', {'rank': 0});
        g.setNode('b', {'rank': 2});
        g.setEdge('a', 'b', {'width': 10, 'height': 20, 'labelRank': 1});

        normalize.run(g);

        final aSuccessors = g.successors('a') ?? [];
        final labelNode = g.node(aSuccessors[0]);
        if (labelNode != null) {
          labelNode['x'] = 50;
          labelNode['y'] = 60;
          labelNode['width'] = 20;
          labelNode['height'] = 10;
        }

        normalize.undo(g);

        final edge = g.edge({'v': 'a', 'w': 'b'});
        final edgeData = pick(edge, ['x', 'y', 'width', 'height']);

        expect(edgeData, equals({'x': 50, 'y': 60, 'width': 20, 'height': 10}));
      });

      test('sets coords and dims for the label, if the long edge has one', () {
        g.setNode('a', {'rank': 0});
        g.setNode('b', {'rank': 4});
        g.setEdge('a', 'b', {'width': 10, 'height': 20, 'labelRank': 2});

        normalize.run(g);

        final aSuccessors = g.successors('a') ?? [];
        final aSucSuccessors = g.successors(aSuccessors[0]) ?? [];
        final labelNode = g.node(aSucSuccessors[0]);
        if (labelNode != null) {
          labelNode['x'] = 50;
          labelNode['y'] = 60;
          labelNode['width'] = 20;
          labelNode['height'] = 10;
        }

        normalize.undo(g);

        final edge = g.edge({'v': 'a', 'w': 'b'});
        final edgeData = pick(edge, ['x', 'y', 'width', 'height']);

        expect(edgeData, equals({'x': 50, 'y': 60, 'width': 20, 'height': 10}));
      });

      test('restores multi-edges', () {
        g.setNode('a', {'rank': 0});
        g.setNode('b', {'rank': 2});
        g.setEdge('a', 'b', {}, 'bar');
        g.setEdge('a', 'b', {}, 'foo');

        normalize.run(g);

        // Get the outgoing edges from 'a'
        final outEdges = g.outEdges('a');
        // Verify we have edges before continuing
        expect(outEdges, isNotNull);
        expect(outEdges!.length, equals(2));

        // Sort by name to match the JavaScript test order
        outEdges.sort(
            (a, b) => (a['name'] as String).compareTo(b['name'] as String));

        // Get the nodes at the other end of these edges
        final barDummy = g.node(outEdges[0]['w']);
        if (barDummy != null) {
          barDummy['x'] = 5;
          barDummy['y'] = 10;
        }

        final fooDummy = g.node(outEdges[1]['w']);
        if (fooDummy != null) {
          fooDummy['x'] = 15;
          fooDummy['y'] = 20;
        }

        normalize.undo(g);

        expect(g.hasEdge('a', 'b'), isFalse);

        final barPoints =
            g.edge({'v': 'a', 'w': 'b', 'name': 'bar'})?['points'] as List?;
        expect(
            barPoints,
            equals([
              {'x': 5, 'y': 10}
            ]));

        final fooPoints =
            g.edge({'v': 'a', 'w': 'b', 'name': 'foo'})?['points'] as List?;
        expect(
            fooPoints,
            equals([
              {'x': 15, 'y': 20}
            ]));
      });
    });
  });
}

// Helper function to pick specific properties from an object
Map<String, dynamic>? pick(Map<dynamic, dynamic>? obj, List<String> keys) {
  if (obj == null) return null;

  final picked = <String, dynamic>{};
  for (final key in keys) {
    if (obj.containsKey(key)) {
      picked[key] = obj[key];
    }
  }
  return picked;
}
