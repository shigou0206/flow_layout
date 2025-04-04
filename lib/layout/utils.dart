import 'package:flow_layout/graph/graph.dart';

int maxRank(Graph g) {
  // 查找最大 rank
  final ranks = g.getNodes().map((v) {
    final rank = g.node(v)?['rank'];
    return (rank is int) ? rank : -99999999;
  }).toList();
  if (ranks.isEmpty) {
    return -99999999; // or 0
  }
  return ranks.reduce((a, b) => a > b ? a : b);
}

List<List<String>> buildLayerMatrix(Graph g) {
  final maximum = maxRank(g);
  final layers = List.generate(maximum + 1, (_) => <String>[]);

  for (final v in g.getNodes()) {
    final node = g.node(v);
    if (node is Map && node['rank'] != null && node['order'] != null) {
      final int rank = node['rank'];
      final int order = node['order'];
      if (layers[rank].length <= order) {
        layers[rank].length = order + 1;
      }
      layers[rank][order] = v;
    }
  }

  return layers;
}

void normalizeRanks(Graph g) {
  // offset 所有 rank，使最小 rank=0
  final ranks = g.getNodes().map((v) {
    final rank = g.node(v)?['rank'];
    return (rank is int) ? rank : (1 << 30);
  }).toList();
  if (ranks.isEmpty) return;

  final minRank = ranks.reduce((a, b) => a < b ? a : b);

  for (final v in g.getNodes()) {
    final node = g.node(v);
    if (node is Map && node.containsKey('rank')) {
      node['rank'] = node['rank'] - minRank;
    }
  }
}

void removeEmptyRanks(Graph g) {
  // 把所有 rank 向前挤压 (但保留 nodeRankFactor的倍数rank)
  final nodeRankFactor = g.graph()?['nodeRankFactor'] ?? 0;
  final ranks =
      g.getNodes().map((v) => g.node(v)?['rank'] as int? ?? 0).toList();
  if (ranks.isEmpty) return;
  final minRank = ranks.reduce((a, b) => a < b ? a : b);

  final layers = <int, List<String>>{};
  for (var v in g.getNodes()) {
    final nodeRank = (g.node(v)['rank'] ?? 0) - minRank;
    layers.putIfAbsent(nodeRank, () => []).add(v);
  }

  int delta = 0;
  final maxRank =
      layers.keys.isEmpty ? 0 : layers.keys.reduce((a, b) => a > b ? a : b);

  for (int i = 0; i <= maxRank; i++) {
    final layer = layers[i];
    // 若是空layer && i%nodeRankFactor!=0 => 往前挤
    if (layer == null && nodeRankFactor != 0 && (i % nodeRankFactor != 0)) {
      delta--;
    } else if (layer != null && delta != 0) {
      for (final v in layer) {
        g.node(v)['rank'] += delta;
      }
    }
  }
}

Map<String, double> intersectRect({
  required double x,
  required double y,
  required double width,
  required double height,
  required Map<String, double> point,
}) {
  final dx = point['x']! - x;
  final dy = point['y']! - y;
  final w = width / 2;
  final h = height / 2;

  if (dx == 0 && dy == 0) {
    throw ArgumentError('Cannot find intersection from inside the rectangle');
  }

  double sx, sy;
  if ((dy.abs() * w) > (dx.abs() * h)) {
    sy = dy < 0 ? -h : h;
    sx = sy * dx / dy;
  } else {
    sx = dx < 0 ? -w : w;
    sy = sx * dy / dx;
  }

  return {
    'x': x + sx,
    'y': y + sy,
  };
}

/// 合并多重边: weight 累加，minlen 取最大值，最终是单图
Graph simplify(Graph g) {
  final simplified = Graph()
    ..setGraph(g.graph())
    ..isMultigraph = false
    ..isCompound = false;

  for (var v in g.getNodes()) {
    simplified.setNode(v, g.node(v));
  }

  final mergedEdges = <String, Map<String, dynamic>>{};

  for (var edge in g.edges()) {
    final v = edge.v;
    final w = edge.w;

    final label =
        g.edge(edge.v, edge.w, edge.name) ?? {'weight': 1, 'minlen': 1};

    final key = '$v::$w';
    final existing = mergedEdges[key] ?? {'weight': 0, 'minlen': 1};

    mergedEdges[key] = {
      'weight': (existing['weight'] ?? 0) + (label['weight'] ?? 1),
      'minlen': [existing['minlen'] ?? 1, label['minlen'] ?? 1]
          .reduce((a, b) => a > b ? a : b),
    };
  }

  mergedEdges.forEach((key, label) {
    final parts = key.split('::');
    simplified.setEdge(parts[0], parts[1], label);
  });

  return simplified;
}

/// 将原图扁平化 (compound => false) 但保留所有节点/边/label
Graph asNonCompoundGraph(Graph g) {
  final ng = Graph(
    isDirected: g.isDirected,
    isMultigraph: g.isMultigraph,
    isCompound: false,
  )..setGraph(g.graph());

  // copy non-subgraph-nodes
  for (var v in g.getNodes()) {
    // 只有没有 children 才是“实节点”
    if ((g.children(v) ?? []).isEmpty) {
      ng.setNode(v, g.node(v));
    }
  }

  // copy edges, 只复制两端节点都存在的边
  for (var e in g.edges()) {
    if (ng.hasNode(e.v) && ng.hasNode(e.w)) {
      final lbl = g.edge(e.v, e.w, e.name);
      ng.setEdge(e.v, e.w, lbl, e.name);
    }
  }

  return ng;
}

/// 计算每个节点 => successors 的 weight 累加
Map<String, Map<String, num>> successorWeights(Graph g) {
  final result = <String, Map<String, num>>{};
  for (var v in g.getNodes()) {
    final sucs = <String, num>{};
    for (var edge in g.outEdges(v) ?? []) {
      final w = edge.w;
      final weight =
          (g.edge(edge.v, edge.w, edge.name) as Map?)?['weight'] ?? 1;
      sucs[w] = (sucs[w] ?? 0) + weight;
    }
    result[v] = sucs;
  }
  return result;
}

/// 计算每个节点 => predecessors 的 weight 累加
Map<String, Map<String, num>> predecessorWeights(Graph g) {
  final result = <String, Map<String, num>>{};
  for (var v in g.getNodes()) {
    final preds = <String, num>{};
    final inE = g.inEdges(v) ?? [];
    for (var e in inE) {
      final u = e.v;
      final lbl = g.edge(e.v, e.w, e.name) as Map? ?? {};
      final wgt = lbl['weight'] ?? 1;
      preds[u] = (preds[u] ?? 0) + wgt;
    }
    result[v] = preds;
  }
  return result;
}

/// 生成 [start..end) or (start..end..step)
List<int> range(int start, [int? end, int step = 1]) {
  if (end == null) {
    end = start;
    start = 0;
  }
  final res = <int>[];
  if (step > 0) {
    for (int i = start; i < end; i += step) {
      res.add(i);
    }
  } else {
    for (int i = start; i > end; i += step) {
      res.add(i);
    }
  }
  return res;
}

/// 分割列表为 (lhs, rhs)
class PartitionResult<T> {
  final List<T> lhs;
  final List<T> rhs;
  PartitionResult(this.lhs, this.rhs);
}

PartitionResult<T> partition<T>(List<T> list, bool Function(T) predicate) {
  final lhs = <T>[];
  final rhs = <T>[];
  for (final x in list) {
    if (predicate(x)) {
      lhs.add(x);
    } else {
      rhs.add(x);
    }
  }
  return PartitionResult(lhs, rhs);
}

/// mapValues
Map<K, V2> mapValues<K, V, V2>(Map<K, V> map, V2 Function(V value, K key) fn) {
  final result = <K, V2>{};
  map.forEach((k, v) {
    result[k] = fn(v, k);
  });
  return result;
}

/// uniqueId
int _idCounter = 0;
String uniqueId([String prefix = '']) {
  _idCounter++;
  return '$prefix$_idCounter';
}

/// zipObject
Map<K, V> zipObject<K, V>(List<K> keys, List<V> values) {
  final m = <K, V>{};
  for (int i = 0; i < keys.length; i++) {
    if (i < values.length) {
      m[keys[i]] = values[i];
    }
  }
  return m;
}

void addSubgraphConstraints(Graph g, Graph cg, List<String> vs) {
  final Map<String, String> prev = {};
  String? rootPrev;

  for (final v in vs) {
    String? child = g.parent(v);
    String? parent;
    String? prevChild;

    while (child != null) {
      parent = g.parent(child);
      if (parent != null) {
        prevChild = prev[parent];
        prev[parent] = child;
      } else {
        prevChild = rootPrev;
        rootPrev = child;
      }

      if (prevChild != null && prevChild != child) {
        cg.setEdge(prevChild, child);
        break;
      }

      child = parent;
    }
  }
}

class BarycenterResult {
  final String v;
  final double? barycenter;
  final double? weight;

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
        final edgeLabel = g.edge(e.v, e.w, e.name);
        final nodeU = g.node(e.v);

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
