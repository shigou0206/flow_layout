import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/rank/utils.dart';
import 'package:flow_layout/layout/rank/feasible_tree.dart';
import 'package:flow_layout/layout/rank/network_simplex.dart';

/// 为输入图中的每个节点分配一个排名，该排名尊重节点之间边上指定的"minlen"约束。
///
/// 这个基本结构源自Gansner等人的"一种绘制有向图的技术"。
/// 
/// 前置条件：
/// 1. 图必须是连通的DAG（有向无环图）
/// 2. 图节点必须是对象
/// 3. 图边必须有"weight"和"minlen"属性
///
/// 后置条件：
/// 1. 图节点将基于算法结果具有"rank"属性。
///    排名可以从任何索引（包括负数）开始，我们稍后会修复它们。
void rank(Graph g) {
  final graphData = g.graph();
  final ranker = graphData['ranker'] as String? ?? 'network-simplex';
  
  print('Using ranker: $ranker');
  
  // 根据排名器选择相应的排名算法
  switch (ranker) {
    case 'longest-path':
      longestPathRanker(g);
      break;
    case 'tight-tree':
      tightTreeRanker(g);
      break;
    case 'network-simplex':
      networkSimplexRanker(g);
      break;
    default:
      // 对于未知排名器，使用networkSimplex作为默认方法
      print('Unknown ranker: $ranker, using network-simplex as default');
      networkSimplexRanker(g);
      break;
  }
  
  // 确保所有节点都有rank值设置
  for (final v in g.getNodes()) {
    if (!g.node(v).containsKey('rank')) {
      print('Node $v has no rank after ranking, setting to 0');
      g.node(v)['rank'] = 0;
    }
  }
}

/// 一个快速简单的排名器，但结果远非最优。
void longestPathRanker(Graph g) {
  longestPath(g);
}

/// 紧密树排名器
void tightTreeRanker(Graph g) {
  longestPath(g);
  feasibleTree(g);
}

/// 网络单纯形排名器
void networkSimplexRanker(Graph g) {
  networkSimplex(g);
} 