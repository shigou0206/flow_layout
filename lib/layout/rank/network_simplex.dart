import 'dart:math';
import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/utils.dart'; // 包含 simplify, applyWithChunking, etc.
import 'package:flow_layout/graph/alg/preorder.dart';
import 'package:flow_layout/graph/alg/postorder.dart';
import 'package:flow_layout/layout/rank/utils.dart'; // 包含 longestPath 等
import 'package:flow_layout/layout/rank/feasible_tree.dart'; // longestPath(g)

// ---------------------------------------------------------------------
// networkSimplex 算法及其内部函数
// ---------------------------------------------------------------------

void networkSimplex(Graph g) {
  print("=== networkSimplex START ===");

  // 1) 简化图（去除多余边等）
  print("[1] simplify(g)");
  g = simplify(g);
  print("[1] Graph after simplify: ${g.edges().map((e) => '${e.v}-${e.w}${e.name != null ? '-${e.name}' : ''}').toList()}");

  // 2) 用 longestPath 初始化 rank
  print("[2] longestPath(g) => initRank");
  longestPath(g);
  for (var v in g.getNodes()) {
    final r = g.node(v)['rank'];
    print("  node $v init rank = $r");
  }

  // 3) 构造可行的 tight tree
  print("[3] feasibleTree(g)");
  final t = feasibleTree(g);
  print("  feasibleTree edges => ${t.edges().map((e) => '${e.v}-${e.w}').toList()}");

  // 4) 初始化 low/lim 值
  print("[4] initLowLimValues(t)");
  initLowLimValues(t);
  print("[4] Low/Lim values initialized for tree: ${t.getNodes().map((v) => '${v}: ${t.node(v)['low']}, ${t.node(v)['lim']}').toList()}");

  // 5) 初始化 cutvalue
  print("[5] initCutValues(t, g)");
  initCutValues(t, g);
  print("[5] Cut values initialized for tree edges: ${t.edges().map((e) => '${e.v}-${e.w}: ${t.edgeLabels[Edge(e.v, e.w).id]?['cutvalue']}').toList()}");

  // 🚨 修复的关键：按树边实际方向(parent->child)来正确取值
  for (final v in t.getNodes()) {
    final nodeLabel = t.node(v);
    final parent = nodeLabel['parent'] as String?;
    if (parent != null) {
      Edge treeEdge;
      if (t.hasEdge(parent, v)) {
        treeEdge = Edge(parent, v);
      } else {
        treeEdge = Edge(v, parent);
      }
      final edgeId = treeEdge.id;
      final cv = t.edgeLabels[edgeId]?['cutvalue'];
      print('  edge ${treeEdge.v}-${treeEdge.w} cutvalue=$cv');
    }
  }

  // 6) 主循环：若存在负 cutvalue 的边，则交换
  print("[6] main loop: leaveEdge / enterEdge / exchangeEdges");
  while (true) {
    final e = leaveEdge(t);
    if (e == null) {
      print("  no negative cutvalue => break");
      break;
    }
    print("  leaveEdge => ${e.v}-${e.w}, cutvalue=${t.edge(e)['cutvalue']}");
    final f = enterEdge(t, g, e);
    if (f == null) {
      print("  enterEdge => null, break");
      break;
    }
    print("  enterEdge => ${f.v}-${f.w}");
    exchangeEdges(t, g, e, f);
    print("  exchangeEdges done => re-initLowLim & cutValues");
    // 重新计算 low/lim 和 cutvalue
    initLowLimValues(t);
    initCutValues(t, g);

    // 🚨 此处同样需要使用parent->child方向打印cutvalue
    for (final v in t.getNodes()) {
      final nodeLabel = t.node(v);
      final parent = nodeLabel['parent'] as String?;
      if (parent != null) {
        Edge treeEdge;
        if (t.hasEdge(parent, v)) {
          treeEdge = Edge(parent, v);
        } else {
          treeEdge = Edge(v, parent);
        }
        final edgeId = treeEdge.id;
        final cv2 = t.edgeLabels[edgeId]?['cutvalue'];
        print('    edge ${treeEdge.v}-${treeEdge.w} new cutvalue=$cv2');
      }
    }
  }

  print("=== networkSimplex END ===");
}

void initCutValues(Graph t, Graph g) {
  print("\n📊 [initCutValues] START");
  for (final e in t.edges()) {
    final edgeId = Edge(e.v, e.w).id; // 关键修正！
    t.edgeLabels[edgeId] ??= <String, dynamic>{};
    print("  Initialized edge $edgeId in cut values.");
  }

  final vs = postorder(t, t.getNodes());
  final slice = vs.sublist(0, vs.length - 1);
  print("  Processing nodes in postorder (except root): $slice");

  for (final v in slice) {
    assignCutValue(t, g, v);
  }
  print("📊 [initCutValues] END\n");
}

void assignCutValue(Graph t, Graph g, String child) {
  final childLab = t.node(child);
  final parent = childLab?['parent'] as String?;
  if (parent == null) {
    print("  ⚠️ assignCutValue: node '$child' has no parent, skipping");
    return;
  }

  Edge treeEdge;

  // 🚨 明确检查边的实际方向
  if (t.hasEdge(parent, child)) {
    treeEdge = Edge(parent, child);
    print("  📌 assignCutValue: found tree edge in direction parent->child: $parent->$child");
  } else if (t.hasEdge(child, parent)) {
    treeEdge = Edge(child, parent);
    print("  📌 assignCutValue: found tree edge in direction child->parent: $child->$parent");
  } else {
    // 若树中找不到对应边则返回（理论上不可能）
    print("  ❌ assignCutValue: no edge found between $child and $parent in tree!");
    return;
  }

  final edgeId = treeEdge.id;
  final tLabel = t.edgeLabels[edgeId];
  if (tLabel == null) {
    print("  ❌ assignCutValue: no edge label found for $edgeId!");
    return;
  }

  final val = calcCutValue(t, g, child);
  tLabel['cutvalue'] = val;

  print("  ✅ assigned cutValue=$val to edge=$edgeId");
}

double calcCutValue(Graph t, Graph g, String child) {
  final childLab = t.node(child);
  if (childLab == null) return 0.0;
  

  final parent = childLab['parent'] as String?;
  if (parent == null) return 0.0;

  print("🔍 正在检查边：$child->$parent 或 $parent->$child");
  print("🔍 当前所有边：${g.edgeLabels.keys}");

  bool childIsTail;
  var eLabel = g.edge(child, parent);
  if (eLabel != null) {
    childIsTail = true;
  } else {
    eLabel = g.edge(parent, child);
    if (eLabel != null) {
      childIsTail = false;
    } else {
      print("  ⚠️ calcCutValue: no edge found between $child and $parent in graph!");
      return 0.0;
    }
  }

  print("  🚩 calcCutValue: child=$child, parent=$parent, childIsTail=$childIsTail, graphEdge=${eLabel != null}");

  final weight = (eLabel['weight'] as num?)?.toDouble() ?? 1.0;
  double cutValue = weight;
  print("    Initial cutValue = $weight (edge weight)");

  final childEdges = g.nodeEdges(child) ?? [];
  print("    Processing ${childEdges.length} edges of node $child");

  for (final e in childEdges) {
    final isOutEdge = e.v == child;
    final other = isOutEdge ? e.w : e.v;
    if (other == parent) {
      print("    Skipping edge to parent: ${e.v}-${e.w}");
      continue;
    }

    final eData = g.edge(e.v, e.w, e.name) ?? {};
    final wgt = (eData['weight'] as num?)?.toDouble() ?? 1.0;

    final pointsToHead = (isOutEdge == childIsTail);
    final adjustedWeight = pointsToHead ? wgt : -wgt;
    cutValue += adjustedWeight;
    print("    Edge ${e.v}-${e.w} contributes $adjustedWeight (pointsToHead=$pointsToHead, weight=$wgt)");

    if (isTreeEdge(t, child, other)) {
      print("    Tree edge found: $child-$other");
      final eId = Edge(child, other).id;
      final tLabel = t.edgeLabels[eId];
      final otherCutVal = (tLabel?['cutvalue'] as num?)?.toDouble() ?? 0.0;
      final cutvalContribution = pointsToHead ? -otherCutVal : otherCutVal;
      cutValue += cutvalContribution;
      print("    Edge $child-$other is a tree edge with cutvalue=$otherCutVal, contributes $cutvalContribution");
    }
  }

  print("  ✅ calcCutValue result for child=$child, cutValue=$cutValue");
  return cutValue;
}

bool isTreeEdge(Graph t, String u, String v) {
  final result = t.hasEdge(u, v);
  return result;
}

void initLowLimValues(Graph tree, [String? root]) {
  print("\n🔢 [initLowLimValues] START");
  final nodes = tree.getNodes();
  if (root == null && nodes.isNotEmpty) {
    root = nodes.first;
  }
  print("  Using root: $root");
  final visited = <String, bool>{};
  dfsAssignLowLim(tree, visited, 1, root, null);
  print("  Final Low/Lim values:");
  for (final v in tree.getNodes()) {
    print("    Node $v: low=${tree.node(v)['low']}, lim=${tree.node(v)['lim']}, parent=${tree.node(v)['parent']}");
  }
  print("🔢 [initLowLimValues] END\n");
}

int dfsAssignLowLim(Graph tree, Map<String, bool> visited, int nextLim,
    String? v, String? parent) {
  if (v == null) return nextLim;
  print("  🚩 dfsAssignLowLim: node=$v, parent=$parent, nextLim=$nextLim");

  visited[v] = true;

  var label = tree.node(v);
  if (label == null) {
    label = <String, dynamic>{};
    tree.setNode(v, label);
  }

  int low = nextLim;
  final neighbors = tree.neighbors(v) ?? [];
  print("    Neighbors of $v: $neighbors");
  
  for (final w in neighbors) {
    if (!visited.containsKey(w)) {
      print("    Processing unvisited neighbor: $w");
      nextLim = dfsAssignLowLim(tree, visited, nextLim, w, v);
    } else {
      print("    Skipping already visited neighbor: $w");
    }
  }
  
  label['low'] = low;
  label['lim'] = nextLim++;
  if (parent != null) {
    label['parent'] = parent;
  } else {
    label.remove('parent');
  }
  print("    Assigned to node $v: low=$low, lim=${nextLim-1}${parent != null ? ', parent=$parent' : ''}");
  
  return nextLim;
}

Edge? leaveEdge(Graph tree) {
  print("\n🔍 [leaveEdge] START");
  for (final e in tree.edges()) {
    final edgeId = Edge(e.v, e.w).id;
    final edgeLabel = tree.edgeLabels[edgeId];
    if (edgeLabel == null) {
      print("  ❌ edge $edgeId edgeLabel is null, continue...");
      continue;
    }

    final cutvalue = (edgeLabel['cutvalue'] as num?)?.toDouble() ?? 0.0;
    print("  ✔️ checking edge $edgeId, cutvalue=$cutvalue");

    if (cutvalue < 0) {
      print("    🎯 edge $edgeId has negative cutvalue=$cutvalue, return it!");
      print("🔍 [leaveEdge] END -> found ${e.v}-${e.w}\n");
      return e;
    }
  }

  print("  ✅ no edge with negative cutvalue found, return null");
  print("🔍 [leaveEdge] END -> null\n");
  return null;
}

Edge? enterEdge(Graph t, Graph g, Edge e) {
  print("\n🔎 [enterEdge] START for leaving edge ${e.v}-${e.w}");
  String v = e.v, w = e.w;
  bool directVW = g.hasEdge(v, w);
  
  if (!directVW) {
    print("  No direct edge $v->$w in graph g, flipping v and w");
    v = e.w;
    w = e.v;
  } else {
    print("  Direct edge $v->$w exists in graph g");
  }
  
  final vLabel = t.node(v);
  final wLabel = t.node(w);
  print("  v=$v (lim=${vLabel['lim']}), w=$w (lim=${wLabel['lim']})");
  
  var tailLabel = vLabel;
  bool flip = false;
  final vLim = (vLabel['lim'] is int) ? vLabel['lim'] as int : 0;
  final wLim = (wLabel['lim'] is int) ? wLabel['lim'] as int : 0;
  
  if (vLim > wLim) {
    print("  v's lim ($vLim) > w's lim ($wLim), flipping tail to w");
    tailLabel = wLabel;
    flip = true;
  } else {
    print("  v's lim ($vLim) <= w's lim ($wLim), tail remains v");
  }
  
  print("  Tail node: ${flip ? w : v} with lim=${tailLabel['lim']}, low=${tailLabel['low']}");
  print("  Searching for an edge (a,b) where ${flip ? 'a' : 'b'} is a descendant of tail and ${flip ? 'b' : 'a'} is not");
  
  final allEdges = g.edges();
  print("  Checking ${allEdges.length} edges in graph g");
  
  Edge? best;
  double bestSlack = double.infinity;
  int edgeChecked = 0;
  
  for (final edge in allEdges) {
    edgeChecked++;
    if (edgeChecked % 10 == 0) {
      print("  Progress: checked $edgeChecked/${allEdges.length} edges");
    }
    
    final eVLabel = t.node(edge.v);
    final eWLabel = t.node(edge.w);
    
    final vIsDesc = isDescendant(t, eVLabel, tailLabel);
    final wIsDesc = isDescendant(t, eWLabel, tailLabel);
    
    if ((flip == vIsDesc) && (flip != wIsDesc)) {
      print("    ✓ Edge ${edge.v}-${edge.w} meets criteria (vIsDesc=$vIsDesc, wIsDesc=$wIsDesc)");
      final s = slack(g, edge);
      print("    Slack = $s (current best: $bestSlack)");
      
      if (s < bestSlack) {
        bestSlack = s;
        best = edge;
        print("    👉 New best edge: ${edge.v}-${edge.w} with slack=$s");
      }

    }

  }
  
  if (best != null) {
    print("  Found entering edge: ${best.v}-${best.w} with slack=$bestSlack");
  } else {
    print("  No valid entering edge found");
  }
  
  print("🔎 [enterEdge] END -> ${best?.v}-${best?.w}\n");
  return best;
}

void exchangeEdges(Graph t, Graph g, Edge e, Edge f) {
  print("\n🔄 [exchangeEdges] START");
  
  print("  Removing edge ${e.v}-${e.w} from tree");
  t.removeEdge(e.v, e.w, e.name);
  
  print("  Adding edge ${f.v}-${f.w} to tree");
  final originalLabel = g.edge(f.v, f.w, f.name) ?? {};
  t.setEdge(f.v, f.w, originalLabel, f.name);

  print("  Tree edges after exchange: ${t.edges().map((e) => '${e.v}-${e.w}').toList()}");
  
  print("  Recalculating low/lim values");
  initLowLimValues(t);
  
  print("  Recalculating cut values");
  initCutValues(t, g);
  
  print("  Updating ranks in graph g");
  updateRanks(t, g);
  
  print("🔄 [exchangeEdges] END\n");
}

void updateRanks(Graph t, Graph g) {
  print("\n📏 [updateRanks] START");
  
  // 找 root: tree 中没有 parent 的那个
  final root = t.getNodes().firstWhere(
        (v) => !t.node(v).containsKey('parent'),
        orElse: () => '',
      );

  if (root.isEmpty) {
    print("  ❌ No root found in tree, cannot update ranks");
    return;
  }
  
  print("  Found root node: $root");

  // 先清空所有rank
  for (var nodeId in g.getNodes()) {
    print("  Clearing rank for node: $nodeId");
    g.node(nodeId)['rank'] = null;
  }
  
  print("  Setting root rank to 0");
  g.node(root)['rank'] = 0;

  final vs = preorder(t, root);
  print("  Processing nodes in preorder: $vs");
  
  for (final v in vs.skip(1)) {
    final parent = t.node(v)['parent'] as String?;
    if (parent == null) {
      print("  ⚠️ Node $v has no parent in tree, skipping");
      continue;
    }

    final parentRank = g.node(parent)['rank'] as int? ?? 0;
    print("  Processing node $v with parent $parent (rank=$parentRank)");

    double minlen = 1.0;
    if (g.edge(parent, v) != null) {
      minlen = (g.edge(parent, v)['minlen'] as num?)?.toDouble() ?? 1.0;
      final newRank = parentRank + minlen.round();
      print("  Edge parent->child: $parent->$v, minlen=$minlen, new rank=$newRank");
      g.node(v)['rank'] = newRank;
    } else if (g.edge(v, parent) != null) {
      minlen = (g.edge(v, parent)['minlen'] as num?)?.toDouble() ?? 1.0;
      final newRank = parentRank - minlen.round();
      print("  Edge child->parent: $v->$parent, minlen=$minlen, new rank=$newRank");
      g.node(v)['rank'] = newRank;
    } else {
      print("  ⚠️ No edge between $v and $parent in graph g!");
    }

  }
  
  print("  Final ranks:");
  for (final v in g.getNodes()) {
    print("    $v: ${g.node(v)['rank']}");
  }
  
  print("📏 [updateRanks] END\n");
}

bool isDescendant(Graph t, dynamic vLabel, dynamic rootLabel) {
  if (vLabel == null || rootLabel == null) return false;
  final vLim = (vLabel['lim'] is int) ? vLabel['lim'] as int : 0;
  final rLow = (rootLabel['low'] is int) ? rootLabel['low'] as int : 0;
  final rLim = (rootLabel['lim'] is int) ? rootLabel['lim'] as int : 0;
  return (rLow <= vLim) && (vLim <= rLim);
}


