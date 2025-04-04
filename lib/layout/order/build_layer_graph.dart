import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/utils.dart' as util;

Graph buildLayerGraph(Graph g, int rank, String relationship) {
  final root = createRootNode(g);
  final result = Graph(isCompound: true)
    ..setGraph({'root': root})
    ..setDefaultNodeLabel((v) => g.node(v));

  for (final v in g.getNodes()) {
    final node = g.node(v) as Map? ?? {};
    final parent = g.parent(v);

    if ((node['rank'] == rank) ||
        (node['minRank'] != null &&
            node['maxRank'] != null &&
            node['minRank'] <= rank &&
            rank <= node['maxRank'])) {
      result.setNode(v);
      result.setParent(v, parent ?? root);

      // 假设只有短边！
      final edges = relationship == 'inEdges' ? g.inEdges(v) : g.outEdges(v);

      for (final e in edges ?? []) {
        final u = e.v == v ? e.w : e.v;
        final existingEdge = result.edge(u, v) as Map?;
        final existingWeight =
            existingEdge != null ? existingEdge['weight'] : 0;
        final gEdgeLabel = g.edgeLabels[e.id] as Map? ?? {};
        final weight = (gEdgeLabel['weight'] ?? 1) + existingWeight;

        result.setEdge(u, v, {'weight': weight});
      }

      if (node.containsKey('minRank')) {
        result.setNode(v, {
          'borderLeft': node['borderLeft'][rank],
          'borderRight': node['borderRight'][rank]
        });
      }
    }
  }

  return result;
}

String createRootNode(Graph g) {
  String v;
  do {
    v = util.uniqueId('_root');
  } while (g.hasNode(v));
  return v;
}
