import 'package:flow_layout/graph/graph.dart';

class BarycenterResult {
  final String v;
  double? barycenter;
  double? weight;

  BarycenterResult({required this.v, this.barycenter, this.weight});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarycenterResult &&
          runtimeType == other.runtimeType &&
          v == other.v &&
          barycenter == other.barycenter &&
          weight == other.weight;

  @override
  int get hashCode => Object.hash(v, barycenter, weight);

  @override
  String toString() =>
      'BarycenterResult(v: $v, barycenter: $barycenter, weight: $weight)';
}

List<BarycenterResult> barycenter(Graph g, [List<String>? movable]) {
  movable ??= [];

  return movable.map((v) {
    // 1) 获取所有入边
    final inEdges = g.inEdges(v);

    // 2) 若无入边 => 直接返回
    if (inEdges == null || inEdges.isEmpty) {
      return BarycenterResult(v: v);
    } else {
      double sum = 0.0;
      double totalWeight = 0.0;

      for (var e in inEdges) {
        final edgeLabel = g.edge(e);
        final nodeU = g.node(e['v']);

        final weight =
            ((edgeLabel is Map ? edgeLabel['weight'] : null) ?? 1).toDouble();
        final order = ((nodeU is Map ? nodeU['order'] : null) ?? 0).toDouble();

        sum += weight * order;
        totalWeight += weight;
      }
      final bc = totalWeight > 0 ? sum / totalWeight : null;

      return BarycenterResult(
        v: v,
        barycenter: bc,
        weight: totalWeight,
      );
    }
  }).toList();
}
