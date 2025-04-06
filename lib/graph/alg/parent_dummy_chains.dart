import 'package:flow_layout/graph/graph.dart';
import 'dart:math' as math;

/// 为虚拟节点链设置父节点
///
/// 此函数为虚拟节点链分配父节点，使用原始边端点的最低公共祖先路径
/// 来决定每个虚拟节点的父节点
void parentDummyChains(Graph g) {
  // 获取图的后序遍历编号
  final postorderNums = _calculatePostorder(g);

  // 获取图的dummy链
  final graphData = g.graph();
  if (graphData == null || !graphData.containsKey('dummyChains')) {
    return;
  }

  // 处理每个dummy链
  final dummyChains = graphData['dummyChains'] as List;
  for (final v in dummyChains) {
    var node = g.node(v);
    if (node == null || !node.containsKey('edgeObj')) continue;

    final edgeObj = node['edgeObj'] as Map<String, dynamic>;
    final pathData = _findPath(g, postorderNums, edgeObj['v'], edgeObj['w']);
    final path = pathData['path'] as List<String>;
    final lca = pathData['lca'] as String?;

    int pathIdx = 0;
    String? pathV = path.isNotEmpty ? path[pathIdx] : null;
    bool ascending = true;

    // 遍历虚拟节点链，为每个节点设置父节点
    var currentV = v;
    while (currentV != edgeObj['w']) {
      node = g.node(currentV);
      if (node == null) break;

      if (ascending) {
        while (pathIdx < path.length &&
            path[pathIdx] != lca &&
            g.node(path[pathIdx])!.containsKey('maxRank') &&
            (g.node(path[pathIdx])!['maxRank'] as num) <
                (node['rank'] as num)) {
          pathIdx++;
        }

        if (pathIdx < path.length && path[pathIdx] == lca) {
          ascending = false;
        }
      }

      if (!ascending) {
        while (pathIdx < path.length - 1 &&
            g.node(path[pathIdx + 1])!.containsKey('minRank') &&
            (g.node(path[pathIdx + 1])!['minRank'] as num) <=
                (node['rank'] as num)) {
          pathIdx++;
        }
      }

      // 设置当前虚拟节点的父节点
      pathV = pathIdx < path.length ? path[pathIdx] : null;
      if (pathV != null) {
        g.setParent(currentV, pathV);
      }

      // 移动到链中的下一个节点
      final successors = g.successors(currentV);
      if (successors == null || successors.isEmpty) break;
      currentV = successors[0];
    }
  }
}

/// 计算后序遍历编号，用于查找最低公共祖先
Map<String, Map<String, int>> _calculatePostorder(Graph g) {
  final result = <String, Map<String, int>>{};
  int lim = 0;

  void dfs(String v) {
    final low = lim;
    final children = g.children(v) ?? [];
    for (final child in children) {
      dfs(child);
    }
    result[v] = {'low': low, 'lim': lim++};
  }

  final rootChildren = g.children() ?? [];
  for (final child in rootChildren) {
    dfs(child);
  }

  return result;
}

/// 在两个节点之间找到路径，经过它们的最低公共祖先(LCA)
/// 返回完整路径和LCA
Map<String, dynamic> _findPath(
    Graph g, Map<String, Map<String, int>> postorderNums, String v, String w) {
  final vPath = <String>[];
  final wPath = <String>[];

  // 获取低值和限值范围
  final vPostorder = postorderNums[v];
  final wPostorder = postorderNums[w];

  // 若未找到对应的后序编号，直接返回空路径
  if (vPostorder == null || wPostorder == null) {
    return {'path': <String>[], 'lca': null};
  }

  final low = math.min(vPostorder['low']!, wPostorder['low']!);
  final lim = math.max(vPostorder['lim']!, wPostorder['lim']!);

  String? parent;
  String? lca;

  // 从v向上遍历找到LCA
  parent = v;
  do {
    parent = g.parent(parent);
    if (parent != null) {
      vPath.add(parent);

      // 判断是否找到了LCA
      final parentPostorder = postorderNums[parent];
      if (parentPostorder != null &&
          (parentPostorder['low']! > low || lim > parentPostorder['lim']!)) {
        continue;
      }
    }
    break;
    // ignore: unnecessary_null_comparison
  } while (parent != null);

  lca = parent;

  // 从w向上遍历到LCA
  parent = w;
  while (parent != lca) {
    parent = g.parent(parent);
    if (parent == null) break;
    wPath.add(parent);
  }

  // 翻转wPath并与vPath合并形成完整路径
  return {'path': vPath + wPath.reversed.toList(), 'lca': lca};
}
