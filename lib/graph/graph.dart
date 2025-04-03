enum _ArgSentinel { noVal }

class Edge {
  final String v;
  final String w;
  final String? name;

  const Edge(this.v, this.w, [this.name]);

  String get id =>
      name != null ? '$v\u0001$w\u0001$name' : '$v\u0001$w\u0001\u0000';
}

class Graph {
  bool isDirected;
  bool isMultigraph;
  bool isCompound;

  dynamic label;
  dynamic Function(String)? defaultNodeLabelFn;
  dynamic Function(String, String, String?)? defaultEdgeLabelFn;

  final Map<String, dynamic> nodes = {};
  final Map<String, Map<String, Edge>> _in = {};
  final Map<String, Map<String, int>> _preds = {};
  final Map<String, Map<String, Edge>> _out = {};
  final Map<String, Map<String, int>> _sucs = {};

  final Map<String, Edge> edgeObjs = {};
  final Map<String, dynamic> edgeLabels = {};

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

  /* ----------- Graph label ----------- */
  Graph setGraph(dynamic label) {
    this.label = label;
    return this;
  }

  dynamic graph() => label;

  /* ----------- Defaults ----------- */
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
      // 生成一个包装函数
      defaultEdgeLabelFn = (String v, String w, String? name) {
        // 我们一次尝试 3参数, 如果调用失败, 再试 1参数, 再试 0参数
        // 这样可兼容 JS 测试中的各种函数声明
        try {
          // 先尝试: newDefault(v, w, name)
          return Function.apply(newDefault, [v, w, name]);
        } catch (e1) {
          try {
            // 再尝试: newDefault(v)
            return Function.apply(newDefault, [v]);
          } catch (e2) {
            try {
              // 最后尝试: newDefault()
              return Function.apply(newDefault, []);
            } catch (e3) {
              // 实在不行 => 返回 null
              return null;
            }
          }
        }
      };
    } else {
      // 如果 newDefault 不是函数，就直接用常量
      defaultEdgeLabelFn = (_, __, ___) => newDefault;
    }
    return this;
  }

  /* ----------- Node manipulation ----------- */
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

  /* ----------- Compound Graph ----------- */
  Graph setParent(dynamic nd, [dynamic parent]) {
    if (!isCompound) {
      throw Exception('Not a compound graph');
    }
    final v = '$nd';

    if (parent == null) {
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

    final newParent = parent.toString().isEmpty ? '\u0000' : '$parent';
    while (true) {
      if (newParent == v) {
        throw Exception('Cycle detected...');
      }
      final p = this.parent(newParent);
      if (p == null) break;
      if (p == v) {
        throw Exception('Cycle detected...');
      }
      if (p.isEmpty) break;
      final gp = this.parent(p);
      if (gp == null) break;
      if (gp == v) {
        throw Exception('Cycle detected...');
      }
    }

    setNode(newParent);
    setNode(v);

    final oldP = _parent[v];
    if (oldP == null) {
      _children['\u0000']?.remove(v);
    } else {
      _children[oldP]?.remove(v);
    }
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

  /* ----------- Edge manipulation ----------- */

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
      if (arg1 != _ArgSentinel.noVal) {
        value = arg1;
      }
    } else {
      v = '$arg0';
      w = (arg1 != _ArgSentinel.noVal) ? '$arg1' : '';
      if (arg2 != _ArgSentinel.noVal) value = arg2;
      if (arg3 != _ArgSentinel.noVal) name = '$arg3';
    }
    // 若 name=='null' 就当没 name
    if (name == 'null') {
      name = null;
    }

    // 在无向图中, 若 v>w => 交换
    if (!isDirected && v.compareTo(w) > 0) {
      final tmp = v;
      v = w;
      w = tmp;
    }

    final e = Edge(v, w, name);
    final id = e.id;

    final bool labelProvided = (value != _ArgSentinel.noVal);

    if (edgeLabels.containsKey(id)) {
      // 已有 -> 只在显式提供 label 时覆盖
      if (labelProvided) {
        edgeLabels[id] = value;
      }
      return this;
    }

    if (name != null && !isMultigraph) {
      throw Exception('Cannot set a named edge when isMultigraph = false');
    }

    setNode(v);
    setNode(w);

    if (labelProvided) {
      edgeLabels[id] = value;
    } else {
      edgeLabels[id] = defaultEdgeLabelFn!(v, w, name);
    }

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

    // 无向图需要 reorder
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
    // arg0 可能是 { v:'a', w:'b', name:'...' } 或 src
    // arg1 可能是 dst or label
    // arg2 可能是 name
    String v;
    String w;
    String? name;

    if (arg0 is Map && arg0.containsKey('v') && arg0.containsKey('w')) {
      // edge({v:'a', w:'b', name:'nm'})
      v = '${arg0['v']}';
      w = '${arg0['w']}';
      if (arg0.containsKey('name')) {
        name = '${arg0['name']}';
      }
    } else {
      // edge(src, dst, name)
      v = '$arg0'; // arg0 must not be null here
      w = '$arg1'; // arg1
      if (arg2 != null) {
        // or skip if you want name is optional
        name = '$arg2';
      }
    }

    // 在无向图里也要进行 reorder
    if (!isDirected && v.compareTo(w) > 0) {
      final tmp = v;
      v = w;
      w = tmp;
    }
    // if name == 'null' => name = null
    if (name == 'null') {
      name = null;
    }

    // 现在拿到 id
    final id = Edge(v, w, name).id;
    return edgeLabels[id]; // or 你原先的逻辑
  }

  dynamic edgeAsObj([dynamic arg0, dynamic arg1, dynamic arg2]) {
    String v;
    String w;
    String? name;

    // 检测是否是对象模式
    if (arg0 is Map && arg0.containsKey('v') && arg0.containsKey('w')) {
      v = '${arg0['v']}';
      w = '${arg0['w']}';
      if (arg0.containsKey('name')) {
        name = '${arg0['name']}';
      }
    } else {
      // 正常 (src,dst,name)
      v = '$arg0';
      w = arg1 != null ? '$arg1' : '';
      if (arg2 != null) {
        name = '$arg2';
      }
    }

    // 若是无向图，v>w 时交换
    if (!isDirected && v.compareTo(w) > 0) {
      final tmp = v;
      v = w;
      w = tmp;
    }

    // 若 name=='null' -> name=null
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
    // 判断第一个参数是否是 Map {v,w,name}
    String v;
    String w;
    String? name;

    if (arg0 is Map && arg0.containsKey('v') && arg0.containsKey('w')) {
      // removeEdge({v:'a',w:'b',name:'foo'})
      v = '${arg0['v']}';
      w = '${arg0['w']}';
      if (arg0.containsKey('name')) {
        name = '${arg0['name']}';
      }
    } else {
      // removeEdge(src, dst, [name])
      v = '$arg0';
      w = arg1 != null ? '$arg1' : '';
      if (arg2 != null) {
        name = '$arg2';
      }
    }

    // 若无向图 => reorder
    if (!isDirected && v.compareTo(w) > 0) {
      final tmp = v;
      v = w;
      w = tmp;
    }
    // 若 name=='null' => name=null
    if (name == 'null') {
      name = null;
    }

    final id = Edge(v, w, name).id;
    final e = edgeObjs[id];
    if (e == null) return this;

    // 其余保持原逻辑
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
    final all = inMap.values.toList();
    if (u == null) return all;
    final uu = '$u';
    return all.where((edge) => edge.v == uu).toList();
  }

  List<Edge>? outEdges(dynamic nodeId, [dynamic w]) {
    final v = '$nodeId';
    final outMap = _out[v];
    if (outMap == null) return null;
    final all = outMap.values.toList();
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

  /* ------------------ Graph queries ------------------ */
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
