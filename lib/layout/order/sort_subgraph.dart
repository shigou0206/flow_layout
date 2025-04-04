import 'barycenter.dart';
import 'resolve_conflicts.dart';
import 'sort.dart';
import 'package:flow_layout/graph/graph.dart';

SortResult sortSubgraph(Graph g, String v, Graph cg, [bool biasRight = false]) {
  List<String> movable = g.children(v) ?? [];
  final node = g.node(v) as Map?;
  final bl = node?['borderLeft'] as String?;
  final br = node?['borderRight'] as String?;
  final subgraphs = <String, SortResult>{};

  if (bl != null) {
    movable = movable.where((w) => w != bl && w != br).toList();
  }

  final barycenters = barycenter(g, movable);

  for (var entry in barycenters) {
    if ((g.children(entry.v))?.isNotEmpty == true) {
      final subgraphResult = sortSubgraph(g, entry.v, cg, biasRight);
      subgraphs[entry.v] = subgraphResult;
      if (subgraphResult.barycenter != null) {
        mergeBarycenters(entry, subgraphResult);
      }
    }
  }

  final resolvedEntries = resolveConflicts(
    barycenters,
    cg,
  );

  expandSubgraphs(resolvedEntries, subgraphs);

  var result = sort(
    resolvedEntries
        .map((e) => Entry(
              vs: e.vs,
              i: e.i,
              barycenter: e.barycenter,
              weight: e.weight,
            ))
        .toList(),
    biasRight,
  );

  if (bl != null && br != null) {
    result = SortResult(vs: [bl, ...result.vs, br]);

    final blPreds = g.predecessors(bl);
    if (blPreds?.isNotEmpty == true) {
      final blOrder = (g.node(blPreds!.first) as Map)['order'] as int;
      final brOrder =
          (g.node(g.predecessors(br)!.first) as Map)['order'] as int;

      if (result.barycenter == null) {
        result = SortResult(vs: result.vs, barycenter: 0, weight: 0);
      }

      result = SortResult(
        vs: result.vs,
        barycenter: (result.barycenter! * result.weight! + blOrder + brOrder) /
            (result.weight! + 2),
        weight: result.weight! + 2,
      );
    }
  }

  return result;
}

void expandSubgraphs(
    List<ConflictEntry> entries, Map<String, SortResult> subgraphs) {
  for (var entry in entries) {
    entry.vs = entry.vs.expand((v) => subgraphs[v]?.vs ?? [v]).toList();
  }
}

void mergeBarycenters(BarycenterResult target, SortResult other) {
  if (target.barycenter != null) {
    target.barycenter = (target.barycenter! * target.weight! +
            other.barycenter! * other.weight!) /
        (target.weight! + other.weight!);
    target.weight = target.weight! + other.weight!;
  } else {
    target.barycenter = other.barycenter;
    target.weight = other.weight;
  }
}
