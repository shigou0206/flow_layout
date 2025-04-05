// preorder.dart
import 'dfs.dart'; 
import 'package:flow_layout/graph/graph.dart';

List<String> preorder(Graph g, dynamic vs) {
  return dfs(g, vs, 'pre');
}