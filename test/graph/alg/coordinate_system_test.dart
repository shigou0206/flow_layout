import "package:flutter_test/flutter_test.dart";
import "package:flow_layout/graph/graph.dart";
import "package:flow_layout/graph/alg/coordinate_system.dart";

void main() {
  group('coordinateSystem', () {
    late Graph g;

    setUp(() {
      g = Graph();
    });

    group('coordinateSystem.adjust', () {
      setUp(() {
        g.setNode('a', {'width': 100, 'height': 200});
      });

      test('does nothing to node dimensions with rankdir = TB', () {
        g.setGraph({'rankdir': 'TB'});
        CoordinateSystem.adjust(g);
        expect(g.node('a'), equals({'width': 100, 'height': 200}));
      });

      test('does nothing to node dimensions with rankdir = BT', () {
        g.setGraph({'rankdir': 'BT'});
        CoordinateSystem.adjust(g);
        expect(g.node('a'), equals({'width': 100, 'height': 200}));
      });

      test('swaps width and height for nodes with rankdir = LR', () {
        g.setGraph({'rankdir': 'LR'});
        CoordinateSystem.adjust(g);
        expect(g.node('a'), equals({'width': 200, 'height': 100}));
      });

      test('swaps width and height for nodes with rankdir = RL', () {
        g.setGraph({'rankdir': 'RL'});
        CoordinateSystem.adjust(g);
        expect(g.node('a'), equals({'width': 200, 'height': 100}));
      });
    });

    group('coordinateSystem.undo', () {
      setUp(() {
        g.setNode('a', {'width': 100, 'height': 200, 'x': 20, 'y': 40});
      });

      test('does nothing to points with rankdir = TB', () {
        g.setGraph({'rankdir': 'TB'});
        CoordinateSystem.undo(g);
        expect(g.node('a'), equals({'x': 20, 'y': 40, 'width': 100, 'height': 200}));
      });

      test('flips the y coordinate for points with rankdir = BT', () {
        g.setGraph({'rankdir': 'BT'});
        CoordinateSystem.undo(g);
        expect(g.node('a'), equals({'x': 20, 'y': -40, 'width': 100, 'height': 200}));
      });

      test('swaps dimensions and coordinates for points with rankdir = LR', () {
        g.setGraph({'rankdir': 'LR'});
        CoordinateSystem.undo(g);
        expect(g.node('a'), equals({'x': 40, 'y': 20, 'width': 200, 'height': 100}));
      });

      test('swaps dims and coords and flips x for points with rankdir = RL', () {
        g.setGraph({'rankdir': 'RL'});
        CoordinateSystem.undo(g);
        expect(g.node('a'), equals({'x': -40, 'y': 20, 'width': 200, 'height': 100}));
      });
    });
  });
}