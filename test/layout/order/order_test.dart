import 'package:flutter_test/flutter_test.dart';
import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/order/layout_order.dart';
import 'package:flow_layout/layout/order/cross_count.dart';
import 'package:flow_layout/layout/utils.dart' as util;

void main() {
  late Graph g;

  setUp(() {
    g = Graph()..setDefaultEdgeLabel({'weight': 1});
  });

  test("does not add crossings to a tree structure", () {
    g.setNode("a", {"rank": 1});
    for (var v in ["b", "e"]) {
      g.setNode(v, {"rank": 2});
    }
    for (var v in ["c", "d", "f"]) {
      g.setNode(v, {"rank": 3});
    }

    g.setPath(["a", "b", "c"]);
    g.setEdge("b", "d");
    g.setPath(["a", "e", "f"]);

    order(g);
    final layering = util.buildLayerMatrix(g);
    expect(crossCount(g, layering), equals(0));
  });

  test("can solve a simple graph", () {
    for (var v in ["a", "d"]) {
      g.setNode(v, {"rank": 1});
    }
    for (var v in ["b", "f", "e"]) {
      g.setNode(v, {"rank": 2});
    }
    for (var v in ["c", "g"]) {
      g.setNode(v, {"rank": 3});
    }

    order(g);
    final layering = util.buildLayerMatrix(g);
    expect(crossCount(g, layering), equals(0));
  });

  test("can minimize crossings", () {
    g.setNode("a", {"rank": 1});
    for (var v in ["b", "e", "g"]) {
      g.setNode(v, {"rank": 2});
    }
    for (var v in ["c", "f", "h"]) {
      g.setNode(v, {"rank": 3});
    }
    g.setNode("d", {"rank": 4});

    order(g);
    final layering = util.buildLayerMatrix(g);
    expect(crossCount(g, layering), lessThanOrEqualTo(1));
  });

  test('can skip the optimal ordering', () {
    g.setNode("a", {"rank": 1});
    for (var v in ["b", "d"]) {
      g.setNode(v, {"rank": 2});
    }
    for (var v in ["c", "e"]) {
      g.setNode(v, {"rank": 3});
    }

    g.setPath(["a", "b", "c"]);
    g.setPath(["a", "d"]);
    g.setEdge("b", "e");
    g.setEdge("d", "c");

    order(g, disableOptimalOrderHeuristic: true);
    final layering = util.buildLayerMatrix(g);
    expect(crossCount(g, layering), equals(1));
  });
}
