package com.nawaf.meetingpoint.Service;

import com.nawaf.meetingpoint.Api.NavigationException;
import com.nawaf.meetingpoint.DTO.Navigation.*;
import com.nawaf.meetingpoint.DTO.Meeting.MeetingPointResponse;
import com.nawaf.meetingpoint.Navigation.Graph.MeetingPoint;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.*;

@Service
@RequiredArgsConstructor
public class MeetingOptimizerService {
    private final GraphService graph;
    private final RoutingService routing;
    private final MapMatchingService matching;
    private final LocationService locations;
    public MeetingOptimizationResponse optimize(MeetingOptimizationRequest request) {
        if (request==null || request.participants()==null || request.participants().isEmpty() || request.participants().size()>100)
            throw new NavigationException(400,"Provide between 1 and 100 participants");
        Map<Integer,MapMatchResponse> starts=new TreeMap<>();
        Map<Integer,RoutingService.SearchTree> trees=new TreeMap<>();
        Set<Integer> ids = new HashSet<>();
        for (ParticipantLocationDTO input:request.participants()) {
            if (input==null || input.userId()==null || input.userId()<=0 || !ids.add(input.userId()))
                throw new NavigationException(400,"Participant IDs must be positive and unique");
        }
        for (ParticipantLocationDTO p : locations.resolveParticipants(request.groupId(),request.participants())) {
            MapMatchResponse start=matching.match(p.latitude(),p.longitude());
            starts.put(p.userId(),start); trees.put(p.userId(),routing.search(matching.departures(start),null));
        }
        MeetingPoint best=null; double bestMax=Double.POSITIVE_INFINITY,bestTotal=Double.POSITIVE_INFINITY,bestDistance=Double.POSITIVE_INFINITY;
        for (MeetingPoint candidate:graph.getMeetingPoints().stream().sorted(Comparator.comparing(MeetingPoint::id)).toList()) {
            double max=0,total=0,distance=0; boolean reachable=true;
            for (var tree:trees.values()) {
                Double d=tree.distances().get(candidate.nodeId());
                if (d==null) {reachable=false;break;}
                double eta=routing.seconds(d); max=Math.max(max,eta);total+=eta;distance+=d;
            }
            if (reachable && (max<bestMax || (max==bestMax && (total<bestTotal || (total==bestTotal && distance<bestDistance))))) {
                best=candidate;bestMax=max;bestTotal=total;bestDistance=distance;
            }
        }
        if (best==null) throw new NavigationException(422,"No meeting point is reachable by all participants");
        List<ParticipantRouteResponse> routes=new ArrayList<>();
        for (Integer id:trees.keySet()) {
            double d=trees.get(id).distances().get(best.nodeId());
            routes.add(new ParticipantRouteResponse(id,d,routing.seconds(d),matching.pathFrom(starts.get(id),trees.get(id),best.nodeId())));
        }
        return new MeetingOptimizationResponse(point(best),bestMax,bestTotal,bestDistance,List.copyOf(routes));
    }
    public List<MeetingPointResponse> meetingPoints() { return graph.getMeetingPoints().stream().sorted(Comparator.comparing(MeetingPoint::id)).map(this::point).toList(); }
    private MeetingPointResponse point(MeetingPoint p) {
        // The navigable destination is the associated graph node; no invented off-graph connector.
        var node=graph.getNode(p.nodeId());
        return new MeetingPointResponse(p.id(),p.name(),p.nodeId(),node.latitude(),node.longitude());
    }
}
