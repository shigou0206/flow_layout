import 'dart:math';
import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/utils.dart';

typedef Conflicts = Map<String, Map<String, bool>>;

/* ===========================================================
 * 1) findType1Conflicts
 * ===========================================================
 */
Conflicts findType1Conflicts(Graph g, List<List<String>> layering) {
  final conflicts = <String, Map<String, bool>>{};

  List<String> visitLayer(List<String> prevLayer, List<String> layer) {
    int k0 = 0;
    int scanPos = 0;
    final prevLayerLength = prevLayer.length;
    final lastNode = layer.isNotEmpty ? layer.last : null;

    for (int i = 0; i < layer.length; i++) {
      final v = layer[i];
      final w = _findOtherInnerSegmentNode(g, v);
      final k1 = (w != null && g.node(w)?['order'] is int)
          ? g.node(w)!['order'] as int
          : prevLayerLength;

      if (w != null || v == lastNode) {
        for (var scanNode in layer.sublist(scanPos, i + 1)) {
          for (var u in g.predecessors(scanNode) ?? []) {
            final uNode = g.node(u);
            final uPos = (uNode?['order'] is int) ? uNode!['order'] as int : 0;
            if ((uPos < k0 || k1 < uPos) &&
                !((uNode?['dummy'] == true) &&
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
    for (int i = 1; i < layering.length; i++) {
      visitLayer(layering[i - 1], layering[i]);
    }
  }
  return conflicts;
}

String? _findOtherInnerSegmentNode(Graph g, String v) {
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

void addConflict(Conflicts conflicts, String v, String w) {
  if (v.compareTo(w) > 0) {
    final tmp = v;
    v = w;
    w = tmp;
  }
  conflicts.putIfAbsent(v, () => {})[w] = true;
}

bool hasConflict(Conflicts conflicts, String v, String w) {
  if (v.compareTo(w) > 0) {
    final tmp = v;
    v = w;
    w = tmp;
  }
  return conflicts[v] != null && conflicts[v]!.containsKey(w);
}

/* ===========================================================
 * 2) findType2Conflicts
 * ===========================================================
 */
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
          nextNorthPos = (g.node(predecessors.first)?['order'] as int?) ?? 0;
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
    for (int i = 1; i < layering.length; i++) {
      visitLayer(layering[i - 1], layering[i]);
    }
  }
  return conflicts;
}

/* ===========================================================
 * 3) verticalAlignment
 * ===========================================================
 */
class AlignmentResult {
  final Map<String, String> root;
  final Map<String, String> align;
  AlignmentResult(this.root, this.align);
}

AlignmentResult verticalAlignment(Graph g, List<List<String>> layering,
    Conflicts conflicts, List<String> Function(String)? neighborFn) {
  final Map<String, String> root = {};
  final Map<String, String> align = {};
  final Map<String, int> pos = {};

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
      final ws = (neighborFn != null) ? neighborFn(v) : <String>[];
      if (ws.isNotEmpty) {
        ws.sort((a, b) => (pos[a] ?? 0).compareTo(pos[b] ?? 0));
        final mp = (ws.length - 1) / 2;
        for (int i = mp.floor(); i <= mp.ceil(); i++) {
          final w = ws[i];
          if (align[v] == v &&
              prevIdx < (pos[w] ?? 0) &&
              !hasConflict(conflicts, v, w)) {
            align[w] = v;
            root[v] = root[w]!;
            align[v] = root[w]!;
            prevIdx = (pos[w] ?? 0);
          }
        }
      }
    }
  }

  return AlignmentResult(root, align);
}

/* ===========================================================
 * 4) horizontalCompaction
 * ===========================================================
 */
Map<String, num> horizontalCompaction(Graph g, List<List<String>> layering,
    Map<String, String> root, Map<String, String> align, bool reverseSep) {
  print("=== horizontalCompaction ===");
  print("reverseSep = $reverseSep");
  final Map<String, num> xs = {};
  final blockG = _buildBlockGraph(g, layering, root, reverseSep);
  final borderType = reverseSep ? 'borderLeft' : 'borderRight';

  // 初始化 0
  for (var v in blockG.getNodes()) {
    xs[v] = 0;
  }

  void iterate(void Function(String) setXsFunc,
      List<String> Function(String) nextNodesFunc) {
    final stack = List.of(blockG.getNodes());
    final visited = <String>{};
    while (stack.isNotEmpty) {
      final elem = stack.removeLast();
      if (visited.contains(elem)) {
        setXsFunc(elem);
      } else {
        visited.add(elem);
        stack.add(elem);
        stack.addAll(nextNodesFunc(elem));
      }
    }
  }

  void pass1(String elem) {
    final inEdges = blockG.inEdges(elem) ?? [];
    num maxVal = 0;
    for (var e in inEdges) {
      final w = blockG.edge(e);
      final sepVal = (w is num) ? w : 0;
      final prevX = xs[e.v] ?? 0;
      final val = prevX + sepVal;
      maxVal = max(maxVal, val);
      print("pass1: e=${e.v}->${e.w}, sepVal=$sepVal, prevX=$prevX => $val");
    }
    xs[elem] = maxVal;
    print("pass1: set xs[$elem] = $maxVal");
  }

  void pass2(String elem) {
    final outEdges = blockG.outEdges(elem) ?? [];
    num minVal = double.infinity;
    for (var e in outEdges) {
      final w = blockG.edge(e);
      final sepVal = (w is num) ? w : 0;
      final nextX = xs[e.w] ?? 0;
      final val = nextX - sepVal;
      print("pass2: e=${e.v}->${e.w}, sepVal=$sepVal, nextX=$nextX => $val");
      minVal = min(minVal, val);
    }
    final nodeData = g.node(elem) ?? {};
    if (minVal != double.infinity && nodeData['borderType'] != borderType) {
      final oldVal = xs[elem] ?? 0;
      xs[elem] = max(oldVal, minVal);
      print("pass2: set xs[$elem] = ${xs[elem]} (was=$oldVal, minVal=$minVal)");
    } else {
      print(
          "pass2: no update for $elem (minVal=$minVal, borderType=${nodeData['borderType']})");
    }
  }

  iterate(pass1, (v) => blockG.predecessors(v) ?? []);
  print("after pass1, xs=$xs");

  iterate(pass2, (v) => blockG.successors(v) ?? []);
  print("after pass2, xs=$xs");

  // assign back
  for (var v in align.keys) {
    final r = root[v];
    final assigned = xs[r] ?? 0;
    xs[v] = assigned;
    print("align: xs[$v] = xs[$r] = $assigned");
  }

  print("=== end horizontalCompaction => xs=$xs ===");
  return xs;
}

/* ===========================================================
 * 5) _buildBlockGraph
 * ===========================================================
 */
Graph _buildBlockGraph(Graph g, List<List<String>> layering,
    Map<String, String> root, bool reverseSep) {
  print("_buildBlockGraph: reverseSep=$reverseSep");

  final blockGraph = Graph()
    ..setGraph(g.graph())
    ..isMultigraph = false
    ..isCompound = false;

  print("blockGraph.isDirected = ${blockGraph.isDirected}");

  final graphLabel = g.graph();
  final nodesep = (graphLabel['nodesep'] as num?) ?? 0;
  final edgesep = (graphLabel['edgesep'] as num?) ?? 0;
  final sepFn = _sep(nodesep, edgesep, reverseSep);

  print("_buildBlockGraph: nodeSep=$nodesep, edgeSep=$edgesep");

  for (int layerIdx = 0; layerIdx < layering.length; layerIdx++) {
    final layer = layering[layerIdx];
    print("layer[$layerIdx]: $layer");
    String? u;
    for (final v in layer) {
      final vRoot = root[v] ?? v;
      if (!blockGraph.hasNode(vRoot)) {
        blockGraph.setNode(vRoot);
        print("setNode($vRoot)");
      }

      if (u != null) {
        final uRoot = root[u] ?? u;
        if (!blockGraph.hasNode(uRoot)) {
          blockGraph.setNode(uRoot);
          print("setNode($uRoot)");
        }
        final prevVal = blockGraph.edge(uRoot, vRoot) as num? ?? 0;
        final sepVal = sepFn(g, v, u);
        final newVal = max(prevVal, sepVal);
        print(
            "u=$u, v=$v => setEdge($uRoot->$vRoot, max($prevVal, $sepVal)=$newVal)");
        blockGraph.setEdge(uRoot, vRoot, newVal);
      }
      u = v;
    }
  }

  return blockGraph;
}

/* ===========================================================
 * 6) _sep
 * ===========================================================
 */
num Function(Graph, String, String) _sep(
    num nodeSep, num edgeSep, bool reverseSep) {
  return (Graph g, String v, String w) {
    final vData = g.node(v) ?? {};
    final wData = g.node(w) ?? {};

    final vWidth = (vData['width'] is num) ? vData['width'] as num : 0;
    final wWidth = (wData['width'] is num) ? wData['width'] as num : 0;

    print(
        "_sep: v=$v (width=$vWidth,dummy=${vData['dummy']},labelpos=${vData['labelpos']}),"
        " w=$w (width=$wWidth,dummy=${wData['dummy']},labelpos=${wData['labelpos']}),"
        " nodeSep=$nodeSep, edgeSep=$edgeSep, reverse=$reverseSep");

    num sum = 0;
    num delta = 0;

    // v half width
    sum += vWidth / 2;

    if (vData['labelpos'] is String) {
      final labelPos = (vData['labelpos'] as String).toLowerCase();
      switch (labelPos) {
        case 'l':
          delta = -vWidth / 2;
          break;
        case 'r':
          delta = vWidth / 2;
          break;
      }
      if (delta != 0) {
        sum += reverseSep ? delta : -delta;
      }
      delta = 0;
    }

    final isVDummy = (vData['dummy'] == true ||
        vData['dummy'] == 'edge' ||
        vData['dummy'] == 'edge-label');
    sum += ((isVDummy ? edgeSep : nodeSep) / 2);

    final isWDummy = (wData['dummy'] == true ||
        wData['dummy'] == 'edge' ||
        wData['dummy'] == 'edge-label');
    sum += ((isWDummy ? edgeSep : nodeSep) / 2);

    sum += wWidth / 2;

    if (wData['labelpos'] is String) {
      final labelPos = (wData['labelpos'] as String).toLowerCase();
      switch (labelPos) {
        case 'l':
          delta = wWidth / 2;
          break;
        case 'r':
          delta = -wWidth / 2;
          break;
      }
      if (delta != 0) {
        sum += reverseSep ? delta : -delta;
      }
    }

    print("_sep => result=$sum");
    return sum;
  };
}

/* ===========================================================
 * 7) findSmallestWidthAlignment
 * ===========================================================
 */
Map<String, num> findSmallestWidthAlignment(
    Graph g, Map<String, Map<String, num>> xss) {
  Map<String, num>? bestXs;
  num bestWidth = double.infinity;

  for (var xs in xss.values) {
    num minX = double.infinity;
    num maxX = double.negativeInfinity;
    xs.forEach((v, x) {
      final halfW = _width(g, v) / 2;
      maxX = max(maxX, x + halfW);
      minX = min(minX, x - halfW);
    });
    final curWidth = maxX - minX;
    if (curWidth < bestWidth) {
      bestWidth = curWidth;
      bestXs = xs;
    }
  }
  return bestXs ?? {};
}

/* ===========================================================
 * 8) alignCoordinates
 * ===========================================================
 */
void alignCoordinates(
    Map<String, Map<String, num>> xss, Map<String, num> alignTo) {
  final atVals = alignTo.values.toList();
  if (atVals.isEmpty) return;

  final alignToMin = applyWithChunking(atVals, min);
  final alignToMax = applyWithChunking(atVals, max);

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
        xss[alignment] = mapValues(xs, (val, key) => val + delta);
      }
    }
  }
}

/* ===========================================================
 * 9) balance
 * ===========================================================
 */
Map<String, num> balance(Map<String, Map<String, num>> xss, [String? align]) {
  final ul = xss['ul']!;
  if (align != null) {
    final a = align.toLowerCase();
    return mapValues(ul, (val, v) {
      return xss[a]![v]!;
    });
  } else {
    return mapValues(ul, (val, v) {
      final coords = xss.values.map((xs) => xs[v]!).toList()..sort();
      return (coords[1] + coords[2]) / 2;
    });
  }
}

/* ===========================================================
 * 10) positionX
 * ===========================================================
 */
Map<String, num> positionX(Graph g) {
  print("=== positionX START ===");
  final layering = buildLayerMatrix(g);
  print("layering=$layering");

  final c1 = findType1Conflicts(g, layering);
  final c2 = findType2Conflicts(g, layering);
  final conflicts = {...c1, ...c2};
  print("type1Conflicts=$c1, type2Conflicts=$c2");

  final Map<String, Map<String, num>> xss = {};

  for (var vert in ['u', 'd']) {
    final usedLayering = (vert == 'u') ? layering : layering.reversed.toList();
    for (var horiz in ['l', 'r']) {
      List<List<String>> currLayering;
      if (horiz == 'r') {
        currLayering =
            usedLayering.map((lyr) => lyr.reversed.toList()).toList();
      } else {
        currLayering = usedLayering;
      }

      final neighborFn = (vert == 'u')
          ? (String v) => g.predecessors(v) ?? []
          : (String v) => g.successors(v) ?? [];

      print("call verticalAlignment with vert=$vert horiz=$horiz");
      final alignment =
          verticalAlignment(g, currLayering, conflicts, neighborFn);

      print("call horizontalCompaction with vert=$vert horiz=$horiz");
      var xs = horizontalCompaction(
          g, currLayering, alignment.root, alignment.align, (horiz == 'r'));
      if (horiz == 'r') {
        xs = mapValues(xs, (val, key) => -val);
      }
      xss[vert + horiz] = xs;
    }
  }

  final best = findSmallestWidthAlignment(g, xss);
  alignCoordinates(xss, best);
  final balanced = balance(xss, g.graph()['align'] as String?);
  print("=== positionX END => $balanced ===");
  return balanced;
}

/* ===========================================================
 * 11) _width
 * ===========================================================
 */
num _width(Graph g, String v) {
  final node = g.node(v);
  if (node != null && node['width'] is num) {
    return node['width'] as num;
  }
  return 0;
}
