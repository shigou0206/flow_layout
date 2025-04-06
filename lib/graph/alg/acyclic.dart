import 'package:flow_layout/graph/graph.dart';

/// 用于处理有向图中的环的算法。
///
/// 该类可以:
/// 1. 使用贪婪算法或深度优先搜索找出有向图中的反馈弧集
/// 2. 通过反转反馈弧集中的边使图变为无环图
/// 3. 撤销上述操作，恢复图的原始状态
class Acyclic {
  // 添加静态字段来存储原始边
  static final Map<int, List<Map<String, dynamic>>> _originalState = {};

  /// 运行算法使图变为无环
  ///
  /// 返回图是否发生了改变
  static bool run(Graph g) {
    // 检查图是否有环
    if (_findCycles(g).isEmpty) {
      return false; // 图已经是无环的，不需要修改
    }

    // 保存原始状态以便撤销
    _saveGraphState(g);

    final acyclicer = g.graph()?['acyclicer'] as String?;
    Map<String, dynamic> feedbackEdges;

    if (acyclicer == 'greedy') {
      feedbackEdges = _greedyFas(g);
    } else {
      feedbackEdges = _dfsFeedbackEdges(g);
    }

    if (feedbackEdges.isEmpty) {
      return false; // 算法没有找到需要反转的边
    }

    _removeCycles(g, feedbackEdges);
    return true; // 图被修改了
  }

  /// 撤销之前对图的改变，恢复环
  // static void undo(Graph g) {
  //   final graphId = g.hashCode;

  //   // 如果没有保存这个图的状态，直接返回
  //   if (!_originalState.containsKey(graphId)) {
  //     return;
  //   }

  //   // 获取原始状态
  //   final originalEdges = _originalState[graphId]!;

  //   // 找到所有标记了 reversed 的边
  //   final reversedEdges = <Map<String, dynamic>>[];
  //   for (final edgeObj in g.edges()) {
  //     final edge = g.edge(edgeObj);
  //     if (edge != null && edge['reversed'] == true) {
  //       reversedEdges.add(Map<String, dynamic>.from(edgeObj));
  //     }
  //   }

  //   // 先删除所有被反转的边
  //   for (final edge in reversedEdges) {
  //     g.removeEdge(edge);
  //   }

  //   // 再添加所有原始边
  //   for (final originalEdge in originalEdges) {
  //     final v = originalEdge['v'] as String;
  //     final w = originalEdge['w'] as String;
  //     final name = originalEdge['name']; // 支持多边图中的命名边
  //     final edge = g.edge(name);
  //     g.setEdge(v, w, Map<String, dynamic>.from(edge), name);
  //   }

  //   // 清除状态
  //   _originalState.remove(graphId);
  // }

  static void undo(Graph g) {
    final graphId = g.hashCode;

    if (!_originalState.containsKey(graphId)) {
      return;
    }

    // 仅恢复存在于 originalEdges 中的边
    final originalEdges = _originalState[graphId]!;

    final originalEdgeSet = originalEdges
        .map((e) => '${e['v']}->${e['w']}@${e['name'] ?? ''}')
        .toSet();

    final reversedEdges = g.edges().where((edgeObj) {
      final edgeLabel = g.edge(edgeObj);
      final edgeKey =
          '${edgeObj['w']}->${edgeObj['v']}@${edgeLabel?['forwardName'] ?? ''}';
      return edgeLabel != null &&
          edgeLabel['reversed'] == true &&
          originalEdgeSet.contains(edgeKey);
    }).toList();

    for (final edge in reversedEdges) {
      final edgeLabel = g.edge(edge);
      if (edgeLabel == null) continue;

      final originalV = edge['v'] as String;
      final originalW = edge['w'] as String;
      final originalName = edgeLabel['forwardName'] as String?;

      g.removeEdge(edge);

      final restoredLabel = Map<String, dynamic>.from(edgeLabel)
        ..remove('reversed')
        ..remove('forwardName');

      g.setEdge(originalW, originalV, restoredLabel, originalName);
    }

    // 清除状态
    _originalState.remove(graphId);
  }

  /// 保存图的初始状态
  static void _saveGraphState(Graph g) {
    final graphId = g.hashCode;
    final edges = <Map<String, dynamic>>[];

    // 保存所有边的信息，包括多边图中的命名边
    for (final edgeObj in g.edges()) {
      final v = edgeObj['v'] as String;
      final w = edgeObj['w'] as String;
      final name = edgeObj['name']; // 支持多边图
      final label = g.edge(edgeObj);

      if (label != null) {
        edges.add({
          'v': v,
          'w': w,
          'name': name,
          'label': Map<String, dynamic>.from(label)
        });
      }
    }

    _originalState[graphId] = edges;
  }

  /// 查找图中的所有环
  static List<List<String>> _findCycles(Graph g) {
    final visited = <String>{};
    final cycles = <List<String>>[];

    void dfs(String node, List<String> path, Set<String> onStack) {
      if (onStack.contains(node)) {
        // 找到环
        final cycleStart = path.indexOf(node);
        final cycle = path.sublist(cycleStart);
        cycles.add(cycle);
        return;
      }

      if (visited.contains(node)) return;

      visited.add(node);
      onStack.add(node);
      path.add(node);

      final successors = g.successors(node) ?? [];
      for (final next in successors) {
        dfs(next, [...path], {...onStack});
      }

      onStack.remove(node);
    }

    for (final node in g.getNodes()) {
      if (!visited.contains(node)) {
        dfs(node, [], {});
      }
    }

    return cycles;
  }

  /// 使用贪婪算法查找反馈弧集
  static Map<String, dynamic> _greedyFas(Graph g) {
    // 使用临时图进行环检测，有序添加边
    final tmpGraph = Graph(isDirected: true);

    // 将节点添加到临时图
    for (final node in g.getNodes()) {
      tmpGraph.setNode(node);
    }

    // 将所有边按权重从高到低排序（确保低权重的边最后处理）
    final sortedEdges = <Map<String, dynamic>>[...g.edges()];
    sortedEdges.sort((a, b) {
      final weightA = _getEdgeWeight(g, a);
      final weightB = _getEdgeWeight(g, b);
      // 降序排序，高权重优先
      return weightB.compareTo(weightA);
    });

    // 标记反馈弧集
    final feedbackEdges = <String, dynamic>{};

    // 从高权重边开始逐个添加，低权重边最后添加
    for (final edge in sortedEdges) {
      final v = edge['v'] as String;
      final w = edge['w'] as String;

      print('Processing edge $v -> $w with weight ${_getEdgeWeight(g, edge)}');

      // 尝试添加到辅助图中
      tmpGraph.setEdge(v, w, {});

      // 检查是否形成环路
      final hasCycle = _findCycles(tmpGraph).isNotEmpty;

      if (hasCycle) {
        // 如果形成环，则将低权重边加入反馈弧集
        print('Edge $v -> $w creates cycle, marking for reversal');
        feedbackEdges[_edgeKey(edge)] = edge;

        // 从临时图中移除这条边
        tmpGraph.removeEdge(v, w);
      }
    }

    return feedbackEdges;
  }

  /// 获取边的权重
  static num _getEdgeWeight(Graph g, Map<String, dynamic> edge) {
    final label = g.edge(edge);
    return label != null && label.containsKey('weight')
        ? label['weight'] as num
        : 1;
  }

  /// 用于边的键生成
  static String _edgeKey(Map<String, dynamic> edge) {
    final nameStr = edge['name'] != null ? ':${edge['name']}' : '';
    return '${edge['v']}:${edge['w']}$nameStr';
  }

  /// 使用 DFS 查找反馈弧集
  static Map<String, dynamic> _dfsFeedbackEdges(Graph g) {
    final visited = <String>{};
    final onStack = <String>{};
    final results = <String, dynamic>{};

    void dfs(String u) {
      if (visited.contains(u)) {
        return;
      }

      visited.add(u);
      onStack.add(u);

      final successors = g.successors(u) ?? [];
      for (final v in successors) {
        if (onStack.contains(v)) {
          // 找到一个环
          final edges = g.outEdges(u, v) ?? [];
          for (final edge in edges) {
            results[_edgeKey(edge)] = edge;
          }
        } else if (!visited.contains(v)) {
          dfs(v);
        }
      }

      onStack.remove(u);
    }

    for (final node in g.getNodes()) {
      if (!visited.contains(node)) {
        dfs(node);
      }
    }

    return results;
  }

  /// 通过反转反馈弧集中的边移除环
  static void _removeCycles(Graph g, Map<String, dynamic> feedbackEdges) {
    for (final edgeObj in feedbackEdges.values) {
      final v = edgeObj['v'] as String;
      final w = edgeObj['w'] as String;
      final name = edgeObj['name']; // 支持多边图

      // 获取原始边标签
      final label = g.edge(v, w, name) ?? {};

      // 移除原始边
      g.removeEdge(v, w, name);

      // 确保边被移除
      if (g.hasEdge(v, w, name)) {
        print('Failed to remove edge $v -> $w');
      }

      // 创建新标签，将原始方向记录下来
      final newLabel = Map<String, dynamic>.from(label);
      newLabel['reversed'] = true;
      newLabel['originalSource'] = v;
      newLabel['originalTarget'] = w;

      // 为多边图创建反向边（可能需要新名称）
      if (g.isMultigraph && g.hasEdge(w, v)) {
        // 使用新的唯一名称
        final newName = name != null ? '${name}_reversed' : 'reversed';
        g.setEdge(w, v, newLabel, newName);
      } else {
        // 使用原始名称（如果有）
        g.setEdge(w, v, newLabel, name);
      }
    }
  }
}
