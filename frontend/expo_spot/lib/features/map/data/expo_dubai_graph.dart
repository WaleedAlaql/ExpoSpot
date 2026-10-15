import 'dart:convert';
import 'dart:math' as math;

import 'package:expo_spot/features/map/domain/expo_dubai_venue.dart';
import 'package:expo_spot/features/map/models/venue_graph_models.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

/// In-memory Expo Dubai pedestrian graph (nodes, edges, meeting points).
class ExpoDubaiGraph {
  ExpoDubaiGraph._({
    required this.nodes,
    required this.adjacency,
    required this.meetingPoints,
  });

  final Map<int, VenueGraphNode> nodes;
  final Map<int, List<VenueAdjacencyEdge>> adjacency;
  final List<VenueMeetingPoint> meetingPoints;

  static const _componentFilter = 1;

  static Future<ExpoDubaiGraph> loadFromAssets() async {
    final nodesJson = await rootBundle.loadString('assets/map-data/nodes.json');
    final edgesJson = await rootBundle.loadString('assets/map-data/edges.json');
    final pointsJson =
        await rootBundle.loadString('assets/map-data/meeting-points.json');

    final nodeList = (jsonDecode(nodesJson) as List)
        .cast<Map<String, dynamic>>()
        .map(VenueGraphNode.fromJson)
        .where((n) => n.componentId == _componentFilter)
        .toList();

    final nodes = {for (final n in nodeList) n.id: n};

    final edgeInputs = (jsonDecode(edgesJson) as List)
        .cast<Map<String, dynamic>>()
        .map(VenueGraphEdge.fromJson)
        .where((e) => e.componentId == _componentFilter)
        .toList();

    final adjacency = <int, List<VenueAdjacencyEdge>>{
      for (final id in nodes.keys) id: <VenueAdjacencyEdge>[],
    };

    for (final input in edgeInputs) {
      final from = nodes[input.fromNodeId];
      final to = nodes[input.toNodeId];
      if (from == null || to == null) continue;

      final distance = _haversine(from.latLng, to.latLng);
      if (distance <= 0) continue;

      adjacency[from.id]!.add(VenueAdjacencyEdge(to.id, distance));
      if (input.bidirectional) {
        adjacency[to.id]!.add(VenueAdjacencyEdge(from.id, distance));
      }
    }

    final meetingPoints = (jsonDecode(pointsJson) as List)
        .cast<Map<String, dynamic>>()
        .map(VenueMeetingPoint.fromJson)
        .where((p) => nodes.containsKey(p.nodeId))
        .toList();

    return ExpoDubaiGraph._(
      nodes: nodes,
      adjacency: adjacency,
      meetingPoints: meetingPoints,
    );
  }

  VenueMeetingPoint? meetingPointById(String id) {
    for (final point in meetingPoints) {
      if (point.id == id) return point;
    }
    return null;
  }

  VenueMeetingPoint get earthPlaza =>
      meetingPointById('mp-986398789') ?? meetingPoints.first;

  int nearestNodeId(LatLng position) {
    var bestId = nodes.keys.first;
    var bestDistance = double.infinity;

    for (final entry in nodes.entries) {
      final d = _haversine(position, entry.value.latLng);
      if (d < bestDistance) {
        bestDistance = d;
        bestId = entry.key;
      }
    }
    return bestId;
  }

  List<LatLng> shortestPathLatLng({
    required LatLng from,
    required LatLng to,
  }) {
    final startId = nearestNodeId(from);
    final goalId = nearestNodeId(to);
    final pathIds = _dijkstra(startId, goalId);
    if (pathIds.isEmpty) return [from, to];
    return [
      from,
      ...pathIds.map((id) => nodes[id]!.latLng),
      to,
    ];
  }

  List<int> _dijkstra(int startId, int goalId) {
    if (!nodes.containsKey(startId) || !nodes.containsKey(goalId)) {
      return const [];
    }

    final dist = <int, double>{for (final id in nodes.keys) id: double.infinity};
    final prev = <int, int?>{for (final id in nodes.keys) id: null};
    final visited = <int>{};

    dist[startId] = 0;
    final queue = PriorityQueue<_QueueNode>(
      (a, b) => a.cost.compareTo(b.cost),
    )..add(_QueueNode(startId, 0));

    while (queue.isNotEmpty) {
      final current = queue.removeFirst();
      if (visited.contains(current.nodeId)) continue;
      visited.add(current.nodeId);

      if (current.nodeId == goalId) break;

      for (final edge in adjacency[current.nodeId] ?? const []) {
        final alt = dist[current.nodeId]! + edge.distanceMeters;
        if (alt < dist[edge.toNodeId]!) {
          dist[edge.toNodeId] = alt;
          prev[edge.toNodeId] = current.nodeId;
          queue.add(_QueueNode(edge.toNodeId, alt));
        }
      }
    }

    if (prev[goalId] == null && startId != goalId) return const [];

    final path = <int>[];
    var cursor = goalId;
    while (cursor != startId) {
      path.add(cursor);
      final parent = prev[cursor];
      if (parent == null) return const [];
      cursor = parent;
    }
    path.add(startId);
    return path.reversed.toList();
  }

  static double _haversine(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final dLat = _toRad(b.latitude - a.latitude);
    final dLng = _toRad(b.longitude - a.longitude);
    final lat1 = _toRad(a.latitude);
    final lat2 = _toRad(b.latitude);

    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(dLng / 2), 2);
    return 2 * earthRadius * math.asin(math.sqrt(h));
  }

  static double _toRad(double deg) => deg * math.pi / 180.0;
}

class VenueAdjacencyEdge {
  const VenueAdjacencyEdge(this.toNodeId, this.distanceMeters);
  final int toNodeId;
  final double distanceMeters;
}

class _QueueNode {
  const _QueueNode(this.nodeId, this.cost);
  final int nodeId;
  final double cost;
}

/// Minimal binary heap priority queue for Dijkstra.
class PriorityQueue<T> {
  PriorityQueue(this.compare);
  final int Function(T a, T b) compare;
  final List<T> _heap = [];

  bool get isNotEmpty => _heap.isNotEmpty;

  void add(T value) {
    _heap.add(value);
    _bubbleUp(_heap.length - 1);
  }

  T removeFirst() {
    final root = _heap.first;
    final last = _heap.removeLast();
    if (_heap.isNotEmpty) {
      _heap[0] = last;
      _bubbleDown(0);
    }
    return root;
  }

  void _bubbleUp(int index) {
    while (index > 0) {
      final parent = (index - 1) ~/ 2;
      if (compare(_heap[index], _heap[parent]) >= 0) break;
      _swap(index, parent);
      index = parent;
    }
  }

  void _bubbleDown(int index) {
    while (true) {
      final left = index * 2 + 1;
      final right = left + 1;
      var smallest = index;

      if (left < _heap.length &&
          compare(_heap[left], _heap[smallest]) < 0) {
        smallest = left;
      }
      if (right < _heap.length &&
          compare(_heap[right], _heap[smallest]) < 0) {
        smallest = right;
      }
      if (smallest == index) return;
      _swap(index, smallest);
      index = smallest;
    }
  }

  void _swap(int a, int b) {
    final tmp = _heap[a];
    _heap[a] = _heap[b];
    _heap[b] = tmp;
  }
}

extension ExpoDubaiGraphDefaults on ExpoDubaiGraph {
  LatLng get defaultCenter => ExpoDubaiVenue.center;
}
