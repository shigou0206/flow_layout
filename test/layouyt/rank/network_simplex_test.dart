import 'package:flutter_test/flutter_test.dart';
import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/rank/network_simplex.dart';
import 'package:flow_layout/layout/utils.dart';
import 'package:flow_layout/layout/rank/utils.dart';

/// 1) ns(g) = networkSimplex(g) 然后 normalizeRanks(g)
void ns(Graph g) {
  networkSimplex(g);
  normalizeRanks(g);
}

/// 2) undirectedEdge(e)
///    返回一个 { "v": ..., "w": ... }，其中 "v" < "w"
Map<String, String> undirectedEdge(Edge e) {
  if (e.v.compareTo(e.w) < 0) {
    return {'v': e.v, 'w': e.w};
  } else {
    return {'v': e.w, 'w': e.v};
  }
}

void main() {
  late Graph g;
  late Graph gansnerGraph;
  late Graph gansnerTree;

  setUp(() {
    // 如果 Graph.setDefaultNodeLabel(...) 签名是 (String) => dynamic
    // 那么这里要写 (String _) => <String,dynamic>{}
    g = Graph(
      isMultigraph: true,
    )
      ..setDefaultNodeLabel((String _) => <String, dynamic>{})
      ..setDefaultEdgeLabel(
          (String _) => <String, dynamic>{'minlen': 1, 'weight': 1});

    gansnerGraph = Graph()
      ..setDefaultNodeLabel((_) => <String, dynamic>{})
      ..setDefaultEdgeLabel((_) => <String, dynamic>{'minlen': 1, 'weight': 1})
      ..setPath(["a", "b", "c", "d", "h"])
      ..setPath(["a", "e", "g", "h"])
      ..setPath(["a", "f", "g"]);

    gansnerTree = Graph(isDirected: false)
      ..setDefaultNodeLabel((_) => <String, dynamic>{})
      ..setDefaultEdgeLabel((_) => <String, dynamic>{})
      ..setPath(['a', 'b', 'c', 'd', 'h', 'g', 'e'])
      ..setEdge('g', 'f');
  });

  group('network simplex', () {
    test('can assign a rank to a single node', () {
      g.setNode("a");
      ns(g);

      // 期望: a 的 rank == 0
      expect(g.node("a")['rank'], equals(0),
          reason: 'A single node should be rank=0 by default');
    });

    test('can assign a rank to a 2-node connected graph', () {
      // 建一个只有 a->b 的小图
      g.setEdge("a", "b", {'minlen': 1, 'weight': 1});

      ns(g);

      // 期望 a=0, b=1
      expect(g.node("a")['rank'], equals(0));
      expect(g.node("b")['rank'], equals(1));
    });

    test('can assign ranks for a diamond', () {
      // diamond: a->b->d, a->c->d
      g.setPath(["a", "b", "d"], {'minlen': 1, 'weight': 1});
      g.setPath(["a", "c", "d"], {'minlen': 1, 'weight': 1});

      ns(g);

      expect(g.node("a")['rank'], equals(0));
      expect(g.node("b")['rank'], equals(1));
      expect(g.node("c")['rank'], equals(1));
      expect(g.node("d")['rank'], equals(2));
    });

    test('uses the minlen attribute on the edge', () {
      // g.setPath(["a","b","d"]) => a->b->d
      g.setPath(["a", "b", "d"], {'minlen': 1, 'weight': 1});
      // g.setEdge("a","c") => minlen=1 (default)
      g.setEdge("a", "c");
      // c->d, with minlen=2
      g.setEdge("c", "d", {'minlen': 2});

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
      g.setEdge("a", "e", {'weight': 2, 'minlen': 1});
      // 3) e->d => (weight=1, minlen=1 default)
      g.setEdge("e", "d");
      // 4) b->c => 这里是 multi-edge, labelKey= "multi", weight=1, minlen=2
      g.setEdge("b", "c", {'weight': 1, 'minlen': 2}, "multi");

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

  group('leaveEdge', () {
    test('returns null if there is no edge with a negative cutvalue', () {
      final tree = Graph(isDirected: false);
      tree.setEdge('a', 'b', {'cutvalue': 1});
      tree.setEdge('b', 'c', {'cutvalue': 1});

      final result = leaveEdge(tree);

      expect(result, isNull);
    });

    test('returns an edge if one is found with a negative cutvalue', () {
      final tree = Graph(isDirected: false);
      tree.setEdge('a', 'b', {'cutvalue': 1});
      tree.setEdge('b', 'c', {'cutvalue': -1});

      final result = leaveEdge(tree);

      expect(result, isNotNull);
      expect(result!.v, 'b');
      expect(result.w, 'c');
    });
  });

  group('enterEdge tests', () {
    late Graph g;
    late Graph t;

    setUp(() {
      g = Graph();
      t = Graph(isDirected: false);
    });

    Edge undirectedEdge(Edge e) {
      return Edge(
        e.v.compareTo(e.w) <= 0 ? e.v : e.w,
        e.v.compareTo(e.w) <= 0 ? e.w : e.v,
      );
    }

    test('finds an edge from the head to tail component', () {
      g.setNode('a', {'rank': 0});
      g.setNode('b', {'rank': 2});
      g.setNode('c', {'rank': 3});
      g.setPath(['a', 'b', 'c']);
      g.setEdge('a', 'c');

      t.setPath(['b', 'c', 'a']);
      initLowLimValues(t, 'c');

      final f = enterEdge(t, g, Edge('b', 'c'));
      expect(undirectedEdge(f!), undirectedEdge(Edge('a', 'b')));
    });

    test('works when the root of the tree is in the tail component', () {
      g.setNode('a', {'rank': 0});
      g.setNode('b', {'rank': 2});
      g.setNode('c', {'rank': 3});
      g.setPath(['a', 'b', 'c']);
      g.setEdge('a', 'c');

      t.setPath(['b', 'c', 'a']);
      initLowLimValues(t, 'b');

      final f = enterEdge(t, g, Edge('b', 'c'));
      expect(undirectedEdge(f!), undirectedEdge(Edge('a', 'b')));
    });

    test('finds the edge with the least slack', () {
      g
        ..setNode('a', {'rank': 0})
        ..setNode('b', {'rank': 1})
        ..setNode('c', {'rank': 3})
        ..setNode('d', {'rank': 4})
        ..setEdge('a', 'd')
        ..setPath(['a', 'c', 'd'])
        ..setEdge('b', 'c');

      t.setPath(['c', 'd', 'a', 'b']);
      initLowLimValues(t, 'a');

      final f = enterEdge(t, g, Edge('c', 'd'));
      expect(undirectedEdge(f!), undirectedEdge(Edge('b', 'c')));
    });

    test('finds an appropriate edge for gansner graph #1', () {
      g = gansnerGraph;
      t = gansnerTree;
      longestPath(g);
      initLowLimValues(t, 'a');

      final f = enterEdge(t, g, Edge('g', 'h'));
      expect(undirectedEdge(f!).v, equals('a'));
      expect(['e', 'f'], contains(undirectedEdge(f).w));
    });

    test('finds an appropriate edge for gansner graph #2', () {
      g = gansnerGraph;
      t = gansnerTree;
      longestPath(g);
      initLowLimValues(t, 'e');

      final f = enterEdge(t, g, Edge('g', 'h'));
      expect(undirectedEdge(f!).v, equals('a'));
      expect(['e', 'f'], contains(undirectedEdge(f).w));
    });

    test('finds an appropriate edge for gansner graph #3', () {
      g = gansnerGraph;
      t = gansnerTree;
      longestPath(g);
      initLowLimValues(t, 'a');

      final f = enterEdge(t, g, Edge('h', 'g'));
      expect(undirectedEdge(f!).v, equals('a'));
      expect(['e', 'f'], contains(undirectedEdge(f).w));
    });

    test('finds an appropriate edge for gansner graph #4', () {
      g = gansnerGraph;
      t = gansnerTree;
      longestPath(g);
      initLowLimValues(t, 'e');

      final f = enterEdge(t, g, Edge('h', 'g'));
      expect(undirectedEdge(f!).v, equals('a'));
      expect(['e', 'f'], contains(undirectedEdge(f).w));
    });
  });
  test("assigns low, lim, and parent for each node in a tree", () {
    var g = Graph()
        .setDefaultNodeLabel((_) => <String, dynamic>{}) // 关键修复在这里
        .setNodes(["a", "b", "c", "d", "e"]).setPath(
            ["a", "b", "a", "c", "d", "c", "e"]);

    initLowLimValues(g, "a");

    var a = g.node("a");
    var b = g.node("b");
    var c = g.node("c");
    var d = g.node("d");
    var e = g.node("e");

    expect(g.getNodes().map((v) => g.node(v)['lim']).toList()..sort(),
        equals([1, 2, 3, 4, 5]));

    expect(a['low'], equals(1));
    expect(a['lim'], equals(5));

    expect(b['parent'], equals("a"));
    expect(b['lim'] < a['lim'], isTrue);

    expect(c['parent'], equals("a"));
    expect(c['lim'] < a['lim'], isTrue);
    expect(c['lim'] != b['lim'], isTrue);

    expect(d['parent'], equals("c"));
    expect(d['lim'] < c['lim'], isTrue);

    expect(e['parent'], equals("c"));
    expect(e['lim'] < c['lim'], isTrue);
    expect(e['lim'] != d['lim'], isTrue);
  });
  group("exchangeEdges", () {
    late Graph g;
    late Graph t;

    setUp(() {
      g = gansnerGraph;
      t = gansnerTree;
      longestPath(g);
      initLowLimValues(t);
      initCutValues(t, g);
      print("=== BEFORE exchangeEdges ===");
      for (final v in t.getNodes()) {
        print(
            "Node $v: low=${t.node(v)['low']}, lim=${t.node(v)['lim']}, parent=${t.node(v)['parent']}");
      }
      for (final e in t.edges()) {
        final cv = t.edge(e)['cutvalue'];
        print("Edge ${e.v}-${e.w} initial cutvalue=$cv");
      }
      print("=============================");
    });

    test("exchanges edges and updates cut values and low/lim numbers", () {
      exchangeEdges(t, g, const Edge("g", "h", null, false),
          const Edge("a", "e", null, false));

      // Check new cut values
      expect(t.edge("a", "b")['cutvalue'], equals(2));
      expect(t.edge("b", "c")['cutvalue'], equals(2));
      expect(t.edge("c", "d")['cutvalue'], equals(2));
      expect(t.edge("d", "h")['cutvalue'], equals(2));
      expect(t.edge("a", "e")['cutvalue'], equals(1));
      expect(t.edge("e", "g")['cutvalue'], equals(1));
      expect(t.edge("g", "f")['cutvalue'], equals(0));

      // Ensure lim numbers are correct
      final lims = t.getNodes().map((v) => t.node(v)['lim'] as int).toList()
        ..sort();
      expect(lims, equals([1, 2, 3, 4, 5, 6, 7, 8]));
    });

    test("updates ranks", () {
      exchangeEdges(t, g, const Edge("g", "h", null, false),
          const Edge("a", "e", null, false));
      normalizeRanks(g);

      // Check new ranks
      expect(g.node("a")['rank'], equals(0));
      expect(g.node("b")['rank'], equals(1));
      expect(g.node("c")['rank'], equals(2));
      expect(g.node("d")['rank'], equals(3));
      expect(g.node("e")['rank'], equals(1));
      expect(g.node("f")['rank'], equals(1));
      expect(g.node("g")['rank'], equals(2));
      expect(g.node("h")['rank'], equals(4));
    });
  });
}
