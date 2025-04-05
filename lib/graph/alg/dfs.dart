import 'package:flow_layout/graph/graph.dart';

/// 对给定图 [g] 从节点 [vs] 出发做 DFS，顺序可 "pre" 或 "post"
/// - 若是有向图，使用 `g.successors(v)`
/// - 若是无向图，使用 `g.neighbors(v)`
List<String> dfs(Graph g, dynamic vs, [String order = 'pre']) {
  // 1) 若 vs 不是列表，则变成列表
  List<String> startNodes;
  if (vs is List<String>) {
    startNodes = vs;
  } else if (vs is String) {
    startNodes = [vs];
  } else {
    throw ArgumentError('dfs: vs must be String or List<String>');
  }

  // 2) 根据图是否有向，选择遍历函数
  //    directed => successors(v)
  //    undirected => neighbors(v)
  List<String> Function(String) navigation = g.isDirected
      ? (v) => g.successors(v) ?? []
      : (v) => g.neighbors(v) ?? [];

  // 3) 选 pre / post 遍历实现
  //    默认 preOrder
  final List<String> Function(
    String start,
    List<String> Function(String) nav,
    Map<String,bool> visited
  ) orderFunc = (order == 'post')
      ? _postOrderDfs
      : _preOrderDfs; 

  // 4) 记录访问顺序
  final List<String> acc = [];
  // 记录 visited
  final visited = <String,bool>{};

  // 5) 对每个起点执行 DFS
  for (final v in startNodes) {
    if (!g.hasNode(v)) {
      throw StateError("Graph does not have node: $v");
    }
    // 可能多个起点
    final partial = orderFunc(v, navigation, visited);
    acc.addAll(partial);
  }
  return acc;
}

/// 后序 DFS (post-order) - 迭代实现
List<String> _postOrderDfs(
  String start,
  List<String> Function(String) navigation,
  Map<String,bool> visited,
) {
  final result = <String>[];
  // stack 每个元素: [node, isSecondVisit]
  // isSecondVisit=true 表示弹出时要加入 result
  final stack = <List<dynamic>>[
    [start, false]
  ];

  while (stack.isNotEmpty) {
    final curr = stack.removeLast();
    final node = curr[0] as String;
    final isSecondVisit = curr[1] as bool;

    if (isSecondVisit) {
      // 第二次遇到 => 输出
      result.add(node);
    } else {
      if (!visited.containsKey(node)) {
        visited[node] = true;
        // 入栈第二次遇到的标记
        stack.add([node, true]);
        // 把 neighbors (或 successors) 逆序推入栈
        final neighbors = navigation(node);
        forEachRight(neighbors, (w, i, arr) {
          stack.add([w, false]);
        });
      }
    }
  }

  return result;
}

/// 前序 DFS (pre-order) - 迭代实现
List<String> _preOrderDfs(
  String start,
  List<String> Function(String) navigation,
  Map<String,bool> visited,
) {
  final result = <String>[];
  final stack = <String>[start];

  while (stack.isNotEmpty) {
    final curr = stack.removeLast();
    if (!visited.containsKey(curr)) {
      visited[curr] = true;
      result.add(curr);
      final neighbors = navigation(curr);
      // 逆序压栈 => 维持与递归一致的访问顺序
      forEachRight(neighbors, (w, i, arr) {
        stack.add(w);
      });
    }
  }

  return result;
}

/// 模拟 JS 里的 forEachRight(array, iteratee)
/// 从数组末尾往前迭代
void forEachRight<T>(List<T> array, void Function(T item, int index, List<T> arr) iteratee) {
  for (int i = array.length - 1; i >= 0; i--) {
    iteratee(array[i], i, array);
  }
}