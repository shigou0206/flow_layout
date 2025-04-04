import 'init_order.dart';
import 'cross_count.dart';
import 'sort_subgraph.dart';
import 'build_layer_graph.dart';
import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/utils.dart' as util;

void order(Graph g, {bool disableOptimalOrderHeuristic = false}) {
  final maxRank = util.maxRank(g);

  final downLayerGraphs =
      buildLayerGraphs(g, util.range(1, maxRank + 1), 'inEdges');
  final upLayerGraphs =
      buildLayerGraphs(g, util.range(maxRank - 1, -1, -1), 'outEdges');

  var layering = initOrder(g);
  assignOrder(g, layering);

  if (disableOptimalOrderHeuristic) return;

  var bestCC = double.infinity;
  List<List<String>> best = [];

  for (var i = 0, lastBest = 0; lastBest < 4; i++, lastBest++) {
    sweepLayerGraphs(i % 2 == 1 ? downLayerGraphs : upLayerGraphs, i % 4 >= 2);

    layering = util.buildLayerMatrix(g);
    final cc = crossCount(g, layering);

    if (cc < bestCC) {
      lastBest = 0;
      best = layering.map((layer) => List<String>.from(layer)).toList();
      bestCC = cc.toDouble();
    }
  }

  assignOrder(g, best);
}

List<Graph> buildLayerGraphs(Graph g, List<int> ranks, String relationship) =>
    ranks.map((rank) => buildLayerGraph(g, rank, relationship)).toList();

void sweepLayerGraphs(List<Graph> layerGraphs, bool biasRight) {
  final cg = Graph();

  for (var lg in layerGraphs) {
    final root = lg.graph()?['root'] as String;
    final sorted = sortSubgraph(lg, root, cg, biasRight);

    for (var i = 0; i < sorted.vs.length; i++) {
      final v = sorted.vs[i];
      final node = lg.node(v);
      if (node != null && node is Map) {
        node['order'] = i;
      } else {
        lg.setNode(v, {'order': i});
      }
    }

    util.addSubgraphConstraints(lg, cg, sorted.vs);
  }
}

void assignOrder(Graph g, List<List<String>> layering) {
  for (var layer in layering) {
    for (var i = 0; i < layer.length; i++) {
      final nodeData = g.node(layer[i]) as Map<String, dynamic>;
      nodeData['order'] = i;
    }
  }
}
