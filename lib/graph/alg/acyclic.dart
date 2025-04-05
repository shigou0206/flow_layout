import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/graph/alg/greedy_fas.dart' as greedy_fas;

/// 处理有向图中的循环，使其变为有向无环图(DAG)
/// 
/// 通过反转特定边的方向来移除图中的环，使其成为DAG
/// 可以使用两种方法：
/// 1. 贪婪最小反馈弧集(greedy FAS)算法
/// 2. 基于深度优先搜索(DFS)的算法
class Acyclic {
  
  /// 运行无环化算法，反转必要的边使图变为DAG
  /// 
  /// 如果图的graph对象中acyclicer属性为"greedy"，则使用贪婪算法
  /// 否则使用基于DFS的算法
  static void run(Graph g) {
    List<Map<String, dynamic>> edges;
    
    // 根据图属性选择算法
    final graphData = g.graph() ?? {};
    if (graphData.containsKey('acyclicer') && graphData['acyclicer'] == 'greedy') {
      // 使用贪婪算法
      final weightFn = (Map<String, dynamic> e) {
        final edge = g.edge(e);
        if (edge is Map && edge.containsKey('weight')) {
          return edge['weight'] as num;
        }
        return 1; // 默认权重
      };
      edges = greedy_fas.greedyFAS(g, weightFn);
    } else {
      // 使用DFS算法
      edges = _dfsFAS(g);
    }
    
    // 反转找到的边
    for (final e in edges) {
      final label = g.edge(e);
      if (label == null) continue;
      
      // 保存原始信息并移除原边
      final forwardName = e.containsKey('name') ? e['name'] : null;
      g.removeEdge(e);
      
      // 设置反向边
      Map<String, dynamic> newLabel;
      if (label is Map) {
        newLabel = Map<String, dynamic>.from(label);
        newLabel['forwardName'] = forwardName;
        newLabel['reversed'] = true;
      } else {
        // 处理非Map类型的标签
        newLabel = {
          'label': label,
          'forwardName': forwardName,
          'reversed': true
        };
      }
      
      // 创建反向边(w->v)替代原来的(v->w)
      // 不要使用命名边，因为默认情况下图不是多重图
      g.setEdge(e['w'], e['v'], newLabel);
    }
  }
  
  /// 基于DFS的反馈弧集算法
  /// 
  /// 使用深度优先搜索找到图中的环，并返回需要反转的边
  static List<Map<String, dynamic>> _dfsFAS(Graph g) {
    final fas = <Map<String, dynamic>>[];
    final stack = <String, bool>{};
    final visited = <String, bool>{};
    
    void dfs(String v) {
      if (visited.containsKey(v)) return;
      
      visited[v] = true;
      stack[v] = true;
      
      final outEdges = g.outEdges(v) ?? [];
      for (final e in outEdges) {
        final w = e['w'] as String;
        if (stack.containsKey(w)) {
          // 找到回边，加入反馈弧集
          fas.add(e);
        } else {
          dfs(w);
        }
      }
      
      stack.remove(v);
    }
    
    // 对每个未访问的节点执行DFS
    for (final v in g.getNodes()) {
      dfs(v);
    }
    
    return fas;
  }
  
  /// 恢复原图，撤销边的反转
  static void undo(Graph g) {
    final edgesToRemove = <Map<String, dynamic>>[];
    
    // 首先收集需要恢复的边
    for (final e in g.edges()) {
      final label = g.edge(e);
      if (label is Map && label.containsKey('reversed') && label['reversed'] == true) {
        edgesToRemove.add(e);
      }
    }
    
    // 恢复边
    for (final e in edgesToRemove) {
      final label = g.edge(e);
      if (label == null || label is! Map) continue;
      
      g.removeEdge(e);
      
      // 获取原始名称并清除反转标记
      final Map<String, dynamic> newLabel = Map<String, dynamic>.from(label);
      final forwardName = newLabel.containsKey('forwardName') ? newLabel['forwardName'] : null;
      newLabel.remove('reversed');
      newLabel.remove('forwardName');
      
      // 如果标签是通过包装原始值创建的，恢复原始值
      if (newLabel.containsKey('label') && newLabel.length == 1) {
        // 不使用命名边
        g.setEdge(e['w'], e['v'], newLabel['label']);
      } else {
        // 不使用命名边
        g.setEdge(e['w'], e['v'], newLabel);
      }
    }
  }
} 