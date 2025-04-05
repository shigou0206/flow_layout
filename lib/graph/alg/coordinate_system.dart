import 'package:flow_layout/graph/graph.dart';

/// 坐标系统调整工具
/// 
/// 在不同布局方向下调整图形的坐标系统
class CoordinateSystem {
  /// 根据图的rankdir属性调整节点和边的坐标
  /// 
  /// 在布局过程开始前调用，用于调整布局方向
  static void adjust(Graph g) {
    final graphData = g.graph();
    if (graphData == null || !graphData.containsKey('rankdir')) return;
    
    String rankDir = (graphData['rankdir'] as String).toLowerCase();
    if (rankDir == 'lr' || rankDir == 'rl') {
      _swapWidthHeight(g);
    }
  }
  
  /// 恢复节点和边的坐标到正常显示状态
  /// 
  /// 在布局过程结束后调用，用于恢复显示方向
  static void undo(Graph g) {
    final graphData = g.graph();
    if (graphData == null || !graphData.containsKey('rankdir')) return;
    
    String rankDir = (graphData['rankdir'] as String).toLowerCase();
    if (rankDir == 'bt' || rankDir == 'rl') {
      _reverseY(g);
    }
    
    if (rankDir == 'lr' || rankDir == 'rl') {
      _swapXY(g);
      _swapWidthHeight(g);
    }
  }
  
  /// 交换宽度和高度
  static void _swapWidthHeight(Graph g) {
    for (final v in g.getNodes()) {
      final nodeData = g.node(v);
      if (nodeData != null && nodeData is Map) {
        _swapWidthHeightOne(nodeData);
      }
    }
    
    for (final e in g.edges()) {
      final edgeData = g.edge(e);
      if (edgeData != null && edgeData is Map) {
        _swapWidthHeightOne(edgeData);
      }
    }
  }
  
  /// 交换单个对象的宽度和高度
  static void _swapWidthHeightOne(Map<dynamic, dynamic> attrs) {
    if (attrs.containsKey('width') && attrs.containsKey('height')) {
      final w = attrs['width'];
      attrs['width'] = attrs['height'];
      attrs['height'] = w;
    }
  }
  
  /// 反转Y坐标
  static void _reverseY(Graph g) {
    for (final v in g.getNodes()) {
      final nodeData = g.node(v);
      if (nodeData != null && nodeData is Map) {
        _reverseYOne(nodeData);
      }
    }
    
    for (final e in g.edges()) {
      final edgeData = g.edge(e);
      if (edgeData != null && edgeData is Map) {
        // 反转边的所有点的Y坐标
        if (edgeData.containsKey('points') && edgeData['points'] is List) {
          final points = edgeData['points'] as List;
          for (final point in points) {
            if (point is Map) {
              _reverseYOne(point);
            }
          }
        }
        
        // 如果边自身有Y坐标（例如边标签），也要反转
        if (edgeData.containsKey('y')) {
          _reverseYOne(edgeData);
        }
      }
    }
  }
  
  /// 反转单个对象的Y坐标
  static void _reverseYOne(Map<dynamic, dynamic> attrs) {
    if (attrs.containsKey('y')) {
      attrs['y'] = -(attrs['y'] as num);
    }
  }
  
  /// 交换X和Y坐标
  static void _swapXY(Graph g) {
    for (final v in g.getNodes()) {
      final nodeData = g.node(v);
      if (nodeData != null && nodeData is Map) {
        _swapXYOne(nodeData);
      }
    }
    
    for (final e in g.edges()) {
      final edgeData = g.edge(e);
      if (edgeData != null && edgeData is Map) {
        // 交换边的所有点的X和Y坐标
        if (edgeData.containsKey('points') && edgeData['points'] is List) {
          final points = edgeData['points'] as List;
          for (final point in points) {
            if (point is Map) {
              _swapXYOne(point);
            }
          }
        }
        
        // 如果边自身有X和Y坐标（例如边标签），也要交换
        if (edgeData.containsKey('x') && edgeData.containsKey('y')) {
          _swapXYOne(edgeData);
        }
      }
    }
  }
  
  /// 交换单个对象的X和Y坐标
  static void _swapXYOne(Map<dynamic, dynamic> attrs) {
    if (attrs.containsKey('x') && attrs.containsKey('y')) {
      final x = attrs['x'];
      attrs['x'] = attrs['y'];
      attrs['y'] = x;
    }
  }
} 