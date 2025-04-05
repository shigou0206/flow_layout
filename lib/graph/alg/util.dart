import '../graph.dart';

/// 向图中添加一个虚拟节点
/// 
/// [g] - 要添加节点的图
/// [type] - 虚拟节点的类型
/// [attrs] - 虚拟节点的属性
/// [prefix] - 节点名称前缀
/// 
/// 返回包含新节点ID的Map
Map<String, dynamic> addDummyNode(Graph g, String type, Map<String, dynamic> attrs, String prefix) {
  var v;
  do {
    v = '_${prefix}${nextDummyId++}';
  } while (g.hasNode(v));

  attrs['dummy'] = type;
  g.setNode(v, attrs);
  
  return {'v': v};
}

/// 下一个虚拟节点的ID
int nextDummyId = 0; 