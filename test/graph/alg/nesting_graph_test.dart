import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/graph/alg/nesting_graph.dart';
import 'package:flutter_test/flutter_test.dart';

/// Finds the connected components in the graph
List<List<String>> components(Graph g) {
  final visited = <String, bool>{};
  final result = <List<String>>[];

  for (final node in g.getNodes()) {
    if (!visited.containsKey(node)) {
      final component = <String>[];
      _dfs(g, node, visited, component);
      result.add(component);
    }
  }

  return result;
}

/// Helper DFS function for finding connected components
void _dfs(
    Graph g, String node, Map<String, bool> visited, List<String> component) {
  visited[node] = true;
  component.add(node);

  final neighbors = g.isDirected
      ? [...g.successors(node) ?? [], ...g.predecessors(node) ?? []]
      : g.neighbors(node) ?? [];

  for (final neighbor in neighbors) {
    if (!visited.containsKey(neighbor)) {
      _dfs(g, neighbor, visited, component);
    }
  }
}

void main() {
  group('rank/nestingGraph', () {
    late Graph g;

    setUp(() {
      g = Graph(isCompound: true);
      g.setGraph({});
      g.setDefaultNodeLabel((v) => {});
    });

    group('run', () {
      test('connects a disconnected graph', () {
        g.setNode('a', {});
        g.setNode('b', {});
        expect(components(g).length, equals(2));

        NestingGraph.run(g);
        expect(components(g).length, equals(1));
        expect(g.hasNode('a'), isTrue);
        expect(g.hasNode('b'), isTrue);
      });

      test('adds border nodes to the top and bottom of a subgraph', () {
        g.setParent('a', 'sg1');
        NestingGraph.run(g);

        final borderTop = g.node('sg1')?['borderTop'];
        final borderBottom = g.node('sg1')?['borderBottom'];

        expect(borderTop, isNotNull);
        expect(borderBottom, isNotNull);
        expect(g.parent(borderTop), equals('sg1'));
        expect(g.parent(borderBottom), equals('sg1'));

        expect(g.outEdges(borderTop, 'a')?.length, equals(1));
        expect(g.edge(g.outEdges(borderTop, 'a')![0])?['minlen'], equals(1));

        expect(g.outEdges('a', borderBottom)?.length, equals(1));
        expect(g.edge(g.outEdges('a', borderBottom)![0])?['minlen'], equals(1));

        expect(g.node(borderTop),
            equals({'width': 0, 'height': 0, 'dummy': 'border'}));
        expect(g.node(borderBottom),
            equals({'width': 0, 'height': 0, 'dummy': 'border'}));
      });

      test('adds edges between borders of nested subgraphs', () {
        g.setParent('sg2', 'sg1');
        g.setParent('a', 'sg2');
        NestingGraph.run(g);

        final sg1Top = g.node('sg1')?['borderTop'];
        final sg1Bottom = g.node('sg1')?['borderBottom'];
        final sg2Top = g.node('sg2')?['borderTop'];
        final sg2Bottom = g.node('sg2')?['borderBottom'];

        expect(sg1Top, isNotNull);
        expect(sg1Bottom, isNotNull);
        expect(sg2Top, isNotNull);
        expect(sg2Bottom, isNotNull);

        expect(g.outEdges(sg1Top, sg2Top)?.length, equals(1));
        expect(g.edge(g.outEdges(sg1Top, sg2Top)![0])?['minlen'], equals(1));

        expect(g.outEdges(sg2Bottom, sg1Bottom)?.length, equals(1));
        expect(
            g.edge(g.outEdges(sg2Bottom, sg1Bottom)![0])?['minlen'], equals(1));
      });

      test('adds sufficient weight to border to node edges', () {
        // We want to keep subgraphs tight, so we should ensure that the weight for
        // the edge between the top (and bottom) border nodes and nodes in the
        // subgraph have weights exceeding anything in the graph.
        g.setParent('x', 'sg');
        g.setEdge('a', 'x', {'weight': 100});
        g.setEdge('x', 'b', {'weight': 200});
        NestingGraph.run(g);

        final top = g.node('sg')?['borderTop'];
        final bot = g.node('sg')?['borderBottom'];

        expect((g.edge(top, 'x')?['weight'] as num), greaterThan(300));
        expect((g.edge('x', bot)?['weight'] as num), greaterThan(300));
      });

      test('adds an edge from the root to the tops of top-level subgraphs', () {
        g.setParent('a', 'sg1');
        NestingGraph.run(g);

        final root = g.graph()?['nestingRoot'];
        final borderTop = g.node('sg1')?['borderTop'];

        expect(root, isNotNull);
        expect(borderTop, isNotNull);
        expect(g.outEdges(root, borderTop)?.length, equals(1));
        expect(g.hasEdge(root, borderTop), isTrue);
      });

      test('adds an edge from root to each node with the correct minlen #1',
          () {
        g.setNode('a', {});
        NestingGraph.run(g);

        final root = g.graph()?['nestingRoot'];
        expect(root, isNotNull);
        expect(g.outEdges(root, 'a')?.length, equals(1));
        expect(g.edge(g.outEdges(root, 'a')![0]),
            equals({'weight': 0, 'minlen': 1}));
      });

      test('adds an edge from root to each node with the correct minlen #2',
          () {
        g.setParent('a', 'sg1');
        NestingGraph.run(g);

        final root = g.graph()?['nestingRoot'];
        expect(root, isNotNull);
        expect(g.outEdges(root, 'a')?.length, equals(1));
        expect(g.edge(g.outEdges(root, 'a')![0]),
            equals({'weight': 0, 'minlen': 3}));
      });

      test('adds an edge from root to each node with the correct minlen #3',
          () {
        g.setParent('sg2', 'sg1');
        g.setParent('a', 'sg2');
        NestingGraph.run(g);

        final root = g.graph()?['nestingRoot'];
        expect(root, isNotNull);
        expect(g.outEdges(root, 'a')?.length, equals(1));
        expect(g.edge(g.outEdges(root, 'a')![0]),
            equals({'weight': 0, 'minlen': 5}));
      });

      test('does not add an edge from the root to itself', () {
        g.setNode('a', {});
        NestingGraph.run(g);

        final root = g.graph()?['nestingRoot'];
        expect(g.outEdges(root, root), isEmpty);
      });

      test('expands inter-node edges to separate SG border and nodes #1', () {
        g.setEdge('a', 'b', {'minlen': 1});
        NestingGraph.run(g);
        expect(g.edge('a', 'b')?['minlen'], equals(1));
      });

      test('expands inter-node edges to separate SG border and nodes #2', () {
        g.setParent('a', 'sg1');
        g.setEdge('a', 'b', {'minlen': 1});
        NestingGraph.run(g);
        expect(g.edge('a', 'b')?['minlen'], equals(3));
      });

      test('expands inter-node edges to separate SG border and nodes #3', () {
        g.setParent('sg2', 'sg1');
        g.setParent('a', 'sg2');
        g.setEdge('a', 'b', {'minlen': 1});
        NestingGraph.run(g);
        expect(g.edge('a', 'b')?['minlen'], equals(5));
      });

      test('sets minlen correctly for nested SG border to children', () {
        g.setParent('a', 'sg1');
        g.setParent('sg2', 'sg1');
        g.setParent('b', 'sg2');
        NestingGraph.run(g);

        // We expect the following layering:
        //
        // 0: root
        // 1: empty (close sg2)
        // 2: empty (close sg1)
        // 3: open sg1
        // 4: open sg2
        // 5: a, b
        // 6: close sg2
        // 7: close sg1

        final root = g.graph()?['nestingRoot'];
        final sg1Top = g.node('sg1')?['borderTop'];
        final sg1Bot = g.node('sg1')?['borderBottom'];
        final sg2Top = g.node('sg2')?['borderTop'];
        final sg2Bot = g.node('sg2')?['borderBottom'];

        expect(g.edge(root, sg1Top)?['minlen'], equals(3));
        expect(g.edge(sg1Top, sg2Top)?['minlen'], equals(1));
        expect(g.edge(sg1Top, 'a')?['minlen'], equals(2));
        expect(g.edge('a', sg1Bot)?['minlen'], equals(2));
        expect(g.edge(sg2Top, 'b')?['minlen'], equals(1));
        expect(g.edge('b', sg2Bot)?['minlen'], equals(1));
        expect(g.edge(sg2Bot, sg1Bot)?['minlen'], equals(1));
      });
    });

    group('cleanup', () {
      test('removes nesting graph edges', () {
        g.setParent('a', 'sg1');
        g.setEdge('a', 'b', {'minlen': 1});
        NestingGraph.run(g);
        NestingGraph.cleanup(g);
        expect(g.successors('a'), equals(['b']));
      });

      test('removes the root node', () {
        g.setParent('a', 'sg1');
        NestingGraph.run(g);
        NestingGraph.cleanup(g);
        // sg1 + sg1Top + sg1Bottom + "a"
        expect(g.getNodes().length, equals(4));
      });
    });
  });
}
