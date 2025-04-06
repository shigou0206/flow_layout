import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/position/layout_position.dart' as position;
import 'package:test/test.dart';

void main() {
  group('position', () {
    late Graph g;

    setUp(() {
      g = Graph()
        ..isCompound = true
        ..setGraph({
          'ranksep': 50,
          'nodesep': 50,
          'edgesep': 10
        });
    });
    
    // Helper function to extract node coordinates
    Map<String, Map<String, num>> extractCoordinates(Graph g) {
      final result = <String, Map<String, num>>{};
      for (final v in g.getNodes()) {
        final node = g.node(v);
        if (node != null) {
          final coords = <String, num>{};
          if (node['x'] != null) coords['x'] = node['x'] as num;
          if (node['y'] != null) coords['y'] = node['y'] as num;
          if (coords.isNotEmpty) {
            result[v] = coords;
          }
        }
      }
      return result;
    }

    test('respects ranksep', () {
      g.graph()?['ranksep'] = 1000;
      g.setNode('a', {'width': 50, 'height': 100, 'rank': 0, 'order': 0});
      g.setNode('b', {'width': 50, 'height': 80, 'rank': 1, 'order': 0});
      g.setEdge('a', 'b', {});
      
      // Debug: Print node attributes before positioning
      print('Before positioning - Node a: ${g.node('a')}');
      print('Before positioning - Node b: ${g.node('b')}');
      
      position.position(g);
      
      // Debug: Print node attributes after positioning
      print('After positioning - Node a: ${g.node('a')}');
      print('After positioning - Node b: ${g.node('b')}');
      
      final coords = extractCoordinates(g);
      print('Extracted coordinates: $coords');
      
      final expectedY = 100 + 1000 + 80 / 2;
      expect(coords['b']?['y'], equals(expectedY));
    });

    test('use the largest height in each rank with ranksep', () {
      g.graph()?['ranksep'] = 1000;
      g.setNode('a', {'width': 50, 'height': 100, 'rank': 0, 'order': 0});
      g.setNode('b', {'width': 50, 'height': 80, 'rank': 0, 'order': 1});
      g.setNode('c', {'width': 50, 'height': 90, 'rank': 1, 'order': 0});
      g.setEdge('a', 'c', {});
      
      // Debug: Print node attributes before positioning
      print('Before positioning - Node a: ${g.node('a')}');
      print('Before positioning - Node b: ${g.node('b')}');
      print('Before positioning - Node c: ${g.node('c')}');
      
      position.position(g);
      
      // Debug: Print node attributes after positioning
      print('After positioning - Node a: ${g.node('a')}');
      print('After positioning - Node b: ${g.node('b')}');
      print('After positioning - Node c: ${g.node('c')}');
      
      final coords = extractCoordinates(g);
      print('Extracted coordinates: $coords');
      
      expect(coords['a']?['y'], equals(100 / 2));
      expect(coords['b']?['y'], equals(100 / 2)); // Note we used 100 and not 80 here
      expect(coords['c']?['y'], equals(100 + 1000 + 90 / 2));
    });

    test('respects nodesep', () {
      g.graph()?['nodesep'] = 1000;
      g.setNode('a', {'width': 50, 'height': 100, 'rank': 0, 'order': 0});
      g.setNode('b', {'width': 70, 'height': 80, 'rank': 0, 'order': 1});
      
      // Debug: Print node attributes before positioning
      print('Before positioning - Node a: ${g.node('a')}');
      print('Before positioning - Node b: ${g.node('b')}');
      
      position.position(g);
      
      // Debug: Print node attributes after positioning
      print('After positioning - Node a: ${g.node('a')}');
      print('After positioning - Node b: ${g.node('b')}');
      
      final coords = extractCoordinates(g);
      print('Extracted coordinates: $coords');
      
      // The expected x value for node b: node_a.x + 50/2 + 1000 + 70/2
      if (coords['a'] != null && coords['b'] != null) {
        final aX = coords['a']!['x'] as num;
        final bX = coords['b']!['x'] as num;
        final expectedX = aX + 50 / 2 + 1000 + 70 / 2;
        expect(bX, equals(expectedX));
      } else {
        fail('Node a or b coordinates are missing');
      }
    });

    test('should not try to position the subgraph node itself', () {
      g.setNode('a', {'width': 50, 'height': 50, 'rank': 0, 'order': 0});
      g.setNode('sg1', {});
      g.setParent('a', 'sg1');
      
      // Debug: Print node attributes before positioning
      print('Before positioning - Node a: ${g.node('a')}');
      print('Before positioning - Subgraph node sg1: ${g.node('sg1')}');
      
      position.position(g);
      
      // Debug: Print node attributes after positioning
      print('After positioning - Node a: ${g.node('a')}');
      print('After positioning - Subgraph node sg1: ${g.node('sg1')}');
      
      final coords = extractCoordinates(g);
      print('Extracted coordinates: $coords');
      
      expect(coords.containsKey('sg1'), isFalse);
    });
  });
} 