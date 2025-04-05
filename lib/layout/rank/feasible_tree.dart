import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/rank/utils.dart';

Graph feasibleTree(Graph g) {
  // 1) 新建一个无向图 t
  //    假设 Graph 构造可以指定 directed=false
  final t = Graph(isDirected: false)
    ..setDefaultNodeLabel((_) => {})
    ..setDefaultEdgeLabel((_) => {});

  // 2) 选择任意 start 节点
  final nodes = g.getNodes();
  if (nodes.isEmpty) {
    return t; // 空图 => 直接返回
  }
  final start = nodes.first;
  final size = g.nodeCount;

  // 在 t 中把 start 加进去
  t.setNode(start, {});

  // 3) 重复：若 tightTree(t,g) 的节点数 < size, 
  //          找到 slack 最小的跨边 => shiftRanks => 直到节点都连入
  while (tightTree(t, g) < size) {
    final e = findMinSlackEdge(t, g);
    if (e == null) {
      // 如果找不到 => 说明不再有满足 (t中有一端, t中无另一端) 的边
      // 通常图应该是 connected DAG, 这里 theoretically 不会发生
      break;
    }

    final inT = t.hasNode(e['v']);
    // 如果 e.v 在 t 里, slack>0 => delta=slack; 
    // 否则 => delta=-slack
    final double d = slack(g, e);
    final double delta = inT ? d : -d;

    shiftRanks(t, g, delta);
  }

  return t;
}

/// 查找并连通 "紧" (slack=0) 的节点 => 返回 t 的节点数
int tightTree(Graph t, Graph g) {
  // DFS: 把能以 slack=0 连到 t 中的节点都连上
  void dfs(String v) {
    // 遍历与 v 相连的边
    final edgesOfV = g.nodeEdges(v) ?? [];
    for (final e in edgesOfV) {
      final String w = (e['v'] == v) ? e['w'] : e['v'];
      // slack=0 && t 中不包含 w => 加入
      if (!t.hasNode(w) && slack(g, e) == 0.0) {
        // 把 w 加到 t
        t.setNode(w, {});
        // 加一条无向边 v-w
        t.setEdge(v, w, {});
        dfs(w);
      }
    }
  }

  // 对 t 已有节点做 DFS
  final existingNodes = t.getNodes();
  for (final v in existingNodes) {
    dfs(v);
  }

  return t.nodeCount;
}

/// 找到一条 (一端在 t, 一端不在 t) 的边, slack最小的 => return
Map<String, dynamic>? findMinSlackEdge(Graph t, Graph g) {
  Map<String, dynamic>? bestEdge;
  double bestSlack = double.infinity;

  final allEdges = g.edges();
  for (final e in allEdges) {
    // 看是否是一端在 t, 一端不在 t
    final bool vInT = t.hasNode(e['v']);
    final bool wInT = t.hasNode(e['w']);
    if (vInT != wInT) {
      // slack
      final s = slack(g, e);
      if (s < bestSlack) {
        bestSlack = s;
        bestEdge = e;
      }
    }
  }

  return bestEdge;
}

/// 对 t 中所有节点的 rank 进行统一 +delta
void shiftRanks(Graph t, Graph g, double delta) {
  final tNodes = t.getNodes();
  for (final v in tNodes) {
    final nData = g.node(v);
    if (nData is Map) {
      // 取 rank 强转成 double (或 int => toDouble)
      final oldRank = (nData['rank'] is int)
          ? (nData['rank'] as int).toDouble()
          : (nData['rank'] as double?) ?? 0.0;
      final newRank = (oldRank + delta).round();
      nData['rank'] = newRank;  // 这里是double
    }
  }
}