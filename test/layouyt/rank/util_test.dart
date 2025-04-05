import 'package:flutter_test/flutter_test.dart';
import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/rank/utils.dart';
import 'package:flow_layout/layout/utils.dart';

void main() {
  group('rank/util', () {
    group('longestPath', () {
      late Graph g;

      setUp(() {
        // 新建一个有向图
        g = Graph(isDirected: true);

        // setDefaultNodeLabel(() => ({})) 等价
        // 这里可根据你Graph的实现思路
        g.setDefaultNodeLabel((String v) => <String,dynamic>{});
        // setDefaultEdgeLabel(() => ({ minlen: 1 }))
        g.setDefaultEdgeLabel((String v, String w, String? name) => {
          'minlen': 1
        });
      });

      test('can assign a rank to a single node graph', () {
        g.setNode('a');
        longestPath(g);
        normalizeRanks(g);
        expect(g.node('a')['rank'], equals(0));
      });

      test('can assign ranks to unconnected nodes', () {
        g.setNode('a');
        g.setNode('b');
        longestPath(g);
        normalizeRanks(g);
        expect(g.node('a')['rank'], equals(0));
        expect(g.node('b')['rank'], equals(0));
      });

      test('can assign ranks to connected nodes', () {
        // 仅 "a" -> "b"
        g.setEdge('a','b');
        longestPath(g);
        normalizeRanks(g);
        expect(g.node('a')['rank'], equals(0));
        expect(g.node('b')['rank'], equals(1));
      });

      test('can assign ranks for a diamond', () {
        // diamond:
        //   a -> b
        //   a -> c
        //   b -> d
        //   c -> d
        g.setPath(['a','b','d']);
        g.setPath(['a','c','d']);
        longestPath(g);
        normalizeRanks(g);
        expect(g.node('a')['rank'], equals(0));
        expect(g.node('b')['rank'], equals(1));
        expect(g.node('c')['rank'], equals(1));
        expect(g.node('d')['rank'], equals(2));
      });

      test('uses the minlen attribute on the edge', () {
        // a->b->d
        // a->c->d (with c->d minlen=2)
        g.setPath(['a','b','d']);
        g.setEdge('a','c'); // minlen=1 (default)
        g.setEdge('c','d', {'minlen':2}); 
        longestPath(g);
        normalizeRanks(g);

        expect(g.node('a')['rank'], equals(0));
        // longest path biases towards the "lowest rank it can assign" 
        // => so b gets rank=2, c=1, d=3
        expect(g.node('b')['rank'], equals(2));
        expect(g.node('c')['rank'], equals(1));
        expect(g.node('d')['rank'], equals(3));
      });
    });
  });
}