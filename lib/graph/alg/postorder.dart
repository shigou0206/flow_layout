// postorder.dart
import 'dfs.dart'; 
import 'package:flow_layout/graph/graph.dart';

List<String> postorder(Graph g, dynamic vs) {
  return dfs(g, vs, 'post');
}