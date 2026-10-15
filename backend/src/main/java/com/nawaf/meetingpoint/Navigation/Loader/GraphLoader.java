
package com.nawaf.meetingpoint.Navigation.Loader;

import com.nawaf.meetingpoint.Navigation.Graph.*;
import jakarta.annotation.PostConstruct;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;
import tools.jackson.core.type.TypeReference;
import tools.jackson.databind.ObjectMapper;

import java.io.InputStream;
import java.util.*;

@Component
@RequiredArgsConstructor
public class GraphLoader {

    private final ObjectMapper objectMapper;

    @Getter
    private VenueGraph graph;

    @PostConstruct
    public void load() {
        try {
            List<GraphNode> nodeList = read(
                    "map-data/nodes.json",
                    new TypeReference<List<GraphNode>>() {}
            );

            List<GraphEdgeInput> edgeList = read(
                    "map-data/edges.json",
                    new TypeReference<List<GraphEdgeInput>>() {}
            );

            List<MeetingPoint> meetingPoints = read(
                    "map-data/meeting-points.json",
                    new TypeReference<List<MeetingPoint>>() {}
            );

            // Build nodes
            Map<Long, GraphNode> nodes = new HashMap<>();

            for (GraphNode node : nodeList) {
                if (node == null
                        || node.id() == null
                        || !validCoordinates(
                        node.latitude(),
                        node.longitude()
                )) {
                    throw new IllegalStateException(
                            "Invalid node: " + node
                    );
                }

                if (nodes.putIfAbsent(node.id(), node) != null) {
                    throw new IllegalStateException(
                            "Duplicate node ID: " + node.id()
                    );
                }
            }

            if (nodes.isEmpty()) {
                throw new IllegalStateException(
                        "Graph has no nodes"
                );
            }

            // Initialize adjacency list
            Map<Long, List<GraphEdge>> adjacency = new HashMap<>();

            for (Long nodeId : nodes.keySet()) {
                adjacency.put(nodeId, new ArrayList<>());
            }

            // Build edges
            List<GraphEdge> edges = new ArrayList<>();

            for (GraphEdgeInput input : edgeList) {

                if (input == null) {
                    throw new IllegalStateException(
                            "Null edge in edges.json"
                    );
                }

                Long fromId = resolveId(
                        input.fromNodeId(),
                        input.from(),
                        "from"
                );

                Long toId = resolveId(
                        input.toNodeId(),
                        input.to(),
                        "to"
                );

                if (input.bidirectional() == null) {
                    throw new IllegalStateException(
                            "Missing bidirectional: " + input
                    );
                }

                GraphNode from = nodes.get(fromId);
                GraphNode to = nodes.get(toId);

                if (from == null || to == null) {
                    throw new IllegalStateException(
                            "Edge references unknown node: " + input
                    );
                }

                if (fromId.equals(toId)) {
                    throw new IllegalStateException(
                            "Self-loop edge: " + fromId
                    );
                }

                double distance = haversine(
                        from.latitude(),
                        from.longitude(),
                        to.latitude(),
                        to.longitude()
                );

                if (!Double.isFinite(distance) || distance <= 0) {
                    throw new IllegalStateException(
                            "Invalid edge distance: " + input
                    );
                }

                GraphEdge edge = new GraphEdge(
                        fromId,
                        toId,
                        distance,
                        input.bidirectional()
                );

                edges.add(edge);
                adjacency.get(fromId).add(edge);

                if (Boolean.TRUE.equals(edge.bidirectional())) {
                    GraphEdge reverse = new GraphEdge(
                            toId,
                            fromId,
                            distance,
                            true
                    );

                    adjacency.get(toId).add(reverse);
                }
            }

            // Validate meeting points
            Set<String> meetingPointIds = new HashSet<>();

            for (MeetingPoint point : meetingPoints) {

                if (point == null
                        || point.id() == null
                        || point.id().isBlank()
                        || point.name() == null
                        || point.name().isBlank()
                        || point.name().length() > 100
                        || point.nodeId() == null
                        || !validCoordinates(
                        point.latitude(),
                        point.longitude()
                )) {
                    throw new IllegalStateException(
                            "Invalid meeting point: " + point
                    );
                }

                if (!meetingPointIds.add(point.id())) {
                    throw new IllegalStateException(
                            "Duplicate meeting point ID: " + point.id()
                    );
                }

                if (!nodes.containsKey(point.nodeId())) {
                    throw new IllegalStateException(
                            "Meeting point references unknown node: "
                                    + point.nodeId()
                    );
                }

                // A meeting point can be near its graph node,
                // not necessarily at the exact same coordinates.
            }

            // Immutable adjacency
            Map<Long, List<GraphEdge>> immutableAdjacency =
                    new HashMap<>();

            adjacency.forEach((id, neighbors) ->
                    immutableAdjacency.put(
                            id,
                            List.copyOf(neighbors)
                    )
            );

            // Store graph in memory
            graph = new VenueGraph(
                    Map.copyOf(nodes),
                    List.copyOf(edges),
                    List.copyOf(meetingPoints),
                    Map.copyOf(immutableAdjacency)
            );

            System.out.println(
                    "Graph loaded successfully: "
                            + graph.nodes().size() + " nodes, "
                            + graph.edges().size() + " edges, "
                            + graph.meetingPoints().size()
                            + " meeting points"
            );

        } catch (Exception e) {
            throw new IllegalStateException(
                    "Failed to load venue graph", e
            );
        }
    }

    private Long resolveId(
            Long primary,
            Long alternative,
            String field
    ) {
        if (primary != null && alternative != null
                && !primary.equals(alternative)) {
            throw new IllegalStateException(
                    "Conflicting edge " + field + " IDs"
            );
        }

        Long result = primary != null ? primary : alternative;

        if (result == null) {
            throw new IllegalStateException(
                    "Missing edge " + field + " node ID"
            );
        }

        return result;
    }

    private boolean validCoordinates(
            Double latitude,
            Double longitude
    ) {
        return latitude != null
                && longitude != null
                && Double.isFinite(latitude)
                && Double.isFinite(longitude)
                && latitude >= -90
                && latitude <= 90
                && longitude >= -180
                && longitude <= 180;
    }

    private <T> T read(
            String path,
            TypeReference<T> type
    ) throws Exception {

        ClassPathResource resource =
                new ClassPathResource(path);

        try (InputStream stream = resource.getInputStream()) {
            return objectMapper.readValue(stream, type);
        }
    }

    private double haversine(
            double lat1,
            double lon1,
            double lat2,
            double lon2
    ) {
        double earthRadius = 6371000.0;

        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);

        double a = Math.pow(Math.sin(dLat / 2), 2)
                + Math.cos(Math.toRadians(lat1))
                * Math.cos(Math.toRadians(lat2))
                * Math.pow(Math.sin(dLon / 2), 2);

        return 2 * earthRadius
                * Math.asin(Math.sqrt(Math.min(1.0, a)));
    }

    private record GraphEdgeInput(
            Long fromNodeId,
            Long toNodeId,
            Long from,
            Long to,
            Boolean bidirectional
    ) {}
}
