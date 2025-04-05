import 'package:flow_layout/graph/graph.dart';
import 'dart:math' as math;

/// 嵌套图相关工具函数和算法
/// 
/// 嵌套图为子图的顶部和底部创建边界节点，添加适当的边以确保所有集群节点
/// 放置在这些边界之间，并确保图是连通的。
/// 
/// 前置条件:
///   1. 输入图是一个DAG(有向无环图)
///   2. 输入图中的节点具有minlen属性
///
/// 后置条件:
///   1. 输入图是连通的
///   2. 为子图的顶部和底部添加了边界节点
///   3. 调整节点的minlen属性，确保节点不会与子图边界节点位于同一级别
class NestingGraph {
  
  /// 运行嵌套图算法
  static void run(Graph g) {
    final root = _addDummyNode(g, "root", {}, "_root");
    final depths = _treeDepths(g);
    final depthsArr = depths.values.toList();
    final height = (depthsArr.isEmpty ? 0 : depthsArr.fold(0, math.max)) - 1;
    final nodeSep = 2 * height + 1;
    
    // 设置图的嵌套根节点
    final graphData = g.graph() ?? {};
    graphData['nestingRoot'] = root;
    g.setGraph(graphData);
    
    // 将minlen乘以nodeSep，以便在非边界级别上对齐节点
    for (final e in g.edges()) {
      final edge = g.edge(e);
      if (edge is Map && edge.containsKey('minlen')) {
        edge['minlen'] = (edge['minlen'] as num) * nodeSep;
        g.setEdge(e, edge);
      }
    }
    
    // 计算一个足够大的权重，使子图在垂直方向上保持紧凑
    final weight = _sumWeights(g) + 1;
    
    // 创建边界节点并连接它们
    final children = g.children() ?? [];
    for (final child in children) {
      _dfs(g, root, nodeSep, weight, height, depths, child);
    }
    
    // 保存节点层的乘数，用于以后移除空边界层
    graphData['nodeRankFactor'] = nodeSep;
    g.setGraph(graphData);
  }
  
  /// 清理嵌套图
  static void cleanup(Graph g) {
    final graphData = g.graph();
    if (graphData == null) return;
    
    if (graphData.containsKey('nestingRoot')) {
      final nestingRoot = graphData['nestingRoot'];
      g.removeNode(nestingRoot);
      graphData.remove('nestingRoot');
      g.setGraph(graphData);
    }
    
    // 移除所有嵌套边
    final edgesToRemove = <Map<String, dynamic>>[];
    for (final e in g.edges()) {
      final edge = g.edge(e);
      if (edge is Map && edge.containsKey('nestingEdge') && edge['nestingEdge'] == true) {
        edgesToRemove.add(e);
      }
    }
    
    for (final e in edgesToRemove) {
      g.removeEdge(e);
    }
  }
  
  /// 添加一个边界节点
  static String _addBorderNode(Graph g, String prefix) {
    final id = "_${prefix}_${g.nodeCount}";
    g.setNode(id, {'width': 0, 'height': 0, 'dummy': 'border'});
    return id;
  }
  
  /// 添加一个虚拟节点
  static String _addDummyNode(Graph g, String type, Map<String, dynamic> attrs, String prefix) {
    final id = "_${prefix}_${g.nodeCount}";
    final nodeAttrs = {...attrs, 'dummy': type};
    g.setNode(id, nodeAttrs);
    return id;
  }
  
  /// 深度优先搜索处理子图
  static void _dfs(
      Graph g, 
      String root, 
      int nodeSep, 
      num weight, 
      int height, 
      Map<String, int> depths, 
      String v) {
    
    final children = g.children(v) ?? [];
    if (children.isEmpty) {
      if (v != root) {
        g.setEdge(root, v, {'weight': 0, 'minlen': nodeSep});
      }
      return;
    }
    
    final top = _addBorderNode(g, "bt");
    final bottom = _addBorderNode(g, "bb");
    final label = g.node(v) ?? {};
    
    g.setParent(top, v);
    label['borderTop'] = top;
    g.setNode(v, label);
    
    g.setParent(bottom, v);
    label['borderBottom'] = bottom;
    g.setNode(v, label);
    
    for (final child in children) {
      _dfs(g, root, nodeSep, weight, height, depths, child);
      
      final childNode = g.node(child) ?? {};
      final childTop = childNode.containsKey('borderTop') ? childNode['borderTop'] : child;
      final childBottom = childNode.containsKey('borderBottom') ? childNode['borderBottom'] : child;
      final thisWeight = childNode.containsKey('borderTop') ? weight : 2 * weight;
      final minlen = childTop != childBottom ? 1 : height - depths[v]! + 1;
      
      g.setEdge(top, childTop, {
        'weight': thisWeight,
        'minlen': minlen,
        'nestingEdge': true
      });
      
      g.setEdge(childBottom, bottom, {
        'weight': thisWeight,
        'minlen': minlen,
        'nestingEdge': true
      });
    }
    
    if (g.parent(v) == null) {
      g.setEdge(root, top, {'weight': 0, 'minlen': height + depths[v]!});
    }
  }
  
  /// 计算树的深度
  static Map<String, int> _treeDepths(Graph g) {
    final depths = <String, int>{};
    
    void dfs(String v, int depth) {
      final children = g.children(v) ?? [];
      if (children.isNotEmpty) {
        for (final child in children) {
          dfs(child, depth + 1);
        }
      }
      depths[v] = depth;
    }
    
    final rootChildren = g.children() ?? [];
    for (final v in rootChildren) {
      dfs(v, 1);
    }
    
    return depths;
  }
  
  /// 计算所有边的权重总和
  static num _sumWeights(Graph g) {
    num sum = 0;
    for (final e in g.edges()) {
      final edge = g.edge(e);
      if (edge is Map && edge.containsKey('weight')) {
        sum += edge['weight'] as num;
      }
    }
    return sum;
  }
} 