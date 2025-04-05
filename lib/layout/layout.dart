import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/graph/alg/acyclic.dart' as acyclic;
import 'package:flow_layout/graph/alg/normalize.dart' as normalize;
import 'package:flow_layout/layout/rank/rank.dart' as rank;
import 'package:flow_layout/layout/utils.dart' as util;
import 'package:flow_layout/graph/alg/parent_dummy_chains.dart' as parentDummyChains;
import 'package:flow_layout/graph/alg/nesting_graph.dart' as nestingGraph;
import 'package:flow_layout/graph/alg/add_border_segments.dart' as addBorderSegments;
import 'package:flow_layout/graph/alg/coordinate_system.dart';
import 'package:flow_layout/layout/order/layout_order.dart' as order;
import 'package:flow_layout/layout/position/layout_position.dart' as position;

/// 执行图布局算法
void layout(Graph g, [Map<String, dynamic>? opts]) {
  final time = (opts != null && opts['debugTiming'] == true) 
      ? util.time : util.notime;
  
  time('layout', () {
    final layoutGraph = time('  buildLayoutGraph', () => buildLayoutGraph(g));
    time('  runLayout', () => runLayout(layoutGraph, time, opts));
    time('  updateInputGraph', () => updateInputGraph(g, layoutGraph));
  });
}

/// 运行核心布局算法
void runLayout(Graph g, Function time, [Map<String, dynamic>? opts]) {
  try {
    time('    makeSpaceForEdgeLabels', () => makeSpaceForEdgeLabels(g));
    time('    removeSelfEdges',        () => removeSelfEdges(g));
    time('    acyclic',                () => acyclic.Acyclic.run(g));
    time('    nestingGraph.run',       () => nestingGraph.NestingGraph.run(g));
    time('    rank',                   () => rank.rank(util.asNonCompoundGraph(g)));
    time('    injectEdgeLabelProxies', () => injectEdgeLabelProxies(g));
    time('    removeEmptyRanks',       () => util.removeEmptyRanks(g));
    time('    nestingGraph.cleanup',   () => nestingGraph.NestingGraph.cleanup(g));
    time('    normalizeRanks',         () => util.normalizeRanks(g));
    time('    assignRankMinMax',       () => assignRankMinMax(g));
    time('    removeEdgeLabelProxies', () => removeEdgeLabelProxies(g));
    time('    normalize.run',          () => normalize.run(g));
    time('    parentDummyChains',      () => parentDummyChains.parentDummyChains(g));
    time('    addBorderSegments',      () => addBorderSegments.addBorderSegments(g));
    
    // 启用order和position模块
    bool disableOptimalOrderHeuristic = opts != null && opts['disableOptimalOrderHeuristic'] == true;
    time('    order',                  () => order.order(g, disableOptimalOrderHeuristic: disableOptimalOrderHeuristic));
    time('    insertSelfEdges',        () => insertSelfEdges(g));
    time('    adjustCoordinateSystem', () => CoordinateSystem.adjust(g));
    time('    position',               () => position.position(g));
    time('    positionSelfEdges',      () => positionSelfEdges(g));
    time('    removeBorderNodes',      () => removeBorderNodes(g));
    time('    normalize.undo',         () => normalize.undo(g));
    time('    fixupEdgeLabelCoords',   () => fixupEdgeLabelCoords(g));
    time('    undoCoordinateSystem',   () => CoordinateSystem.undo(g));
    time('    translateGraph',         () => translateGraph(g));
    time('    assignNodeIntersects',   () => assignNodeIntersects(g));
    time('    reversePoints',          () => reversePointsForReversedEdges(g));
    time('    acyclic.undo',           () => acyclic.Acyclic.undo(g));
  } catch (e, stackTrace) {
    print('布局过程出错: $e');
    print(stackTrace);
    
    // 确保至少有基本布局信息
    _ensureBasicLayout(g);
  }
}

/// 确保图中的所有节点至少有基本布局信息
void _ensureBasicLayout(Graph g) {
  // 为没有坐标的节点设置一个默认位置
  int x = 0;
  int y = 0;
  const int gridSize = 100;
  
  for (final v in g.getNodes()) {
    final node = g.node(v);
    if (node != null) {
      // 确保节点有宽度和高度
      if (!node.containsKey('width')) {
        node['width'] = 30;
      }
      if (!node.containsKey('height')) {
        node['height'] = 30;
      }
      
      // 确保节点有坐标
      if (!node.containsKey('x')) {
        node['x'] = x;
        x += gridSize;
      }
      if (!node.containsKey('y')) {
        node['y'] = y;
        
        // 换行
        if (x > 500) {
          x = 0;
          y += gridSize;
        }
      }
    }
  }
}

/// 从布局图复制最终布局信息回输入图
void updateInputGraph(Graph inputGraph, Graph layoutGraph) {
  for (final v in inputGraph.getNodes()) {
    final inputLabel = inputGraph.node(v);
    final layoutLabel = layoutGraph.node(v);

    if (inputLabel != null && layoutLabel != null) {
      // 复制坐标属性，确保类型一致
      if (layoutLabel.containsKey('x')) {
        inputLabel['x'] = layoutLabel['x'];
      }
      if (layoutLabel.containsKey('y')) {
        inputLabel['y'] = layoutLabel['y'];
      }
      if (layoutLabel.containsKey('rank')) {
        // 确保rank是int或double类型
        if (layoutLabel['rank'] is int || layoutLabel['rank'] is double) {
          inputLabel['rank'] = layoutLabel['rank'];
        }
      }

      if ((layoutGraph.children(v) ?? []).isNotEmpty) {
        if (layoutLabel.containsKey('width')) {
          inputLabel['width'] = layoutLabel['width'];
        }
        if (layoutLabel.containsKey('height')) {
          inputLabel['height'] = layoutLabel['height'];
        }
      }
    }
  }

  for (final e in inputGraph.edges()) {
    final inputLabel = inputGraph.edge(e);
    final layoutLabel = layoutGraph.edge(e);

    if (inputLabel != null && layoutLabel != null) {
      if (layoutLabel.containsKey('points')) {
        inputLabel['points'] = layoutLabel['points'];
      }
      if (layoutLabel.containsKey('x')) {
        inputLabel['x'] = layoutLabel['x'];
      }
      if (layoutLabel.containsKey('y')) {
        inputLabel['y'] = layoutLabel['y'];
      }
    }
  }

  final inputGraphData = inputGraph.graph() ?? {};
  final layoutGraphData = layoutGraph.graph() ?? {};
  
  if (layoutGraphData.containsKey('width')) {
    inputGraphData['width'] = layoutGraphData['width'];
  }
  if (layoutGraphData.containsKey('height')) {
    inputGraphData['height'] = layoutGraphData['height'];
  }
  
  inputGraph.setGraph(inputGraphData);
}

final List<String> graphNumAttrs = ['nodesep', 'edgesep', 'ranksep', 'marginx', 'marginy'];
final Map<String, dynamic> graphDefaults = {
  'ranksep': 50, 
  'edgesep': 20, 
  'nodesep': 50, 
  'rankdir': 'tb'
};
final List<String> graphAttrs = ['acyclicer', 'ranker', 'rankdir', 'align'];
final List<String> nodeNumAttrs = ['width', 'height'];
final Map<String, dynamic> nodeDefaults = {'width': 0, 'height': 0};
final List<String> edgeNumAttrs = ['minlen', 'weight', 'width', 'height', 'labeloffset'];
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

/// 为边标签分配空间
void makeSpaceForEdgeLabels(Graph g) {
  final graph = g.graph() ?? {};
  graph['ranksep'] = (graph['ranksep'] as num) / 2;
  g.setGraph(graph);
  
  for (final e in g.edges()) {
    final edge = g.edge(e) ?? {};
    edge['minlen'] = (edge['minlen'] as num) * 2;
    
    if ((edge['labelpos'] as String).toLowerCase() != 'c') {
      if (graph['rankdir'] == 'TB' || graph['rankdir'] == 'BT') {
        edge['width'] = (edge['width'] as num) + (edge['labeloffset'] as num);
      } else {
        edge['height'] = (edge['height'] as num) + (edge['labeloffset'] as num);
      }
    }
    
    g.setEdge(e['v'], e['w'], edge, e['name']);
  }
}

/// 注入边标签代理节点
void injectEdgeLabelProxies(Graph g) {
  for (final e in g.edges()) {
    final edge = g.edge(e);
    if (edge != null && edge['width'] != null && edge['height'] != null) {
      final v = g.node(e['v']);
      final w = g.node(e['w']);
      
      if (v != null && w != null && v['rank'] != null && w['rank'] != null) {
        final label = {
          'rank': (w['rank'] - v['rank']) / 2 + v['rank'], 
          'e': e
        };
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
            ? maxRank : node['maxRank'];
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

/// 平移图以确保所有坐标为正
void translateGraph(Graph g) {
  double minX = double.infinity;
  double maxX = -double.infinity;
  double minY = double.infinity;
  double maxY = -double.infinity;

  // 找出所有节点的位置极值
  for (final v in g.getNodes()) {
    final node = g.node(v);
    if (node == null) continue;
    
    final x = (node['x'] is num) ? (node['x'] as num).toDouble() : 0.0;
    final y = (node['y'] is num) ? (node['y'] as num).toDouble() : 0.0;
    final width = (node['width'] is num) ? (node['width'] as num).toDouble() : 0.0;
    final height = (node['height'] is num) ? (node['height'] as num).toDouble() : 0.0;
    
    final left = x - width / 2;
    final right = x + width / 2;
    final top = y - height / 2;
    final bottom = y + height / 2;
    
    if (left < minX) minX = left;
    if (right > maxX) maxX = right;
    if (top < minY) minY = top;
    if (bottom > maxY) maxY = bottom;
  }

  // 找出所有边的points位置极值
  for (final e in g.edges()) {
    final edge = g.edge(e);
    if (edge == null) continue;
    
    if (edge.containsKey('points') && edge['points'] is List) {
      final points = edge['points'] as List;
      for (int i = 0; i < points.length; i++) {
        if (points[i] is Map) {
          final point = points[i] as Map;
          if (point.containsKey('x') && point.containsKey('y')) {
            final x = (point['x'] is num) ? (point['x'] as num).toDouble() : 0.0;
            final y = (point['y'] is num) ? (point['y'] as num).toDouble() : 0.0;
            
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

  // 取得所需的边距
  final marginX = (g.graph()?['marginx'] is num) ? (g.graph()?['marginx'] as num).toDouble() : 20.0;
  final marginY = (g.graph()?['marginy'] is num) ? (g.graph()?['marginy'] as num).toDouble() : 20.0;

  // 计算偏移量以使所有坐标为正数，并增加边距
  final deltaX = marginX - minX;
  final deltaY = marginY - minY;

  // 设置图大小和偏移量
  final graphData = g.graph() ?? {};
  graphData['width'] = graphWidth + 2 * marginX;
  graphData['height'] = graphHeight + 2 * marginY;
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
    
    if (edge.containsKey('points') && edge['points'] is List) {
      final points = edge['points'] as List;
      List<Map<String, double>> newPoints = [];
      
      for (int i = 0; i < points.length; i++) {
        if (points[i] is Map) {
          final point = points[i] as Map;
          if (point.containsKey('x') && point.containsKey('y')) {
            final x = (point['x'] is num) ? (point['x'] as num).toDouble() : 0.0;
            final y = (point['y'] is num) ? (point['y'] as num).toDouble() : 0.0;
            newPoints.add({'x': x + deltaX, 'y': y + deltaY});
          }
        }
      }
      
      edge['points'] = newPoints;
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
        
        if (edge['points'] == null || (edge['points'] as List).isEmpty) {
          edge['points'] = [];
          p1 = nodeW;
          p2 = nodeV;
        } else {
          final points = edge['points'] as List;
          p1 = points[0];
          p2 = points[points.length - 1];
        }
        
        (edge['points'] as List).insert(0, util.intersectRectForLayout(nodeV, p1));
        (edge['points'] as List).add(util.intersectRectForLayout(nodeW, p2));
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
          edge['x'] = (edge['x'] as num) - (edge['width'] as num) / 2 - (edge['labeloffset'] as num);
          break;
        case 'r':
          edge['x'] = (edge['x'] as num) + (edge['width'] as num) / 2 + (edge['labeloffset'] as num);
          break;
      }
    }
  }
}

/// 反转反向边的点
void reversePointsForReversedEdges(Graph g) {
  for (final e in g.edges()) {
    final edge = g.edge(e);
    if (edge != null && edge['reversed'] == true && edge['points'] != null) {
      (edge['points'] as List).reversed.toList();
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
        
        (node['selfEdges'] as List).add({
          'e': e, 
          'label': g.edge(e)
        });
        
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
            util.addDummyNode(g, 'selfedge', {
              'width': selfEdge['label']['width'],
              'height': selfEdge['label']['height'],
              'rank': node['rank'],
              'order': i + (++orderShift),
              'e': selfEdge['e'],
              'label': selfEdge['label']
            }, '_se');
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
        
        g.setEdge(selfEdge['v'], selfEdge['w'], node['label'], selfEdge['name']);
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
Map<String, dynamic> selectNumberAttrs(Map<dynamic, dynamic> obj, List<String> attrs) {
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