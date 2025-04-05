import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/graph/alg/greedy_fas.dart';

void main() {
  print('Testing greedyFAS algorithm');

  // 测试简单图
  testSimpleGraph();

  // 测试循环图
  testCyclicGraph();

  // 测试带权重的图
  testWeightedGraph();

  print('All tests completed');
}

void testSimpleGraph() {
  print('\n=== Testing Simple Graph ===');
  
  final g = Graph()
    ..setNode('a')
    ..setNode('b')
    ..setNode('c')
    ..setNode('d')
    ..setEdge('a', 'b')
    ..setEdge('b', 'c')
    ..setEdge('c', 'd');

  print('Graph edges before FAS:');
  printEdges(g);

  final fas = greedyFAS(g);
  
  print('Feedback arc set:');
  for (final edge in fas) {
    print('  ${edge['v']} -> ${edge['w']}');
  }
  
  print('FAS size: ${fas.length}');
  if (fas.isEmpty) {
    print('✅ No edges in FAS for acyclic graph');
  } else {
    print('❌ Expected empty FAS for acyclic graph');
  }
}

void testCyclicGraph() {
  print('\n=== Testing Cyclic Graph ===');
  
  final g = Graph()
    ..setNode('a')
    ..setNode('b')
    ..setNode('c')
    ..setNode('d')
    ..setEdge('a', 'b')
    ..setEdge('b', 'c')
    ..setEdge('c', 'd')
    ..setEdge('d', 'a'); // creates a cycle

  print('Graph edges before FAS:');
  printEdges(g);

  final fas = greedyFAS(g);
  
  print('Feedback arc set:');
  for (final edge in fas) {
    print('  ${edge['v']} -> ${edge['w']}');
  }
  
  print('FAS size: ${fas.length}');
  if (fas.length == 1) {
    print('✅ Found a feedback arc to break the cycle');
  } else {
    print('❌ Expected a single edge in FAS');
  }
}

void testWeightedGraph() {
  print('\n=== Testing Weighted Graph ===');
  
  final g = Graph()
    ..setNode('a')
    ..setNode('b')
    ..setNode('c')
    ..setNode('d')
    ..setEdge('a', 'b', {'weight': 3})
    ..setEdge('b', 'c', {'weight': 2})
    ..setEdge('c', 'd', {'weight': 1})
    ..setEdge('d', 'a', {'weight': 0.5}); // low weight edge should be in FAS

  print('Graph edges before FAS (with weights):');
  printEdgesWithWeights(g);

  // Define custom weight function
  dynamic weightFn(Map<String, dynamic> edge) {
    final edgeData = g.edge(edge) as Map<String, dynamic>?;
    return edgeData != null && edgeData.containsKey('weight') 
        ? edgeData['weight'] 
        : 1;
  }

  final fas = greedyFAS(g, weightFn);
  
  print('Feedback arc set:');
  for (final edge in fas) {
    print('  ${edge['v']} -> ${edge['w']} (weight: ${g.edge(edge)['weight']})');
  }
  
  print('FAS size: ${fas.length}');
  if (fas.length == 1) {
    print('✅ Found a feedback arc to break the cycle');
    if (fas.first['v'] == 'd' && fas.first['w'] == 'a') {
      print('✅ Correctly selected the minimum weight edge (d->a)');
    } else {
      print('❌ Expected minimum weight edge (d->a) in FAS');
    }
  } else {
    print('❌ Expected a single edge in FAS');
  }
}

void printEdges(Graph g) {
  final edges = g.edges();
  if (edges == null || edges.isEmpty) {
    print('  No edges in graph');
    return;
  }
  
  for (final edge in edges) {
    print('  ${edge['v']} -> ${edge['w']}');
  }
}

void printEdgesWithWeights(Graph g) {
  final edges = g.edges();
  if (edges == null || edges.isEmpty) {
    print('  No edges in graph');
    return;
  }
  
  for (final edge in edges) {
    final weight = g.edge(edge)['weight'] ?? 1;
    print('  ${edge['v']} -> ${edge['w']} (weight: $weight)');
  }
} 