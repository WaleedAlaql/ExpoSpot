package com.nawaf.meetingpoint.Controller;
import com.nawaf.meetingpoint.DTO.Navigation.*;
import com.nawaf.meetingpoint.DTO.Meeting.MeetingPointResponse;
import com.nawaf.meetingpoint.Service.*;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import java.util.List;
@RestController
@RequestMapping("/api/v1/navigation")
@RequiredArgsConstructor
public class NavigationController {
    private final RoutingService routing;
    private final MapMatchingService matching;
    private final MeetingOptimizerService optimizer;
    private final GraphService graph;
    private final NavigationService navigation;
    @PostMapping("/route")
    public RouteResponse route(@Valid @RequestBody RouteRequest request) { return routing.route(request.fromNodeId(),request.toNodeId()); }
    @PostMapping("/route/gps")
    public GpsRouteResponse gps(@Valid @RequestBody GpsRouteRequest request) { return matching.route(request); }
    @PostMapping("/map-match")
    public MapMatchResponse match(@Valid @RequestBody GpsPosition request) { return matching.match(request.latitude(),request.longitude()); }
    @PostMapping("/optimize")
    public MeetingOptimizationResponse optimize(@Valid @RequestBody MeetingOptimizationRequest request) { return optimizer.optimize(request); }
    @GetMapping("/meeting-points")
    public List<MeetingPointResponse> points() { return optimizer.meetingPoints(); }
    @GetMapping("/graph")
    public GraphResponse graph() { return new GraphResponse(graph.getNodes().stream().sorted(java.util.Comparator.comparing(com.nawaf.meetingpoint.Navigation.Graph.GraphNode::id)).toList(),graph.getEdges(),optimizer.meetingPoints()); }
    @PostMapping("/groups/{groupId}/recommendation")
    public MeetingOptimizationResponse recommend(@PathVariable Integer groupId,@Valid @RequestBody MeetingOptimizationRequest request) { return navigation.recommend(groupId,request); }
    @PostMapping("/groups/{groupId}/routes")
    public GpsRouteResponse recalculate(@PathVariable Integer groupId,@Valid @RequestBody NavigationUpdateRequest request) { return navigation.recalculate(groupId,request); }
}
