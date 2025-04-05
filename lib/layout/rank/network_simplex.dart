// import 'package:flow_layout/graph/graph.dart';
// import 'package:flow_layout/layout/utils.dart'; 
// import 'package:flow_layout/layout/rank/utils.dart';
// import 'package:flow_layout/graph/alg/preorder.dart';
// import 'package:flow_layout/graph/alg/postorder.dart';

// /// 入口函数：对图做 network simplex 排列
// void networkSimplex(Graph g) {
//   // 1) 简化图 (去除多余边等)
//   g = simplify(g);

//   // 2) 用 longestPath 给节点做初步 rank
//   longestPath(g); 
//   // 这里假设 initRank 就是你提到的 longestPath(g)

//   // 3) 构造一个可行的 tight tree
//   Graph t = feasibleTree(g);

//   // 4) 给树上每个节点赋 low/lim，用于后续 cutValue
//   initLowLimValues(t);

//   // 5) 初始化 cutvalue
//   initCutValues(t, g);

//   // 6) 迭代：若存在 cutvalue < 0 的边 => 做交换
//   Edge? e;
//   while ((e = leaveEdge(t)) != null) {
//     final f = enterEdge(t, g, e);
//     if (f == null) {
//       // 如果没有可进入的边了，就跳出
//       break;
//     }
//     exchangeEdges(t, g, e, f);
//   }
// }

// /* 
//  * 初始化 cut values
//  */
// void initCutValues(Graph t, Graph g) {
//   // postorder(t, t.nodes()) => 返回后序遍历序列
//   // 假设已有 postorder(...)
//   final vs = postorder(t, t.getNodes());
//   // vs 的最后一个可能是 root => 不用?
//   final slice = vs.sublist(0, vs.length - 1);

//   for (final v in slice) {
//     assignCutValue(t, g, v);
//   }
// }

// void assignCutValue(Graph t, Graph g, String child) {
//   final childLab = t.node(child);
//   final parent = (childLab is Map && childLab.containsKey('parent'))
//     ? childLab['parent'] as String?
//     : null;
//   if (parent == null) return;

//   // t.edge(child, parent).cutvalue = calcCutValue(...)
//   final edgeId = Edge(child, parent).id;
//   final treeEdgeLabel = t.edgeObjs[edgeId]; 
//   if (treeEdgeLabel == null) return;

//   final val = calcCutValue(t, g, child);
//   // 在 Dart 里，你可能需要存到 t.edgeLabels[edgeId]['cutvalue']
//   // 或用其他方式
//   final eLbl = t.edgeLabels[edgeId] ?? <String, dynamic>{};
//   eLbl['cutvalue'] = val;
//   t.edgeLabels[edgeId] = eLbl;
// }

// /*
//  * 给定 tight tree t, 原图 g, 以及一个节点 child,
//  * 计算 child->parent 这条边的 cutValue
//  */
// double calcCutValue(Graph t, Graph g, String child) {
//   final childLab = t.node(child);
//   if (childLab == null) return 0.0;
//   final parent = childLab['parent'];
//   if (parent == null) return 0.0;

//   // 看看在原图 g 里，是 child->parent 还是 parent->child
//   // 以确定 childIsTail
//   bool childIsTail = g.hasEdge(child, parent);
  
//   // 找到 edge 的 label
//   final eLabel = childIsTail
//     ? g.edge(child, parent)
//     : g.edge(parent, child);

//   if (eLabel == null) return 0.0;

//   double cutValue = 0.0;
//   // edge.weight  => 先转 double
//   final weight = (eLabel['weight'] is int)
//     ? (eLabel['weight'] as int).toDouble()
//     : (eLabel['weight'] as double?) ?? 1.0;

//   // 初始 cutValue = weight
//   cutValue = weight;

//   // 遍历 child 的所有关联边
//   final edgesOfChild = g.nodeEdges(child) ?? [];
//   for (final e in edgesOfChild) {
//     final isOutEdge = (e.v == child);
//     final other = isOutEdge ? e.w : e.v;
//     if (other == parent) {
//       continue;
//     }

//     // edge weight
//     final eData = g.edge(e.v, e.w, e.name) ?? {};
//     final wgt = (eData['weight'] is int)
//       ? (eData['weight'] as int).toDouble()
//       : (eData['weight'] as double?) ?? 1.0;

//     // pointsToHead => 
//     //   (isOutEdge == true)表示 child -> other
//     //   childIsTail => child 在 tail
//     // => pointsToHead = isOutEdge == childIsTail
//     final pointsToHead = (isOutEdge == childIsTail);

//     if (pointsToHead) {
//       cutValue += wgt;
//     } else {
//       cutValue -= wgt;
//     }

//     // 如果 other 在 t 里是 child 的 tree-edge?
//     if (isTreeEdge(t, child, other)) {
//       // child-other cutvalue
//       final eId = Edge(child, other).id;
//       final tLabel = t.edgeLabels[eId] ?? {};
//       final otherCutVal = (tLabel['cutvalue'] is double)
//         ? tLabel['cutvalue'] as double
//         : 0.0;
//       // 计算公式
//       cutValue += pointsToHead ? -otherCutVal : otherCutVal;
//     }
//   }

//   return cutValue;
// }

// bool isTreeEdge(Graph t, String u, String v) {
//   return t.hasEdge(u, v) || t.hasEdge(v, u);
// }

// /*
//  * 为树中的节点赋 low/lim (用于后续 cutValue)
//  */
// void initLowLimValues(Graph tree, [String? root]) {
//   final nodes = tree.getNodes();
//   if (root == null && nodes.isNotEmpty) {
//     root = nodes[0];
//   }
//   final visited = <String, bool>{};
//   dfsAssignLowLim(tree, visited, 1, root, null);
// }

// int dfsAssignLowLim(Graph tree, Map<String,bool> visited, int nextLim,
//     String? v, String? parent) {
//   if (v == null) return nextLim;
//   visited[v] = true;

//   final label = tree.node(v);
//   int low = nextLim;

//   final neighbors = tree.neighbors(v) ?? [];
//   for (final w in neighbors) {
//     if (!visited.containsKey(w)) {
//       nextLim = dfsAssignLowLim(tree, visited, nextLim, w, v);
//     }
//   }

//   // label.low = low; label.lim = nextLim++;
//   label['low'] = low;
//   label['lim'] = nextLim++;
  
//   if (parent != null) {
//     label['parent'] = parent;
//   } else {
//     label.remove('parent');
//   }
//   return nextLim;
// }

// /*
//  * 找到 cutvalue < 0 的一条边
//  */
// Edge? leaveEdge(Graph tree) {
//   for (final e in tree.edges()) {
//     final edgeId = e.id;
//     final eData = tree.edgeLabels[edgeId] ?? {};
//     final cutv = (eData['cutvalue'] is double)
//       ? eData['cutvalue'] as double
//       : 0.0;
//     if (cutv < 0) {
//       return e;
//     }
//   }
//   return null;
// }

// /*
//  * 找到一条可进入的边 f
//  */
// Edge? enterEdge(Graph t, Graph g, Edge e) {
//   // e 是 tree-edge (v->w 或 w->v), 先看看在 g 里是否 v->w
//   String v = e.v, w = e.w;
//   bool directVW = g.hasEdge(v, w);

//   // 若不是 v->w，则 flip
//   if (!directVW) {
//     v = e.w; w = e.v;
//   }

//   final vLabel = t.node(v), wLabel = t.node(w);
//   // tailLabel
//   var tailLabel = vLabel;
//   bool flip = false;

//   // 如果 v.lim > w.lim 就 flip
//   final vLim = (vLabel['lim'] is int) ? vLabel['lim'] : 0;
//   final wLim = (wLabel['lim'] is int) ? wLabel['lim'] : 0;
//   if (vLim > wLim) {
//     tailLabel = wLabel;
//     flip = true;
//   }

//   // candidates = g.edges() 过滤:
//   //   flip == isDescendant(t, e.v, tailLabel)
//   //   flip != isDescendant(t, e.w, tailLabel)
//   final allEdges = g.edges();
//   Edge? best;
//   double bestSlack = double.infinity;

//   for (final edge in allEdges) {
//     final eVLabel = t.node(edge.v);
//     final eWLabel = t.node(edge.w);
//     bool vIsDesc = isDescendant(t, eVLabel, tailLabel);
//     bool wIsDesc = isDescendant(t, eWLabel, tailLabel);

//     // flip == vIsDesc && flip != wIsDesc
//     if ((flip == vIsDesc) && (flip != wIsDesc)) {
//       final s = slack(g, edge);
//       if (s < bestSlack) {
//         bestSlack = s;
//         best = edge;
//       }
//     }
//   }

//   return best;
// }

// /*
//  * 交换 tree 中的一条边 e, 用 f 替换
//  */
// void exchangeEdges(Graph t, Graph g, Edge e, Edge f) {
//   // 移除 e
//   t.removeEdge(e.v, e.w, e.name);
//   // 加入 f
//   t.setEdge(f.v, f.w, {});
//   initLowLimValues(t);
//   initCutValues(t, g);
//   updateRanks(t, g);
// }

// /*
//  * 根据树的结构，更新 g 中节点 rank
//  */
// void updateRanks(Graph t, Graph g) {
//   // 找 root: tree 中没有 parent 的那个
//   final root = t.getNodes().firstWhereOrNull((v) {
//     final nd = g.node(v);
//     if (nd is Map && nd.containsKey('parent')) {
//       return false;
//     }
//     return true;
//   });
//   if (root == null) return;

//   // preorder(t, root)
//   final vs = preorder(t, root);
//   // vs去掉root自己
//   final slice = vs.sublist(1);

//   for (final v in slice) {
//     final parent = (t.node(v)['parent'] as String?);
//     if (parent == null) continue;

//     // edge in g?
//     var eData = g.edge(v, parent);
//     bool flipped = false;
//     if (eData == null) {
//       eData = g.edge(parent, v);
//       flipped = true;
//     }
//     if (eData == null) continue;

//     final minlen = (eData['minlen'] is int)
//       ? eData['minlen'] as int
//       : (eData['minlen'] as double? ?? 1.0).round();

//     final parentRank = (g.node(parent)['rank'] is int)
//       ? g.node(parent)['rank'] as int
//       : 0;

//     final newRank = parentRank + (flipped ? minlen : -minlen);
//     g.node(v)['rank'] = newRank;
//   }
// }

// /*
//  * 是否 vLabel 是 rootLabel 的后代
//  */
// bool isDescendant(Graph t, dynamic vLabel, dynamic rootLabel) {
//   if (vLabel == null || rootLabel == null) return false;
//   final vLow = (vLabel['low'] is int) ? vLabel['low'] as int : 0;
//   final vLim = (vLabel['lim'] is int) ? vLabel['lim'] as int : 0;
//   final rLow = (rootLabel['low'] is int) ? rootLabel['low'] as int : 0;
//   final rLim = (rootLabel['lim'] is int) ? rootLabel['lim'] as int : 0;
//   return (rLow <= vLim) && (vLim <= rLim);
// }