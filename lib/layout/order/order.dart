// import 'package:flow_layout/graph/graph.dart';
// import 'package:flow_layout/layout/utils.dart';
// import 'init_order.dart';
// import 'cross_count.dart';
// import 'sort_subgraph.dart';
// import 'build_layer_graph.dart';
// import 'add_subgraph_constraints.dart';

// void order(Graph g, {Function(Graph, Function)? customOrder, bool disableOptimalOrderHeuristic = false}) {
//   if (customOrder != null) {
//     customOrder(g, order);
//     return;
//   }

//   final maxRank = maxRankValue(g);
//   final downLayerGraphs = buildLayerGraphs(g, range(1, maxRank + 1), 'inEdges');
//   final upLayerGraphs = buildLayerGraphs(g, range(maxRank - 1, -1, -1), 'outEdges');

//   var layering = initOrder(g);
//   assignOrder(g, layering);

//   if (disableOptimalOrderHeuristic) {
//     return;
//   }

//   int bestCC = 1 << 30;
//   List<List<String>> best = [];

//   for (int i = 0, lastBest = 0; lastBest < 4; ++i, ++lastBest) {
//     sweepLayerGraphs(i % 2 == 1 ? downLayerGraphs : upLayerGraphs, i % 4 >= 2);

//     layering = buildLayerMatrix(g);
//     int cc = crossCount(g, layering);
//     if (cc < bestCC) {
//       lastBest = 0;
//       best = layering.map((layer) => List<String>.from(layer)).toList();
//       bestCC = cc;
//     }
//   }

//   assignOrder(g, best);
// }

// List<Graph> buildLayerGraphs(Graph g, List<int> ranks, String relationship) {
//   return ranks.map((rank) => buildLayerGraph(g, rank, relationship)).toList();
// }

// void sweepLayerGraphs(List<Graph> layerGraphs, bool biasRight) {
//   final cg = Graph();
//   for (final lg in layerGraphs) {
//     final root = lg.graph()?['root'];
//     final sorted = sortSubgraph(lg, root, cg, biasRight);
//     for (var i = 0; i < sorted.vs.length; i++) {
//       lg.node(sorted.vs[i])?['order'] = i;
//     }
//     addSubgraphConstraints(lg, cg, sorted.vs);
//   }
// }

// void assignOrder(Graph g, List<List<String>> layering) {
//   for (final layer in layering) {
//     for (int i = 0; i < layer.length; i++) {
//       final node = g.node(layer[i]);
//       if (node != null) {
//         node['order'] = i;
//       }
//     }
//   }
// }

// int maxRankValue(Graph g) {
//   int max = -1;
//   for (var nodeId in g.getNodes()) {
//     final node = g.node(nodeId);
//     if (node != null && node['rank'] is int && node['rank'] > max) {
//       max = node['rank'];
//     }
//   }
//   return max;
// }
