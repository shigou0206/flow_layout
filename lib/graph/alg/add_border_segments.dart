import 'package:flow_layout/graph/graph.dart';

/// 为复合图添加边界段
/// 
/// 该函数为每个具有minRank和maxRank的子图添加左右边界节点，
/// 以便后续布局算法能够确保子图内部的节点不会超出边界。
void addBorderSegments(Graph g) {
  /// 深度优先遍历处理子图
  void dfs(String v) {
    final children = g.children(v) ?? [];
    final node = g.node(v);
    
    // 先处理子节点
    if (children.isNotEmpty) {
      for (final child in children) {
        dfs(child);
      }
    }

    // 如果节点有minRank属性，则为其添加边界节点
    if (node != null && node is Map && node.containsKey('minRank')) {
      // 强制转换为Map<String, dynamic>类型
      final Map<String, dynamic> typedNode = Map<String, dynamic>.from(node);
      
      // 初始化左右边界节点数组
      typedNode['borderLeft'] = <dynamic>[];
      typedNode['borderRight'] = <dynamic>[];
      
      // 为每个rank添加边界节点
      for (int rank = typedNode['minRank'] as int; 
           rank < (typedNode['maxRank'] as int) + 1; 
           ++rank) {
        _addBorderNode(g, 'borderLeft', '_bl', v, typedNode, rank);
        _addBorderNode(g, 'borderRight', '_br', v, typedNode, rank);
      }
      
      // 更新图中的节点
      g.setNode(v, typedNode);
    }
  }

  // 对图中的每个顶层节点执行dfs
  final children = g.children() ?? [];
  for (final child in children) {
    dfs(child);
  }
}

/// 添加边界节点
/// 
/// 为指定子图在特定rank上添加边界节点，并与前一rank的边界节点连接
void _addBorderNode(
    Graph g, 
    String prop, 
    String prefix, 
    String sg, 
    Map<String, dynamic> sgNode, 
    int rank) {
  
  // 创建边界节点的标签
  final label = <String, dynamic>{
    'width': 0, 
    'height': 0, 
    'rank': rank, 
    'borderType': prop
  };
  
  // 获取上一个rank的边界节点
  final prev = sgNode[prop] is List && (sgNode[prop] as List).length > (rank - 1) && rank > 0
      ? (sgNode[prop] as List)[rank - 1] 
      : null;
  
  // 添加新的边界节点
  final curr = _addDummyNode(g, 'border', label, prefix);
  
  // 将当前边界节点存储到子图节点中
  final borderList = sgNode[prop] as List;
  while (borderList.length <= rank) {
    borderList.add(null);
  }
  borderList[rank] = curr;
  
  // 设置边界节点的父节点
  g.setParent(curr, sg);
  
  // 如果存在上一个rank的边界节点，则连接它们
  if (prev != null) {
    g.setEdge(prev, curr, <String, dynamic>{'weight': 1});
  }
}

/// 添加一个虚拟节点
String _addDummyNode(Graph g, String type, Map<String, dynamic> attrs, String prefix) {
  final id = '_${prefix}${g.nodeCount}';
  final nodeAttrs = <String, dynamic>{...attrs, 'dummy': type};
  g.setNode(id, nodeAttrs);
  return id;
} 