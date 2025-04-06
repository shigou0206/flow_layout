import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/layout.dart';

void main() {
  print("===== Testing layout algorithm =====");
  
  // Test a simple graph with a single node
  testSimpleGraph();
  
  // Test a more complex graph
  testComplexGraph();
}

void testSimpleGraph() {
  print("\n----- Testing simple graph -----");
  
  final g = Graph()
    ..setGraph({'rankdir': 'TB'})
    ..setNode('a', {'width': 50, 'height': 100});
  
  try {
    layout(g);
    print("✓ Layout successful");
    printNodeCoordinates(g);
  } catch (e, stackTrace) {
    print("✗ Layout failed: $e");
    print("Stack trace: $stackTrace");
  }
}

void testComplexGraph() {
  print("\n----- Testing complex graph -----");
  
  final g = Graph()
    ..setGraph({'rankdir': 'TB', 'nodesep': 50, 'ranksep': 70})
    ..setNode('a', {'width': 50, 'height': 100})
    ..setNode('b', {'width': 75, 'height': 50})
    ..setNode('c', {'width': 60, 'height': 80})
    ..setNode('d', {'width': 90, 'height': 120})
    ..setEdge('a', 'b')
    ..setEdge('b', 'c')
    ..setEdge('a', 'd')
    ..setEdge('c', 'd');
  
  try {
    layout(g);
    print("✓ Layout successful");
    printNodeCoordinates(g);
    printEdgeCoordinates(g);
  } catch (e, stackTrace) {
    print("✗ Layout failed: $e");
    print("Stack trace: $stackTrace");
  }
}

void printNodeCoordinates(Graph g) {
  print("\nNode coordinates:");
  for (final v in g.getNodes()) {
    final node = g.node(v);
    print("Node $v: x=${node['x']}, y=${node['y']}");
  }
}

void printEdgeCoordinates(Graph g) {
  print("\nEdge information:");
  for (final e in g.edges()) {
    final edge = g.edge(e);
    print("Edge ${e['v']} -> ${e['w']}:");
    if (edge.containsKey('points')) {
      final points = edge['points'] as List;
      print("  Points: [");
      for (final point in points) {
        print("    {x: ${point['x']}, y: ${point['y']}}");
      }
      print("  ]");
    }
  }
} 