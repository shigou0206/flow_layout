import 'dart:math' as math;
import '../graph.dart';
import 'list.dart';

/// 默认的权重函数，返回1作为默认权重
dynamic Function(Map<String, dynamic>) defaultWeightFn = (_) => 1;

/// 贪心算法寻找图的反馈弧集(FAS)
/// 反馈弧集是使图无环的最小边集
/// 算法来源：P. Eades, X. Lin, and W. F. Smyth, "A fast and
/// effective heuristic for the feedback arc set problem."
/// 该实现允许加权边
List<Map<String, dynamic>> greedyFAS(
  Graph g, [
  dynamic Function(Map<String, dynamic>)? weightFn,
]) {
  if (g.nodeCount <= 1) {
    return [];
  }

  final state = _buildState(g, weightFn ?? defaultWeightFn);
  final results = _doGreedyFAS(state['graph'] as Graph,
      state['buckets'] as List<ListQueue<dynamic>>, state['zeroIdx'] as int);

  // 展开多重边
  final List<Map<String, dynamic>> expandedResults = [];
  for (final e in results) {
    final outEdges = g.outEdges(e['v'], e['w']);
    if (outEdges != null && outEdges.isNotEmpty) {
      expandedResults.addAll(outEdges);
    }
  }

  return expandedResults;
}

/// 执行贪心FAS算法
List<Map<String, dynamic>> _doGreedyFAS(
    Graph g, List<ListQueue<dynamic>> buckets, int zeroIdx) {
  final results = <Map<String, dynamic>>[];
  final sources = buckets[buckets.length - 1];
  final sinks = buckets[0];

  dynamic entry;
  while (g.nodeCount > 0) {
    while ((entry = sinks.dequeue()) != null) {
      _removeNode(g, buckets, zeroIdx, entry);
    }
    while ((entry = sources.dequeue()) != null) {
      _removeNode(g, buckets, zeroIdx, entry);
    }
    if (g.nodeCount > 0) {
      for (int i = buckets.length - 2; i > 0; --i) {
        entry = buckets[i].dequeue();
        if (entry != null) {
          final removed = _removeNode(g, buckets, zeroIdx, entry, true);
          if (removed != null) {
            results.addAll(removed);
          }
          break;
        }
      }
    }
  }

  return results;
}

/// 从图中移除节点并更新桶
List<Map<String, dynamic>>? _removeNode(
    Graph g, List<ListQueue<dynamic>> buckets, int zeroIdx, dynamic entry,
    [bool collectPredecessors = false]) {
  List<Map<String, dynamic>>? results;
  if (collectPredecessors) {
    results = <Map<String, dynamic>>[];
  }

  // 处理入边
  final inEdges = g.inEdges(entry['v']);
  if (inEdges != null) {
    for (final edge in inEdges) {
      final weight = g.edge(edge);
      final uEntry = g.node(edge['v']);

      if (collectPredecessors) {
        results!.add({'v': edge['v'], 'w': edge['w']});
      }

      uEntry['out'] -= weight;
      _assignBucket(buckets, zeroIdx, uEntry);
    }
  }

  // 处理出边
  final outEdges = g.outEdges(entry['v']);
  if (outEdges != null) {
    for (final edge in outEdges) {
      final weight = g.edge(edge);
      final w = edge['w'];
      final wEntry = g.node(w);
      wEntry['in'] -= weight;
      _assignBucket(buckets, zeroIdx, wEntry);
    }
  }

  g.removeNode(entry['v']);

  return results;
}

/// 构建算法需要的初始状态
Map<String, dynamic> _buildState(
    Graph g, dynamic Function(Map<String, dynamic>) weightFn) {
  final fasGraph = Graph();
  int maxIn = 0;
  int maxOut = 0;

  // 初始化节点
  for (final v in g.getNodes()) {
    fasGraph.setNode(v, {'v': v, 'in': 0, 'out': 0});
  }

  // 聚合边的权重，并将多重边权重合并到单个边
  final edges = g.edges();
  for (final e in edges) {
    final edgeObj = {'v': e['v'], 'w': e['w']};
    final prevWeight = fasGraph.edge(edgeObj) ?? 0;
    final weight = weightFn(e);
    final edgeWeight = prevWeight + weight;

    fasGraph.setEdge(e['v'], e['w'], edgeWeight);

    // 更新最大出度和入度
    final nodeV = fasGraph.node(e['v']);
    nodeV['out'] += weight;
    maxOut = math.max(maxOut, (nodeV['out'] as num).toInt());

    final nodeW = fasGraph.node(e['w']);
    nodeW['in'] += weight;
    maxIn = math.max(maxIn, (nodeW['in'] as num).toInt());
  }

  // 创建桶
  final buckets = <ListQueue<dynamic>>[];
  for (int i = 0; i < maxOut + maxIn + 3; i++) {
    buckets.add(ListQueue<dynamic>());
  }

  final zeroIdx = maxIn + 1;

  // 初始分配节点到桶
  for (final v in fasGraph.getNodes()) {
    _assignBucket(buckets, zeroIdx, fasGraph.node(v));
  }

  return {'graph': fasGraph, 'buckets': buckets, 'zeroIdx': zeroIdx};
}

/// 将节点分配到相应的桶
void _assignBucket(
    List<ListQueue<dynamic>> buckets, int zeroIdx, dynamic entry) {
  if (entry['out'] == 0) {
    buckets[0].enqueue(entry);
  } else if (entry['in'] == 0) {
    buckets[buckets.length - 1].enqueue(entry);
  } else {
    // 使用round()来保证整数转换正确处理浮点数差值
    final diff = (entry['out'] as num) - (entry['in'] as num);
    final idx = diff.round() + zeroIdx;
    buckets[idx].enqueue(entry);
  }
}

/// 生成指定范围的整数列表
List<int> range(int limit) {
  final range = <int>[];
  for (int i = 0; i < limit; i++) {
    range.add(i);
  }
  return range;
}
