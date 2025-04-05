import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/rank/rank.dart';
import 'package:flow_layout/layout/utils.dart';

void main() {
  print('Testing rank functionality');
  
  // 测试单个节点图
  testSingleNodeGraph();
  
  // 测试路径图
  testPathGraph();
  
  // 测试菱形图
  testDiamondGraph();
  
  // 测试多边图
  testMultiEdgeGraph();
  
  // 测试不同排名器
  testDifferentRankers();
  
  print('All tests completed');
}

void testSingleNodeGraph() {
  print('\n===== Testing Single Node Graph =====');
  final g = Graph()
    ..setGraph({})
    ..setNode('a', {});
  
  rank(g);
  
  if (g.node('a').containsKey('rank')) {
    print('✅ Node a has rank: ${g.node('a')['rank']}');
  } else {
    print('❌ Node a has no rank');
  }
}

void testPathGraph() {
  print('\n===== Testing Path Graph =====');
  final g = Graph()
    ..setGraph({})
    ..setDefaultNodeLabel((_) => {})
    ..setDefaultEdgeLabel((_, __, ___) => {'minlen': 1, 'weight': 1})
    ..setPath(['a', 'b', 'c', 'd']);
  
  rank(g);
  normalizeRanks(g);
  
  print('Node ranks:');
  for (final v in g.getNodes()) {
    print('  $v: ${g.node(v)['rank']} (${g.node(v)['rank'].runtimeType})');
  }
  
  // 验证minlen约束
  bool allValid = true;
  for (final e in g.edges()) {
    final vRankValue = g.node(e['v'])['rank'];
    final wRankValue = g.node(e['w'])['rank'];
    
    if (vRankValue == null || wRankValue == null) {
      print('❌ Rank value is null for edge ${e['v']}->${e['w']}');
      allValid = false;
      continue;
    }
    
    // 将rank值转换为num类型
    final num vRank = vRankValue is num ? vRankValue : 0;
    final num wRank = wRankValue is num ? wRankValue : 0;
    
    final edgeData = g.edge(e) ?? {'minlen': 1, 'weight': 1};
    final minlen = edgeData['minlen'] is num ? edgeData['minlen'] as num : 1;
    
    if (wRank - vRank < minlen) {
      print('❌ Edge ${e['v']}->${e['w']} violates minlen constraint: ${wRank - vRank} < $minlen');
      allValid = false;
    }
  }
  
  if (allValid) {
    print('✅ All edges respect minlen constraint');
  }
}

void testDiamondGraph() {
  print('\n===== Testing Diamond Graph =====');
  final g = Graph()
    ..setGraph({})
    ..setDefaultNodeLabel((_) => {})
    ..setDefaultEdgeLabel((_, __, ___) => {'minlen': 1, 'weight': 1})
    ..setPath(['a', 'b', 'd'])
    ..setPath(['a', 'c', 'd']);
  
  rank(g);
  normalizeRanks(g);
  
  print('Node ranks:');
  for (final v in g.getNodes()) {
    print('  $v: ${g.node(v)['rank']} (${g.node(v)['rank'].runtimeType})');
  }
  
  // 验证b和c在同一个rank
  if (g.node('b')['rank'] == g.node('c')['rank']) {
    print('✅ Nodes b and c have the same rank');
  } else {
    print('❌ Nodes b and c have different ranks');
  }
  
  // 验证minlen约束
  bool allValid = true;
  for (final e in g.edges()) {
    final vRankValue = g.node(e['v'])['rank'];
    final wRankValue = g.node(e['w'])['rank'];
    
    if (vRankValue == null || wRankValue == null) {
      print('❌ Rank value is null for edge ${e['v']}->${e['w']}');
      allValid = false;
      continue;
    }
    
    // 将rank值转换为num类型
    final num vRank = vRankValue is num ? vRankValue : 0;
    final num wRank = wRankValue is num ? wRankValue : 0;
    
    final edgeData = g.edge(e) ?? {'minlen': 1, 'weight': 1};
    final minlen = edgeData['minlen'] is num ? edgeData['minlen'] as num : 1;
    
    if (wRank - vRank < minlen) {
      print('❌ Edge ${e['v']}->${e['w']} violates minlen constraint: ${wRank - vRank} < $minlen');
      allValid = false;
    }
  }
  
  if (allValid) {
    print('✅ All edges respect minlen constraint');
  }
}

void testMultiEdgeGraph() {
  print('\n===== Testing Multi-Edge Graph =====');
  final g = Graph(isMultigraph: true)
    ..setGraph({})
    ..setDefaultNodeLabel((_) => {})
    ..setDefaultEdgeLabel((_, __, ___) => {'minlen': 1, 'weight': 1})
    ..setEdge('a', 'b', {'weight': 2, 'minlen': 1})
    ..setEdge('a', 'b', {'weight': 1, 'minlen': 2}, 'multi');
  
  rank(g);
  normalizeRanks(g);
  
  print('Node ranks:');
  for (final v in g.getNodes()) {
    print('  $v: ${g.node(v)['rank']} (${g.node(v)['rank'].runtimeType})');
  }
  
  // 验证rank差是否尊重最大minlen
  final aRankValue = g.node('a')['rank'];
  final bRankValue = g.node('b')['rank'];
  
  if (aRankValue == null || bRankValue == null) {
    print('❌ Rank value is null for a or b');
  } else {
    // 将rank值转换为num类型
    final num aRank = aRankValue is num ? aRankValue : 0;
    final num bRank = bRankValue is num ? bRankValue : 0;
    
    if (bRank - aRank >= 2) {
      print('✅ Rank difference respects maximum minlen: ${bRank - aRank} >= 2');
    } else {
      print('❌ Rank difference does not respect maximum minlen: ${bRank - aRank} < 2');
    }
  }
}

void testDifferentRankers() {
  print('\n===== Testing Different Rankers =====');
  final rankers = [
    'longest-path', 
    'tight-tree',
    'network-simplex', 
    'unknown-should-still-work'
  ];
  
  for (final ranker in rankers) {
    print('\nTesting ranker: $ranker');
    final g = Graph()
      ..setGraph({'ranker': ranker})
      ..setDefaultNodeLabel((_) => {})
      ..setDefaultEdgeLabel((_, __, ___) => {'minlen': 1, 'weight': 1})
      ..setPath(['a', 'b', 'c', 'd']);
    
    rank(g);
    
    // 验证所有节点都有rank值
    bool allHaveRank = true;
    for (final v in g.getNodes()) {
      if (!g.node(v).containsKey('rank')) {
        print('❌ Node $v has no rank');
        allHaveRank = false;
      }
    }
    
    if (allHaveRank) {
      print('✅ All nodes have rank values');
    }
    
    // 验证minlen约束
    bool allValid = true;
    for (final e in g.edges()) {
      // 安全地获取rank值，支持int和double类型
      final vRankValue = g.node(e['v'])['rank'];
      final wRankValue = g.node(e['w'])['rank'];
      
      if (vRankValue == null || wRankValue == null) {
        print('❌ Rank value is null for edge ${e['v']}->${e['w']}');
        allValid = false;
        continue;
      }
      
      // 将rank值转换为num类型
      final num vRank = vRankValue is num ? vRankValue : 0;
      final num wRank = wRankValue is num ? wRankValue : 0;
      
      final edgeData = g.edge(e) ?? {'minlen': 1, 'weight': 1};
      final minlen = edgeData['minlen'] is num ? edgeData['minlen'] as num : 1;
      
      if (wRank - vRank < minlen) {
        print('❌ Edge ${e['v']}->${e['w']} violates minlen constraint: ${wRank - vRank} < $minlen');
        allValid = false;
      }
    }
    
    if (allValid) {
      print('✅ All edges respect minlen constraint');
    }
    
    print('Node ranks:');
    for (final v in g.getNodes()) {
      print('  $v: ${g.node(v)['rank']} (${g.node(v)['rank'].runtimeType})');
    }
  }
} 