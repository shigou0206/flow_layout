import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/utils.dart' as util;

Graph buildLayerGraph(Graph g, int rank, String relationship) {
  final root = createRootNode(g);
  final result = Graph(isCompound: true)
    ..setGraph({'root': root})
    ..setDefaultNodeLabel((v) => g.node(v));

  // Add nodes for this rank
  for (final v in g.getNodes()) {
    final node = g.node(v) as Map? ?? {};
    final parent = g.parent(v);

    if ((node['rank'] == rank) ||
        (node['minRank'] != null &&
            node['maxRank'] != null &&
            node['minRank'] <= rank &&
            rank <= node['maxRank'])) {
      // Add the node to the graph
      result.setNode(v);
      result.setParent(v, parent ?? root);

      // For each edge incident on v, add a corresponding edge to the layer graph
      final edges = relationship == 'inEdges' ? g.inEdges(v) : g.outEdges(v);

      for (final e in edges ?? []) {
        // For inEdges, we keep the original edge direction (u->v)
        // For outEdges, we reverse it (v->u)
        String source, target;
        
        if (relationship == 'inEdges') {
          source = e['v'];
          target = e['w'];
        } else { // outEdges
          source = e['w'];
          target = e['v'];
        }
        
        // Get original edge data from the graph
        final edgeData = g.edge(e) ?? {};
        final edgeWeight = (edgeData['weight'] ?? 1).toDouble();
        
        // If there's already an edge between these nodes, add to its weight
        final existingEdge = result.edge(source, target);
        final existingWeight = existingEdge is Map ? (existingEdge['weight'] ?? 0).toDouble() : 0.0;
        
        result.setEdge(source, target, {'weight': edgeWeight + existingWeight});
      }

      // Handle compound nodes with borders
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
