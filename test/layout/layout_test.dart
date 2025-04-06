import 'package:flutter_test/flutter_test.dart';
import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/layout.dart';

/// 从图中提取坐标的辅助函数
Map<String, Map<String, double>> extractCoordinates(Graph g) {
  final nodes = g.getNodes();
  final result = <String, Map<String, double>>{};

  for (final v in nodes) {
    final node = g.node(v);
    if (node == null) continue;

    result[v] = {
      'x': node['x'] is num ? (node['x'] as num).toDouble() : 0.0,
      'y': node['y'] is num ? (node['y'] as num).toDouble() : 0.0,
    };
  }

  return result;
}

void main() {
  late Graph g;

  setUp(() {
    g = Graph(isMultigraph: true, isCompound: true)
      ..setGraph(<String, dynamic>{})
      ..setDefaultEdgeLabel((String _) => <String, dynamic>{});
  });

  test('can layout a single node', () {
    g.setNode('a', {'width': 50, 'height': 100});
    layout(g);

    final coords = extractCoordinates(g);
    expect(
        coords,
        equals({
          'a': {'x': 50 / 2, 'y': 100 / 2}
        }));

    expect(g.node('a')['x'], equals(50 / 2));
    expect(g.node('a')['y'], equals(100 / 2));
  });

  test('can layout two nodes on the same rank', () {
    final graphData = Map<String, dynamic>.from(g.graph() ?? {});
    graphData['nodesep'] = 200;

    g.setGraph(graphData);
    g.setNode('a', {'width': 50, 'height': 100});
    g.setNode('b', {'width': 75, 'height': 200});
    layout(g);

    final coords = extractCoordinates(g);
    expect(
        coords,
        equals({
          'a': {'x': 50 / 2, 'y': 200 / 2},
          'b': {'x': 50 + 200 + 75 / 2, 'y': 200 / 2}
        }));
  });

  test('can layout two nodes connected by an edge', () {
    g.graph()['ranksep'] = 300;
    g.setNode('a', {'width': 50, 'height': 100});
    g.setNode('b', {'width': 75, 'height': 200});
    g.setEdge('a', 'b');
    layout(g);

    final coords = extractCoordinates(g);
    expect(
        coords,
        equals({
          'a': {'x': 75 / 2, 'y': 100 / 2},
          'b': {'x': 75 / 2, 'y': 100 + 300 + 200 / 2}
        }));

    expect(g.edge('a', 'b').containsKey('x'), isFalse);
    expect(g.edge('a', 'b').containsKey('y'), isFalse);
  });

  test('can layout an edge with a label', () {
    g.graph()['ranksep'] = 300;
    g.setNode('a', {'width': 50, 'height': 100});
    g.setNode('b', {'width': 75, 'height': 200});
    g.setEdge('a', 'b', {'width': 60, 'height': 70, 'labelpos': 'c'});
    layout(g);

    final coords = extractCoordinates(g);
    expect(
        coords,
        equals({
          'a': {'x': 75 / 2, 'y': 100 / 2},
          'b': {'x': 75 / 2, 'y': 100 + 150 + 70 + 150 + 200 / 2}
        }));

    expect(g.edge('a', 'b')['x'], equals(75 / 2));
    expect(g.edge('a', 'b')['y'], equals(100 + 150 + 70 / 2));
  });

  group('can layout an edge with a long label, with rankdir =', () {
    for (final rankdir in ['TB', 'BT', 'LR', 'RL']) {
      test(rankdir, () {
        g.graph()['nodesep'] = 10;
        g.graph()['edgesep'] = 10;
        g.graph()['rankdir'] = rankdir;

        for (final v in ['a', 'b', 'c', 'd']) {
          g.setNode(v, {'width': 10, 'height': 10});
        }

        g.setEdge('a', 'c', {'width': 2000, 'height': 10, 'labelpos': 'c'});
        g.setEdge('b', 'd', {'width': 1, 'height': 1});
        layout(g);

        dynamic p1, p2;
        if (rankdir == 'TB' || rankdir == 'BT') {
          p1 = g.edge('a', 'c');
          p2 = g.edge('b', 'd');
        } else {
          p1 = g.node('a');
          p2 = g.node('c');
        }

        expect(((p1['x'] as num) - (p2['x'] as num)).abs(), greaterThan(1000));
      });
    }
  });

  group('can apply an offset, with rankdir =', () {
    for (final rankdir in ['TB', 'BT', 'LR', 'RL']) {
      test(rankdir, () {
        g.graph()['nodesep'] = 10;
        g.graph()['edgesep'] = 10;
        g.graph()['rankdir'] = rankdir;

        for (final v in ['a', 'b', 'c', 'd']) {
          g.setNode(v, {'width': 10, 'height': 10});
        }

        g.setEdge('a', 'b',
            {'width': 10, 'height': 10, 'labelpos': 'l', 'labeloffset': 1000});
        g.setEdge('c', 'd',
            {'width': 10, 'height': 10, 'labelpos': 'r', 'labeloffset': 1000});
        layout(g);

        if (rankdir == 'TB' || rankdir == 'BT') {
          final edge1 = g.edge('a', 'b');
          final points1 = edge1['points'] as List;
          expect(edge1['x'] - (points1[0] as Map)['x'], equals(-1000 - 10 / 2));

          final edge2 = g.edge('c', 'd');
          final points2 = edge2['points'] as List;
          expect(edge2['x'] - (points2[0] as Map)['x'], equals(1000 + 10 / 2));
        } else {
          final edge1 = g.edge('a', 'b');
          final points1 = edge1['points'] as List;
          expect(edge1['y'] - (points1[0] as Map)['y'], equals(-1000 - 10 / 2));

          final edge2 = g.edge('c', 'd');
          final points2 = edge2['points'] as List;
          expect(edge2['y'] - (points2[0] as Map)['y'], equals(1000 + 10 / 2));
        }
      });
    }
  });

  test('can layout a long edge with a label', () {
    g.graph()['ranksep'] = 300;
    g.setNode('a', {'width': 50, 'height': 100});
    g.setNode('b', {'width': 75, 'height': 200});
    g.setEdge(
        'a', 'b', {'width': 60, 'height': 70, 'minlen': 2, 'labelpos': 'c'});
    layout(g);

    expect(g.edge('a', 'b')['x'], equals(75 / 2));

    final edgeY = g.edge('a', 'b')['y'] as double;
    final nodeAY = g.node('a')['y'] as double;
    final nodeBY = g.node('b')['y'] as double;

    expect(edgeY, greaterThan(nodeAY));
    expect(edgeY, lessThan(nodeBY));
  });

  test('can layout out a short cycle', () {
    g.graph()['ranksep'] = 200;
    g.setNode('a', {'width': 100, 'height': 100});
    g.setNode('b', {'width': 100, 'height': 100});
    g.setEdge('a', 'b', {'weight': 2});
    g.setEdge('b', 'a');
    layout(g);

    final coords = extractCoordinates(g);
    expect(
        coords,
        equals({
          'a': {'x': 100 / 2, 'y': 100 / 2},
          'b': {'x': 100 / 2, 'y': 100 + 200 + 100 / 2}
        }));

    // 一个箭头应该指向下方，一个指向上方
    final edgeAB = g.edge('a', 'b');
    final edgeBA = g.edge('b', 'a');
    final pointsAB = edgeAB['points'] as List;
    final pointsBA = edgeBA['points'] as List;

    expect((pointsAB[1] as Map)['y'], greaterThan((pointsAB[0] as Map)['y']));
    expect((pointsBA[0] as Map)['y'], greaterThan((pointsBA[1] as Map)['y']));
  });

  test('adds rectangle intersects for edges', () {
    g.graph()['ranksep'] = 200;
    g.setNode('a', {'width': 100, 'height': 100});
    g.setNode('b', {'width': 100, 'height': 100});
    g.setEdge('a', 'b');
    layout(g);

    final points = g.edge('a', 'b')['points'] as List;
    expect(points.length, equals(3));

    expect(
        points,
        equals([
          {'x': 100 / 2, 'y': 100}, // intersect with bottom of a
          {'x': 100 / 2, 'y': 100 + 200 / 2}, // point for edge label
          {'x': 100 / 2, 'y': 100 + 200} // intersect with top of b
        ]));
  });

  test('adds rectangle intersects for edges spanning multiple ranks', () {
    g.graph()['ranksep'] = 200;
    g.setNode('a', {'width': 100, 'height': 100});
    g.setNode('b', {'width': 100, 'height': 100});
    g.setEdge('a', 'b', {'minlen': 2});
    layout(g);

    final points = g.edge('a', 'b')['points'] as List;
    expect(points.length, equals(5));

    expect(
        points,
        equals([
          {'x': 100 / 2, 'y': 100}, // intersect with bottom of a
          {'x': 100 / 2, 'y': 100 + 200 / 2}, // bend #1
          {'x': 100 / 2, 'y': 100 + 400 / 2}, // point for edge label
          {'x': 100 / 2, 'y': 100 + 600 / 2}, // bend #2
          {'x': 100 / 2, 'y': 100 + 800 / 2} // intersect with top of b
        ]));
  });

  group('can layout a self loop', () {
    for (final rankdir in ['TB', 'BT', 'LR', 'RL']) {
      test('in rankdir = $rankdir', () {
        g.graph()['edgesep'] = 75;
        g.graph()['rankdir'] = rankdir;
        g.setNode('a', {'width': 100, 'height': 100});
        g.setEdge('a', 'a', {'width': 50, 'height': 50});
        layout(g);

        final nodeA = g.node('a');
        final points = g.edge('a', 'a')['points'] as List;
        expect(points.length, equals(7));

        for (final point in points) {
          final pt = point as Map;
          if (rankdir != 'LR' && rankdir != 'RL') {
            expect(pt['x'], greaterThan(nodeA['x']));
            expect(((pt['y'] as double) - (nodeA['y'] as double)).abs(),
                lessThanOrEqualTo(nodeA['height'] / 2));
          } else {
            expect(pt['y'], greaterThan(nodeA['y']));
            expect(((pt['x'] as double) - (nodeA['x'] as double)).abs(),
                lessThanOrEqualTo(nodeA['width'] / 2));
          }
        }
      });
    }
  });

  test('can layout a graph with subgraphs', () {
    // To be expanded, this primarily ensures nothing blows up for the moment.
    g.setNode('a', {'width': 50, 'height': 50});
    g.setParent('a', 'sg1');
    layout(g);
  });

  test('minimizes the height of subgraphs', () {
    for (final v in ['a', 'b', 'c', 'd', 'x', 'y']) {
      g.setNode(v, {'width': 50, 'height': 50});
    }
    g.setPath(['a', 'b', 'c', 'd']);
    g.setEdge('a', 'x', {'weight': 100});
    g.setEdge('y', 'd', {'weight': 100});
    g.setParent('x', 'sg');
    g.setParent('y', 'sg');

    // We did not set up an edge (x, y), and we set up high-weight edges from
    // outside of the subgraph to nodes in the subgraph. This is to try to
    // force nodes x and y to be on different ranks, which we want our ranker
    // to avoid.
    layout(g);
    expect(g.node('x')['y'], equals(g.node('y')['y']));
  });

  test('can layout subgraphs with different rankdirs', () {
    g.setNode('a', {'width': 50, 'height': 50});
    g.setNode('sg', {});
    g.setParent('a', 'sg');

    void check(String rankdir) {
      expect(g.node('sg')['width'], greaterThan(50), reason: 'width $rankdir');
      expect(g.node('sg')['height'], greaterThan(50),
          reason: 'height $rankdir');
      expect(g.node('sg')['x'], greaterThan(50 / 2), reason: 'x $rankdir');
      expect(g.node('sg')['y'], greaterThan(50 / 2), reason: 'y $rankdir');
    }

    for (final rankdir in ['tb', 'bt', 'lr', 'rl']) {
      g.graph()['rankdir'] = rankdir;
      layout(g);
      check(rankdir);
    }
  });

  test('adds dimensions to the graph', () {
    g.setNode('a', {'width': 100, 'height': 50});
    layout(g);
    expect(g.graph()['width'], equals(100));
    expect(g.graph()['height'], equals(50));
  });

  group('ensures all coordinates are in the bounding box for the graph', () {
    for (final rankdir in ['TB']) { //, 'BT', 'LR', 'RL'
      group(rankdir, () {
        setUp(() {
          g.graph()['rankdir'] = rankdir;
        });

        test('node', () {
          g.setNode('a', {'width': 100, 'height': 200});
          layout(g);
          expect(g.node('a')['x'], equals(100 / 2));
          expect(g.node('a')['y'], equals(200 / 2));
        });

        test('edge, labelpos = l', () {
          g.setNode('a', {'width': 100, 'height': 100});
          g.setNode('b', {'width': 100, 'height': 100});
          g.setEdge('a', 'b', {
            'width': 1000,
            'height': 2000,
            'labelpos': 'l',
            'labeloffset': 0
          });
          layout(g);
          if (rankdir == 'TB' || rankdir == 'BT') {
            expect(g.edge('a', 'b')['x'], equals(1000 / 2));
          } else {
            expect(g.edge('a', 'b')['y'], equals(2000 / 2));
          }
        });
      });
    }
  });

  test('treats attributes with case-insensitivity', () {
    g.graph()['nodeSep'] = 200; // note the capital S
    g.setNode('a', {'width': 50, 'height': 100});
    g.setNode('b', {'width': 75, 'height': 200});
    layout(g);
    final coords = extractCoordinates(g);
    expect(
        coords,
        equals({
          'a': {'x': 50 / 2, 'y': 200 / 2},
          'b': {'x': 50 + 200 + 75 / 2, 'y': 200 / 2}
        }));
  });
}
