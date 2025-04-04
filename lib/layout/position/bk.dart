import 'dart:math';

import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/utils.dart'; // 假定 util.dart 中包含 range, buildLayerMatrix, applyWithChunking, mapValues 等工具函数

/// 用于存储冲突信息，key 是较小的节点 id，value 是一个 Map，其中 key 为较大节点 id，值为 true
typedef Conflicts = Map<String, Map<String, bool>>;

/// 查找 type-1 冲突（非 inner segment 与 inner segment 相交）
Conflicts findType1Conflicts(Graph g, List<List<String>> layering) {
  final conflicts = <String, Map<String, bool>>{};

  // 内部函数：处理相邻两层
  List<String> visitLayer(List<String> prevLayer, List<String> layer) {
    int k0 = 0;
    int scanPos = 0;
    final prevLayerLength = prevLayer.length;
    final lastNode = layer.isNotEmpty ? layer.last : null;

    for (int i = 0; i < layer.length; i++) {
      final v = layer[i];
      final w = findOtherInnerSegmentNode(g, v);
      // 若 w 存在则取其 order，否则使用上一层的节点数
      final k1 = (w != null && g.node(w) != null && g.node(w)['order'] is int)
          ? g.node(w)['order'] as int
          : prevLayerLength;
      if (w != null || v == lastNode) {
        // 处理从 scanPos 到 i 的节点
        for (var scanNode in layer.sublist(scanPos, i + 1)) {
          for (var u in g.predecessors(scanNode) ?? []) {
            final uLabel = g.node(u);
            final uPos = (uLabel['order'] is int) ? uLabel['order'] as int : 0;
            if ((uPos < k0 || k1 < uPos) &&
                !(uLabel['dummy'] == true &&
                    (g.node(scanNode)?['dummy'] == true))) {
              addConflict(conflicts, u, scanNode);
            }
          }
        }
        scanPos = i + 1;
        k0 = k1;
      }
    }
    return layer;
  }

  if (layering.isNotEmpty) {
    // 模拟 reduce，每次传入前一层和当前层
    for (int i = 1; i < layering.length; i++) {
      visitLayer(layering[i - 1], layering[i]);
    }
  }

  return conflicts;
}

/// 查找 type-2 冲突
Conflicts findType2Conflicts(Graph g, List<List<String>> layering) {
  final conflicts = <String, Map<String, bool>>{};

  void scan(List<String> south, int southPos, int southEnd, int prevNorthBorder,
      int nextNorthBorder) {
    for (int i = southPos; i < southEnd; i++) {
      final v = south[i];
      final vNode = g.node(v);
      if (vNode != null && vNode['dummy'] == true) {
        for (var u in g.predecessors(v) ?? []) {
          final uNode = g.node(u);
          if (uNode != null &&
              uNode['dummy'] == true &&
              (uNode['order'] is int) &&
              ((uNode['order'] as int) < prevNorthBorder ||
                  (uNode['order'] as int) > nextNorthBorder)) {
            addConflict(conflicts, u, v);
          }
        }
      }
    }
  }

  List<String> visitLayer(List<String> north, List<String> south) {
    int prevNorthPos = -1;
    int nextNorthPos = 0;
    int southPos = 0;

    for (int southLookahead = 0;
        southLookahead < south.length;
        southLookahead++) {
      final v = south[southLookahead];
      final vNode = g.node(v);
      if (vNode != null && vNode['dummy'] == 'border') {
        final predecessors = g.predecessors(v) ?? [];
        if (predecessors.isNotEmpty) {
          nextNorthPos = g.node(predecessors.first)['order'] as int? ?? 0;
          scan(south, southPos, southLookahead, prevNorthPos, nextNorthPos);
          southPos = southLookahead;
          prevNorthPos = nextNorthPos;
        }
      }
      scan(south, southPos, south.length, nextNorthPos, north.length);
    }
    return south;
  }

  if (layering.isNotEmpty) {
    // 模拟 reduce，依次处理每两层
    for (int i = 1; i < layering.length; i++) {
      visitLayer(layering[i - 1], layering[i]);
    }
  }

  return conflicts;
}

/// 若节点 v 是 dummy，则返回其前驱中第一个 dummy 节点，否则返回 null
String? findOtherInnerSegmentNode(Graph g, String v) {
  final vNode = g.node(v);
  if (vNode != null && vNode['dummy'] == true) {
    for (var u in (g.predecessors(v) ?? [])) {
      final uNode = g.node(u);
      if (uNode != null && uNode['dummy'] == true) {
        return u;
      }
    }
  }
  return null;
}

/// 添加冲突记录，顺序调整为较小的 id 在前
void addConflict(Conflicts conflicts, String v, String w) {
  if (v.compareTo(w) > 0) {
    final tmp = v;
    v = w;
    w = tmp;
  }
  conflicts.putIfAbsent(v, () => {})[w] = true;
}

/// 判断 v 和 w 之间是否已有冲突记录
bool hasConflict(Conflicts conflicts, String v, String w) {
  if (v.compareTo(w) > 0) {
    final tmp = v;
    v = w;
    w = tmp;
  }
  return conflicts[v] != null && conflicts[v]!.containsKey(w);
}

/// 用于返回 verticalAlignment 的结果
class AlignmentResult {
  final Map<String, String> root;
  final Map<String, String> align;
  AlignmentResult(this.root, this.align);
}

/// 将节点尽可能对齐成垂直块。neighborFn 是一个函数，返回节点 v 的相邻节点（上层或下层）
AlignmentResult verticalAlignment(Graph g, List<List<String>> layering,
    Conflicts conflicts, List<String>? Function(String) neighborFn) {
  final Map<String, String> root = {};
  final Map<String, String> align = {};
  final Map<String, int> pos = {};

  // 记录每个节点在所在层中的顺序
  for (var layer in layering) {
    for (int order = 0; order < layer.length; order++) {
      final v = layer[order];
      root[v] = v;
      align[v] = v;
      pos[v] = order;
    }
  }

  for (var layer in layering) {
    int prevIdx = -1;
    for (var v in layer) {
      var ws = neighborFn(v) ?? [];
      if (ws.isNotEmpty) {
        ws.sort((a, b) => (pos[a] ?? 0) - (pos[b] ?? 0));
        final mp = (ws.length - 1) / 2;
        for (int i = mp.floor(); i <= mp.ceil(); i++) {
          final w = ws[i];
          if (align[v] == v &&
              prevIdx < (pos[w] ?? 0) &&
              !hasConflict(conflicts, v, w)) {
            align[w] = v;
            root[v] = root[w]!;
            align[v] = root[w]!;
            prevIdx = pos[w]!;
          }
        }
      }
    }
  }

  return AlignmentResult(root, align);
}

/// 水平压缩算法：给定对齐结果，计算每个 block 的 x 坐标
Map<String, num> horizontalCompaction(Graph g, List<List<String>> layering,
    Map<String, String> root, Map<String, String> align, bool reverseSep) {
  final Map<String, num> xs = {};
  final blockG = buildBlockGraph(g, layering, root, reverseSep);
  final borderType = reverseSep ? 'borderLeft' : 'borderRight';

  print("=== horizontalCompaction 开始 ===");
  print("blockG nodes: ${blockG.getNodes()}");

  // 初始化 xs 对于 blockG 中的每个节点
  for (final v in blockG.getNodes()) {
    xs[v] = 0;
    print("初始化 xs[$v] = 0");
  }

  // 内部通用迭代器
  void iterate(void Function(String) setXsFunc,
      List<String> Function(String) nextNodesFunc) {
    final List<String> stack = List.from(blockG.getNodes());
    final Set<String> visited = {};
    while (stack.isNotEmpty) {
      final elem = stack.removeLast();
      if (visited.contains(elem)) {
        print("迭代: 已访问 $elem，调用 setXsFunc");
        setXsFunc(elem);
      } else {
        print("迭代: 访问 $elem");
        visited.add(elem);
        stack.add(elem);
        final nextNodes = nextNodesFunc(elem);
        print("迭代: $elem 的后继节点: $nextNodes");
        stack.addAll(nextNodes);
      }
    }
  }

  // 第一遍：确定最小坐标
  void pass1(String elem) {
    final inEdges = blockG.inEdges(elem) ?? [];
    num maxVal = 0;
    print("pass1: 处理节点 $elem, inEdges: $inEdges");
    for (var e in inEdges) {
      // 采用 blockG.edge(e.v, e.w, e.name) 形式取边值
      final sepValue = (blockG.edge(e.v, e.w, e.name) as num?) ?? 0;
      final prevX = xs[e.v] ?? 0;
      final value = prevX + sepValue;
      print(
          "pass1: edge from ${e.v} to $elem, sepValue=$sepValue, prevX=$prevX, value=$value");
      maxVal = max(maxVal, value);
    }
    xs[elem] = maxVal;
    print("pass1: 设定 xs[$elem] = $maxVal");
  }

  // 第二遍：尽量向右移动
  void pass2(String elem) {
    final outEdges = blockG.outEdges(elem) ?? [];
    num minVal = double.infinity;
    print("pass2: 处理节点 $elem, outEdges: $outEdges");
    for (var e in outEdges) {
      final sepValue = (blockG.edge(e.v, e.w, e.name) as num?) ?? 0;
      final nextX = xs[e.w] ?? 0;
      final value = nextX - sepValue;
      print(
          "pass2: edge from $elem to ${e.w}, sepValue=$sepValue, nextX=$nextX, value=$value");
      minVal = min(minVal, value);
    }
    final node = g.node(elem);
    if (minVal != double.infinity && node?['borderType'] != borderType) {
      xs[elem] = max(xs[elem] ?? 0, minVal);
      print("pass2: 设定 xs[$elem] = ${xs[elem]} (minVal=$minVal)");
    } else {
      print(
          "pass2: 对节点 $elem 不做调整 (minVal=$minVal, node['borderType']=${node?['borderType']})");
    }
  }

  // 包装函数，确保类型正确
  List<String> predecessorsWrapper(String v) => blockG.predecessors(v) ?? [];
  List<String> successorsWrapper(String v) => blockG.successors(v) ?? [];

  print("开始第一遍迭代 (pass1)...");
  iterate(pass1, predecessorsWrapper);
  print("第一遍迭代结束，xs: $xs");

  print("开始第二遍迭代 (pass2)...");
  iterate(pass2, successorsWrapper);
  print("第二遍迭代结束，xs: $xs");

  // 将 x 坐标赋值给所有节点：同一 block 中所有节点共享相同的 x 坐标
  for (var v in align.keys) {
    xs[v] = xs[root[v]] ?? 0;
    print("对齐: 将 xs[$v] 设为 xs[${root[v]}] = ${xs[v]}");
  }

  print("=== horizontalCompaction 结束, xs: $xs ===");
  return xs;
}

/// 构造 block 图，用于水平压缩。blockGraph 为简单图，节点为 block，边的权重由 sep 算法计算
Graph buildBlockGraph(Graph g, List<List<String>> layering,
    Map<String, String> root, bool reverseSep) {
  final blockGraph = Graph()
    ..setGraph(g.graph())
    ..isMultigraph = false
    ..isCompound = false;
  final graphLabel = g.graph();
  final sepFn = sep(graphLabel['nodesep'] as num? ?? 0,
      graphLabel['edgesep'] as num? ?? 0, reverseSep);

  for (var layer in layering) {
    String? u;
    for (var v in layer) {
      final vRoot = root[v] ?? v;
      blockGraph.setNode(vRoot, g.node(v));
      if (u != null) {
        final uRoot = root[u] ?? u;
        final prevMax = blockGraph.edge(uRoot, vRoot) as num? ?? 0;
        final sepVal = sepFn(g, v, u);
        blockGraph.setEdge(uRoot, vRoot, max(sepVal, prevMax));
      }
      u = v;
    }
  }

  return blockGraph;
}

/// 返回所有 alignments 中宽度最小的那个 alignment 对应的 x 坐标 Map
Map<String, num> findSmallestWidthAlignment(
    Graph g, Map<String, Map<String, num>> xss) {
  Map<String, num>? bestXs;
  num bestWidth = double.infinity;

  for (var xs in xss.values) {
    num minX = double.infinity;
    num maxX = double.negativeInfinity;
    xs.forEach((v, x) {
      final halfWidth = width(g, v) / 2;
      maxX = max(maxX, x + halfWidth);
      minX = min(minX, x - halfWidth);
    });
    final curWidth = maxX - minX;
    if (curWidth < bestWidth) {
      bestWidth = curWidth;
      bestXs = xs;
    }
  }
  return bestXs ?? {};
}

/// 对齐各个 alignment 的坐标，使其左对齐或右对齐于最小宽度 alignment
void alignCoordinates(
    Map<String, Map<String, num>> xss, Map<String, num> alignTo) {
  final alignToVals = alignTo.values.toList();
  final alignToMin = applyWithChunking(alignToVals, min);
  final alignToMax = applyWithChunking(alignToVals, max);

  for (var vert in ['u', 'd']) {
    for (var horiz in ['l', 'r']) {
      final alignment = vert + horiz;
      final xs = xss[alignment];
      if (xs == null || xs == alignTo) continue;
      final xsVals = xs.values.toList();
      num delta;
      if (horiz == 'l') {
        delta = alignToMin - applyWithChunking(xsVals, min);
      } else {
        delta = alignToMax - applyWithChunking(xsVals, max);
      }
      if (delta != 0) {
        xss[alignment] = mapValues(xs, (x, key) => x + delta);
      }
    }
  }
}

/// 根据对齐结果平衡各个方向的坐标。若 g.graph()['align'] 存在，则返回该方向的对齐值，否则取中位数附近的平均值
Map<String, num> balance(Map<String, Map<String, num>> xss, [String? align]) {
  return mapValues(xss['ul']!, (num numVal, String v) {
    if (align != null) {
      return xss[align.toLowerCase()]![v]!;
    } else {
      final xsList = xss.values.map((xs) => xs[v]!).toList()..sort();
      // 取第二和第三个的平均值（假定 xss 有 4 个方向）
      return (xsList[1] + xsList[2]) / 2;
    }
  });
}

/// 主函数，计算所有节点的 x 坐标
Map<String, num> positionX(Graph g) {
  final layering =
      buildLayerMatrix(g); // 假定 buildLayerMatrix 返回 List<List<String>>
  final conflicts = {
    ...findType1Conflicts(g, layering),
    ...findType2Conflicts(g, layering)
  };

  final Map<String, Map<String, num>> xss = {};
  List<List<String>> adjustedLayering = [];
  for (var vert in ['u', 'd']) {
    // 根据 vertical 参数决定 layer 顺序
    adjustedLayering = (vert == 'u') ? layering : List.from(layering.reversed);
    for (var horiz in ['l', 'r']) {
      List<List<String>> currLayering = [];
      if (horiz == 'r') {
        currLayering = adjustedLayering
            .map((inner) => List<String>.from(inner.reversed))
            .toList();
      } else {
        currLayering = adjustedLayering;
      }
      // 根据上下层决定邻接函数
      final neighborFn = (vert == 'u')
          ? (String v) => g.predecessors(v)
          : (String v) => g.successors(v);
      final alignment =
          verticalAlignment(g, currLayering, conflicts, neighborFn);
      var xs = horizontalCompaction(
          g, currLayering, alignment.root, alignment.align, horiz == 'r');
      if (horiz == 'r') {
        xs = mapValues(xs, (x, key) => -x);
      }
      xss[vert + horiz] = xs;
    }
  }

  final smallestWidth = findSmallestWidthAlignment(g, xss);
  alignCoordinates(xss, smallestWidth);
  return balance(xss, g.graph()['align'] as String?);
}

/// 返回一个分离函数，用于计算两个节点之间的间隔
num Function(Graph, String, String) sep(
    num nodeSep, num edgeSep, bool reverseSep) {
  return (Graph g, String v, String w) {
    final vLabel = g.node(v);
    final wLabel = g.node(w);
    num sum = 0;
    num delta = 0;

    sum += (vLabel['width'] as num) / 2;
    if (vLabel.containsKey('labelpos')) {
      switch ((vLabel['labelpos'] as String).toLowerCase()) {
        case 'l':
          delta = -((vLabel['width'] as num) / 2);
          break;
        case 'r':
          delta = (vLabel['width'] as num) / 2;
          break;
      }
    }
    if (delta != 0) {
      sum += reverseSep ? delta : -delta;
    }
    delta = 0;

    sum += ((vLabel['dummy'] == true ? edgeSep : nodeSep) / 2);
    sum += ((wLabel['dummy'] == true ? edgeSep : nodeSep) / 2);

    sum += (wLabel['width'] as num) / 2;
    if (wLabel.containsKey('labelpos')) {
      switch ((wLabel['labelpos'] as String).toLowerCase()) {
        case 'l':
          delta = (wLabel['width'] as num) / 2;
          break;
        case 'r':
          delta = -((wLabel['width'] as num) / 2);
          break;
      }
    }
    if (delta != 0) {
      sum += reverseSep ? delta : -delta;
    }
    return sum;
  };
}

/// 返回节点的宽度
num width(Graph g, String v) {
  final node = g.node(v);
  return (node != null && node.containsKey('width')) ? node['width'] as num : 0;
}
