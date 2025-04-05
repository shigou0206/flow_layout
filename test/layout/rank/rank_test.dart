import 'package:flutter_test/flutter_test.dart';
import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/rank/rank.dart';
import 'package:flow_layout/layout/utils.dart';

void main() {
  final RANKERS = [
    'longest-path', 
    'tight-tree',
    'network-simplex', 
  ];
  
  group('rank', () {
    late Graph g;

    setUp(() {
      g = Graph()
        ..setGraph({})
        ..setDefaultNodeLabel((_) => {})
        ..setDefaultEdgeLabel((_, __, ___) => {'minlen': 1, 'weight': 1})
        ..setPath(['a', 'b', 'c', 'd', 'h'])
        ..setPath(['a', 'e', 'g', 'h'])
        ..setPath(['a', 'f', 'g']);
    });

    for (final ranker in RANKERS) {
      group(ranker, () {
        test('respects the minlen attribute', () {
          g.setGraph({'ranker': ranker});
          rank(g);
          
          for (final v in g.getNodes()) {
            expect(g.node(v).containsKey('rank'), isTrue, 
              reason: 'Node $v should have a rank assigned');
            expect(g.node(v)['rank'], isNotNull, 
              reason: 'Node $v rank should not be null');
          }
          
          for (final e in g.edges()) {
            final vRankValue = g.node(e['v'])['rank'];
            final wRankValue = g.node(e['w'])['rank'];
            
            expect(vRankValue, isNotNull, reason: 'Rank for node ${e["v"]} should not be null');
            expect(wRankValue, isNotNull, reason: 'Rank for node ${e["w"]} should not be null');
            
            // 将rank值转换为num类型
            final num vRank = vRankValue is num ? vRankValue : 0;
            final num wRank = wRankValue is num ? wRankValue : 0;
            
            final edgeData = g.edge(e) ?? {'minlen': 1, 'weight': 1};
            final minlen = edgeData['minlen'] is num ? edgeData['minlen'] as num : 1;
            
            expect(wRank - vRank >= minlen, isTrue, 
              reason: 'Edge ${e['v']}->${e['w']} has rank diff ${wRank - vRank} < minlen $minlen');
          }
        });

        test('can rank a single node graph', () {
          final singleNodeGraph = Graph()
            ..setGraph({'ranker': ranker})
            ..setNode('a', {});
            
          rank(singleNodeGraph);
          
          expect(singleNodeGraph.node('a').containsKey('rank'), isTrue,
            reason: 'Node a should have a rank assigned');
          expect(singleNodeGraph.node('a')['rank'], isIn([0, 0.0]),
            reason: 'Node a should have rank 0 (int or double)');
        });
      });
    }

    test('uses the minlen attribute on edges', () {
      g = Graph()
        ..setGraph({})
        ..setDefaultNodeLabel((_) => {})
        ..setDefaultEdgeLabel((_, __, ___) => {'minlen': 1, 'weight': 1});
        
      g.setEdge('a', 'b', {'minlen': 2});
      g.setEdge('b', 'c', {'minlen': 1});
      
      rank(g);
      normalizeRanks(g);
      
      expect(g.node('a')['rank'], isIn([0, 0.0]));
      expect(g.node('b')['rank'], isIn([2, 2.0]));
      expect(g.node('c')['rank'], isIn([3, 3.0]));
    });

    test('can handle a diamond graph', () {
      g = Graph()
        ..setGraph({})
        ..setDefaultNodeLabel((_) => {})
        ..setDefaultEdgeLabel((_, __, ___) => {'minlen': 1, 'weight': 1});
        
      g.setPath(['a', 'b', 'd']);
      g.setPath(['a', 'c', 'd']);
      
      rank(g);
      normalizeRanks(g);
      
      expect(g.node('a')['rank'], isIn([0, 0.0]));
      expect(g.node('b')['rank'], isIn([1, 1.0]));
      expect(g.node('c')['rank'], isIn([1, 1.0]));
      expect(g.node('d')['rank'], isIn([2, 2.0]));
    });

    test('properly handles multi-edges', () {
      g = Graph(isMultigraph: true)
        ..setGraph({})
        ..setDefaultNodeLabel((_) => {})
        ..setDefaultEdgeLabel((_, __, ___) => {'minlen': 1, 'weight': 1});
        
      g.setEdge('a', 'b', {'weight': 2, 'minlen': 1});
      g.setEdge('a', 'b', {'weight': 1, 'minlen': 2}, 'multi');
      
      rank(g);
      normalizeRanks(g);
      
      expect(g.node('a')['rank'], isIn([0, 0.0]));
      // The rank difference should respect the maximum minlen between the multi-edges
      expect(g.node('b')['rank'], isIn([2, 2.0]));
    });
  });
}