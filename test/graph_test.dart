import 'package:flutter_test/flutter_test.dart';
import 'package:flow_layout/graph/graph.dart';

/// 如果有需要对 edges() 进行排序比对，可以用 sortEdges 函数
int sortEdges(a, b) {
  final vCmp = a.v.compareTo(b.v);
  if (vCmp != 0) return vCmp;
  final wCmp = a.w.compareTo(b.w);
  if (wCmp != 0) return wCmp;

  // 若 multigraph 带 name，也可比 name
  if (a.name == null && b.name == null) return 0;
  if (a.name == null) return -1;
  if (b.name == null) return 1;
  return a.name.compareTo(b.name);
}

void main() {
  late Graph g;

  setUp(() {
    g = Graph();
  });

  group('Graph - initial state', () {
    test('has no nodes', () {
      expect(g.nodeCount, 0);
    });

    test('has no edges', () {
      expect(g.edgeCount, 0);
    });

    test('has no attributes', () {
      expect(g.graph(), isNull);
    });

    test('defaults to a simple directed graph', () {
      expect(g.isDirected, isTrue);
      expect(g.isCompound, isFalse);
      expect(g.isMultigraph, isFalse);
    });

    test('can be set to undirected', () {
      final g2 = Graph(isDirected: false);
      expect(g2.isDirected, isFalse);
      expect(g2.isCompound, isFalse);
      expect(g2.isMultigraph, isFalse);
    });

    test('can be set to a compound graph', () {
      final g2 = Graph(isCompound: true);
      expect(g2.isDirected, isTrue);
      expect(g2.isCompound, isTrue);
      expect(g2.isMultigraph, isFalse);
    });

    test('can be set to a multigraph', () {
      final g2 = Graph(isMultigraph: true);
      expect(g2.isDirected, isTrue);
      expect(g2.isCompound, isFalse);
      expect(g2.isMultigraph, isTrue);
    });
  });

  group('Graph - setGraph', () {
    test('can get and set properties for the graph', () {
      g.setGraph('foo');
      expect(g.graph(), 'foo');
    });

    test('is chainable', () {
      final result = g.setGraph('bar');
      expect(result, same(g));
    });
  });

  group('Graph - nodes()', () {
    test('is empty if there are no nodes in the graph', () {
      expect(g.getNodes(), <String>[]);
    });

    test('returns the ids of nodes in the graph', () {
      g.setNode('a');
      g.setNode('b');
      // sort() 改用 toList()..sort() 或类似
      final nodes = g.getNodes()..sort();
      expect(nodes, ['a', 'b']);
    });
  });

  group('Graph - sources()', () {
    test('returns nodes with no in-edges', () {
      g.setPath(['a', 'b', 'c']);
      g.setNode('d');
      final src = g.sources()..sort();
      expect(src, ['a', 'd']);
    });
  });

  group('Graph - sinks()', () {
    test('returns nodes with no out-edges', () {
      g.setPath(['a', 'b', 'c']);
      g.setNode('d');
      final sk = g.sinks()..sort();
      expect(sk, ['c', 'd']);
    });
  });

  group('filterNodes', () {
    test('returns an identical graph when the filter selects everything', () {
      g.setGraph('graph label');
      g.setNode('a', 123);
      g.setPath(['a', 'b', 'c']);
      g.setEdge('a', 'c', 456);

      final g2 = g.filterNodes((_) => true);

      final nodesSorted = g2.getNodes()..sort();
      expect(nodesSorted, ['a', 'b', 'c']);

      final aSucc = g2.successors('a')?..sort();
      expect(aSucc, ['b', 'c']);

      final bSucc = g2.successors('b')?..sort();
      expect(bSucc, ['c']);

      expect(g2.node('a'), 123);
      expect(g2.edge('a', 'c'), 456);
      expect(g2.graph(), 'graph label');
    });

    test('returns an empty graph when the filter selects nothing', () {
      g.setPath(['a', 'b', 'c']);
      final g2 = g.filterNodes((_) => false);
      expect(g2.getNodes(), <String>[]);
      expect(g2.edges(), <Edge>[]);
    });

    test('only includes nodes for which the filter returns true', () {
      g.setNodes(['a', 'b']);
      final g2 = g.filterNodes((v) => v == 'a');
      expect(g2.getNodes(), ['a']);
    });

    test('removes edges that are connected to removed nodes', () {
      g.setEdge('a', 'b');
      final g2 = g.filterNodes((v) => v == 'a');
      final nodesSorted = g2.getNodes()..sort();
      expect(nodesSorted, ['a']);
      expect(g2.edges(), <Edge>[]);
    });

    test('preserves the directed option', () {
      g = Graph(isDirected: true);
      expect(g.filterNodes((_) => true).isDirected, isTrue);

      g = Graph(isDirected: false);
      expect(g.filterNodes((_) => true).isDirected, isFalse);
    });

    test('preserves the multigraph option', () {
      g = Graph(isMultigraph: true);
      expect(g.filterNodes((_) => true).isMultigraph, isTrue);

      g = Graph(isMultigraph: false);
      expect(g.filterNodes((_) => true).isMultigraph, isFalse);
    });

    test('preserves the compound option', () {
      g = Graph(isCompound: true);
      expect(g.filterNodes((_) => true).isCompound, isTrue);

      g = Graph(isCompound: false);
      expect(g.filterNodes((_) => true).isCompound, isFalse);
    });

    test('includes subgraphs', () {
      g = Graph(isCompound: true);
      g.setParent('a', 'parent');

      final g2 = g.filterNodes((_) => true);
      expect(g2.parent('a'), 'parent');
    });

    test('includes multi-level subgraphs', () {
      g = Graph(isCompound: true);
      g.setParent('a', 'parent');
      g.setParent('parent', 'root');

      final g2 = g.filterNodes((_) => true);
      expect(g2.parent('a'), 'parent');
      expect(g2.parent('parent'), 'root');
    });

    test('promotes a node to a higher subgraph if its parent is not included',
        () {
      g = Graph(isCompound: true);
      g.setParent('a', 'parent');
      g.setParent('parent', 'root');

      final g2 = g.filterNodes((v) => v != 'parent');
      // a 原本的 parent 是 parent，但 parent 不在新图
      // 所以 a 被提升到 root
      expect(g2.parent('a'), 'root');
    });
  });

  group('Graph - setNodes()', () {
    test('creates multiple nodes', () {
      g.setNodes(['a', 'b', 'c']);
      expect(g.hasNode('a'), isTrue);
      expect(g.hasNode('b'), isTrue);
      expect(g.hasNode('c'), isTrue);
    });

    test('can set a value for all of the nodes', () {
      g.setNodes(['a', 'b', 'c'], 'foo');
      expect(g.node('a'), equals('foo'));
      expect(g.node('b'), equals('foo'));
      expect(g.node('c'), equals('foo'));
    });

    test('is chainable', () {
      expect(g.setNodes(['a', 'b', 'c']), same(g));
    });
  });

  group('Graph - setNode()', () {
    test("creates the node if it isn't part of the graph", () {
      g.setNode('a');
      expect(g.hasNode('a'), isTrue);
      // 默认返回的值可能是 null, undefined 对应 Dart null
      expect(g.node('a'), isNull);
      expect(g.nodeCount, equals(1));
    });

    test('can set a value for the node', () {
      g.setNode('a', 'foo');
      expect(g.node('a'), equals('foo'));
    });

    test("does not change the node's value with a 1-arg invocation", () {
      g.setNode('a', 'foo');
      g.setNode('a');
      expect(g.node('a'), equals('foo'));
    });

    test("can remove the node's value by passing null", () {
      // JS中 undefined 相当于 Dart中的 null
      g.setNode('a', null);
      expect(g.node('a'), isNull);
    });

    test('is idempotent', () {
      g.setNode('a', 'foo');
      g.setNode('a', 'foo');
      expect(g.node('a'), equals('foo'));
      expect(g.nodeCount, equals(1));
    });

    test('uses the stringified form of the id', () {
      // Dart setNode 只接受 string, 但可以模拟
      g.setNode('1');
      expect(g.hasNode('1'), isTrue);
      expect(g.getNodes(), equals(['1']));
    });

    test('is chainable', () {
      expect(g.setNode('a'), same(g));
    });
  });

  group('Graph - setNodeDefaults()', () {
    test('sets a default label for new nodes', () {
      g.setDefaultNodeLabel('foo');
      g.setNode('a');
      expect(g.node('a'), equals('foo'));
    });

    test('does not change existing nodes', () {
      g.setNode('a');
      g.setDefaultNodeLabel('foo');
      // 之前的 node 是 null label, 不会自动改
      expect(g.node('a'), isNull);
    });

    test('is not used if an explicit value is set', () {
      g.setDefaultNodeLabel('foo');
      g.setNode('a', 'bar');
      expect(g.node('a'), equals('bar'));
    });

    test('can take a function', () {
      g.setDefaultNodeLabel((_) => 'foo');
      g.setNode('a');
      expect(g.node('a'), equals('foo'));
    });

    test("can take a function that takes the node's name", () {
      g.setDefaultNodeLabel((v) => '$v-foo');
      g.setNode('a');
      expect(g.node('a'), equals('a-foo'));
    });

    test('is chainable', () {
      expect(g.setDefaultNodeLabel('foo'), same(g));
    });
  });

  group('Graph - node()', () {
    test("returns null if the node isn't part of the graph", () {
      expect(g.node('a'), isNull);
    });

    test('returns the value of the node if it is part of the graph', () {
      g.setNode('a', 'foo');
      expect(g.node('a'), equals('foo'));
    });
  });

  group('Graph - removeNode()', () {
    test('does nothing if the node is not in the graph', () {
      expect(g.nodeCount, 0);
      g.removeNode('a');
      expect(g.hasNode('a'), isFalse);
      expect(g.nodeCount, 0);
    });

    test('removes the node if it is in the graph', () {
      g.setNode('a');
      g.removeNode('a');
      expect(g.hasNode('a'), isFalse);
      expect(g.nodeCount, 0);
    });

    test('is idempotent', () {
      g.setNode('a');
      g.removeNode('a');
      g.removeNode('a');
      expect(g.hasNode('a'), isFalse);
      expect(g.nodeCount, 0);
    });

    test('removes edges incident on the node', () {
      g.setEdge('a', 'b');
      g.setEdge('b', 'c');
      g.removeNode('b');
      expect(g.edgeCount, 0);
    });

    test('removes parent / child relationships for the node', () {
      final g2 = Graph(isCompound: true);
      g2.setParent('c', 'b');
      g2.setParent('b', 'a');
      g2.removeNode('b');

      // b 不再有 parent
      expect(g2.parent('b'), isNull);
      // b 不在图中，所以 children('b') 也是 null or undefined
      expect(g2.children('b'), isNull);
      // a 的 children 里不应该再有 b
      final aKids = g2.children('a');
      expect(aKids, isNot(contains('b')));
      // c 的 parent 被提升到 root
      expect(g2.parent('c'), isNull);
    });

    test('is chainable', () {
      expect(g.removeNode('a'), same(g));
    });
  });

  group('Graph - setParent', () {
    // 这里的 g 将在每个 test 前初始化
    late Graph g;

    setUp(() {
      // 与 JS 中 `beforeEach(function() { g = new Graph({ compound: true }); })` 对应
      // 只在此 group 生效，其他 group 不受影响
      g = Graph(isCompound: true);
    });

    test('throws if the graph is not compound', () {
      // JS: expect(function() { new Graph().setParent("a","parent"); }).to.throw();
      final nonCompound = Graph(isCompound: false);
      expect(
        () => nonCompound.setParent('a', 'parent'),
        throwsException,
      );
    });

    test('creates the parent if it does not exist', () {
      g.setNode('a');
      g.setParent('a', 'parent');
      expect(g.hasNode('parent'), isTrue);
      expect(g.parent('a'), equals('parent'));
    });

    test('creates the child if it does not exist', () {
      g.setNode('parent');
      g.setParent('a', 'parent');
      expect(g.hasNode('a'), isTrue);
      expect(g.parent('a'), equals('parent'));
    });

    test('has the parent as null if it has never been invoked', () {
      // JS 里 `be.undefined` <-> Dart 里 null
      g.setNode('a');
      expect(g.parent('a'), isNull);
    });

    test('moves the node from the previous parent', () {
      g.setParent('a', 'parent');
      g.setParent('a', 'parent2');
      expect(g.parent('a'), equals('parent2'));
      expect(g.children('parent'), <String>[]);
      expect(g.children('parent2'), <String>['a']);
    });

    test('removes the parent if the parent is null', () {
      // 对应 JS: setParent('a','parent'); setParent('a', undefined)
      g.setParent('a', 'parent');
      g.setParent('a', null);
      expect(g.parent('a'), isNull);

      // 测试 children() 的根节点看看
      final rootKids = g.children()!..sort();
      expect(rootKids, <String>['a', 'parent']);
    });

    test('removes the parent if no parent was specified', () {
      // JS: setParent('a','parent'); setParent('a');
      g.setParent('a', 'parent');
      g.setParent('a'); // 等价 setParent('a', null)
      expect(g.parent('a'), isNull);

      final rootKids = g.children()!..sort();
      expect(rootKids, <String>['a', 'parent']);
    });

    test('is idempotent to remove a parent', () {
      // JS: setParent('a','parent'); setParent('a'); setParent('a');
      g.setParent('a', 'parent');
      g.setParent('a'); // remove parent
      g.setParent('a'); // remove again
      expect(g.parent('a'), isNull);

      final rootKids = g.children()!..sort();
      expect(rootKids, <String>['a', 'parent']);
    });

    test('uses the stringified form of the id', () {
      // JS: g.setParent(2,1); g.setParent(3,2);
      g.setParent('2', '1');
      g.setParent('3', '2');
      expect(g.parent('2'), equals('1'));
      expect(g.parent('3'), equals('2'));
    });

    test('preserves the tree invariant', () {
      // JS: g.setParent('c','b'); g.setParent('b','a'); expect(function() {g.setParent('a','c');}).to.throw();
      g.setParent('c', 'b');
      g.setParent('b', 'a');
      expect(() => g.setParent('a', 'c'), throwsException);
    });

    test('is chainable', () {
      // JS: expect(g.setParent('a','parent')).to.equal(g);
      final result = g.setParent('a', 'parent');
      expect(result, same(g));
    });
  });

  group('Graph - parent()', () {
    late Graph g;

    setUp(() {
      // compound=true 用于测试 parent/child 逻辑
      g = Graph(isCompound: true);
    });

    test('returns null if the graph is not compound', () {
      final g2 = Graph(isCompound: false);
      expect(g2.parent('a'), isNull);
    });

    test("returns null if the node isn't in the graph", () {
      // JS: expect(g.parent('a')).to.be.undefined;
      // Dart: isNull
      expect(g.parent('a'), isNull);
    });

    test('defaults to null for new nodes', () {
      g.setNode('a');
      expect(g.parent('a'), isNull);
    });

    test('returns the current parent assignment', () {
      g.setNode('a');
      g.setNode('parent');
      g.setParent('a', 'parent');
      expect(g.parent('a'), 'parent');
    });
  });

  group('Graph - children()', () {
    late Graph g;

    setUp(() {
      g = Graph(isCompound: true);
    });

    test('returns null if the node is not in the graph', () {
      // JS: expect(g.children('a')).to.be.undefined;
      // Dart: isNull
      expect(g.children('a'), isNull);
    });

    test('defaults to an empty list for new nodes', () {
      g.setNode('a');
      expect(g.children('a'), <String>[]);
    });

    test('returns null for a non-compound graph without the node', () {
      final g2 = Graph(isCompound: false);
      expect(g2.children('a'), isNull);
    });

    test('returns an empty list for a non-compound graph with the node', () {
      final g2 = Graph(isCompound: false);
      g2.setNode('a');
      // JS: g.children('a') => []
      expect(g2.children('a'), <String>[]);
    });

    test('returns all nodes for the root of a non-compound graph', () {
      final g2 = Graph(isCompound: false);
      g2.setNode('a');
      g2.setNode('b');
      final kids = g2.children()!..sort();
      expect(kids, <String>['a', 'b']);
    });

    test('returns children for the node', () {
      g.setParent('a', 'parent');
      g.setParent('b', 'parent');
      final kids = g.children('parent')!..sort();
      expect(kids, <String>['a', 'b']);
    });

    test('returns all nodes without a parent when the parent is not set', () {
      // JS: setNode('a'), setNode('b'), setNode('c'), setNode('parent'); setParent('a','parent');
      g.setNode('a');
      g.setNode('b');
      g.setNode('c');
      g.setNode('parent');
      g.setParent('a', 'parent');

      // children() / children(undefined) => [b,c,parent]
      final rootKids1 = g.children()!..sort();
      expect(rootKids1, <String>['b', 'c', 'parent']);

      // Dart 中 children(null) == children(undefined) 也写成 g.children(null)
      // 但要和 JS 对齐, 这里 children(undefined) <-> children() in Dart.
      // So just do the same call.
      final rootKids2 = g.children()!..sort();
      expect(rootKids2, <String>['b', 'c', 'parent']);
    });
  });

  group('Graph - predecessors()', () {
    test('returns null for a node not in the graph', () {
      // JS expect(g.predecessors('a')).to.be.undefined => Dart: isNull
      expect(g.predecessors('a'), isNull);
    });

    test('returns the predecessors of a node', () {
      g.setEdge('a', 'b');
      g.setEdge('b', 'c');
      g.setEdge('a', 'a');

      // a 的 predecessors => a (self loop)
      var predsA = g.predecessors('a');
      predsA?.sort();
      expect(predsA, ['a']);

      // b 的 predecessors => a
      var predsB = g.predecessors('b');
      predsB?.sort();
      expect(predsB, ['a']);

      // c 的 predecessors => b
      var predsC = g.predecessors('c');
      predsC?.sort();
      expect(predsC, ['b']);
    });
  });

  group('Graph - successors()', () {
    test('returns null for a node not in the graph', () {
      expect(g.successors('a'), isNull);
    });

    test('returns the successors of a node', () {
      g.setEdge('a', 'b');
      g.setEdge('b', 'c');
      g.setEdge('a', 'a');

      var succA = g.successors('a');
      succA?.sort();
      expect(succA, ['a', 'b']);

      var succB = g.successors('b');
      succB?.sort();
      expect(succB, ['c']);

      var succC = g.successors('c');
      expect(succC, <String>[]);
    });
  });

  group('Graph - neighbors()', () {
    test('returns null for a node not in the graph', () {
      expect(g.neighbors('a'), isNull);
    });

    test('returns the neighbors of a node', () {
      g.setEdge('a', 'b');
      g.setEdge('b', 'c');
      g.setEdge('a', 'a');

      var neighA = g.neighbors('a');
      neighA?.sort();
      expect(neighA, ['a', 'b']);

      var neighB = g.neighbors('b');
      neighB?.sort();
      expect(neighB, ['a', 'c']);

      var neighC = g.neighbors('c');
      neighC?.sort();
      expect(neighC, ['b']);
    });
  });

  group('Graph - isLeaf()', () {
    test('returns false for connected node in undirected graph', () {
      final g2 = Graph(isDirected: false);
      g2.setNode('a');
      g2.setNode('b');
      g2.setEdge('a', 'b');
      expect(g2.isLeaf('b'), isFalse);
    });

    test('returns true for an unconnected node in undirected graph', () {
      final g2 = Graph(isDirected: false);
      g2.setNode('a');
      expect(g2.isLeaf('a'), isTrue);
    });

    test('returns true for an unconnected node in directed graph', () {
      g.setNode('a');
      expect(g.isLeaf('a'), isTrue);
    });

    test('returns false for predecessor node in directed graph', () {
      g.setNode('a');
      g.setNode('b');
      g.setEdge('a', 'b');
      expect(g.isLeaf('a'), isFalse);
    });

    test('returns true for successor node in directed graph', () {
      g.setNode('a');
      g.setNode('b');
      g.setEdge('a', 'b');
      expect(g.isLeaf('b'), isTrue);
    });
  });

  group('Graph - edges()', () {
    test('is empty if there are no edges in the graph', () {
      expect(g.edges(), <dynamic>[]);
    });

    test('returns the keys for edges in the graph', () {
      g.setEdge('a', 'b');
      g.setEdge('b', 'c');
      final allEdges = g.edges();
      // JS 测试 sort(sortEdges) => expected => [ {v:'a',w:'b'}, {v:'b',w:'c'} ]
      // 我们在 Dart 用 sortEdges 函数
      allEdges.sort(sortEdges);
      expect(
        allEdges.map((e) => {'v': e.v, 'w': e.w}).toList(),
        [
          {'v': 'a', 'w': 'b'},
          {'v': 'b', 'w': 'c'},
        ],
      );
    });
  });

  group('Graph - setPath()', () {
    test('creates a path of multiple edges', () {
      g.setPath(['a', 'b', 'c']);
      expect(g.hasEdge('a', 'b'), isTrue);
      expect(g.hasEdge('b', 'c'), isTrue);
    });

    test('can set a value for all of the edges', () {
      g.setPath(['a', 'b', 'c'], 'foo');
      expect(g.edge('a', 'b'), equals('foo'));
      expect(g.edge('b', 'c'), equals('foo'));
    });

    test('is chainable', () {
      final result = g.setPath(['a', 'b', 'c']);
      expect(result, same(g));
    });
  });

  group('Graph - setEdge()', () {
    test("creates the edge if it isn't part of the graph", () {
      // 1) setNode('a'), setNode('b')
      g.setNode('a');
      g.setNode('b');
      g.setEdge('a', 'b');

      // edge('a','b') 应为 null (JS: undefined)
      expect(g.edge('a', 'b'), isNull);
      // 但 hasEdge('a','b') = true
      expect(g.hasEdge('a', 'b'), isTrue);

      // JS 测试也检查 hasEdge({v:'a', w:'b'}) => same as hasEdge('a','b') in Dart
      expect(g.hasEdge('a', 'b'), isTrue);
      // edgeCount=1
      expect(g.edgeCount, equals(1));
    });

    test('creates the nodes for the edge if they are not part of the graph',
        () {
      g.setEdge('a', 'b');
      expect(g.hasNode('a'), isTrue);
      expect(g.hasNode('b'), isTrue);
      expect(g.nodeCount, equals(2));
    });

    test("creates a multi-edge if it isn't part of the graph", () {
      final g2 = Graph(isMultigraph: true);
      g2.setEdge('a', 'b', null, 'name');
      // JS: expect(g.hasEdge('a','b'))=false, hasEdge('a','b','name')=true
      expect(g2.hasEdge('a', 'b'), isFalse);
      expect(g2.hasEdge('a', 'b', 'name'), isTrue);
    });

    test('throws if a multi-edge is used with a non-multigraph', () {
      expect(
        () => g.setEdge('a', 'b', null, 'name'),
        throwsException,
      );
    });

    test('changes the value for an edge if it is already in the graph', () {
      g.setEdge('a', 'b', 'foo');
      g.setEdge('a', 'b', 'bar');
      expect(g.edge('a', 'b'), equals('bar'));
    });

    test('deletes the value for the edge if the value arg is null', () {
      // JS: setEdge('a','b','foo'); setEdge('a','b',undefined)
      g.setEdge('a', 'b', 'foo');
      g.setEdge('a', 'b', null);
      expect(g.edge('a', 'b'), isNull);
      expect(g.hasEdge('a', 'b'), isTrue);
    });

    test('changes the value for a multi-edge if it is already in the graph',
        () {
      final g2 = Graph(isMultigraph: true);
      g2.setEdge('a', 'b', 'value', 'name');
      g2.setEdge('a', 'b', null, 'name');
      // JS: expect(g.edge('a','b','name')).to.be.undefined
      expect(g2.edge('a', 'b', 'name'), isNull);
      expect(g2.hasEdge('a', 'b', 'name'), isTrue);
    });

    test('can take an edge object as the first parameter', () {
      // JS: g.setEdge({v:'a', w:'b'}, 'value'); expect(g.edge('a','b')).to.equal('value');
      g.setEdge({'v': 'a', 'w': 'b'}, 'value');
      expect(g.edge('a', 'b'), equals('value'));
    });

    test('can take a multi-edge object as the first parameter', () {
      final g2 = Graph(isMultigraph: true);
      // JS: g.setEdge({v:'a', w:'b', name:'nm'}, 'value'); => g.edge('a','b','nm')=='value'
      g2.setEdge({'v': 'a', 'w': 'b', 'name': 'nm'}, 'value');
      expect(g2.edge('a', 'b', 'nm'), equals('value'));
    });

    test('uses the stringified form of the id #1', () {
      g.setEdge(1, 2, 'foo');
      final allEdges = g.edges();
      // JS expect(g.edges()).eqls([{v:'1',w:'2'}]);
      expect(
        allEdges.map((e) => e.name).where((n) => n != null).isEmpty,
        isTrue,
      );
      expect(
        allEdges.map((e) => {'v': e.v, 'w': e.w}).toList(),
        [
          {'v': '1', 'w': '2'}
        ],
      );

      // edge('1','2')='foo', edge(1,2)='foo'
      expect(g.edge('1', '2'), equals('foo'));
      expect(g.edge(1, 2), equals('foo'));

      // edgeAsObj(1,2) => {label:'foo'}
      final asObj = g.edgeAsObj(1, 2);
      expect(asObj, {'label': 'foo'});
    });

    test('uses the stringified form of the id #2', () {
      // JS: g = new Graph({multigraph:true});
      g = Graph(isMultigraph: true);
      g.setEdge(1, 2, 'foo', null); // name=undefined => normal edge
      final es = g.edges();
      // expect(es).eqls([{v:'1', w:'2'}])
      expect(
        es
            .map(
                (e) => {'v': e.v, 'w': e.w, if (e.name != null) 'name': e.name})
            .toList(),
        [
          {'v': '1', 'w': '2'}
        ],
      );

      expect(g.edge('1', '2'), 'foo');
      expect(g.edge(1, 2), 'foo');
      expect(g.edgeAsObj(1, 2), {'label': 'foo'});
    });

    test('uses the stringified form of the id with a name', () {
      g = Graph(isMultigraph: true);
      // JS: g.setEdge(1,2,'foo',3)
      g.setEdge(1, 2, 'foo', '3');

      // edge('1','2','3') => 'foo'
      expect(g.edge('1', '2', '3'), 'foo');
      expect(g.edge(1, 2, '3'), 'foo');

      expect(g.edgeAsObj(1, 2, '3'), {'label': 'foo'});

      final es = g.edges();
      // expect(es).eqls([{v:'1', w:'2', name:'3'}])
      expect(
        es.map((e) => {'v': e.v, 'w': e.w, 'name': e.name}).toList(),
        [
          {'v': '1', 'w': '2', 'name': '3'}
        ],
      );
    });

    test('treats edges in opposite directions as distinct in a digraph', () {
      g.setEdge('a', 'b');
      expect(g.hasEdge('a', 'b'), isTrue);
      expect(g.hasEdge('b', 'a'), isFalse);
    });

    test('handles undirected graph edges', () {
      final g2 = Graph(isDirected: false);
      g2.setEdge('a', 'b', 'foo');
      expect(g2.edge('a', 'b'), 'foo');
      expect(g2.edge('b', 'a'), 'foo');
    });

    test(
        'handles undirected edges where id has different order than Stringified id',
        () {
      final g2 = Graph(isDirected: false);
      g2.setEdge(9, 10, 'foo');

      // JS: expect(g.hasEdge('9','10'))=true, hasEdge('10','9')=true
      expect(g2.hasEdge('9', '10'), isTrue);
      expect(g2.hasEdge(9, 10), isTrue);
      expect(g2.hasEdge('10', '9'), isTrue);
      expect(g2.hasEdge(10, 9), isTrue);

      // edge('9','10') => 'foo'
      expect(g2.edge('9', '10'), 'foo');
      expect(g2.edge(9, 10), 'foo');
    });

    test('is chainable', () {
      final r = g.setEdge('a', 'b');
      expect(r, same(g));
    });
  });

  group('Graph - setDefaultEdgeLabel', () {
    test('sets a default label for new edges', () {
      g.setDefaultEdgeLabel('foo');
      g.setEdge('a', 'b');
      expect(g.edge('a', 'b'), equals('foo'));
    });

    test('does not change existing edges', () {
      g.setEdge('a', 'b');
      g.setDefaultEdgeLabel('foo');
      // 先有再改默认 => 旧边不变
      expect(g.edge('a', 'b'), isNull);
    });

    test('is not used if an explicit value is set', () {
      g.setDefaultEdgeLabel('foo');
      g.setEdge('a', 'b', 'bar');
      expect(g.edge('a', 'b'), equals('bar'));
    });

    test('can take a function', () {
      g.setDefaultEdgeLabel((_) => 'foo');
      g.setEdge('a', 'b');
      expect(g.edge('a', 'b'), equals('foo'));
    });

    test("can take a function that takes the edge's endpoints and name", () {
      final g2 = Graph(isMultigraph: true);
      g2.setDefaultEdgeLabel((v, w, name) => '$v-$w-$name-foo');
      g2.setEdge({'v': 'a', 'w': 'b', 'name': 'name'});
      expect(g2.edge('a', 'b', 'name'), equals('a-b-name-foo'));
    });

    test('does not set a default value for a multi-edge that already exists',
        () {
      final g2 = Graph(isMultigraph: true);
      g2.setEdge('a', 'b', 'old', 'name');
      g2.setDefaultEdgeLabel((_) => 'should not set this');
      g2.setEdge({'v': 'a', 'w': 'b', 'name': 'name'});
      expect(g2.edge('a', 'b', 'name'), equals('old'));
    });

    test('is chainable', () {
      expect(g.setDefaultEdgeLabel('foo'), same(g));
    });
  });

  group('Graph - edge()', () {
    test("returns null if the edge isn't part of the graph", () {
      expect(g.edge('a', 'b'), isNull);
      expect(g.edge({'v': 'a', 'w': 'b'}), isNull);
      expect(g.edge('a', 'b', 'foo'), isNull);
    });

    test('returns the value of the edge if it is part of the graph', () {
      g.setEdge('a', 'b', {'foo': 'bar'});
      expect(g.edge('a', 'b'), equals({'foo': 'bar'}));
      expect(g.edgeAsObj('a', 'b'), equals({'foo': 'bar'}));
      expect(g.edge({'v': 'a', 'w': 'b'}), equals({'foo': 'bar'}));
      expect(g.edgeAsObj({'v': 'a', 'w': 'b'}), equals({'foo': 'bar'}));
      // 这是有向图 => edge('b','a') 不存在
      expect(g.edge('b', 'a'), isNull);
      expect(g.edgeAsObj('b', 'a'), {'label': null});
    });

    test('returns the value of a multi-edge if it is part of the graph', () {
      final g2 = Graph(isMultigraph: true);
      g2.setEdge('a', 'b', {'bar': 'baz'}, 'foo');
      expect(g2.edge('a', 'b', 'foo'), equals({'bar': 'baz'}));
      expect(g2.edgeAsObj('a', 'b', 'foo'), equals({'bar': 'baz'}));
      expect(g2.edge('a', 'b'), isNull);
      expect(g2.edgeAsObj('a', 'b'), {'label': null});
    });

    test('returns an edge in either direction in an undirected graph', () {
      final g2 = Graph(isDirected: false);
      g2.setEdge('a', 'b', {'foo': 'bar'});
      expect(g2.edge('a', 'b'), equals({'foo': 'bar'}));
      expect(g2.edgeAsObj('a', 'b'), equals({'foo': 'bar'}));
      expect(g2.edge('b', 'a'), equals({'foo': 'bar'}));
      expect(g2.edgeAsObj('b', 'a'), equals({'foo': 'bar'}));
    });
  });

  group('Graph - removeEdge()', () {
    test('has no effect if the edge is not in the graph', () {
      g.removeEdge('a', 'b');
      expect(g.hasEdge('a', 'b'), isFalse);
      expect(g.edgeCount, 0);
    });

    test('can remove an edge by edgeObj', () {
      final g2 = Graph(isMultigraph: true);
      g2.setEdge({'v': 'a', 'w': 'b', 'name': 'foo'});
      g2.removeEdge({'v': 'a', 'w': 'b', 'name': 'foo'});
      expect(g2.hasEdge('a', 'b', 'foo'), isFalse);
      expect(g2.edgeCount, 0);
    });

    test('can remove an edge by separate ids', () {
      final g2 = Graph(isMultigraph: true);
      g2.setEdge({'v': 'a', 'w': 'b', 'name': 'foo'});
      g2.removeEdge('a', 'b', 'foo');
      expect(g2.hasEdge('a', 'b', 'foo'), isFalse);
      expect(g2.edgeCount, 0);
    });

    test('correctly removes neighbors', () {
      g.setEdge('a', 'b');
      g.removeEdge('a', 'b');
      expect(g.successors('a'), <String>[]);
      expect(g.neighbors('a'), <String>[]);
      expect(g.predecessors('b'), <String>[]);
      expect(g.neighbors('b'), <String>[]);
    });

    test('correctly decrements neighbor counts', () {
      final g2 = Graph(isMultigraph: true);
      g2.setEdge('a', 'b');
      g2.setEdge({'v': 'a', 'w': 'b', 'name': 'foo'});
      g2.removeEdge('a', 'b');
      // JS: expect(g.hasEdge('a','b','foo')) => true
      expect(g2.hasEdge('a', 'b', 'foo'), isTrue);
      // successors('a') => ['b']
      expect(g2.successors('a'), <String>['b']);
      expect(g2.neighbors('a'), <String>['b']);
      expect(g2.predecessors('b'), <String>['a']);
      expect(g2.neighbors('b'), <String>['a']);
    });

    test('works with undirected graphs', () {
      final g2 = Graph(isDirected: false);
      g2.setEdge('h', 'g');
      g2.removeEdge('g', 'h');
      expect(g2.neighbors('g'), <String>[]);
      expect(g2.neighbors('h'), <String>[]);
    });

    test('is chainable', () {
      g.setEdge('a', 'b');
      expect(g.removeEdge('a', 'b'), same(g));
    });
  });

  group('Graph - inEdges', () {
    test('returns null for a node that is not in the graph', () {
      expect(g.inEdges('a'), isNull);
    });

    test('returns the edges that point at the specified node', () {
      g.setEdge('a', 'b');
      g.setEdge('b', 'c');
      expect(g.inEdges('a'), <dynamic>[]);
      expect(
          g.inEdges('b'),
          [
            {'v': 'a', 'w': 'b'},
          ].map((e) => e).toList());
      expect(
          g.inEdges('c'),
          [
            {'v': 'b', 'w': 'c'},
          ].map((e) => e).toList());
    });

    test('works for multigraphs', () {
      final g2 = Graph(isMultigraph: true);
      g2.setEdge('a', 'b');
      g2.setEdge('a', 'b', null, 'bar');
      g2.setEdge('a', 'b', null, 'foo');
      expect(g2.inEdges('a'), <dynamic>[]);

      // edges from a -> b, with 3 names (one is default)
      final bIn = g2.inEdges('b')!..sort(sortEdges);
      expect(
          bIn
              .map((e) =>
                  {'v': e.v, 'w': e.w, if (e.name != null) 'name': e.name})
              .toList(),
          [
            {'v': 'a', 'w': 'b', 'name': 'bar'},
            {'v': 'a', 'w': 'b', 'name': 'foo'},
            {'v': 'a', 'w': 'b'},
          ]);
    });

    test('can return only edges from a specified node', () {
      final g2 = Graph(isMultigraph: true);
      g2.setEdge('a', 'b');
      g2.setEdge('a', 'b', null, 'foo');
      g2.setEdge('a', 'c');
      g2.setEdge('b', 'c');
      g2.setEdge('z', 'a');
      g2.setEdge('z', 'b');
      expect(g2.inEdges('a', 'b'), <dynamic>[]);
      final bInFromA = g2.inEdges('b', 'a')!..sort(sortEdges);
      expect(
          bInFromA
              .map((e) =>
                  {'v': e.v, 'w': e.w, if (e.name != null) 'name': e.name})
              .toList(),
          [
            {'v': 'a', 'w': 'b', 'name': 'foo'},
            {'v': 'a', 'w': 'b'},
          ]);
    });
  });

  group('Graph - outEdges', () {
    test('returns null for a node that is not in the graph', () {
      expect(g.outEdges('a'), isNull);
    });

    test('returns all edges that this node points at', () {
      g.setEdge('a', 'b');
      g.setEdge('b', 'c');
      expect(
          g.outEdges('a'),
          [
            {'v': 'a', 'w': 'b'},
          ].map((e) => e).toList());
      expect(
          g.outEdges('b'),
          [
            {'v': 'b', 'w': 'c'},
          ].map((e) => e).toList());
      expect(g.outEdges('c'), <dynamic>[]);
    });

    test('works for multigraphs', () {
      final g2 = Graph(isMultigraph: true);
      g2.setEdge('a', 'b');
      g2.setEdge('a', 'b', null, 'bar');
      g2.setEdge('a', 'b', null, 'foo');
      final aOut = g2.outEdges('a')!..sort(sortEdges);
      expect(
          aOut
              .map((e) =>
                  {'v': e.v, 'w': e.w, if (e.name != null) 'name': e.name})
              .toList(),
          [
            {'v': 'a', 'w': 'b', 'name': 'bar'},
            {'v': 'a', 'w': 'b', 'name': 'foo'},
            {'v': 'a', 'w': 'b'},
          ]);
      expect(g2.outEdges('b'), <dynamic>[]);
    });

    test('can return only edges to a specified node', () {
      final g2 = Graph(isMultigraph: true);
      g2.setEdge('a', 'b');
      g2.setEdge('a', 'b', null, 'foo');
      g2.setEdge('a', 'c');
      g2.setEdge('b', 'c');
      g2.setEdge('z', 'a');
      g2.setEdge('z', 'b');
      final aToB = g2.outEdges('a', 'b')!..sort(sortEdges);
      expect(
          aToB
              .map((e) =>
                  {'v': e.v, 'w': e.w, if (e.name != null) 'name': e.name})
              .toList(),
          [
            {'v': 'a', 'w': 'b', 'name': 'foo'},
            {'v': 'a', 'w': 'b'},
          ]);
      expect(g2.outEdges('b', 'a'), <dynamic>[]);
    });
  });

  group('Graph - nodeEdges', () {
    test('returns null for a node that is not in the graph', () {
      expect(g.nodeEdges('a'), isNull);
    });

    test('returns all edges that this node points at', () {
      g.setEdge('a', 'b');
      g.setEdge('b', 'c');
      final aEdges = g.nodeEdges('a')!;
      expect(
          aEdges,
          [
            {'v': 'a', 'w': 'b'},
          ].map((e) => e).toList());

      final bEdges = g.nodeEdges('b')!;
      // JS => bEdges => [ {v:'a',w:'b'}, {v:'b',w:'c'} ]
      // Dart => compare
      bEdges.sort(sortEdges);
      expect(bEdges.map((e) => {'v': e.v, 'w': e.w}).toList(), [
        {'v': 'a', 'w': 'b'},
        {'v': 'b', 'w': 'c'},
      ]);

      expect(
          g.nodeEdges('c'),
          [
            {'v': 'b', 'w': 'c'},
          ].map((e) => e).toList());
    });

    test('works for multigraphs', () {
      final g2 = Graph(isMultigraph: true);
      g2.setEdge('a', 'b');
      g2.setEdge({'v': 'a', 'w': 'b', 'name': 'bar'});
      g2.setEdge({'v': 'a', 'w': 'b', 'name': 'foo'});
      final aEdges = g2.nodeEdges('a')!..sort(sortEdges);
      expect(
          aEdges
              .map((e) =>
                  {'v': e.v, 'w': e.w, if (e.name != null) 'name': e.name})
              .toList(),
          [
            {'v': 'a', 'w': 'b', 'name': 'bar'},
            {'v': 'a', 'w': 'b', 'name': 'foo'},
            {'v': 'a', 'w': 'b'},
          ]);
      final bEdges = g2.nodeEdges('b')!..sort(sortEdges);
      expect(
          bEdges
              .map((e) =>
                  {'v': e.v, 'w': e.w, if (e.name != null) 'name': e.name})
              .toList(),
          [
            {'v': 'a', 'w': 'b', 'name': 'bar'},
            {'v': 'a', 'w': 'b', 'name': 'foo'},
            {'v': 'a', 'w': 'b'},
          ]);
    });

    test('can return only edges between specific nodes', () {
      final g2 = Graph(isMultigraph: true);
      g2.setEdge('a', 'b');
      g2.setEdge({'v': 'a', 'w': 'b', 'name': 'foo'});
      g2.setEdge('a', 'c');
      g2.setEdge('b', 'c');
      g2.setEdge('z', 'a');
      g2.setEdge('z', 'b');

      final abEdges = g2.nodeEdges('a', 'b')!..sort(sortEdges);
      expect(
          abEdges
              .map((e) =>
                  {'v': e.v, 'w': e.w, if (e.name != null) 'name': e.name})
              .toList(),
          [
            {'v': 'a', 'w': 'b', 'name': 'foo'},
            {'v': 'a', 'w': 'b'},
          ]);

      final baEdges = g2.nodeEdges('b', 'a')!..sort(sortEdges);
      expect(
          baEdges
              .map((e) =>
                  {'v': e.v, 'w': e.w, if (e.name != null) 'name': e.name})
              .toList(),
          [
            {'v': 'a', 'w': 'b', 'name': 'foo'},
            {'v': 'a', 'w': 'b'},
          ]);
    });
  });
}
