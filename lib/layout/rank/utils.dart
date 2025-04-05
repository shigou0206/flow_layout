import 'dart:math' as math;
import 'package:flow_layout/graph/graph.dart';

void longestPath(Graph g) {
  // visited 用于避免重复 DFS
  final visited = <String,bool>{};

  /// 局部函数 dfs(v): 返回节点 v 的 rank
  double dfs(String v) {
    final label = g.node(v);
    // 若已访问 => 直接返回已算好的 rank
    if (visited.containsKey(v)) {
      return (label['rank'] as double?) ?? 0.0;
    }
    visited[v] = true;

    // 计算 outEdgesMinLens = [ dfs(e.w) - minlen(e) for e in outEdges(v) ]
    final outEdges = g.outEdges(v) ?? [];
    if (outEdges.isEmpty) {
      // 如果没有后继边 => 这个节点 rank 设成 0
      label['rank'] = 0.0;
      return 0.0;
    } else {
      // 否则取各后继点 rank - minlen
      final lens = <double>[];
      for (final e in outEdges) {
        final w = e.w; 
        final edgeData = g.edge(e) ?? {};
        final minlen = (edgeData['minlen'] as num?) ?? 1;

        final childRank = dfs(w) - minlen.toDouble();
        lens.add(childRank);
      }

      // 取 lens 的最小值
      // 若全是 infinity => minVal 就是 infinity => rank => 0
      double minVal = lens.reduce(math.min);
      if (minVal == double.infinity) {
        minVal = 0.0;
      }
      label['rank'] = minVal;
      return minVal;
    }
  }

  // 对每个源节点执行 dfs
  for (final src in g.sources()) {
    dfs(src);
  }
}

/// 返回边 e 的 slack = rank(w) - rank(v) - minlen(e)
double slack(Graph g, Edge e) {
  // 1) 解析 vRank
  final vRaw = g.node(e.v)['rank'];
  double vRank;
  if (vRaw is num) {
    vRank = vRaw.toDouble();
  } else {
    vRank = 0.0;
  }

  // 2) 解析 wRank
  final wRaw = g.node(e.w)['rank'];
  double wRank;
  if (wRaw is num) {
    wRank = wRaw.toDouble();
  } else {
    wRank = 0.0;
  }

  // 3) 取 edge 数据
  final edgeData = g.edge(e) ?? {};
  final rawMinlen = edgeData['minlen'];
  double minlen;
  if (rawMinlen is num) {
    minlen = rawMinlen.toDouble();
  } else {
    minlen = 1.0; // default
  }

  // 4) slack
  return wRank - vRank - minlen;
}