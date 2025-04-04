import 'package:flutter_test/flutter_test.dart';
import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/order/order.dart';
import 'package:flow_layout/layout/order/cross_count.dart';
import 'package:flow_layout/layout/utils.dart' as util;

void main() {
  late Graph g;

  setUp(() {
    g = Graph()..setDefaultEdgeLabel({'weight': 1});
  });

  test("does not add crossings to a tree structure", () {
    g.setNode("a", {"rank": 1});
    ["b", "e"].forEach((v) => g.setNode(v, {"rank": 2}));
    ["c", "d", "f"].forEach((v) => g.setNode(v, {"rank": 3}));

    g.setPath(["a", "b", "c"]);
    g.setEdge("b", "d");
    g.setPath(["a", "e", "f"]);

    order(g);
    final layering = util.buildLayerMatrix(g);
    expect(crossCount(g, layering), equals(0));
  });

  test("can solve a simple graph", () {
    ["a", "d"].forEach((v) => g.setNode(v, {"rank": 1}));
    ["b", "f", "e"].forEach((v) => g.setNode(v, {"rank": 2}));
    ["c", "g"].forEach((v) => g.setNode(v, {"rank": 3}));

    order(g);
    final layering = util.buildLayerMatrix(g);
    expect(crossCount(g, layering), equals(0));
  });

  test("can minimize crossings", () {
    g.setNode("a", {"rank": 1});
    ["b", "e", "g"].forEach((v) => g.setNode(v, {"rank": 2}));
    ["c", "f", "h"].forEach((v) => g.setNode(v, {"rank": 3}));
    g.setNode("d", {"rank": 4});

    order(g);
    final layering = util.buildLayerMatrix(g);
    expect(crossCount(g, layering), lessThanOrEqualTo(1));
  });

  test('can skip the optimal ordering', () {
    g.setNode("a", {"rank": 1});
    ["b", "d"].forEach((v) => g.setNode(v, {"rank": 2}));
    ["c", "e"].forEach((v) => g.setNode(v, {"rank": 3}));

    g.setPath(["a", "b", "c"]);
    g.setPath(["a", "d"]);
    g.setEdge("b", "e");
    g.setEdge("d", "c");

    order(g, disableOptimalOrderHeuristic: true);
    final layering = util.buildLayerMatrix(g);
    expect(crossCount(g, layering), equals(1));
  });
}
