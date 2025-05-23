import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/graph/alg/acyclic.dart' as acyclic;
import 'package:flow_layout/graph/alg/normalize.dart' as normalize;
import 'package:flow_layout/layout/rank/rank.dart' as rank;
import 'package:flow_layout/layout/utils.dart' as util;
import 'package:flow_layout/graph/alg/parent_dummy_chains.dart'
    as parentDummyChains;
import 'package:flow_layout/graph/alg/nesting_graph.dart' as nestingGraph;
import 'package:flow_layout/graph/alg/add_border_segments.dart'
    as addBorderSegments;
import 'package:flow_layout/graph/alg/coordinate_system.dart';
import 'package:flow_layout/layout/order/layout_order.dart' as order;
import 'package:flow_layout/layout/position/layout_position.dart' as position;
import 'dart:math' as math;

/// 执行布局算法的主函数
void layout(Graph inputGraph, [Map<String, dynamic>? options]) {
  options ??= {};

  // 默认情况下，时间计算使用notime，不计算时间
  final timeFn = options['debugTiming'] == true ? util.time : util.notime;

  timeFn('layout', () {
    final layoutGraph =
        timeFn('  buildLayoutGraph', () => buildLayoutGraph(inputGraph));

    try {
      timeFn('  runLayout', () => runLayout(layoutGraph, options));
      timeFn('  updateInputGraph',
          () => updateInputGraph(inputGraph, layoutGraph));
    } catch (e, stackTrace) {
      print('布局过程出错: $e');
      print(stackTrace);

      // 即使出错，也尝试保留基本的布局信息
      ensureBasicLayout(inputGraph);
    }
  });
}

/// 确保每个节点至少有基本的布局信息
void ensureBasicLayout(Graph g) {
  const gridSize = 100; // 简单网格布局的大小
  double x = 0;
  double y = 0;

  for (final v in g.getNodes()) {
    final node = g.node(v);
    if (node != null) {
      try {
        // 确保节点有宽度和高度
        if (!node.containsKey('width')) {
          node['width'] = 30.0;
        } else if (node['width'] is num) {
          node['width'] = (node['width'] as num).toDouble();
        }

        if (!node.containsKey('height')) {
          node['height'] = 30.0;
        } else if (node['height'] is num) {
          node['height'] = (node['height'] as num).toDouble();
        }

        // 确保节点有坐标
        if (!node.containsKey('x')) {
          node['x'] = x;
          x += gridSize;
        } else if (node['x'] is num) {
          node['x'] = (node['x'] as num).toDouble();
        }

        if (!node.containsKey('y')) {
          node['y'] = y;

          // 换行
          if (x > 500) {
            x = 0;
            y += gridSize;
          }
        } else if (node['y'] is num) {
          node['y'] = (node['y'] as num).toDouble();
        }

        // 确保rank是整数形式
        if (node.containsKey('rank')) {
          if (node['rank'] is num) {
            node['rank'] = (node['rank'] as num).round();
          } else {
            // 如果rank不是数字，移除它以避免类型错误
            node.remove('rank');
          }
        }

        // 确保points数组是正确的格式
        if (node.containsKey('points')) {
          if (node['points'] is! List) {
            node['points'] = <Map<String, double>>[];
          }
        }
      } catch (e) {
        print('确保节点 $v 基本布局时出错: $e');
        // 设置安全的默认值
        node['width'] = 30;
        node['height'] = 30;
        node['x'] = x;
        node['y'] = y;
        x += gridSize;
      }
    }
  }

  // 确保边也有基本的points数据
  for (final e in g.edges()) {
    final edge = g.edge(e);
    if (edge != null) {
      try {
        // 确保边的points属性存在且是列表
        if (!edge.containsKey('points')) {
          edge['points'] = <Map<String, double>>[];
        } else if (edge['points'] is! List) {
          edge['points'] = <Map<String, double>>[];
        }

        // 安全地获取源节点和目标节点
        String? sourceId = e['v'] is String ? e['v'] as String : null;
        String? targetId = e['w'] is String ? e['w'] as String : null;

        if (sourceId != null && targetId != null) {
          final sourceNode = g.node(sourceId);
          final targetNode = g.node(targetId);

          if (sourceNode != null && targetNode != null) {
            // 如果points列表为空，添加简单的源节点到目标节点的直线
            final points = edge['points'] as List;
            if (points.isEmpty) {
              final sourceX = (sourceNode['x'] is num)
                  ? (sourceNode['x'] as num).toDouble()
                  : 0.0;
              final sourceY = (sourceNode['y'] is num)
                  ? (sourceNode['y'] as num).toDouble()
                  : 0.0;
              final targetX = (targetNode['x'] is num)
                  ? (targetNode['x'] as num).toDouble()
                  : 0.0;
              final targetY = (targetNode['y'] is num)
                  ? (targetNode['y'] as num).toDouble()
                  : 0.0;

              points.add({'x': sourceX, 'y': sourceY});
              points.add({'x': targetX, 'y': targetY});
            }
          }
        }
      } catch (e) {
        print('确保边基本布局时出错: $e');
        // 设置一个空的points列表作为安全默认值
        edge['points'] = <Map<String, double>>[];
      }
    }
  }
}

/// 从布局图复制最终布局信息回输入图
void updateInputGraph(Graph inputGraph, Graph layoutGraph) {
  for (final v in inputGraph.getNodes()) {
    final inputLabel = inputGraph.node(v);
    final layoutLabel = layoutGraph.node(v);

    if (layoutLabel is Map<String, dynamic>) {
      final newInputLabel = (inputLabel is Map<String, dynamic>)
          ? Map<String, dynamic>.from(inputLabel)
          : <String, dynamic>{};

      newInputLabel['x'] = (layoutLabel['x'] as num?)?.toDouble() ?? 0.0;
      newInputLabel['y'] = (layoutLabel['y'] as num?)?.toDouble() ?? 0.0;

      if (layoutLabel['rank'] is num) {
        newInputLabel['rank'] = (layoutLabel['rank'] as num).round();
      }

      if ((layoutGraph.children(v) ?? []).isNotEmpty) {
        newInputLabel['width'] =
            (layoutLabel['width'] as num?)?.toDouble() ?? 0.0;
        newInputLabel['height'] =
            (layoutLabel['height'] as num?)?.toDouble() ?? 0.0;
      }

      inputGraph.setNode(v, newInputLabel);
    }
  }

  for (final e in inputGraph.edges()) {
    final inputLabel = inputGraph.edge(e);
    final layoutLabel = layoutGraph.edge(e);

    if (layoutLabel is Map<String, dynamic>) {
      final newInputLabel = (inputLabel is Map<String, dynamic>)
          ? Map<String, dynamic>.from(inputLabel)
          : <String, dynamic>{};

      if (layoutLabel['points'] is List) {
        final pointsList = layoutLabel['points'] as List;
        final newPoints = <Map<String, double>>[];

        for (final pt in pointsList) {
          if (pt is Map) {
            final x = (pt['x'] as num?)?.toDouble() ?? 0.0;
            final y = (pt['y'] as num?)?.toDouble() ?? 0.0;
            newPoints.add({'x': x, 'y': y});
          }
        }

        newInputLabel['points'] = newPoints;
      }

      newInputLabel['x'] = (layoutLabel['x'] as num?)?.toDouble() ?? 0.0;
      newInputLabel['y'] = (layoutLabel['y'] as num?)?.toDouble() ?? 0.0;

      inputGraph.setEdge(e['v'], e['w'], newInputLabel, e['name']);
    }
  }

  final inputGraphData = Map<String, dynamic>.from(inputGraph.graph() ?? {});
  final layoutGraphData = layoutGraph.graph();

  if (layoutGraphData is Map<String, dynamic>) {
    inputGraphData['width'] =
        (layoutGraphData['width'] as num?)?.toDouble() ?? 0.0;
    inputGraphData['height'] =
        (layoutGraphData['height'] as num?)?.toDouble() ?? 0.0;
  }

  inputGraph.setGraph(inputGraphData);
}

final List<String> graphNumAttrs = [
  'nodesep',
  'edgesep',
  'ranksep',
  'marginx',
  'marginy'
];
final Map<String, dynamic> graphDefaults = {
  'ranksep': 50,
  'edgesep': 20,
  'nodesep': 50,
  'rankdir': 'tb'
};
final List<String> graphAttrs = ['acyclicer', 'ranker', 'rankdir', 'align'];
final List<String> nodeNumAttrs = ['width', 'height'];
final Map<String, dynamic> nodeDefaults = {'width': 0, 'height': 0};
final List<String> edgeNumAttrs = [
  'minlen',
  'weight',
  'width',
  'height',
  'labeloffset'
];
final Map<String, dynamic> edgeDefaults = {
  'minlen': 1,
  'weight': 1,
  'width': 0,
  'height': 0,
  'labeloffset': 10,
  'labelpos': 'r'
};
final List<String> edgeAttrs = ['labelpos'];

/// 从一个对象中选取特定属性
Map<String, dynamic> pickMap(Map<dynamic, dynamic> obj, List<String> attrs) {
  final result = <String, dynamic>{};

  for (final attr in attrs) {
    if (obj.containsKey(attr)) {
      result[attr] = obj[attr];
    }
  }

  return result;
}

/// 从输入图构建可用于布局的新图
Graph buildLayoutGraph(Graph inputGraph) {
  final g = Graph();
  g.isMultigraph = true;
  g.isCompound = true;

  final graph = canonicalize(inputGraph.graph() ?? {});

  final graphSettings = <String, dynamic>{};
  graphSettings.addAll(graphDefaults);
  graphSettings.addAll(selectNumberAttrs(graph, graphNumAttrs));
  graphSettings.addAll(pickMap(graph, graphAttrs));

  g.setGraph(graphSettings);

  for (final v in inputGraph.getNodes()) {
    final node = canonicalize(inputGraph.node(v) ?? {});
    final newNode = selectNumberAttrs(node, nodeNumAttrs);

    for (final k in nodeDefaults.keys) {
      if (!newNode.containsKey(k)) {
        newNode[k] = nodeDefaults[k];
      }
    }

    g.setNode(v, newNode);

    final parent = inputGraph.parent(v);
    if (parent != null) {
      g.setParent(v, parent);
    }
  }

  for (final e in inputGraph.edges()) {
    final edge = canonicalize(inputGraph.edge(e) ?? {});
    final edgeSettings = <String, dynamic>{};
    edgeSettings.addAll(edgeDefaults);
    edgeSettings.addAll(selectNumberAttrs(edge, edgeNumAttrs));
    edgeSettings.addAll(pickMap(edge, edgeAttrs));

    g.setEdge(e['v'], e['w'], edgeSettings, e['name']);
  }

  return g;
}

/// 运行核心布局算法
void runLayout(Graph g, [Map<String, dynamic>? opts]) {
  opts ??= {};
  final timeFn = opts['debugTiming'] == true ? util.time : util.notime;

  try {
    timeFn('    makeSpaceForEdgeLabels', () => makeSpaceForEdgeLabels(g));
    timeFn('    removeSelfEdges', () => removeSelfEdges(g));
    timeFn('    acyclic', () => acyclic.Acyclic.run(g));
    timeFn('    nestingGraph.run', () => nestingGraph.NestingGraph.run(g));
    timeFn('    rank', () => rank.rank(util.asNonCompoundGraph(g)));
    timeFn('    injectEdgeLabelProxies', () => injectEdgeLabelProxies(g));
    timeFn('    removeEmptyRanks', () => util.removeEmptyRanks(g));
    timeFn(
        '    nestingGraph.cleanup', () => nestingGraph.NestingGraph.cleanup(g));
    timeFn('    normalizeRanks', () => util.normalizeRanks(g));
    timeFn('    assignRankMinMax', () => assignRankMinMax(g));
    timeFn('    removeEdgeLabelProxies', () => removeEdgeLabelProxies(g));
    timeFn('    normalize.run', () => normalize.run(g));
    timeFn(
        '    parentDummyChains', () => parentDummyChains.parentDummyChains(g));
    timeFn(
        '    addBorderSegments', () => addBorderSegments.addBorderSegments(g));

    // 启用order和position模块
    bool disableOptimalOrderHeuristic =
        opts['disableOptimalOrderHeuristic'] == true;
    timeFn(
        '    order',
        () => order.order(g,
            disableOptimalOrderHeuristic: disableOptimalOrderHeuristic));
    timeFn('    insertSelfEdges', () => insertSelfEdges(g));
    timeFn('    adjustCoordinateSystem', () => CoordinateSystem.adjust(g));
    timeFn('    position', () => position.position(g));
    timeFn('    positionSelfEdges', () => positionSelfEdges(g));
    timeFn('    removeBorderNodes', () => removeBorderNodes(g));
    timeFn('    normalize.undo', () => normalize.undo(g));
    timeFn('    fixupEdgeLabelCoords', () => fixupEdgeLabelCoords(g));
    timeFn('    undoCoordinateSystem', () => CoordinateSystem.undo(g));
    timeFn('    translateGraph', () => translateGraph(g));
    timeFn('    assignNodeIntersects', () => assignNodeIntersects(g));
    timeFn('    reversePoints', () => reversePointsForReversedEdges(g));
    timeFn('    acyclic.undo', () => acyclic.Acyclic.undo(g));
  } catch (e, stackTrace) {
    print('布局过程出错: $e');
    print(stackTrace);

    // 确保至少有基本布局信息
    ensureBasicLayout(g);
  }
}

/// 为边标签分配空间
void makeSpaceForEdgeLabels(Graph g) {
  final graph = Map<String, dynamic>.from(g.graph() ?? {});
  final ranksep = (graph['ranksep'] as num?)?.toDouble() ?? 0.0;
  graph['ranksep'] = ranksep / 2;
  g.setGraph(graph);

  for (final e in g.edges()) {
    final edge = Map<String, dynamic>.from(g.edge(e) ?? {});
    final minlen = (edge['minlen'] as num?)?.toInt() ?? 1;
    edge['minlen'] = minlen * 2;

    final labelpos = (edge['labelpos'] as String?)?.toLowerCase() ?? 'c';
    if (labelpos != 'c') {
      final labeloffset = (edge['labeloffset'] as num?)?.toDouble() ?? 0.0;

      if (graph['rankdir'] == 'TB' || graph['rankdir'] == 'BT') {
        final width = (edge['width'] as num?)?.toDouble() ?? 0.0;
        edge['width'] = width + labeloffset;
      } else {
        final height = (edge['height'] as num?)?.toDouble() ?? 0.0;
        edge['height'] = height + labeloffset;
      }
    }

    g.setEdge(e['v'], e['w'], edge, e['name']);
  }
}

/// 注入边标签代理节点
void injectEdgeLabelProxies(Graph g) {
  for (final e in g.edges()) {
    final edge = g.edge(e);
    if (edge != null &&
        edge['width'] != null &&
        edge['height'] != null &&
        edge['width'] > 0 &&
        edge['height'] > 0) {
      final v = g.node(e['v']);
      final w = g.node(e['w']);

      if (v != null && w != null && v['rank'] != null && w['rank'] != null) {
        final label = {'rank': (w['rank'] - v['rank']) / 2 + v['rank'], 'e': e};
        util.addDummyNode(g, 'edge-proxy', label, '_ep');
      }
    }
  }
}

/// 分配节点的最小和最大等级
void assignRankMinMax(Graph g) {
  var maxRank = 0;
  for (final v in g.getNodes()) {
    final node = g.node(v);
    if (node != null && node['borderTop'] != null) {
      final borderTop = g.node(node['borderTop']);
      final borderBottom = g.node(node['borderBottom']);

      if (borderTop != null && borderBottom != null) {
        node['minRank'] = borderTop['rank'];
        node['maxRank'] = borderBottom['rank'];
        maxRank = (maxRank as num).compareTo(node['maxRank']) > 0
            ? maxRank
            : node['maxRank'];
      }
    }
  }

  final graphData = g.graph() ?? {};
  graphData['maxRank'] = maxRank;
  g.setGraph(graphData);
}

/// 移除边标签代理节点
void removeEdgeLabelProxies(Graph g) {
  for (final v in List<dynamic>.from(g.getNodes())) {
    final node = g.node(v);
    if (node != null && node['dummy'] == 'edge-proxy') {
      final e = node['e'];
      final edge = g.edge(e);

      if (edge != null) {
        edge['labelRank'] = node['rank'];
        g.setEdge(e['v'], e['w'], edge, e['name']);
      }

      g.removeNode(v);
    }
  }
}

/// 平移图以使所有点具有非负坐标，并添加边距
void translateGraph(Graph g) {
  double minX = double.infinity;
  double minY = double.infinity;
  double maxX = -double.infinity;
  double maxY = -double.infinity;

  // 查找图的最小和最大坐标
  for (final v in g.getNodes()) {
    final node = g.node(v);
    if (node == null) continue;

    // 获取节点坐标，确保类型安全
    final x = (node['x'] is num) ? (node['x'] as num).toDouble() : 0.0;
    final y = (node['y'] is num) ? (node['y'] as num).toDouble() : 0.0;

    // 获取节点尺寸，确保类型安全
    final width =
        (node['width'] is num) ? (node['width'] as num).toDouble() : 0.0;
    final height =
        (node['height'] is num) ? (node['height'] as num).toDouble() : 0.0;

    // 更新图的最小和最大坐标，考虑节点尺寸
    minX = math.min(minX, x - width / 2);
    maxX = math.max(maxX, x + width / 2);
    minY = math.min(minY, y - height / 2);
    maxY = math.max(maxY, y + height / 2);
  }

  // 检查边的坐标点
  for (final e in g.edges()) {
    final edge = g.edge(e);
    if (edge == null) continue;

    if (edge.containsKey('points') && edge['points'] is List) {
      final points = edge['points'] as List;
      for (int i = 0; i < points.length; i++) {
        if (points[i] is Map) {
          final point = points[i] as Map;
          if (point.containsKey('x') && point.containsKey('y')) {
            final x =
                (point['x'] is num) ? (point['x'] as num).toDouble() : 0.0;
            final y =
                (point['y'] is num) ? (point['y'] as num).toDouble() : 0.0;

            if (x < minX) minX = x;
            if (x > maxX) maxX = x;
            if (y < minY) minY = y;
            if (y > maxY) maxY = y;
          }
        }
      }
    }
  }

  // 计算图的实际大小
  final graphWidth = maxX - minX;
  final graphHeight = maxY - minY;

  // 处理图是空的情况
  if (!minX.isFinite || !minY.isFinite || !maxX.isFinite || !maxY.isFinite) {
    minX = 0;
    minY = 0;
    maxX = 0;
    maxY = 0;
  }

  // 取得所需的边距
  final marginX = (g.graph()?['marginx'] is num)
      ? (g.graph()?['marginx'] as num).toDouble()
      : 0.0;
  final marginY = (g.graph()?['marginy'] is num)
      ? (g.graph()?['marginy'] as num).toDouble()
      : 0.0;

  // 计算偏移量以使所有坐标为正数，并增加边距
  final deltaX = marginX - minX;
  final deltaY = marginY - minY;

  // 设置图大小和偏移量
  // final graphData = g.graph() ?? {};
  // graphData['width'] = (graphWidth + 2 * marginX).toDouble();
  // graphData['height'] = (graphHeight + 2 * marginY).toDouble();
  // g.setGraph(graphData);

  dynamic currentGraphData = g.graph();
  if (currentGraphData == null || currentGraphData is! Map<String, dynamic>) {
    currentGraphData = {};
  }

  final graphData = Map<String, dynamic>.from(currentGraphData);
  graphData['width'] = (graphWidth + 2 * marginX).toDouble();
  graphData['height'] = (graphHeight + 2 * marginY).toDouble();
  g.setGraph(graphData);

  // 移动所有节点的位置
  for (final v in g.getNodes()) {
    final node = g.node(v);
    if (node == null) continue;

    if (node.containsKey('x')) {
      final oldX = (node['x'] is num) ? (node['x'] as num).toDouble() : 0.0;
      node['x'] = oldX + deltaX;
    }

    if (node.containsKey('y')) {
      final oldY = (node['y'] is num) ? (node['y'] as num).toDouble() : 0.0;
      node['y'] = oldY + deltaY;
    }
  }

  // 移动所有边的points位置
  for (final e in g.edges()) {
    final edge = g.edge(e);
    if (edge == null) continue;

    // 更新边的x, y坐标
    if (edge.containsKey('x')) {
      final oldX = (edge['x'] is num) ? (edge['x'] as num).toDouble() : 0.0;
      edge['x'] = oldX + deltaX;
    }

    if (edge.containsKey('y')) {
      final oldY = (edge['y'] is num) ? (edge['y'] as num).toDouble() : 0.0;
      edge['y'] = oldY + deltaY;
    }

    // 更新边的points数组
    if (edge.containsKey('points')) {
      if (edge['points'] is List) {
        final points = edge['points'] as List;
        final newPoints = <Map<String, double>>[];

        for (int i = 0; i < points.length; i++) {
          if (points[i] is Map) {
            final point = points[i] as Map;
            if (point.containsKey('x') && point.containsKey('y')) {
              final x =
                  (point['x'] is num) ? (point['x'] as num).toDouble() : 0.0;
              final y =
                  (point['y'] is num) ? (point['y'] as num).toDouble() : 0.0;
              newPoints.add({'x': x + deltaX, 'y': y + deltaY});
            }
          }
        }

        edge['points'] = newPoints; // 使用新的points列表替换旧的
      } else {
        // 如果points不是List，创建一个空列表
        edge['points'] = <Map<String, double>>[];
      }
    } else {
      // 如果points不存在，创建一个空列表
      edge['points'] = <Map<String, double>>[];
    }
  }
}

/// 分配节点的交叉点
void assignNodeIntersects(Graph g) {
  for (final e in g.edges()) {
    final edge = g.edge(e);
    if (edge != null) {
      final nodeV = g.node(e['v']);
      final nodeW = g.node(e['w']);

      if (nodeV != null && nodeW != null) {
        dynamic p1, p2;

        // 确保points是一个列表
        if (!edge.containsKey('points')) {
          edge['points'] = <Map<String, double>>[];
        } else if (!(edge['points'] is List)) {
          edge['points'] = <Map<String, double>>[];
        }

        // 获取points列表进行操作
        final points = edge['points'] as List;

        if (points.isEmpty) {
          p1 = nodeW;
          p2 = nodeV;
        } else {
          p1 = points.isNotEmpty ? points[0] : nodeW;
          p2 = points.isNotEmpty ? points[points.length - 1] : nodeV;
        }

        // 计算与节点矩形的交点
        try {
          final intersect1 = util
              .intersectRectForLayout(nodeV, p1)
              .map((k, v) => MapEntry(k, v.toDouble()));
          final intersect2 = util
              .intersectRectForLayout(nodeW, p2)
              .map((k, v) => MapEntry(k, v.toDouble()));

          if (points.isEmpty) {
            points.add(intersect1);
            points.add(intersect2);
          } else {
            points.insert(0, intersect1);
            points.add(intersect2);
          }
        } catch (e) {
          print('Error calculating intersects: $e');
          // 如果计算交点失败，提供一个安全的默认值
          if (points.isEmpty) {
            final nodeVX =
                nodeV['x'] is num ? (nodeV['x'] as num).toDouble() : 0.0;
            final nodeVY =
                nodeV['y'] is num ? (nodeV['y'] as num).toDouble() : 0.0;
            final nodeWX =
                nodeW['x'] is num ? (nodeW['x'] as num).toDouble() : 0.0;
            final nodeWY =
                nodeW['y'] is num ? (nodeW['y'] as num).toDouble() : 0.0;

            points.add({'x': nodeVX, 'y': nodeVY});
            points.add({'x': nodeWX, 'y': nodeWY});
          }
        }
      }
    }
  }
}

/// 修正边标签的坐标
void fixupEdgeLabelCoords(Graph g) {
  for (final e in g.edges()) {
    final edge = g.edge(e);
    if (edge != null && edge.containsKey('x')) {
      if (edge['labelpos'] == 'l' || edge['labelpos'] == 'r') {
        edge['width'] = (edge['width'] as num) - (edge['labeloffset'] as num);
      }

      switch (edge['labelpos']) {
        case 'l':
          edge['x'] = (edge['x'] as num) -
              (edge['width'] as num) / 2 -
              (edge['labeloffset'] as num);
          break;
        case 'r':
          edge['x'] = (edge['x'] as num) +
              (edge['width'] as num) / 2 +
              (edge['labeloffset'] as num);
          break;
      }
    }
  }
}

/// 反转反向边的点
void reversePointsForReversedEdges(Graph g) {
  for (final e in g.edges()) {
    final edge = g.edge(e);
    if (edge != null && edge['reversed'] == true) {
      if (edge.containsKey('points') && edge['points'] is List) {
        final points = edge['points'] as List;
        if (points.isNotEmpty) {
          // 创建一个新的反转列表而不是原地修改
          final reversedPoints =
              List<Map<String, double>>.from(points.reversed);
          edge['points'] = reversedPoints;
        }
      }
    }
  }
}

/// 移除边界节点
void removeBorderNodes(Graph g) {
  for (final v in g.getNodes()) {
    if ((g.children(v) ?? []).isNotEmpty) {
      final node = g.node(v);

      if (node != null && node['borderTop'] != null) {
        final t = g.node(node['borderTop']);
        final b = g.node(node['borderBottom']);
        final leftBorder = node['borderLeft'] as List;
        final rightBorder = node['borderRight'] as List;
        final l = g.node(leftBorder[leftBorder.length - 1]);
        final r = g.node(rightBorder[rightBorder.length - 1]);

        if (t != null && b != null && l != null && r != null) {
          node['width'] = ((r['x'] as num) - (l['x'] as num)).abs();
          node['height'] = ((b['y'] as num) - (t['y'] as num)).abs();
          node['x'] = (l['x'] as num) + (node['width'] as num) / 2;
          node['y'] = (t['y'] as num) + (node['height'] as num) / 2;
        }
      }
    }
  }

  for (final v in List<dynamic>.from(g.getNodes())) {
    final node = g.node(v);
    if (node != null && node['dummy'] == 'border') {
      g.removeNode(v);
    }
  }
}

/// 移除自环边
void removeSelfEdges(Graph g) {
  for (final e in List<Map<String, dynamic>>.from(g.edges())) {
    if (e['v'] == e['w']) {
      final node = g.node(e['v']);
      if (node != null) {
        if (!node.containsKey('selfEdges')) {
          node['selfEdges'] = [];
        }

        (node['selfEdges'] as List).add({'e': e, 'label': g.edge(e)});

        g.removeEdge(e['v'], e['w'], e['name']);
      }
    }
  }
}

/// 插入自环边
void insertSelfEdges(Graph g) {
  final layers = util.buildLayerMatrix(g);

  for (final layer in layers) {
    var orderShift = 0;

    for (var i = 0; i < layer.length; i++) {
      final v = layer[i];
      final node = g.node(v);

      if (node != null) {
        node['order'] = i + orderShift;

        if (node['selfEdges'] != null) {
          for (final selfEdge in node['selfEdges'] as List) {
            util.addDummyNode(
                g,
                'selfedge',
                {
                  'width': selfEdge['label']['width'],
                  'height': selfEdge['label']['height'],
                  'rank': node['rank'],
                  'order': i + (++orderShift),
                  'e': selfEdge['e'],
                  'label': selfEdge['label']
                },
                '_se');
          }

          node.remove('selfEdges');
        }
      }
    }
  }
}

/// 定位自环边
void positionSelfEdges(Graph g) {
  for (final v in List<dynamic>.from(g.getNodes())) {
    final node = g.node(v);

    if (node != null && node['dummy'] == 'selfedge') {
      final selfEdge = node['e'];
      final selfNode = g.node(selfEdge['v']);

      if (selfNode != null) {
        final x = (selfNode['x'] as num) + (selfNode['width'] as num) / 2;
        final y = selfNode['y'] as num;
        final dx = (node['x'] as num) - x as num;
        final dy = (selfNode['height'] as num) / 2;

        g.setEdge(
            selfEdge['v'], selfEdge['w'], node['label'], selfEdge['name']);
        g.removeNode(v);

        node['label']['points'] = [
          {'x': x + 2 * dx / 3, 'y': y - dy},
          {'x': x + 5 * dx / 6, 'y': y - dy},
          {'x': x + dx, 'y': y},
          {'x': x + 5 * dx / 6, 'y': y + dy},
          {'x': x + 2 * dx / 3, 'y': y + dy}
        ];

        node['label']['x'] = node['x'];
        node['label']['y'] = node['y'];
      }
    }
  }
}

/// 选择数字属性
Map<String, dynamic> selectNumberAttrs(
    Map<dynamic, dynamic> obj, List<String> attrs) {
  final result = <String, dynamic>{};

  for (final attr in attrs) {
    if (obj.containsKey(attr)) {
      final val = obj[attr];
      if (val is num) {
        result[attr] = val;
      } else if (val is String) {
        try {
          result[attr] = double.parse(val);
        } catch (e) {
          // 忽略解析错误
        }
      }
    }
  }

  return result;
}

/// 标准化属性
Map<dynamic, dynamic> canonicalize(Map<dynamic, dynamic> attrs) {
  final newAttrs = <dynamic, dynamic>{};

  attrs.forEach((k, v) {
    if (k is String) {
      k = k.toLowerCase();
    }
    newAttrs[k] = v;
  });

  return newAttrs;
}
