import 'dart:collection';
import 'package:flow_layout/graph/graph.dart';

class ConflictEntry {
  List<String> vs;
  int i;
  double? barycenter;
  double? weight;
  int indegree;
  bool merged;
  List<ConflictEntry> inEdges;
  List<ConflictEntry> outEdges;

  ConflictEntry({
    required this.vs,
    required this.i,
    this.barycenter,
    this.weight,
  })  : indegree = 0,
        merged = false,
        inEdges = [],
        outEdges = [];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConflictEntry &&
        listEquals(vs, other.vs) &&
        i == other.i &&
        barycenter == other.barycenter &&
        weight == other.weight;
  }

  @override
  int get hashCode => Object.hash(Object.hashAll(vs), i, barycenter, weight);

  @override
  String toString() =>
      'ConflictEntry(vs: $vs, i: $i, barycenter: $barycenter, weight: $weight)';
}

bool listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (int i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

List<ConflictEntry> resolveConflicts(
    List<Map<String, dynamic>> entries, Graph cg) {
  final mappedEntries = <String, ConflictEntry>{};

  for (var i = 0; i < entries.length; i++) {
    final entry = entries[i];
    final v = entry['v'] as String;
    final tmp = ConflictEntry(
      vs: [v],
      i: i,
      barycenter: entry['barycenter'] as double?,
      weight: entry['weight'] as double?,
    );
    mappedEntries[v] = tmp;
  }

  for (var e in cg.edges()) {
    final entryV = mappedEntries[e.v];
    final entryW = mappedEntries[e.w];
    if (entryV != null && entryW != null) {
      entryW.indegree++;
      entryV.outEdges.add(entryW);
    }
  }

  final sourceSet = Queue<ConflictEntry>();
  for (var entry in mappedEntries.values) {
    if (entry.indegree == 0) sourceSet.add(entry);
  }

  return _doResolveConflicts(sourceSet);
}

List<ConflictEntry> _doResolveConflicts(Queue<ConflictEntry> sourceSet) {
  final entries = <ConflictEntry>[];

  while (sourceSet.isNotEmpty) {
    final entry = sourceSet.removeLast();
    entries.add(entry);

    for (var uEntry in entry.inEdges.reversed) {
      if (uEntry.merged) continue;

      if (uEntry.barycenter == null ||
          entry.barycenter == null ||
          uEntry.barycenter! >= entry.barycenter!) {
        _mergeEntries(entry, uEntry);
      }
    }

    for (var wEntry in entry.outEdges) {
      wEntry.inEdges.add(entry);
      if (--wEntry.indegree == 0) {
        sourceSet.add(wEntry);
      }
    }
  }

  return entries
      .where((entry) => !entry.merged)
      .map((entry) => ConflictEntry(
            vs: entry.vs,
            i: entry.i,
            barycenter: entry.barycenter,
            weight: entry.weight,
          ))
      .toList();
}

void _mergeEntries(ConflictEntry target, ConflictEntry source) {
  double sum = 0;
  double weight = 0;

  if (target.weight != null) {
    sum += target.barycenter! * target.weight!;
    weight += target.weight!;
  }

  if (source.weight != null) {
    sum += source.barycenter! * source.weight!;
    weight += source.weight!;
  }

  target.vs = [...source.vs, ...target.vs];
  target.barycenter = sum / weight;
  target.weight = weight;
  target.i = target.i < source.i ? target.i : source.i;
  source.merged = true;
}
