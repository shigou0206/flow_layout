import 'package:flutter_test/flutter_test.dart';
import 'package:flow_layout/graph/graph.dart';
import 'package:flow_layout/layout/utils.dart'; // 假定其中包含 buildLayerMatrix 等工具函数
import 'package:flow_layout/layout/position/bk.dart' as bk;

void main() {
  group('position/bk', () {
    late Graph g;

    setUp(() {
      // 新建 Graph 实例并设置图属性为空 Map
      g = Graph()..setGraph({});
    });

    group('findType1Conflicts', () {
      late List<List<String>> layering;

      setUp(() {
        // 设置默认边标签函数
        g.setDefaultEdgeLabel(() => {});
        // 添加节点（使用 <String, dynamic> 以允许动态添加属性）
        g
          ..setNode("a", <String, dynamic>{"rank": 0, "order": 0})
          ..setNode("b", <String, dynamic>{"rank": 0, "order": 1})
          ..setNode("c", <String, dynamic>{"rank": 1, "order": 0})
          ..setNode("d", <String, dynamic>{"rank": 1, "order": 1})
          // 设置交叉边： a->d 与 b->c
          ..setEdge("a", "d")
          ..setEdge("b", "c");

        // 根据图构造层次矩阵
        layering = buildLayerMatrix(g);
      });

      test("does not mark edges that have no conflict", () {
        // 移除交叉边，换成平行边 a->c 与 b->d
        g.removeEdge("a", "d");
        g.removeEdge("b", "c");
        g
          ..setEdge("a", "c")
          ..setEdge("b", "d");

        final conflicts = bk.findType1Conflicts(g, layering);
        expect(bk.hasConflict(conflicts, "a", "c"), isFalse);
        expect(bk.hasConflict(conflicts, "b", "d"), isFalse);
      });

      test("does not mark type-0 conflicts (no dummies)", () {
        final conflicts = bk.findType1Conflicts(g, layering);
        expect(bk.hasConflict(conflicts, "a", "d"), isFalse);
        expect(bk.hasConflict(conflicts, "b", "c"), isFalse);
      });

      // 对于每个节点，将其标记为 dummy，测试不会标记冲突
      for (var v in ["a", "b", "c", "d"]) {
        test("does not mark type-0 conflicts ($v is dummy)", () {
          g.node(v)?["dummy"] = true;
          final conflicts = bk.findType1Conflicts(g, layering);
          expect(bk.hasConflict(conflicts, "a", "d"), isFalse);
          expect(bk.hasConflict(conflicts, "b", "c"), isFalse);
        });
      }

      // 对于每个节点，当其它节点均标记为 dummy 时，测试不同的对齐情况
      for (var v in ["a", "b", "c", "d"]) {
        test("does mark type-1 conflicts ($v is non-dummy)", () {
          // 对除 v 外的所有节点，都设置 dummy 为 true
          for (var w in ["a", "b", "c", "d"]) {
            if (v != w) {
              g.node(w)?["dummy"] = true;
            }
          }

          final conflicts = bk.findType1Conflicts(g, layering);
          if (v == "a" || v == "d") {
            expect(bk.hasConflict(conflicts, "a", "d"), isTrue);
            expect(bk.hasConflict(conflicts, "b", "c"), isFalse);
          } else {
            expect(bk.hasConflict(conflicts, "a", "d"), isFalse);
            expect(bk.hasConflict(conflicts, "b", "c"), isTrue);
          }
        });
      }

      test("does not mark type-2 conflicts (all dummies)", () {
        // 所有节点均设置 dummy 为 true
        for (var v in ["a", "b", "c", "d"]) {
          g.node(v)?["dummy"] = true;
        }
        final conflicts = bk.findType1Conflicts(g, layering);
        expect(bk.hasConflict(conflicts, "a", "d"), isFalse);
        expect(bk.hasConflict(conflicts, "b", "c"), isFalse);
        // 额外调用一次确保函数能正常执行
        bk.findType1Conflicts(g, layering);
      });
    });
  });

  group('position/bk', () {
    late Graph g;

    setUp(() {
      g = Graph()..setGraph({});
    });

    group('findType2Conflicts', () {
      late List<List<String>> layering;

      setUp(() {
        g
          ..setDefaultEdgeLabel(() => {})
          ..setNode("a", <String, dynamic>{"rank": 0, "order": 0})
          ..setNode("b", <String, dynamic>{"rank": 0, "order": 1})
          ..setNode("c", <String, dynamic>{"rank": 1, "order": 0})
          ..setNode("d", <String, dynamic>{"rank": 1, "order": 1})
          // 设置交叉边 a->d 与 b->c
          ..setEdge("a", "d")
          ..setEdge("b", "c");

        layering = buildLayerMatrix(g);
      });

      test("marks type-2 conflicts favoring border segments #1", () {
        // 对 "a" 与 "d" 设置 dummy 为 true
        for (var v in ["a", "d"]) {
          g.node(v)?["dummy"] = true;
        }
        // 对 "b" 与 "c" 设置 dummy 为 "border"
        for (var v in ["b", "c"]) {
          g.node(v)?["dummy"] = "border";
        }
        final conflicts = bk.findType2Conflicts(g, layering);
        expect(bk.hasConflict(conflicts, "a", "d"), isTrue);
        expect(bk.hasConflict(conflicts, "b", "c"), isFalse);
        // 调用一次 findType1Conflicts 以确保函数正常运行
        bk.findType1Conflicts(g, layering);
      });

      test("marks type-2 conflicts favoring border segments #2", () {
        // 对 "b" 与 "c" 设置 dummy 为 true
        for (var v in ["b", "c"]) {
          g.node(v)?["dummy"] = true;
        }
        // 对 "a" 与 "d" 设置 dummy 为 "border"
        for (var v in ["a", "d"]) {
          g.node(v)?["dummy"] = "border";
        }
        final conflicts = bk.findType2Conflicts(g, layering);
        expect(bk.hasConflict(conflicts, "a", "d"), isFalse);
        expect(bk.hasConflict(conflicts, "b", "c"), isTrue);
        bk.findType1Conflicts(g, layering);
      });
    });

    group('hasConflict', () {
      test("can test for a type-1 conflict regardless of edge orientation", () {
        final conflicts = <String, Map<String, bool>>{};
        bk.addConflict(conflicts, "b", "a");
        expect(bk.hasConflict(conflicts, "a", "b"), isTrue);
        expect(bk.hasConflict(conflicts, "b", "a"), isTrue);
      });

      test("works for multiple conflicts with the same node", () {
        final conflicts = <String, Map<String, bool>>{};
        bk.addConflict(conflicts, "a", "b");
        bk.addConflict(conflicts, "a", "c");
        expect(bk.hasConflict(conflicts, "a", "b"), isTrue);
        expect(bk.hasConflict(conflicts, "a", "c"), isTrue);
      });
    });

    group('verticalAlignment', () {
      test("Aligns with itself if the node has no adjacencies", () {
        g.setNode("a", <String, dynamic>{"rank": 0, "order": 0});
        g.setNode("b", <String, dynamic>{"rank": 1, "order": 0});
        final layering = buildLayerMatrix(g);
        final conflicts = <String, Map<String, bool>>{};
        final result = bk.verticalAlignment(
            g, layering, conflicts, (String v) => g.predecessors(v) ?? []);
        expect(result.root, equals({"a": "a", "b": "b"}));
        expect(result.align, equals({"a": "a", "b": "b"}));
      });

      test("Aligns with its sole adjacency", () {
        g.setNode("a", <String, dynamic>{"rank": 0, "order": 0});
        g.setNode("b", <String, dynamic>{"rank": 1, "order": 0});
        g.setEdge("a", "b");
        final layering = buildLayerMatrix(g);
        final conflicts = <String, Map<String, bool>>{};
        final result = bk.verticalAlignment(
            g, layering, conflicts, (String v) => g.predecessors(v) ?? []);
        expect(result.root, equals({"a": "a", "b": "a"}));
        expect(result.align, equals({"a": "b", "b": "a"}));
      });

      test("aligns with its left median when possible", () {
        g.setNode("a", <String, dynamic>{"rank": 0, "order": 0});
        g.setNode("b", <String, dynamic>{"rank": 0, "order": 1});
        g.setNode("c", <String, dynamic>{"rank": 1, "order": 0});
        g.setEdge("a", "c");
        g.setEdge("b", "c");
        final layering = buildLayerMatrix(g);
        final conflicts = <String, Map<String, bool>>{};
        final result = bk.verticalAlignment(
            g, layering, conflicts, (String v) => g.predecessors(v) ?? []);
        expect(result.root, equals({"a": "a", "b": "b", "c": "a"}));
        expect(result.align, equals({"a": "c", "b": "b", "c": "a"}));
      });

      test("aligns correctly regardless of node name/insertion order", () {
        // 注意：本测试确保在搜索相邻候选节点时，节点按 order 排序
        g.setNode("b", <String, dynamic>{"rank": 0, "order": 1});
        g.setNode("c", <String, dynamic>{"rank": 1, "order": 0});
        g.setNode("z", <String, dynamic>{"rank": 0, "order": 0});
        g.setEdge("z", "c");
        g.setEdge("b", "c");
        final layering = buildLayerMatrix(g);
        final conflicts = <String, Map<String, bool>>{};
        final result = bk.verticalAlignment(
            g, layering, conflicts, (String v) => g.predecessors(v) ?? []);
        // 期望 z 的 block 为 z，自身对齐，c 与 z 对齐
        expect(result.root, equals({"z": "z", "b": "b", "c": "z"}));
        expect(result.align, equals({"z": "c", "b": "b", "c": "z"}));
      });

      test("aligns with its right median when left is unavailable", () {
        g.setNode("a", <String, dynamic>{"rank": 0, "order": 0});
        g.setNode("b", <String, dynamic>{"rank": 0, "order": 1});
        g.setNode("c", <String, dynamic>{"rank": 1, "order": 0});
        g.setEdge("a", "c");
        g.setEdge("b", "c");
        final layering = buildLayerMatrix(g);
        final conflicts = <String, Map<String, bool>>{};
        bk.addConflict(conflicts, "a", "c");
        final result = bk.verticalAlignment(
            g, layering, conflicts, (String v) => g.predecessors(v) ?? []);
        expect(result.root, equals({"a": "a", "b": "b", "c": "b"}));
        expect(result.align, equals({"a": "a", "b": "c", "c": "b"}));
      });

      test("aligns with neither median if both are unavailable", () {
        g.setNode("a", <String, dynamic>{"rank": 0, "order": 0});
        g.setNode("b", <String, dynamic>{"rank": 0, "order": 1});
        g.setNode("c", <String, dynamic>{"rank": 1, "order": 0});
        g.setNode("d", <String, dynamic>{"rank": 1, "order": 1});
        g.setEdge("a", "d");
        g.setEdge("b", "c");
        g.setEdge("b", "d");
        final layering = buildLayerMatrix(g);
        final conflicts = <String, Map<String, bool>>{};
        final result = bk.verticalAlignment(
            g, layering, conflicts, (String v) => g.predecessors(v) ?? []);
        // 此处：c 与 b 对齐，因此 d 无法与 a 对齐，因为 (a,d) 与 (c,b) 交叉
        expect(result.root, equals({"a": "a", "b": "b", "c": "b", "d": "d"}));
        expect(result.align, equals({"a": "a", "b": "c", "c": "b", "d": "d"}));
      });

      test("aligns with the single median for an odd number of adjacencies",
          () {
        g.setNode("a", <String, dynamic>{"rank": 0, "order": 0});
        g.setNode("b", <String, dynamic>{"rank": 0, "order": 1});
        g.setNode("c", <String, dynamic>{"rank": 0, "order": 2});
        g.setNode("d", <String, dynamic>{"rank": 1, "order": 0});
        g.setEdge("a", "d");
        g.setEdge("b", "d");
        g.setEdge("c", "d");
        final layering = buildLayerMatrix(g);
        final conflicts = <String, Map<String, bool>>{};
        final result = bk.verticalAlignment(
            g, layering, conflicts, (String v) => g.predecessors(v) ?? []);
        expect(result.root, equals({"a": "a", "b": "b", "c": "c", "d": "b"}));
        expect(result.align, equals({"a": "a", "b": "d", "c": "c", "d": "b"}));
      });

      test("aligns blocks across multiple layers", () {
        g.setNode("a", <String, dynamic>{"rank": 0, "order": 0});
        g.setNode("b", <String, dynamic>{"rank": 1, "order": 0});
        g.setNode("c", <String, dynamic>{"rank": 1, "order": 1});
        g.setNode("d", <String, dynamic>{"rank": 2, "order": 0});
        g.setPath(["a", "b", "d"]);
        g.setPath(["a", "c", "d"]);
        final layering = buildLayerMatrix(g);
        final conflicts = <String, Map<String, bool>>{};
        final result = bk.verticalAlignment(
            g, layering, conflicts, (String v) => g.predecessors(v) ?? []);
        expect(result.root, equals({"a": "a", "b": "a", "c": "c", "d": "a"}));
        expect(result.align, equals({"a": "b", "b": "d", "c": "c", "d": "a"}));
      });
    });
  });

  group('horizontalCompaction', () {
    late Graph g;

    setUp(() {
      g = Graph()..setGraph({});
    });

    test("places the center of a single node graph at origin (0,0)", () {
      final root = {"a": "a"};
      final align = {"a": "a"};
      g.setNode("a", <String, dynamic>{"rank": 0, "order": 0});
      final xs =
          bk.horizontalCompaction(g, buildLayerMatrix(g), root, align, false);
      expect(xs["a"], equals(0));
    });

    test("separates adjacent nodes by specified node separation", () {
      final root = {"a": "a", "b": "b"};
      final align = {"a": "a", "b": "b"};
      // 设置图属性 nodesep
      g.graph()["nodesep"] = 100;
      g.setNode("a", <String, dynamic>{"rank": 0, "order": 0, "width": 100});
      g.setNode("b", <String, dynamic>{"rank": 0, "order": 1, "width": 200});
      final xs =
          bk.horizontalCompaction(g, buildLayerMatrix(g), root, align, false);
      expect(xs["a"], equals(0));
      // 计算期望值：100/2 + 100 + 200/2 = 50 + 100 + 100 = 250
      expect(xs["b"], equals(250));
    });

    test("separates adjacent edges by specified node separation", () {
      final root = {"a": "a", "b": "b"};
      final align = {"a": "a", "b": "b"};
      // 设置图属性 edgesep
      g.graph()["edgesep"] = 20;
      g.setNode("a", <String, dynamic>{
        "rank": 0,
        "order": 0,
        "width": 100,
        "dummy": true
      });
      g.setNode("b", <String, dynamic>{
        "rank": 0,
        "order": 1,
        "width": 200,
        "dummy": true
      });
      final xs =
          bk.horizontalCompaction(g, buildLayerMatrix(g), root, align, false);
      expect(xs["a"], equals(0));
      // 期望值：100/2 + 20 + 200/2 = 50 + 20 + 100 = 170
      expect(xs["b"], equals(170));
    });

    test("aligns the centers of nodes in the same block", () {
      // 两个节点处于同一 block，要求最终 x 坐标一致
      final root = {"a": "a", "b": "a"};
      final align = {"a": "b", "b": "a"};
      g.setNode("a", <String, dynamic>{"rank": 0, "order": 0, "width": 100});
      g.setNode("b", <String, dynamic>{"rank": 1, "order": 0, "width": 200});
      final xs =
          bk.horizontalCompaction(g, buildLayerMatrix(g), root, align, false);
      expect(xs["a"], equals(0));
      expect(xs["b"], equals(0));
    });

    test("separates blocks with the appropriate separation", () {
      final root = {"a": "a", "b": "a", "c": "c"};
      final align = {"a": "b", "b": "a", "c": "c"};
      g.graph()["nodesep"] = 75;
      g.setNode("a", <String, dynamic>{"rank": 0, "order": 0, "width": 100});
      g.setNode("b", <String, dynamic>{"rank": 1, "order": 1, "width": 200});
      g.setNode("c", <String, dynamic>{"rank": 1, "order": 0, "width": 50});
      final xs =
          bk.horizontalCompaction(g, buildLayerMatrix(g), root, align, false);
      // 期望值：对于 block a-b，右侧中心位置为 100/2 + 75 + 200/2 = 50+75+100 = 225；
      // c 居左，坐标为 0
      expect(xs["a"], equals(225));
      expect(xs["b"], equals(225));
      expect(xs["c"], equals(0));
    });

    test("separates classes with the appropriate separation", () {
      final root = {"a": "a", "b": "b", "c": "c", "d": "b"};
      final align = {"a": "a", "b": "d", "c": "c", "d": "b"};
      g.graph()["nodesep"] = 75;
      g.setNode("a", <String, dynamic>{"rank": 0, "order": 0, "width": 100});
      g.setNode("b", <String, dynamic>{"rank": 0, "order": 1, "width": 200});
      g.setNode("c", <String, dynamic>{"rank": 1, "order": 0, "width": 50});
      g.setNode("d", <String, dynamic>{"rank": 1, "order": 1, "width": 80});
      final xs =
          bk.horizontalCompaction(g, buildLayerMatrix(g), root, align, false);
      // 期望值：
      // xs.a = 100/2 + 75 + 200/2 = 50 + 75 + 100 = 225
      // xs.b = 225
      // xs.c = 225 - 80/2 - 75 - 50/2 = 225 - 40 - 75 - 25 = 85
      // xs.d = 225
      expect(xs["a"], equals(225));
      expect(xs["b"], equals(225));
      expect(xs["c"], equals(85));
      expect(xs["d"], equals(225));
    });

    test("shifts classes by max sep from the adjacent block #1", () {
      final root = {"a": "a", "b": "b", "c": "a", "d": "b"};
      final align = {"a": "c", "b": "d", "c": "a", "d": "b"};
      g.graph()["nodesep"] = 75;
      g.setNode("a", <String, dynamic>{"rank": 0, "order": 0, "width": 50});
      g.setNode("b", <String, dynamic>{"rank": 0, "order": 1, "width": 150});
      g.setNode("c", <String, dynamic>{"rank": 1, "order": 0, "width": 60});
      g.setNode("d", <String, dynamic>{"rank": 1, "order": 1, "width": 70});
      final xs =
          bk.horizontalCompaction(g, buildLayerMatrix(g), root, align, false);
      expect(xs["a"], equals(0));
      // 期望 xs.b = 50/2 + 75 + 150/2 = 25 + 75 + 75 = 175
      expect(xs["b"], equals(175));
      expect(xs["c"], equals(0));
      expect(xs["d"], equals(175));
    });

    test("shifts classes by max sep from the adjacent block #2", () {
      final root = {"a": "a", "b": "b", "c": "a", "d": "b"};
      final align = {"a": "c", "b": "d", "c": "a", "d": "b"};
      g.graph()["nodesep"] = 75;
      g.setNode("a", <String, dynamic>{"rank": 0, "order": 0, "width": 50});
      g.setNode("b", <String, dynamic>{"rank": 0, "order": 1, "width": 70});
      g.setNode("c", <String, dynamic>{"rank": 1, "order": 0, "width": 60});
      g.setNode("d", <String, dynamic>{"rank": 1, "order": 1, "width": 150});
      final xs =
          bk.horizontalCompaction(g, buildLayerMatrix(g), root, align, false);
      // 期望 xs.b = 60/2 + 75 + 150/2 = 30 + 75 + 75 = 180
      expect(xs["a"], equals(0));
      expect(xs["b"], equals(180));
      expect(xs["c"], equals(0));
      expect(xs["d"], equals(180));
    });

    test("cascades class shift", () {
      final root = {
        "a": "a",
        "b": "b",
        "c": "c",
        "d": "d",
        "e": "b",
        "f": "f",
        "g": "d"
      };
      final align = {
        "a": "a",
        "b": "e",
        "c": "c",
        "d": "g",
        "e": "b",
        "f": "f",
        "g": "d"
      };
      g.graph()["nodesep"] = 75;
      g.setNode("a", <String, dynamic>{"rank": 0, "order": 0, "width": 50});
      g.setNode("b", <String, dynamic>{"rank": 0, "order": 1, "width": 50});
      g.setNode("c", <String, dynamic>{"rank": 1, "order": 0, "width": 50});
      g.setNode("d", <String, dynamic>{"rank": 1, "order": 1, "width": 50});
      g.setNode("e", <String, dynamic>{"rank": 1, "order": 2, "width": 50});
      g.setNode("f", <String, dynamic>{"rank": 2, "order": 0, "width": 50});
      g.setNode("g", <String, dynamic>{"rank": 2, "order": 1, "width": 50});
      final xs =
          bk.horizontalCompaction(g, buildLayerMatrix(g), root, align, false);
      // 此处测试以 f 为 0，其他节点相对 f 计算
      // 由于各个 block 的中心会按照最大分隔值平移，测试中我们根据相对关系做断言
      expect(xs["a"], equals(xs["b"]! - 50 / 2 - 75 - 50 / 2));
      expect(xs["b"], equals(xs["e"]!));
      expect(xs["c"], equals(xs["f"]!));
      expect(xs["d"], equals(xs["c"]! + 50 / 2 + 75 + 50 / 2));
      expect(xs["e"], equals(xs["d"]! + 50 / 2 + 75 + 50 / 2));
      expect(xs["g"], equals(xs["f"]! + 50 / 2 + 75 + 50 / 2));
    });

    test("handles labelpos = l", () {
      final root = {"a": "a", "b": "b", "c": "c"};
      final align = {"a": "a", "b": "b", "c": "c"};
      g.graph()["edgesep"] = 50;
      g.setNode("a", <String, dynamic>{
        "rank": 0,
        "order": 0,
        "width": 100,
        "dummy": "edge"
      });
      g.setNode("b", <String, dynamic>{
        "rank": 0,
        "order": 1,
        "width": 200,
        "dummy": "edge-label",
        "labelpos": "l"
      });
      g.setNode("c", <String, dynamic>{
        "rank": 0,
        "order": 2,
        "width": 300,
        "dummy": "edge"
      });
      final xs =
          bk.horizontalCompaction(g, buildLayerMatrix(g), root, align, false);
      expect(xs["a"], equals(0));
      // 期望 xs.b = xs.a + 100/2 + 50 + 200 = 50 + 50 + 200 = 300
      expect(xs["b"], equals(300));
      // xs.c = xs.b + 0 + 50 + 300/2 = 300 + 0 + 50 + 150 = 500
      expect(xs["c"], equals(500));
    });

    test("handles labelpos = c", () {
      final root = {"a": "a", "b": "b", "c": "c"};
      final align = {"a": "a", "b": "b", "c": "c"};
      g.graph()["edgesep"] = 50;
      g.setNode("a", <String, dynamic>{
        "rank": 0,
        "order": 0,
        "width": 100,
        "dummy": "edge"
      });
      g.setNode("b", <String, dynamic>{
        "rank": 0,
        "order": 1,
        "width": 200,
        "dummy": "edge-label",
        "labelpos": "c"
      });
      g.setNode("c", <String, dynamic>{
        "rank": 0,
        "order": 2,
        "width": 300,
        "dummy": "edge"
      });
      final xs =
          bk.horizontalCompaction(g, buildLayerMatrix(g), root, align, false);
      expect(xs["a"], equals(0));
      // xs.b = xs.a + 100/2 + 50 + 200/2 = 50 + 50 + 100 = 200
      expect(xs["b"], equals(200));
      // xs.c = xs.b + 200/2 + 50 + 300/2 = 200 + 100 + 50 + 150 = 500
      expect(xs["c"], equals(500));
    });

    test("handles labelpos = r", () {
      final root = {"a": "a", "b": "b", "c": "c"};
      final align = {"a": "a", "b": "b", "c": "c"};
      g.graph()["edgesep"] = 50;
      g.setNode("a", <String, dynamic>{
        "rank": 0,
        "order": 0,
        "width": 100,
        "dummy": "edge"
      });
      g.setNode("b", <String, dynamic>{
        "rank": 0,
        "order": 1,
        "width": 200,
        "dummy": "edge-label",
        "labelpos": "r"
      });
      g.setNode("c", <String, dynamic>{
        "rank": 0,
        "order": 2,
        "width": 300,
        "dummy": "edge"
      });
      final xs =
          bk.horizontalCompaction(g, buildLayerMatrix(g), root, align, false);
      expect(xs["a"], equals(0));
      // xs.b = xs.a + 100/2 + 50 + 0 = 50 + 50 = 100
      expect(xs["b"], equals(100));
      // xs.c = xs.b + 200 + 50 + 300/2 = 100 + 200 + 50 + 150 = 500
      expect(xs["c"], equals(500));
    });
  });
}
