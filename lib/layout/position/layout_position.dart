import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/utils.dart';
import 'package:flow_layout/layout/position/bk.dart'; // 包含 positionX 函数

/// 计算节点的位置：先计算 y 坐标，再计算 x 坐标
void position(Graph g) {
  // 将图扁平化（compound => non-compound）
  final nonCompoundGraph = asNonCompoundGraph(g);

  // 计算 y 坐标
  positionY(nonCompoundGraph);

  // 计算 x 坐标
  final xCoords = positionX(nonCompoundGraph);
  
  // 将非复合图中的坐标应用回原始图
  for (final v in g.getNodes()) {
    if (g.children(v) != null && g.children(v)!.isNotEmpty) {
      // 跳过子图容器节点
      continue;
    }
    
    // 获取节点属性
    final node = g.node(v);
    if (node == null) continue;
    
    final nonCompoundNode = nonCompoundGraph.node(v);
    if (nonCompoundNode == null) continue;
    
    // 创建新的节点属性映射，复制所有属性
    final updatedNode = Map<String, dynamic>.from(node);
    
    // 从非复合图复制坐标
    if (nonCompoundNode.containsKey('y')) {
      updatedNode['y'] = nonCompoundNode['y'];
    }
    
    // 应用 X 坐标
    if (xCoords.containsKey(v)) {
      updatedNode['x'] = xCoords[v];
    }
    
    // 更新节点
    g.setNode(v, updatedNode);
  }
}

/// 根据层次计算各节点的 y 坐标
void positionY(Graph g) {
  // 获取层次矩阵，每一层节点顺序已根据 rank 和 order 排序
  final layering = buildLayerMatrix(g);
  
  // 从图的 label 中取出 ranksep 值，如果不存在则默认为 0
  final rankSep = g.graph()?["ranksep"] != null 
      ? (g.graph()?["ranksep"] as num).toDouble() 
      : 0.0;
  double prevY = 0.0;

  // 遍历每一层
  for (int i = 0; i < layering.length; i++) {
    final layer = layering[i];
    
    // 计算本层节点的最大高度
    double maxHeight = 0.0;
    for (final v in layer) {
      final node = g.node(v);
      if (node != null && node["height"] != null) {
        final height = (node["height"] as num).toDouble();
        if (height > maxHeight) {
          maxHeight = height;
        }
      }
    }
    
    // 为每个节点设置 y 坐标：当前层 y 坐标为上层累计高度 + 本层高度的一半
    for (final v in layer) {
      final node = g.node(v);
      if (node != null) {
        // 创建新的节点属性映射，保持类型安全
        final updatedNode = Map<String, dynamic>.from(node);
        updatedNode['y'] = prevY + maxHeight / 2;
        g.setNode(v, updatedNode);
      }
    }
    
    // 更新累积高度：本层高度 + 分层间距
    prevY += maxHeight + rankSep;
  }
}
