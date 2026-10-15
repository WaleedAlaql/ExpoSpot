
package com.nawaf.meetingpoint.Service;

import com.nawaf.meetingpoint.Navigation.Graph.GraphEdge;
import com.nawaf.meetingpoint.Navigation.Graph.GraphNode;
import com.nawaf.meetingpoint.Navigation.Graph.MeetingPoint;
import com.nawaf.meetingpoint.Navigation.Graph.VenueGraph;
import com.nawaf.meetingpoint.Navigation.Loader.GraphLoader;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
@RequiredArgsConstructor
public class GraphService {

    private final GraphLoader graphLoader;

    // Get the entire venue graph
    public VenueGraph getGraph() {
        return graphLoader.getGraph();
    }

    // Get a specific node by ID
    public GraphNode getNode(Long nodeId) {
        GraphNode node = getGraph().nodes().get(nodeId);

        if (node == null) {
            throw new IllegalArgumentException(
                    "Graph node not found: " + nodeId
            );
        }

        return node;
    }

    // Get all nodes
    public List<GraphNode> getNodes() {
        return List.copyOf(getGraph().nodes().values());
    }

    // Get outgoing edges from a specific node
    public List<GraphEdge> getNeighbors(Long nodeId) {
        getNode(nodeId);
        return getGraph().adjacency().get(nodeId);
    }

    // Get all original edges
    public List<GraphEdge> getEdges() {
        return getGraph().edges();
    }

    // Get all meeting points
    public List<MeetingPoint> getMeetingPoints() {
        return getGraph().meetingPoints();
    }

    // Get a specific meeting point by ID
    public MeetingPoint getMeetingPoint(String meetingPointId) {
        return getMeetingPoints().stream()
                .filter(point -> point.id().equals(meetingPointId))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException(
                        "Meeting point not found: " + meetingPointId
                ));
    }

    // Check whether a node exists
    public boolean nodeExists(Long nodeId) {
        return getGraph().nodes().containsKey(nodeId);
    }

    // Check whether a meeting point exists
    public boolean meetingPointExists(String meetingPointId) {
        return getMeetingPoints().stream()
                .anyMatch(point -> point.id().equals(meetingPointId));
    }

    // Get number of nodes
    public int getNodeCount() {
        return getGraph().nodes().size();
    }

    // Get number of edges
    public int getEdgeCount() {
        return getGraph().edges().size();
    }

    // Get number of meeting points
    public int getMeetingPointCount() {
        return getGraph().meetingPoints().size();
    }
}
