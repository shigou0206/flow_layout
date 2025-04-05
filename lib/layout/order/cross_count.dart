import 'package:flow_layout/graph/graph.dart';

int crossCount(Graph g, List<List<String>> layering) {
  int cc = 0;
  for (int i = 1; i < layering.length; ++i) {
    cc += twoLayerCrossCount(g, layering[i - 1], layering[i]);
  }
  return cc;
}

int twoLayerCrossCount(
    Graph g, List<String> northLayer, List<String> southLayer) {
  final southPos =
      Map.fromIterables(southLayer, List.generate(southLayer.length, (i) => i));

  final southEntries = northLayer.expand((v) {
    final outEdges = g.outEdges(v) ?? [];
    return outEdges.map((e) {
      final edgeLabel = g.edge(e);
      return {
        'pos': southPos[e['w']],
        'weight': ((edgeLabel as Map?)?['weight'] ?? 1).toInt(),
      };
    }).toList()
      ..sort((a, b) => (a['pos'] as int).compareTo(b['pos'] as int));
  }).toList();

  int firstIndex = 1;
  while (firstIndex < southLayer.length) {
    firstIndex <<= 1;
  }

  final treeSize = 2 * firstIndex - 1;
  firstIndex -= 1;
  final tree = List.filled(treeSize, 0);

  int cc = 0;
  for (final entry in southEntries) {
    int index = (entry['pos'] as int) + firstIndex;
    final entryWeight = entry['weight'] as int;

    tree[index] += entryWeight;

    int weightSum = 0;
    while (index > 0) {
      if (index % 2 == 1) {
        weightSum += tree[index + 1];
      }
      index = (index - 1) >> 1;
      tree[index] += entryWeight;
    }

    cc += entryWeight * weightSum;
  }

  return cc;
}
