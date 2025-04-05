import '../graph.dart';
import 'util.dart';

/// 规范化图中的边，将长边分解为跨越单个层级的短边
/// 
/// 前置条件:
///   1. 输入图必须是有向无环图(DAG)
///   2. 图中的每个节点都有"rank"属性
///
/// 后置条件:
///   1. 图中所有边的长度为1
///   2. 在边被分割为段时添加虚拟节点
///   3. 图被增强了"dummyChains"属性，包含每条虚拟节点链中的第一个虚拟节点
void run(Graph g) {
  g.setGraph({'dummyChains': []});
  final edges = g.edges();
  if (edges != null) {
    for (final edge in edges) {
      normalizeEdge(g, edge);
    }
  }
}

/// 规范化单条边，将跨越多层级的边分解为多个只跨越一个层级的边
void normalizeEdge(Graph g, Map<String, dynamic> e) {
  var v = e['v'];
  final vRank = g.node(v)['rank'] as int;
  final w = e['w'];
  final wRank = g.node(w)['rank'] as int;
  final name = e['name'];
  final edgeLabel = g.edge(e);
  final labelRank = edgeLabel != null && edgeLabel.containsKey('labelRank') 
      ? edgeLabel['labelRank'] as int? 
      : null;

  // 如果边的长度已经是1，不需要规范化
  if (wRank == vRank + 1) return;

  // 移除原始边
  g.removeEdge(e);

  Map<String, dynamic>? dummy;
  Map<String, dynamic> attrs;
  int currentRank = vRank;
  
  // 为长边创建虚拟节点链
  for (int i = 0; currentRank < wRank - 1; ++i, ++currentRank) {
    // 清除边标签的点
    if (edgeLabel != null && edgeLabel.containsKey('points')) {
      edgeLabel['points'] = [];
    }
    
    // 创建虚拟节点的属性
    attrs = {
      'width': 0, 
      'height': 0,
      'edgeLabel': edgeLabel, 
      'edgeObj': e,
      'rank': currentRank + 1
    };
    
    // 添加虚拟节点
    dummy = addDummyNode(g, 'edge', attrs, '_d');
    
    // 如果当前层级是标签层级，设置标签相关属性
    if (labelRank != null && currentRank + 1 == labelRank) {
      attrs['width'] = edgeLabel['width'];
      attrs['height'] = edgeLabel['height'];
      attrs['dummy'] = 'edge-label';
      attrs['labelpos'] = edgeLabel['labelpos'];
    }
    
    // 创建从上一节点到虚拟节点的边
    final weight = edgeLabel != null && edgeLabel.containsKey('weight') 
        ? edgeLabel['weight'] 
        : null;
    g.setEdge(v, dummy!['v'], {'weight': weight}, name);
    
    // 将第一个虚拟节点添加到dummyChains中
    if (i == 0) {
      final graphData = g.graph();
      if (graphData != null && graphData.containsKey('dummyChains')) {
        (graphData['dummyChains'] as List).add(dummy['v']);
      }
    }
    
    // 更新当前节点为新创建的虚拟节点，准备下一轮循环
    v = dummy['v'];
  }

  // 创建最后一条边，连接到原始目标节点
  final weight = edgeLabel != null && edgeLabel.containsKey('weight') 
      ? edgeLabel['weight'] 
      : null;
  g.setEdge(v, w, {'weight': weight}, name);
}

/// 撤销规范化，恢复原始的长边
void undo(Graph g) {
  final graphData = g.graph();
  if (graphData == null || !graphData.containsKey('dummyChains')) return;
  
  // 保存并清空dummyChains，以便在循环中安全修改
  List<dynamic> dummyChains = List.from(graphData['dummyChains'] as List);
  graphData['dummyChains'] = <String>[];
  
  for (final v in dummyChains) {
    var currentV = v;
    var node = g.node(currentV);
    
    if (node == null || !node.containsKey('edgeObj')) continue;
    
    final edgeObj = node['edgeObj'];
    final origLabel = Map<String, dynamic>.from(node['edgeLabel'] as Map);
    
    // 确保origLabel有一个points数组
    if (!origLabel.containsKey('points') || origLabel['points'] == null) {
      origLabel['points'] = <Map<String, dynamic>>[];
    }
    
    // 恢复原始边
    g.setEdge(edgeObj, origLabel);
    
    // 处理虚拟节点链
    while (node != null && node.containsKey('dummy')) {
      final successors = g.successors(currentV);
      if (successors == null || successors.isEmpty) break;
      
      final w = successors[0];
      
      // 记录虚拟节点的位置
      if (node.containsKey('x') && node.containsKey('y')) {
        List<Map<String, dynamic>> points;
        if (origLabel.containsKey('points') && origLabel['points'] is List) {
          points = (origLabel['points'] as List).cast<Map<String, dynamic>>();
        } else {
          points = <Map<String, dynamic>>[];
          origLabel['points'] = points;
        }
        
        points.add({
          'x': node['x'] as num, 
          'y': node['y'] as num
        });
      }
      
      // 如果是边标签的虚拟节点，保存标签位置和尺寸
      if (node.containsKey('dummy') && node['dummy'] == 'edge-label') {
        if (node.containsKey('x')) origLabel['x'] = node['x'];
        if (node.containsKey('y')) origLabel['y'] = node['y'];
        if (node.containsKey('width')) origLabel['width'] = node['width'];
        if (node.containsKey('height')) origLabel['height'] = node['height'];
      }
      
      // 移除虚拟节点
      g.removeNode(currentV);
      
      // 移动到链中的下一个节点
      currentV = w;
      node = g.node(currentV);
    }
  }
} 