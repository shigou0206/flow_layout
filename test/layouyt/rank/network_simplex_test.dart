import 'package:flutter_test/flutter_test.dart';
import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/rank/network_simplex.dart';
import 'package:flow_layout/layout/utils.dart';

/// 1) ns(g) = networkSimplex(g) 然后 normalizeRanks(g)
void ns(Graph g) {
  networkSimplex(g);
  normalizeRanks(g);
}

/// 2) undirectedEdge(e)
///    返回一个 { "v": ..., "w": ... }，其中 "v" < "w"
Map<String, String> undirectedEdge(Edge e) {
  if (e.v.compareTo(e.w) < 0) {
    return { 'v': e.v, 'w': e.w };
  } else {
    return { 'v': e.w, 'w': e.v };
  }
}

void main() {
  group('network simplex', () {
    late Graph g;
    late Graph gansnerGraph;
    setUp(() {
      // 如果 Graph.setDefaultNodeLabel(...) 签名是 (String) => dynamic
      // 那么这里要写 (String _) => <String,dynamic>{}
      g = Graph(
        isMultigraph:true,
      )
        ..setDefaultNodeLabel((String _) => <String,dynamic>{})
        ..setDefaultEdgeLabel((String _) => <String,dynamic>{
          'minlen': 1,
          'weight': 1
        });

      gansnerGraph = Graph()
        ..setDefaultNodeLabel((_) => <String,dynamic>{})
        ..setDefaultEdgeLabel((_) => <String,dynamic>{ 'minlen': 1, 'weight': 1 })
        ..setPath(["a", "b", "c", "d", "h"])
        ..setPath(["a", "e", "g", "h"])
        ..setPath(["a", "f", "g"]);
    });

    test('can assign a rank to a single node', () {
      g.setNode("a"); 
      ns(g);

      // 期望: a 的 rank == 0
      expect(g.node("a")['rank'], equals(0),
        reason: 'A single node should be rank=0 by default');
    });

    test('can assign a rank to a 2-node connected graph', () {
      // 建一个只有 a->b 的小图
      g.setEdge("a", "b", { 'minlen': 1, 'weight': 1 });

      ns(g);

      // 期望 a=0, b=1
      expect(g.node("a")['rank'], equals(0));
      expect(g.node("b")['rank'], equals(1));
    });

    test('can assign ranks for a diamond', () {
      // diamond: a->b->d, a->c->d
      g.setPath(["a", "b", "d"], { 'minlen': 1, 'weight': 1 });
      g.setPath(["a", "c", "d"], { 'minlen': 1, 'weight': 1 });

      ns(g);

      expect(g.node("a")['rank'], equals(0));
      expect(g.node("b")['rank'], equals(1));
      expect(g.node("c")['rank'], equals(1));
      expect(g.node("d")['rank'], equals(2));
    });

        test('uses the minlen attribute on the edge', () {
      // g.setPath(["a","b","d"]) => a->b->d
      g.setPath(["a", "b", "d"], { 'minlen': 1, 'weight': 1 });
      // g.setEdge("a","c") => minlen=1 (default)
      g.setEdge("a", "c");
      // c->d, with minlen=2
      g.setEdge("c", "d", { 'minlen': 2 });

      ns(g);

      expect(g.node("a")['rank'], equals(0));

      // JS 注释: longest path biases ... 
      // a->b->d => b rank=2, c=1, d=3
      // let's confirm
      expect(g.node("b")['rank'], equals(2));
      expect(g.node("c")['rank'], equals(1));
      expect(g.node("d")['rank'], equals(3));
    });

    test('can rank the gansner graph', () {
      // 这里把g替换为gansnerGraph
      g = gansnerGraph;

      ns(g);

      // JS 里的期望
      expect(g.node("a")['rank'], 0);
      expect(g.node("b")['rank'], 1);
      expect(g.node("c")['rank'], 2);
      expect(g.node("d")['rank'], 3);
      expect(g.node("h")['rank'], 4);
      expect(g.node("e")['rank'], 1);
      expect(g.node("f")['rank'], 1);
      expect(g.node("g")['rank'], 2);
    });

    test('can handle multi-edges', () {
      // 1) setPath(["a","b","c","d"]) => a->b, b->c, c->d
      g.setPath(["a", "b", "c", "d"]);
      // 2) a->e => weight=2, minlen=1
      g.setEdge("a", "e", { 'weight': 2, 'minlen': 1 });
      // 3) e->d => (weight=1, minlen=1 default)
      g.setEdge("e", "d");
      // 4) b->c => 这里是 multi-edge, labelKey= "multi", weight=1, minlen=2
      g.setEdge("b", "c", { 'weight': 1, 'minlen': 2 }, "multi");

      ns(g);

      // JS 里的预期:
      expect(g.node("a")['rank'], 0);
      expect(g.node("b")['rank'], 1);

      // b->c has minlen=2 (due to multi-edge), so c应当 2 ranks 之后 => rank=3
      expect(g.node("c")['rank'], 3);
      expect(g.node("d")['rank'], 4);

      // e => 1
      expect(g.node("e")['rank'], 1);
    });
  });
}