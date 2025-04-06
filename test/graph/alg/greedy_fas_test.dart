import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/graph/alg/greedy_fas.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('greedyFAS', () {
    late Graph g;

    setUp(() {
      g = Graph();
    });

    test('returns the empty set for empty graphs', () {
      expect(greedyFAS(g), equals([]));
    });

    test('returns the empty set for single-node graphs', () {
      g.setNode('a');
      expect(greedyFAS(g), equals([]));
    });

    test('returns an empty set if the input graph is acyclic', () {
      g.setEdge('a', 'b');
      g.setEdge('b', 'c');
      g.setEdge('b', 'd');
      g.setEdge('a', 'e');
      expect(greedyFAS(g), equals([]));
    });

    test('returns a single edge with a simple cycle', () {
      g.setEdge('a', 'b');
      g.setEdge('b', 'a');
      final fas = greedyFAS(g);
      checkFAS(g, fas);
    });

    test('returns a single edge in a 4-node cycle', () {
      g.setEdge('n1', 'n2');
      setPath(g, ['n2', 'n3', 'n4', 'n5', 'n2']);
      g.setEdge('n3', 'n5');
      g.setEdge('n4', 'n2');
      g.setEdge('n4', 'n6');
      final fas = greedyFAS(g);
      checkFAS(g, fas);
    });

    test('returns two edges for two 4-node cycles', () {
      g.setEdge('n1', 'n2');
      setPath(g, ['n2', 'n3', 'n4', 'n5', 'n2']);
      g.setEdge('n3', 'n5');
      g.setEdge('n4', 'n2');
      g.setEdge('n4', 'n6');
      setPath(g, ['n6', 'n7', 'n8', 'n9', 'n6']);
      g.setEdge('n7', 'n9');
      g.setEdge('n8', 'n6');
      g.setEdge('n8', 'n10');
      final fas = greedyFAS(g);
      checkFAS(g, fas);
    });

    test('works with arbitrarily weighted edges', () {
      // Our algorithm should also work for graphs with multi-edges, a graph
      // where more than one edge can be pointing in the same direction between
      // the same pair of incident nodes. We try this by assigning weights to
      // our edges representing the number of edges from one node to the other.

      final g1 = Graph();
      g1.setEdge('n1', 'n2', 2);
      g1.setEdge('n2', 'n1', 1);
      expect(
          greedyFAS(g1, weightFn(g1)).map((e) => {'v': e['v'], 'w': e['w']}),
          equals([
            {'v': 'n2', 'w': 'n1'}
          ]));

      final g2 = Graph();
      g2.setEdge('n1', 'n2', 1);
      g2.setEdge('n2', 'n1', 2);
      expect(
          greedyFAS(g2, weightFn(g2)).map((e) => {'v': e['v'], 'w': e['w']}),
          equals([
            {'v': 'n1', 'w': 'n2'}
          ]));
    });

    test('works for multigraphs', () {
      final g = Graph(isMultigraph: true);
      g.setEdge('a', 'b', 5, 'foo');
      g.setEdge('b', 'a', 2, 'bar');
      g.setEdge('b', 'a', 2, 'baz');
      final fas = greedyFAS(g, weightFn(g));

      // Sort by name for consistent comparison
      final sortedFas = List.from(fas)
        ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

      expect(
          sortedFas.map((e) => {'v': e['v'], 'w': e['w'], 'name': e['name']}),
          equals([
            {'v': 'b', 'w': 'a', 'name': 'bar'},
            {'v': 'b', 'w': 'a', 'name': 'baz'}
          ]));
    });
  });
}

/// Helper function to set a path in the graph
void setPath(Graph g, List<String> path) {
  for (int i = 0; i < path.length - 1; i++) {
    g.setEdge(path[i], path[i + 1]);
  }
}

/// Helper function to validate that a FAS makes a graph acyclic
void checkFAS(Graph g, List<Map<String, dynamic>> fas) {
  final n = g.getNodes().length;
  final m = g.edges()?.length ?? 0;

  final testGraph = Graph();

  // Copy nodes and edges, excluding FAS edges
  for (final node in g.getNodes()) {
    testGraph.setNode(node);
  }

  final edges = g.edges() ?? [];
  for (final edge in edges) {
    bool inFas = false;
    for (final fasEdge in fas) {
      if (fasEdge['v'] == edge['v'] && fasEdge['w'] == edge['w']) {
        inFas = true;
        break;
      }
    }
    if (!inFas) {
      testGraph.setEdge(edge['v'], edge['w']);
    }
  }

  // Check that there are no cycles in the resulting graph
  expect(findCycles(testGraph), equals([]));

  // Check that the FAS size meets the performance bounds
  // Use floor to account for rounding issues in the bound calculation
  final bound = (m / 2).floor() - (n / 6).floor();
  expect(fas.length, lessThanOrEqualTo(bound));
}

/// Helper function to find cycles in a graph
List<List<String>> findCycles(Graph g) {
  final cycles = <List<String>>[];
  final visited = <String, bool>{};
  final path = <String>[];
  final pathSet = <String>{};

  void dfs(String node) {
    // Skip if node is already on current path (cycle found)
    if (pathSet.contains(node)) {
      // Extract the cycle from the path
      final cycleStart = path.indexOf(node);
      cycles.add(path.sublist(cycleStart).toList()..add(node));
      return;
    }

    // Skip if already visited
    if (visited[node] == true) return;

    visited[node] = true;
    path.add(node);
    pathSet.add(node);

    final successors = g.successors(node) ?? [];
    for (final successor in successors) {
      dfs(successor);
    }

    path.removeLast();
    pathSet.remove(node);
  }

  // Apply DFS to each node
  for (final node in g.getNodes()) {
    if (visited[node] != true) {
      dfs(node);
    }
  }

  return cycles;
}

/// Weight function for the greedy FAS algorithm
dynamic Function(Map<String, dynamic>) weightFn(Graph g) {
  return (e) => g.edge(e);
}
