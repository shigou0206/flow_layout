enum _ArgSentinel { noVal }

// 生成边ID的工具函数（替代原Edge.id）
String createEdgeId(String v, String w, String? name, bool isDirected) {
  if (isDirected || v.compareTo(w) <= 0) {
    return name != null ? '$v\u0001$w\u0001$name' : '$v\u0001$w\u0001\u0000';
  } else {
    return name != null ? '$w\u0001$v\u0001$name' : '$w\u0001$v\u0001\u0000';
  }
}

// 创建边的Map表示
Map<String, dynamic> createEdgeMap(String v, String w,
    [String? name, bool isDirected = true]) {
  final map = <String, dynamic>{
    'v': v,
    'w': w,
    'isDirected': isDirected,
  };
  if (name != null && name.isNotEmpty) {
    map['name'] = name;
  }
  return map;
}

class Graph {
  bool isDirected;
  bool isMultigraph;
  bool isCompound;

  dynamic label;
  dynamic Function(String)? defaultNodeLabelFn;
  dynamic Function(String, String, String?)? defaultEdgeLabelFn;

  /// 节点相关存储
  final Map<String, dynamic> nodes = {}; // nodeId -> label
  final Map<String, Map<String, Map<String, dynamic>>> _in =
      {}; // nodeId -> (edgeId -> EdgeMap)
  final Map<String, Map<String, int>> _preds =
      {}; // nodeId -> (predId -> count)
  final Map<String, Map<String, Map<String, dynamic>>> _out =
      {}; // nodeId -> (edgeId -> EdgeMap)
  final Map<String, Map<String, int>> _sucs = {}; // nodeId -> (succId -> count)

  /// 边的存储
  final Map<String, Map<String, dynamic>> edgeObjs = {}; // edgeId -> EdgeMap
  final Map<String, dynamic> edgeLabels = {}; // edgeId -> label

  /// compound graph
  final Map<String, String?> _parent = {'\u0000': null};
  final Map<String, Set<String>> _children = {'\u0000': <String>{}};

  int nodeCount = 0;
  int edgeCount = 0;

  Graph({
    this.isDirected = true,
    this.isMultigraph = false,
    this.isCompound = false,
  }) {
    setDefaultNodeLabel(null);
    setDefaultEdgeLabel(null);
  }

  /* ================= Graph label ================= */
  Graph setGraph(dynamic label) {
    this.label = label;
    return this;
  }

  dynamic graph() => label;

  /* ================= Defaults ================= */
  Graph setDefaultNodeLabel(dynamic newDefault) {
    if (newDefault is Function) {
      defaultNodeLabelFn = newDefault as dynamic Function(String);
    } else {
      defaultNodeLabelFn = (_) => newDefault;
    }
    return this;
  }

  Graph setDefaultEdgeLabel(dynamic newDefault) {
    if (newDefault is Function) {
      defaultEdgeLabelFn = (String v, String w, String? name) {
        // 兼容 JS: 可能是 0/1/3 参
        try {
          return Function.apply(newDefault, [v, w, name]);
        } catch (_) {
          try {
            return Function.apply(newDefault, [v]);
          } catch (_) {
            try {
              return Function.apply(newDefault, []);
            } catch (_) {
              return null;
            }
          }
        }
      };
    } else {
      defaultEdgeLabelFn = (_, __, ___) => newDefault;
    }
    return this;
  }

  /* ================= Node manipulation ================= */
  Graph setNode(dynamic nodeId, [dynamic value]) {
    final v = '$nodeId';
    if (nodes.containsKey(v)) {
      if (value != null) {
        nodes[v] = value;
      }
      return this;
    }
    nodes[v] = (value != null) ? value : defaultNodeLabelFn!(v);
    _in[v] = {};
    _preds[v] = {};
    _out[v] = {};
    _sucs[v] = {};
    nodeCount++;

    if (isCompound) {
      _parent[v] = null;
      _children[v] = {};
      _children['\u0000'] ??= {};
      _children['\u0000']!.add(v);
    }
    return this;
  }

  Graph setNodes(List<dynamic> vs, [dynamic value]) {
    for (var nd in vs) {
      setNode(nd, value);
    }
    return this;
  }

  bool hasNode(dynamic nodeId) => nodes.containsKey('$nodeId');

  dynamic node(dynamic nodeId) => nodes['$nodeId'];

  List<String> getNodes() => nodes.keys.toList();

  Graph removeNode(dynamic nodeId) {
    final v = '$nodeId';
    if (!nodes.containsKey(v)) return this;

    final edgesToRemove = <String>[];
    _in[v]!.keys.forEach(edgesToRemove.add);
    _out[v]!.keys.forEach(edgesToRemove.add);

    for (var eId in edgesToRemove) {
      final eObj = edgeObjs[eId]!;
      removeEdge(eObj['v'], eObj['w'], eObj['name']);
    }

    if (isCompound) {
      final kids = children(v) ?? [];
      for (var kid in kids) {
        setParent(kid, null);
      }
      final p = _parent[v];
      if (p != null) {
        _children[p]?.remove(v);
      } else {
        _children['\u0000']?.remove(v);
      }
      _parent.remove(v);
      _children.remove(v);
    }

    nodes.remove(v);
    _in.remove(v);
    _preds.remove(v);
    _out.remove(v);
    _sucs.remove(v);
    nodeCount--;

    return this;
  }

  /* ================= Compound graph ================= */
  Graph setParent(dynamic nd, [dynamic maybeParent]) {
    if (!isCompound) {
      throw Exception('Not a compound graph');
    }
    final v = '$nd';

    // 1. 若没有指定 parent => 移除父节点
    if (maybeParent == null) {
      final oldParent = _parent[v];
      if (oldParent != null) {
        _children[oldParent]?.remove(v);
      } else {
        _children['\u0000']?.remove(v);
      }
      _parent[v] = null;
      _children['\u0000'] ??= {};
      _children['\u0000']!.add(v);
      return this;
    }

    // 2. 转成字符串 (非空)  -  但有可能是 "" => 用 '\u0000'
    final parentStr = maybeParent.toString();
    final newParent = parentStr.isEmpty ? '\u0000' : parentStr;

    // 3. 确保 newParent/v 都已成为节点
    setNode(newParent);
    setNode(v);

    // 4. 做循环检测: 追溯到最顶层看看是否出现 v 本身 => 会形成环
    String? ancestor =
        newParent; // newParent 是 String, 但要配合 parent(...) => String?
    while (ancestor != null) {
      if (ancestor == v) {
        throw Exception(
            "Setting $newParent as parent of $v would create a cycle");
      }
      ancestor = parent(ancestor); // parent(...) 返回 String? => 可能变 null
    }

    // 5. 把 v 从旧父节点移除
    final oldP = _parent[v];
    if (oldP == null) {
      _children['\u0000']?.remove(v);
    } else {
      _children[oldP]?.remove(v);
    }

    // 6. 绑定新父节点
    _parent[v] = newParent;
    _children[newParent] ??= {};
    _children[newParent]!.add(v);

    return this;
  }

  String? parent(dynamic nodeId) {
    if (!isCompound) return null;
    final v = '$nodeId';
    return _parent[v];
  }

  List<String>? children([dynamic nodeId = '\u0000']) {
    if (!isCompound) {
      if (nodeId == '\u0000') {
        return getNodes();
      }
      if (!hasNode(nodeId)) {
        return null;
      }
      return <String>[];
    }
    final v = '$nodeId';
    return _children[v]?.toList();
  }

  /* ================= Edge manipulation ================= */
  String edgeId(String v, String w, [String? name]) {
    if (!isDirected && v.compareTo(w) > 0) {
      final tmp = v;
      v = w;
      w = tmp;
    }
    if (name == 'null') name = null;
    return createEdgeId(v, w, name, isDirected);
  }

  Graph setEdge(
      [dynamic arg0,
      dynamic arg1 = _ArgSentinel.noVal,
      dynamic arg2 = _ArgSentinel.noVal,
      dynamic arg3 = _ArgSentinel.noVal]) {
    String v;
    String w;
    String? name;
    dynamic value = _ArgSentinel.noVal;

    if (arg0 is Map && arg0.containsKey('v') && arg0.containsKey('w')) {
      v = '${arg0['v']}';
      w = '${arg0['w']}';
      name = arg0.containsKey('name') ? '${arg0['name']}' : null;
      if (arg1 != _ArgSentinel.noVal) value = arg1;
    } else {
      v = '$arg0';
      w = (arg1 != _ArgSentinel.noVal) ? '$arg1' : '';
      if (arg2 != _ArgSentinel.noVal) value = arg2;
      if (arg3 != _ArgSentinel.noVal) name = '$arg3';
    }

    if (name == 'null') {
      name = null;
    }
    if (name != null && !isMultigraph) {
      throw Exception('Cannot set a named edge when isMultigraph = false');
    }

    final id = edgeId(v, w, name);

    final bool labelProvided = (value != _ArgSentinel.noVal);

    if (edgeLabels.containsKey(id)) {
      if (labelProvided) {
        edgeLabels[id] = value;
      }
      return this;
    }

    setNode(v);
    setNode(w);

    final newLabel = labelProvided ? value : defaultEdgeLabelFn!(v, w, name);
    edgeLabels[id] = newLabel;

    final edgeMap = createEdgeMap(v, w, name, isDirected);
    edgeObjs[id] = edgeMap;
    _preds[w]![v] = (_preds[w]![v] ?? 0) + 1;
    _sucs[v]![w] = (_sucs[v]![w] ?? 0) + 1;
    _in[w]![id] = edgeMap;
    _out[v]![id] = edgeMap;
    edgeCount++;

    return this;
  }

  Graph setPath(List<dynamic> vs, [dynamic value]) {
    // 确保节点都存在
    for (final node in vs) {
      if (!hasNode(node)) {
        setNode(node, {}); // ← 没有 nodeData 不要紧，这里用空Map初始化即可
      }
    }

    // 设置路径上的边
    for (int i = 0; i < vs.length - 1; i++) {
      setEdge(vs[i], vs[i + 1], value);
    }
    return this;
  }

  bool hasEdge(dynamic src, dynamic dst, [dynamic nm]) {
    var v = '$src';
    var w = '$dst';
    var name = nm != null ? '$nm' : null;
    if (name == 'null') {
      name = null;
    }

    // 🚩 修正逻辑：无向图下必须统一排序 (v < w)
    if (!isDirected && v.compareTo(w) > 0) {
      final tmp = v;
      v = w;
      w = tmp;
    }

    final id = createEdgeId(v, w, name, isDirected);
    return edgeLabels.containsKey(id);
  }

  dynamic edge([dynamic arg0, dynamic arg1, dynamic arg2]) {
    String v;
    String w;
    String? name;

    if (arg0 is Map && arg0.containsKey('v') && arg0.containsKey('w')) {
      v = '${arg0['v']}';
      w = '${arg0['w']}';
      name = arg0.containsKey('name') ? '${arg0['name']}' : null;
    } else {
      v = '$arg0';
      w = arg1 != null ? '$arg1' : '';
      name = arg2 != null ? '$arg2' : null;
    }

    if (name == 'null') {
      name = null;
    }

    // 🚩【统一用当前Graph的isDirected，重建id】
    final id = createEdgeId(v, w, name, isDirected);
    return edgeLabels[id];
  }

  dynamic edgeAsObj([dynamic arg0, dynamic arg1, dynamic arg2]) {
    String v;
    String w;
    String? name;

    if (arg0 is Map && arg0.containsKey('v') && arg0.containsKey('w')) {
      v = '${arg0['v']}';
      w = '${arg0['w']}';
      name = arg0.containsKey('name') ? '${arg0['name']}' : null;
    } else {
      v = '$arg0';
      w = arg1 != null ? '$arg1' : '';
      name = arg2 != null ? '$arg2' : null;
    }

    if (name == 'null') {
      name = null;
    }

    final id = createEdgeId(v, w, name, isDirected); // 统一这里
    final lbl = edgeLabels[id];

    if (lbl == null) {
      return {'label': null};
    }

    return lbl is Map ? lbl : {'label': lbl};
  }

  Graph removeEdge([dynamic arg0, dynamic arg1, dynamic arg2]) {
    // 解析参数
    String v;
    String w;
    String? name;

    if (arg0 is Map && arg0.containsKey('v') && arg0.containsKey('w')) {
      v = '${arg0['v']}';
      w = '${arg0['w']}';
      if (arg0.containsKey('name')) {
        name = '${arg0['name']}';
      }
    } else {
      v = '$arg0';
      w = arg1 != null ? '$arg1' : '';
      if (arg2 != null) {
        name = '$arg2';
      }
    }

    if (name == 'null') {
      name = null;
    }

    final id = edgeId(v, w, name);
    final e = edgeObjs[id];
    if (e == null) return this;

    // 删除主方向的边
    _preds[e['w']]![e['v']] = (_preds[e['w']]![e['v']]! - 1);
    if (_preds[e['w']]![e['v']] == 0) _preds[e['w']]!.remove(e['v']);

    _sucs[e['v']]![e['w']] = (_sucs[e['v']]![e['w']]! - 1);
    if (_sucs[e['v']]![e['w']] == 0) _sucs[e['v']]!.remove(e['w']);

    _in[e['w']]!.remove(id);
    _out[e['v']]!.remove(id);

    edgeObjs.remove(id);
    edgeLabels.remove(id);
    edgeCount--;

    // 🚩 新增：无向图时，同时删除反向边
    if (!isDirected) {
      final reverseId = edgeId(w, v, name);
      final reverseEdge = edgeObjs[reverseId];
      if (reverseEdge != null) {
        _preds[reverseEdge['w']]![reverseEdge['v']] =
            (_preds[reverseEdge['w']]![reverseEdge['v']]! - 1);
        if (_preds[reverseEdge['w']]![reverseEdge['v']] == 0) {
          _preds[reverseEdge['w']]!.remove(reverseEdge['v']);
        }

        _sucs[reverseEdge['v']]![reverseEdge['w']] =
            (_sucs[reverseEdge['v']]![reverseEdge['w']]! - 1);
        if (_sucs[reverseEdge['v']]![reverseEdge['w']] == 0) {
          _sucs[reverseEdge['v']]!.remove(reverseEdge['w']);
        }

        _in[reverseEdge['w']]!.remove(reverseId);
        _out[reverseEdge['v']]!.remove(reverseId);

        edgeObjs.remove(reverseId);
        edgeLabels.remove(reverseId);
        edgeCount--;
      }
    }

    return this;
  }

  List<Map<String, dynamic>> edges() => edgeObjs.values.toList();

  List<Map<String, dynamic>>? inEdges(dynamic nodeId, [dynamic u]) {
    final v = '$nodeId';
    final inMap = _in[v];
    if (inMap == null) return null;

    var all = inMap.values.toList(); // List<EdgeMap>
    if (u == null) return all;
    final uu = '$u';
    return all.where((edge) => edge['v'] == uu).toList();
  }

  List<Map<String, dynamic>>? outEdges(dynamic nodeId, [dynamic w]) {
    final v = '$nodeId';
    final outMap = _out[v];
    if (outMap == null) return null;

    var all = outMap.values.toList(); // List<EdgeMap>
    if (w == null) return all;
    final ww = '$w';
    return all.where((edge) => edge['w'] == ww).toList();
  }

  List<Map<String, dynamic>>? nodeEdges(dynamic nodeId, [dynamic other]) {
    final v = '$nodeId';
    if (!_in.containsKey(v) || !_out.containsKey(v)) return null;

    final results = <Map<String, dynamic>>[];
    results.addAll(inEdges(v) ?? []);
    results.addAll(outEdges(v) ?? []);

    if (other != null) {
      final oo = '$other';
      return results.where((e) => e['v'] == oo || e['w'] == oo).toList();
    }
    return results;
  }

  /* ================= Graph queries ================= */
  List<String>? successors(dynamic nodeId) {
    final v = '$nodeId';
    return _sucs[v]?.keys.toList();
  }

  List<String>? predecessors(dynamic nodeId) {
    final v = '$nodeId';
    return _preds[v]?.keys.toList();
  }

  List<String>? neighbors(dynamic nodeId) {
    final v = '$nodeId';
    final s1 = predecessors(v);
    final s2 = successors(v);
    if (s1 == null || s2 == null) return null;
    final union = <String>{...s1, ...s2};
    return union.toList();
  }

  bool isLeaf(dynamic nodeId) {
    final v = '$nodeId';
    if (isDirected) {
      final succ = successors(v);
      return succ == null || succ.isEmpty;
    } else {
      final neigh = neighbors(v);
      return neigh == null || neigh.isEmpty;
    }
  }

  List<String> sources() => getNodes().where((v) => _in[v]!.isEmpty).toList();

  List<String> sinks() => getNodes().where((v) => _out[v]!.isEmpty).toList();

  Graph filterNodes(bool Function(String) filter) {
    final newGraph = Graph(
      isDirected: isDirected,
      isMultigraph: isMultigraph,
      isCompound: isCompound,
    );
    newGraph.setGraph(graph());

    for (var v in nodes.keys) {
      if (filter(v)) {
        newGraph.setNode(v, nodes[v]);
      }
    }
    for (var e in edgeObjs.values) {
      if (newGraph.hasNode(e['v']) && newGraph.hasNode(e['w'])) {
        newGraph.setEdge(
            e['v'], e['w'], edge(e['v'], e['w'], e['name']), e['name']);
      }
    }

    if (isCompound) {
      for (var v in newGraph.getNodes()) {
        String? p = parent(v);
        while (p != null && !newGraph.hasNode(p)) {
          p = parent(p);
        }
        if (p != null) {
          newGraph.setParent(v, p);
        } else {
          newGraph.setParent(v);
        }
      }
    }
    return newGraph;
  }
}
