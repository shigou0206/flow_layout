import 'package:flow_layout/graph/graph.dart';

List<List<String>> initOrder(Graph g) {
  final visited = <String, bool>{};
  final simpleNodes = g.getNodes().where((v) => (g.children(v) ?? []).isEmpty);
  final simpleNodesRanks =
      simpleNodes.map((v) => (g.node(v)?['rank'] as int?) ?? 0);
  final maxRank = simpleNodesRanks.isEmpty
      ? 0
      : simpleNodesRanks.reduce((a, b) => a > b ? a : b);

  final layers = List.generate(maxRank + 1, (_) => <String>[]);

  void dfs(String v) {
    if (visited[v] == true) return;
    visited[v] = true;

    final node = g.node(v) as Map?;
    if (node == null || node['rank'] == null) return;

    layers[node['rank'] as int].add(v);

    final successors = g.successors(v) ?? [];
    for (final succ in successors) {
      dfs(succ);
    }
  }

  final orderedVs = simpleNodes.toList()
    ..sort((a, b) {
      final rankA = (g.node(a)?['rank'] as int?) ?? 0;
      final rankB = (g.node(b)?['rank'] as int?) ?? 0;
      return rankA.compareTo(rankB);
    });

  for (final v in orderedVs) {
    dfs(v);
  }

  return layers;
}
