package com.nawaf.meetingpoint.Service;
import com.nawaf.meetingpoint.Api.NavigationException;
import com.nawaf.meetingpoint.DTO.Navigation.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import java.util.List;
@Service
@RequiredArgsConstructor
public class NavigationService {
    private final MeetingOptimizerService optimizer;
    private final MapMatchingService matching;
    private final RoutingService routing;
    private final LocationService locations;
    private final RealtimeEventPublisher publisher;
    public MeetingOptimizationResponse recommend(Integer groupId,MeetingOptimizationRequest request) {
        if (request.groupId()!=null && !request.groupId().equals(groupId)) throw new NavigationException(400,"groupId does not match destination");
        var result=optimizer.optimize(new MeetingOptimizationRequest(groupId,request.participants()));
        publisher.publishRecommendation(groupId,null,result);return result;
    }
    public GpsRouteResponse recalculate(Integer groupId,NavigationUpdateRequest request) {
        locations.requireMembership(groupId,request.userId());
        var result=matching.route(request.route());
        publisher.publishRoutes(groupId,null,List.of(new ParticipantRouteResponse(request.userId(),result.route().distanceMeters(),
            routing.seconds(result.route().distanceMeters()),result.route().path())));
        return result;
    }
}
