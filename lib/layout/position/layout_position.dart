import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/utils.dart';
import 'package:flow_layout/layout/position/bk.dart'; // 包含 positionX 函数

/// 计算节点的位置：先计算 y 坐标，再计算 x 坐标
void position(Graph g) {
  // 将图扁平化（compound => non-compound）
  g = asNonCompoundGraph(g);

  // 计算 y 坐标
  positionY(g);

  // 计算 x 坐标，并赋值给各节点
  final xCoords = positionX(g);
  xCoords.forEach((v, x) {
    g.node(v)?["x"] = x;
  });
}

/// 根据层次计算各节点的 y 坐标
void positionY(Graph g) {
  // 获取层次矩阵，每一层节点顺序已根据 rank 和 order 排序
  final layering = buildLayerMatrix(g);
  // 从图的 label 中取出 ranksep 值，如果不存在则默认为 0
  final rankSep = g.graph()["ranksep"] as num? ?? 0;
  num prevY = 0;

  // 遍历每一层
  for (final layer in layering) {
    // 计算本层节点的最大高度
    num maxHeight = 0;
    for (final v in layer) {
      final height = g.node(v)?["height"] as num? ?? 0;
      if (height > maxHeight) {
        maxHeight = height;
      }
    }
    // 为每个节点设置 y 坐标：当前层 y 坐标为上层累计高度 + 本层高度的一半
    for (final v in layer) {
      g.node(v)?["y"] = prevY + maxHeight / 2;
    }
    // 更新累积高度：本层高度 + 分层间距
    prevY += maxHeight + rankSep;
  }
}
