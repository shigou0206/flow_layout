import 'dart:math';
import 'package:flow_layout/graph/graph.dart';

// ignore: constant_identifier_names
const int CHUNKING_THRESHOLD = 65535;

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

// 修正后的 buildLayerMatrix
List<List<String>> buildLayerMatrix(Graph g) {
  // 计算最大 rank，这里假设 maxRank(g) 已经实现
  final int maxRankValue = maxRank(g) + 1;
  // 初始化层次矩阵，每一层都是空列表
  final layering = List<List<String>>.generate(maxRankValue, (_) => []);

  // 遍历所有节点，根据节点的 rank 和 order 放入对应层
  for (final v in g.getNodes()) {
    final node = g.node(v);
    if (node != null && node["rank"] != null) {
      final int rank = node["rank"] as int;
      final int order = node["order"] as int;
      // 确保该层列表足够长，以便直接使用 order 作为索引
      while (layering[rank].length <= order) {
        layering[rank].add('');
      }
      layering[rank][order] = v;
    }
  }
  return layering;
}

void normalizeRanks(Graph g) {
  // 1) 收集所有节点的 rank (以 double 方式存于 rankValues 做计算)
  final rankValues = <double>[];
  for (final v in g.getNodes()) {
    final nodeData = g.node(v);
    if (nodeData is Map && nodeData.containsKey('rank')) {
      final raw = nodeData['rank'];
      // 如果 raw 是 int => 转 double
      // 如果 raw 是 double => 保留
      if (raw is int) {
        rankValues.add(raw.toDouble());
      } else if (raw is double) {
        rankValues.add(raw);
      }
      // 如果不是 int/double, 跳过
    }
  }

  if (rankValues.isEmpty) {
    // 图里没有任何节点带 rank
    return;
  }

  // 2) 找到最小 rank
  final minRank = rankValues.reduce((a, b) => a < b ? a : b);

  // 3) 把所有 rank - minRank => 保证最小 rank = 0，并转回 int
  for (final v in g.getNodes()) {
    final nodeData = g.node(v);
    if (nodeData is Map && nodeData.containsKey('rank')) {
      final raw = nodeData['rank'];
      double oldVal;
      if (raw is int) {
        oldVal = raw.toDouble();
      } else if (raw is double) {
        oldVal = raw;
      } else {
        continue; // 不处理
      }

      final shifted = oldVal - minRank; 
      // 这里你可以用 floor / round / toInt 看需求，
      // 一般 .round() 或 .toInt() 都行
      nodeData['rank'] = shifted.round();  
      // rank 最终存为 int
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
    // 只有没有 children 才是"实节点"
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

dynamic applyWithChunking(List<num> argsArray, num Function(num, num) fn) {
  // 1) 空列表 => 无法再计算
  if (argsArray.isEmpty) {
    throw ArgumentError('argsArray is empty');
  }

  // 2) 若只有一个元素 => 直接返回它 (无需再调用二元函数)
  if (argsArray.length == 1) {
    return argsArray[0];
  }

  // 3) 若长度超过阈值 => 分块
  if (argsArray.length > CHUNKING_THRESHOLD) {
    final chunks = splitToChunks(argsArray, CHUNKING_THRESHOLD);

    // 对每个 chunk 用 reduce(fn) 得到一个部分结果 partial，然后再合并
    final partials = <num>[];
    for (final chunk in chunks) {
      if (chunk.isEmpty) {
        continue;
      } else if (chunk.length == 1) {
        // 单元素也无法二元调用 => 直接拿这个值
        partials.add(chunk[0]);
      } else {
        // 至少有2个 => reduce
        final partial = chunk.reduce(fn);
        partials.add(partial);
      }
    }

    // 再对 partials 递归调用
    return applyWithChunking(partials, fn);

  } else {
    // 4) 若长度不大 => 直接 reduce(fn)
    //    这样不会一次性 "fn(...多参数...)"
    return argsArray.reduce(fn);
  }
}

/// 将 [array] 按 [chunkSize] 等分；最后一块可能小于 chunkSize
List<List<num>> splitToChunks(List<num> array, [int chunkSize = CHUNKING_THRESHOLD]) {
  final chunks = <List<num>>[];
  for (int i = 0; i < array.length; i += chunkSize) {
    final end = min(i + chunkSize, array.length);
    chunks.add(array.sublist(i, end));
  }
  return chunks;
}
