import 'package:flutter_test/flutter_test.dart';
import 'package:flow_layout/layout/order/sort.dart';

void main() {
  group('sort', () {
    test('sorts nodes by barycenter', () {
      final input = [
        Entry(vs: ['a'], i: 0, barycenter: 2.0, weight: 3.0),
        Entry(vs: ['b'], i: 1, barycenter: 1.0, weight: 2.0),
      ];

      final result = sort(input, false);

      expect(result.vs, equals(['b', 'a']));
      expect(result.barycenter, equals((2 * 3 + 1 * 2) / (3 + 2)));
      expect(result.weight, equals(5));
    });

    test('can sort super-nodes', () {
      final input = [
        Entry(vs: ['a', 'c', 'd'], i: 0, barycenter: 2.0, weight: 3.0),
        Entry(vs: ['b'], i: 1, barycenter: 1.0, weight: 2.0),
      ];

      final result = sort(input, false);

      expect(result.vs, equals(['b', 'a', 'c', 'd']));
      expect(result.barycenter, equals((2 * 3 + 1 * 2) / (3 + 2)));
      expect(result.weight, equals(5));
    });

    test('biases to the left by default', () {
      final input = [
        Entry(vs: ['a'], i: 0, barycenter: 1.0, weight: 1.0),
        Entry(vs: ['b'], i: 1, barycenter: 1.0, weight: 1.0),
      ];

      final result = sort(input, false);

      expect(result.vs, equals(['a', 'b']));
      expect(result.barycenter, equals(1.0));
      expect(result.weight, equals(2));
    });

    test('biases to the right if biasRight = true', () {
      final input = [
        Entry(vs: ['a'], i: 0, barycenter: 1.0, weight: 1.0),
        Entry(vs: ['b'], i: 1, barycenter: 1.0, weight: 1.0),
      ];

      final result = sort(input, true);

      expect(result.vs, equals(['b', 'a']));
      expect(result.barycenter, equals(1.0));
      expect(result.weight, equals(2));
    });

    test('can sort nodes without a barycenter', () {
      final input = [
        Entry(vs: ['a'], i: 0, barycenter: 2.0, weight: 1.0),
        Entry(vs: ['b'], i: 1, barycenter: 6.0, weight: 1.0),
        Entry(vs: ['c'], i: 2),
        Entry(vs: ['d'], i: 3, barycenter: 3.0, weight: 1.0),
      ];

      final result = sort(input, false);

      expect(result.vs, equals(['a', 'd', 'c', 'b']));
      expect(result.barycenter, equals((2 + 6 + 3) / 3));
      expect(result.weight, equals(3));
    });

    test('can handle no barycenters for any nodes', () {
      final input = [
        Entry(vs: ['a'], i: 0),
        Entry(vs: ['b'], i: 3),
        Entry(vs: ['c'], i: 2),
        Entry(vs: ['d'], i: 1),
      ];

      final result = sort(input, false);

      expect(result.vs, equals(['a', 'd', 'c', 'b']));
      expect(result.barycenter, isNull);
      expect(result.weight, isNull);
    });

    test('can handle a barycenter of 0', () {
      final input = [
        Entry(vs: ['a'], i: 0, barycenter: 0.0, weight: 1.0),
        Entry(vs: ['b'], i: 3),
        Entry(vs: ['c'], i: 2),
        Entry(vs: ['d'], i: 1),
      ];

      final result = sort(input, false);

      expect(result.vs, equals(['a', 'd', 'c', 'b']));
      expect(result.barycenter, equals(0.0));
      expect(result.weight, equals(1));
    });
  });
}
