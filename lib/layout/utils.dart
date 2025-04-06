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

// 修正后的 buildLayerMatrix - 增强版处理 rank 和 order 类型
List<List<String>> buildLayerMatrix(Graph g) {
  // 计算最大 rank，这里假设 maxRank(g) 已经实现
  final int maxRankValue = maxRank(g) + 1;
  
  // 初始化层次矩阵，每一层都是空列表
  final layering = List<List<String>>.generate(maxRankValue, (_) => []);

  // 创建一个按 rank 分组的临时结构，并记录每个节点的 order
  final Map<int, Map<int, String>> rankGroups = {};
  
  // 遍历所有节点，根据节点的 rank 分组
  for (final v in g.getNodes()) {
    final node = g.node(v);
    if (node != null && node.containsKey('rank')) {
      // 获取 rank，支持 int 或 double
      int rank;
      if (node['rank'] is int) {
        rank = node['rank'] as int;
      } else if (node['rank'] is double) {
        rank = (node['rank'] as double).round();
      } else {
        continue; // 跳过没有有效 rank 的节点
      }

      // 获取 order，如果不存在则使用当前 rank 组中的节点数作为默认值
      int order;
      if (node.containsKey('order') && node['order'] is int) {
        order = node['order'] as int;
      } else {
        rankGroups.putIfAbsent(rank, () => {});
        order = rankGroups[rank]!.length;
      }

      rankGroups.putIfAbsent(rank, () => {});
      rankGroups[rank]![order] = v;
    }
  }

  // 构建最终的层次矩阵
  for (int rank = 0; rank < maxRankValue; rank++) {
    if (rankGroups.containsKey(rank)) {
      final orderMap = rankGroups[rank]!;
      final orders = orderMap.keys.toList()..sort();
      
      for (final order in orders) {
        // 确保该层列表足够长
        while (layering[rank].length <= order) {
          layering[rank].add('');
        }
        layering[rank][order] = orderMap[order]!;
      }
    }
  }
  
  // 压缩层，移除空白项
  for (int rank = 0; rank < layering.length; rank++) {
    layering[rank] = layering[rank].where((v) => v.isNotEmpty).toList();
  }
  
  return layering;
}

void normalizeRanks(Graph g) {
  print("=== normalizeRanks START ===");
  
  // 1) 收集所有节点的 rank (double 方式)
  final rankValues = <double>[];
  for (final v in g.getNodes()) {
    final nodeData = g.node(v);
    if (nodeData is Map && nodeData.containsKey('rank')) {
      final raw = nodeData['rank'];
      double? asDouble;
      if (raw is int) {
        asDouble = raw.toDouble();
      } else if (raw is double) {
        asDouble = raw;
      }
      if (asDouble != null) {
        rankValues.add(asDouble);
        print("  node $v, raw rank=$raw => collect $asDouble");
      }
    }
  }

  if (rankValues.isEmpty) {
    print("No nodes have rank, skip normalize");
    print("=== normalizeRanks END ===");
    return;
  }

  // 2) 找到最小 rank
  final minRank = rankValues.reduce((a, b) => a < b ? a : b);
  print("  minRank found = $minRank");

  // 3) rank - minRank => 0，并转 int
  for (final v in g.getNodes()) {
    final nodeData = g.node(v);
    if (nodeData is Map && nodeData.containsKey('rank')) {
      final raw = nodeData['rank'];
      double? oldVal;
      if (raw is int) {
        oldVal = raw.toDouble();
      } else if (raw is double) {
        oldVal = raw;
      }
      if (oldVal == null) continue;

      final shifted = oldVal - minRank; 
      final newRank = shifted.round();
      nodeData['rank'] = newRank;

      print("  node $v, oldRank=$oldVal => newRank=$newRank");
    }
  }

  print("=== normalizeRanks END ===");
}

void removeEmptyRanks(Graph g) {
  // 把所有 rank 向前挤压 (但保留 nodeRankFactor的倍数rank)
  final nodeRankFactor = g.graph()?['nodeRankFactor'] ?? 0;
  
  // 修复类型转换问题
  final ranks = <int>[];
  for (final v in g.getNodes()) {
    final node = g.node(v);
    if (node != null && node.containsKey('rank')) {
      final rank = node['rank'];
      if (rank is int) {
        ranks.add(rank);
      } else if (rank is double) {
        ranks.add(rank.round());
      }
    }
  }
  
  if (ranks.isEmpty) return;
  final minRank = ranks.reduce((a, b) => a < b ? a : b);

  final layers = <int, List<String>>{};
  for (var v in g.getNodes()) {
    final node = g.node(v);
    if (node != null && node.containsKey('rank')) {
      int nodeRank;
      final rank = node['rank'];
      if (rank is int) {
        nodeRank = rank - minRank;
      } else if (rank is double) {
        nodeRank = rank.round() - minRank;
      } else {
        continue; // 跳过没有有效rank值的节点
      }
      
      layers.putIfAbsent(nodeRank, () => []).add(v);
    }
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
        final node = g.node(v);
        if (node != null && node.containsKey('rank')) {
          final rank = node['rank'];
          if (rank is int) {
            node['rank'] = rank + delta;
          } else if (rank is double) {
            node['rank'] = rank.round() + delta;
          }
        }
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
    final v = edge['v'];
    final w = edge['w'];

    final label =
        g.edge(edge) ?? {'weight': 1, 'minlen': 1};

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

/// 将复合图转换为非复合图
Graph asNonCompoundGraph(Graph g) {
  final result = Graph(isMultigraph: g.isMultigraph);
  
  result.setGraph(g.graph());
  
  for (final v in g.getNodes()) {
    if (g.children(v) == null || g.children(v)!.isEmpty) {
      result.setNode(v, g.node(v));
    }
  }
  
  for (final e in g.edges()) {
    result.setEdge(e, g.edge(e));
  }
  
  return result;
}

/// 计算每个节点 => successors 的 weight 累加
Map<String, Map<String, num>> successorWeights(Graph g) {
  final result = <String, Map<String, num>>{};
  for (var v in g.getNodes()) {
    final sucs = <String, num>{};
    for (var edge in g.outEdges(v) ?? []) {
      final w = edge['w'];
      final weight =
          (g.edge(edge['v'], edge['w'], edge['name']) as Map?)?['weight'] ?? 1;
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
      final u = e['v'];
      final lbl = g.edge(e) as Map? ?? {};
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

/// 执行函数并计时
dynamic time(String name, Function fn) {
  final start = DateTime.now();
  final result = fn();
  final elapsed = DateTime.now().difference(start).inMilliseconds;
  print('$name: ${elapsed}ms');
  return result;
}

/// 无时间记录的函数执行
dynamic notime(String name, Function fn) {
  return fn();
}

/// 从一个对象中选取特定属性
Map<dynamic, dynamic> pick(Map<dynamic, dynamic> obj, List<String> attrs) {
  final result = <dynamic, dynamic>{};
  
  for (final attr in attrs) {
    if (obj.containsKey(attr)) {
      result[attr] = obj[attr];
    }
  }
  
  return result;
}

/// 添加虚拟节点
String addDummyNode(Graph g, String type, Map<dynamic, dynamic> attrs, String prefix) {
  var v;
  do {
    v = '$prefix${g.nodeCount}';
  } while (g.hasNode(v));

  attrs['dummy'] = type;
  g.setNode(v, attrs);
  return v;
}

/// 计算两个矩形的交点（布局特定版本）
Map<String, num> intersectRectForLayout(Map<dynamic, dynamic> node, Map<dynamic, dynamic> point) {
  final nodeX = node['x'] as num;
  final nodeY = node['y'] as num;
  final nodeWidth = node['width'] as num;
  final nodeHeight = node['height'] as num;
  final pointX = point['x'] as num;
  final pointY = point['y'] as num;
  
  // 矩形的半宽和半高
  final halfWidth = nodeWidth / 2;
  final halfHeight = nodeHeight / 2;
  
  // 计算从矩形中心到点的向量
  final deltaX = pointX - nodeX;
  final deltaY = pointY - nodeY;
  
  // 若点在矩形内部，则返回矩形中心点
  if (deltaX.abs() <= halfWidth && deltaY.abs() <= halfHeight) {
    return {'x': nodeX, 'y': nodeY};
  }
  
  // 计算斜率，处理垂直线的情况
  final slope = deltaX == 0 ? double.infinity : deltaY / deltaX;
  
  // 计算可能的交点坐标
  num intersectX, intersectY;
  
  if (slope.abs() <= halfHeight / halfWidth) {
    // 与左右边相交
    intersectX = nodeX + (deltaX > 0 ? halfWidth : -halfWidth);
    intersectY = nodeY + slope * (intersectX - nodeX);
  } else {
    // 与上下边相交
    intersectY = nodeY + (deltaY > 0 ? halfHeight : -halfHeight);
    intersectX = deltaX == 0 ? nodeX : nodeX + (intersectY - nodeY) / slope;
  }
  
  return {'x': intersectX, 'y': intersectY};
}
