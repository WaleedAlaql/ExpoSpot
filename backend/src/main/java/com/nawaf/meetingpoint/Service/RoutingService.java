package com.nawaf.meetingpoint.Service;

import com.nawaf.meetingpoint.Api.NavigationException;
import com.nawaf.meetingpoint.DTO.Navigation.*;
import com.nawaf.meetingpoint.Navigation.Geo;
import com.nawaf.meetingpoint.Navigation.Graph.*;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import java.util.*;

@Service
public class RoutingService {
    private final GraphService graph;
    private final double speed;
    private final boolean haversineSafe;
    public RoutingService(GraphService graph, @Value("${navigation.walking-speed-mps:1.4}") double speed) {
        if (!Double.isFinite(speed) || speed <= 0) throw new IllegalArgumentException("Walking speed must be positive");
        this.graph = graph; this.speed = speed;
        haversineSafe = graph.getEdges().stream().allMatch(e -> e.distanceMeters() >= heuristic(e.fromNodeId(), e.toNodeId()));
    }
    public RouteResponse route(Long from, Long to) {
        graph.getNode(from); graph.getNode(to);
        SearchTree tree = search(Map.of(from, 0.0), to);
        if (!tree.distances().containsKey(to)) throw new NavigationException(422, "No route available");
        return response(from, to, tree.distances().get(to), path(tree, to));
    }
    // One multi-source Dijkstra traversal is reusable for every optimization candidate.
    public SearchTree search(Map<Long, Double> starts, Long target) {
        Map<Long, Double> distances = new HashMap<>();
        Map<Long, Long> previous = new HashMap<>();
        PriorityQueue<Entry> queue = new PriorityQueue<>(Comparator.comparingDouble(Entry::priority).thenComparingLong(Entry::node));
        starts.entrySet().stream().sorted(Map.Entry.comparingByKey()).forEach(e -> {
            graph.getNode(e.getKey());
            if (!Double.isFinite(e.getValue()) || e.getValue() < 0) throw new NavigationException(400, "Invalid starting distance");
            distances.put(e.getKey(), e.getValue());
            queue.add(new Entry(e.getKey(), e.getValue(), e.getValue()+estimate(e.getKey(),target)));
        });
        while (!queue.isEmpty()) {
            Entry current = queue.poll();
            if (current.distance() != distances.getOrDefault(current.node(), Double.POSITIVE_INFINITY)) continue;
            if (Objects.equals(current.node(), target)) break;
            for (GraphEdge edge : graph.getNeighbors(current.node())) {
                double next = current.distance()+edge.distanceMeters();
                if (next < distances.getOrDefault(edge.toNodeId(), Double.POSITIVE_INFINITY)) {
                    distances.put(edge.toNodeId(), next); previous.put(edge.toNodeId(), current.node());
                    queue.add(new Entry(edge.toNodeId(), next, next+estimate(edge.toNodeId(),target)));
                }
            }
        }
        return new SearchTree(Map.copyOf(distances), Map.copyOf(previous));
    }
    public List<RoutePointResponse> path(SearchTree tree, Long end) {
        if (!tree.distances().containsKey(end)) throw new NavigationException(422, "No route available");
        LinkedList<RoutePointResponse> path = new LinkedList<>();
        for (Long id=end; id!=null; id=tree.previous().get(id)) {
            GraphNode n=graph.getNode(id); path.addFirst(new RoutePointResponse(id,n.latitude(),n.longitude()));
        }
        return List.copyOf(path);
    }
    public double seconds(double distance) { return distance/speed; }
    public RouteResponse response(Long from, Long to, double distance, List<RoutePointResponse> path) {
        return new RouteResponse(from,to,distance,(long)Math.ceil(seconds(distance)),List.copyOf(path));
    }
    private double estimate(Long from, Long to) { return to != null && haversineSafe ? heuristic(from,to) : 0; }
    private double heuristic(Long from, Long to) {
        GraphNode a=graph.getNode(from), b=graph.getNode(to);
        return Geo.meters(a.latitude(),a.longitude(),b.latitude(),b.longitude());
    }
    public record SearchTree(Map<Long,Double> distances, Map<Long,Long> previous) {}
    private record Entry(Long node, double distance, double priority) {}
}
