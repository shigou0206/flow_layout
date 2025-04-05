enum _ArgSentinel { noVal }

class Edge {
  final String v;
  final String w;
  final String? name;

  const Edge(this.v, this.w, [this.name]);

  // 构建 edgeId
  String get id =>
      name != null ? '$v\u0001$w\u0001$name' : '$v\u0001$w\u0001\u0000';

  // ==== 新增 ====
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'v': v, 'w': w};
    if (name != null && name!.isNotEmpty) {
      map['name'] = name;
    }
    return map;
  }
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
  final Map<String, Map<String, Edge>> _in = {}; // nodeId -> (edgeId -> Edge)
  final Map<String, Map<String, int>> _preds =
      {}; // nodeId -> (predId -> count)
  final Map<String, Map<String, Edge>> _out = {}; // nodeId -> (edgeId -> Edge)
  final Map<String, Map<String, int>> _sucs = {}; // nodeId -> (succId -> count)

  /// 边的存储
  final Map<String, Edge> edgeObjs = {}; // edgeId -> Edge
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
      removeEdge(eObj.v, eObj.w, eObj.name);
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
  Graph setEdge(
      [dynamic arg0,
      dynamic arg1 = _ArgSentinel.noVal,
      dynamic arg2 = _ArgSentinel.noVal,
      dynamic arg3 = _ArgSentinel.noVal]) {
    // 1) parse v, w, name, value
    String v;
    String w;
    String? name;
    dynamic value = _ArgSentinel.noVal;

    if (arg0 is Map && arg0.containsKey('v') && arg0.containsKey('w')) {
      // setEdge({ v:'a', w:'b', name:'foo' }, [value])
      v = '${arg0['v']}';
      w = '${arg0['w']}';
      name = arg0.containsKey('name') ? '${arg0['name']}' : null;
      if (arg1 != _ArgSentinel.noVal) {
        value = arg1;
      }
    } else {
      // setEdge(v, w, [value], [name])
      v = '$arg0';
      w = (arg1 != _ArgSentinel.noVal) ? '$arg1' : '';
      if (arg2 != _ArgSentinel.noVal) value = arg2;
      if (arg3 != _ArgSentinel.noVal) name = '$arg3';
    }

    // 若 name == 'null' => 强制为 null
    if (name == 'null') {
      name = null;
    }

    // 如果是无向图，且 v > w => reorder
    if (!isDirected && v.compareTo(w) > 0) {
      final tmp = v;
      v = w;
      w = tmp;
    }

    // 如果 name != null 但不是多重图 => 抛异常
    if (name != null && !isMultigraph) {
      throw Exception('Cannot set a named edge when isMultigraph = false');
    }

    // 构建 Edge / edgeId
    final e = Edge(v, w, name);
    final id = e.id;

    // 是否显式提供 label
    final bool labelProvided = (value != _ArgSentinel.noVal);

    // =============== 检查是否已有这条边 ===============
    if (edgeLabels.containsKey(id)) {
      if (labelProvided) {
        edgeLabels[id] = value; // 覆盖标签
      }
      return this;
    }

    // =============== 边不存在 => 创建新边 ===============
    // 确保节点
    setNode(v);
    setNode(w);

    // 若显式提供 label => 用 value；否则 => defaultEdgeLabelFn
    final newLabel = labelProvided ? value : defaultEdgeLabelFn!(v, w, name);
    edgeLabels[id] = newLabel;

    edgeObjs[id] = e;
    _preds[w]![v] = (_preds[w]![v] ?? 0) + 1;
    _sucs[v]![w] = (_sucs[v]![w] ?? 0) + 1;
    _in[w]![id] = e;
    _out[v]![id] = e;
    edgeCount++;

    return this;
  }

  Graph setPath(List<dynamic> vs, [dynamic value]) {
    for (int i = 0; i < vs.length - 1; i++) {
      setEdge(vs[i], vs[i + 1], value);
    }
    return this;
  }

  bool hasEdge(dynamic src, dynamic dst, [dynamic nm]) {
    var v = '$src';
    var w = '$dst';
    var name = nm != null ? '$nm' : null;
    if (!isDirected && v.compareTo(w) > 0) {
      final tmp = v;
      v = w;
      w = tmp;
    }
    if (name == 'null') {
      name = null;
    }

    final id = Edge(v, w, name).id;
    return edgeLabels.containsKey(id);
  }

  dynamic edge([dynamic arg0, dynamic arg1, dynamic arg2]) {

    if (arg0 is Edge) {
    // 直接从对象里取 v, w, name
    final eObj = arg0;
    final id = eObj.id;  // Edge 里已有 id getter
    return edgeLabels[id];
  }
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
      if (arg2 != null) name = '$arg2';
    }

    if (!isDirected && v.compareTo(w) > 0) {
      final tmp = v;
      v = w;
      w = tmp;
    }
    if (name == 'null') {
      name = null;
    }

    final id = Edge(v, w, name).id;
    return edgeLabels[id];
  }

  dynamic edgeAsObj([dynamic arg0, dynamic arg1, dynamic arg2]) {
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

    if (!isDirected && v.compareTo(w) > 0) {
      final tmp = v;
      v = w;
      w = tmp;
    }
    if (name == 'null') {
      name = null;
    }

    final id = Edge(v, w, name).id;
    final lbl = edgeLabels[id];
    if (lbl == null) {
      return {'label': null};
    }
    if (lbl is Map) {
      return lbl;
    }
    return {'label': lbl};
  }

  Graph removeEdge([dynamic arg0, dynamic arg1, dynamic arg2]) {
    // 解析
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

    if (!isDirected && v.compareTo(w) > 0) {
      final tmp = v;
      v = w;
      w = tmp;
    }
    if (name == 'null') {
      name = null;
    }

    final id = Edge(v, w, name).id;
    final e = edgeObjs[id];
    if (e == null) return this;

    final c1 = _preds[e.w]![e.v]! - 1;
    if (c1 == 0) {
      _preds[e.w]!.remove(e.v);
    } else {
      _preds[e.w]![e.v] = c1;
    }

    final c2 = _sucs[e.v]![e.w]! - 1;
    if (c2 == 0) {
      _sucs[e.v]!.remove(e.w);
    } else {
      _sucs[e.v]![e.w] = c2;
    }

    _in[e.w]!.remove(id);
    _out[e.v]!.remove(id);

    edgeObjs.remove(id);
    edgeLabels.remove(id);
    edgeCount--;

    return this;
  }

  List<Edge> edges() => edgeObjs.values.toList();

  List<Edge>? inEdges(dynamic nodeId, [dynamic u]) {
    final v = '$nodeId';
    final inMap = _in[v];
    if (inMap == null) return null;

    var all = inMap.values.toList(); // List<Edge>
    if (u == null) return all;
    final uu = '$u';
    return all.where((edge) => edge.v == uu).toList();
  }

  List<Edge>? outEdges(dynamic nodeId, [dynamic w]) {
    final v = '$nodeId';
    final outMap = _out[v];
    if (outMap == null) return null;

    var all = outMap.values.toList(); // List<Edge>
    if (w == null) return all;
    final ww = '$w';
    return all.where((edge) => edge.w == ww).toList();
  }

  List<Edge>? nodeEdges(dynamic nodeId, [dynamic other]) {
    final v = '$nodeId';
    if (!_in.containsKey(v) || !_out.containsKey(v)) return null;

    final results = <Edge>[];
    results.addAll(inEdges(v) ?? []);
    results.addAll(outEdges(v) ?? []);

    if (other != null) {
      final oo = '$other';
      return results.where((e) => e.v == oo || e.w == oo).toList();
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
      if (newGraph.hasNode(e.v) && newGraph.hasNode(e.w)) {
        newGraph.setEdge(e.v, e.w, edge(e.v, e.w, e.name), e.name);
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
