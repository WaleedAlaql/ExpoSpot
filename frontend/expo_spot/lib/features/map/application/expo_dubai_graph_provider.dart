import 'package:expo_spot/features/map/data/expo_dubai_graph.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final expoDubaiGraphProvider = FutureProvider<ExpoDubaiGraph>((ref) async {
  return ExpoDubaiGraph.loadFromAssets();
});
