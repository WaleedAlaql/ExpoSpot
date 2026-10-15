
package com.nawaf.meetingpoint.Navigation.Graph;

import java.util.List;
import java.util.Map;

public record VenueGraph(
        Map<Long, GraphNode> nodes,
        List<GraphEdge> edges,
        List<MeetingPoint> meetingPoints,
        Map<Long, List<GraphEdge>> adjacency
) {}
