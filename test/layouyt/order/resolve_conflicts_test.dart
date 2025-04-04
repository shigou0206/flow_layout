import 'package:flutter_test/flutter_test.dart';
import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/order/resolve_conflicts.dart';
import 'package:flow_layout/layout/order/barycenter.dart';

void main() {
  late Graph cg;

  setUp(() => cg = Graph());

  int sortFunc(a, b) => a.vs[0].compareTo(b.vs[0]);

  group('resolveConflicts', () {
    test('returns back nodes unchanged when no constraints exist', () {
      final input = [
        BarycenterResult(v: 'a', barycenter: 2.0, weight: 3.0),
        BarycenterResult(v: 'b', barycenter: 1.0, weight: 2.0)
      ];
      final result = resolveConflicts(input, cg)..sort(sortFunc);
      expect(result, [
        ConflictEntry(vs: ['a'], i: 0, barycenter: 2.0, weight: 3.0),
        ConflictEntry(vs: ['b'], i: 1, barycenter: 1.0, weight: 2.0)
      ]);
    });

    test('returns back nodes unchanged when no conflicts exist', () {
      final input = [
        BarycenterResult(v: 'a', barycenter: 2.0, weight: 3.0),
        BarycenterResult(v: 'b', barycenter: 1.0, weight: 2.0)
      ];
      cg.setEdge('b', 'a');
      final result = resolveConflicts(input, cg)..sort(sortFunc);
      expect(result, [
        ConflictEntry(vs: ['a'], i: 0, barycenter: 2.0, weight: 3.0),
        ConflictEntry(vs: ['b'], i: 1, barycenter: 1.0, weight: 2.0)
      ]);
    });

    test('coalesces nodes when there is a conflict', () {
      final input = [
        BarycenterResult(v: 'a', barycenter: 2.0, weight: 3.0),
        BarycenterResult(v: 'b', barycenter: 1.0, weight: 2.0)
      ];
      cg.setEdge('a', 'b');
      final result = resolveConflicts(input, cg);
      expect(result, [
        ConflictEntry(
          vs: ['a', 'b'],
          i: 0,
          barycenter: (3 * 2 + 2 * 1) / 5,
          weight: 5.0,
        )
      ]);
    });

    test('works with multiple constraints for the same target', () {
      final input = [
        BarycenterResult(v: 'a', barycenter: 4.0, weight: 1.0),
        BarycenterResult(v: 'b', barycenter: 3.0, weight: 1.0),
        BarycenterResult(v: 'c', barycenter: 2.0, weight: 1.0),
      ];
      cg.setEdge('a', 'c');
      cg.setEdge('b', 'c');
      final result = resolveConflicts(input, cg);
      expect(result.length, 1);
      expect(result[0].vs.indexOf('c'), greaterThan(result[0].vs.indexOf('a')));
      expect(result[0].vs.indexOf('c'), greaterThan(result[0].vs.indexOf('b')));
      expect(result[0].i, 0);
      expect(result[0].barycenter, 3.0);
      expect(result[0].weight, 3.0);
    });

    test('does nothing to a node lacking barycenter and constraints', () {
      final input = [
        BarycenterResult(v: 'a'),
        BarycenterResult(v: 'b', barycenter: 1.0, weight: 2.0)
      ];
      final result = resolveConflicts(input, cg)..sort(sortFunc);
      expect(result, [
        ConflictEntry(vs: ['a'], i: 0),
        ConflictEntry(vs: ['b'], i: 1, barycenter: 1.0, weight: 2.0)
      ]);
    });

    test('treats a node w/o barycenter as violating constraints', () {
      final input = [
        BarycenterResult(v: 'a'),
        BarycenterResult(v: 'b', barycenter: 1.0, weight: 2.0)
      ];
      cg.setEdge('a', 'b');
      final result = resolveConflicts(input, cg);
      expect(result, [
        ConflictEntry(vs: ['a', 'b'], i: 0, barycenter: 1.0, weight: 2.0)
      ]);
    });

    test('ignores edges not related to entries', () {
      final input = [
        BarycenterResult(v: 'a', barycenter: 2.0, weight: 3.0),
        BarycenterResult(v: 'b', barycenter: 1.0, weight: 2.0)
      ];
      cg.setEdge('c', 'd');
      final result = resolveConflicts(input, cg)..sort(sortFunc);
      expect(result, [
        ConflictEntry(vs: ['a'], i: 0, barycenter: 2.0, weight: 3.0),
        ConflictEntry(vs: ['b'], i: 1, barycenter: 1.0, weight: 2.0)
      ]);
    });
  });
}
