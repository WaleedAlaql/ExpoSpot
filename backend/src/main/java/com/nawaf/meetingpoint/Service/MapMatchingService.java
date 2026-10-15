package com.nawaf.meetingpoint.Service;

import com.nawaf.meetingpoint.Api.NavigationException;
import com.nawaf.meetingpoint.DTO.Navigation.*;
import com.nawaf.meetingpoint.Navigation.Geo;
import com.nawaf.meetingpoint.Navigation.Graph.*;
import org.locationtech.jts.geom.Envelope;
import org.locationtech.jts.index.strtree.STRtree;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import java.util.*;

@Service
public class MapMatchingService {
    private final GraphService graph;
    private final RoutingService routing;
    private final double maxDistance, xScale;
    private final STRtree index = new STRtree();
    public MapMatchingService(GraphService graph, RoutingService routing,
            @Value("${navigation.max-snap-distance-meters:50}") double maxDistance) {
        if (!Double.isFinite(maxDistance) || maxDistance <= 0) throw new IllegalArgumentException("Invalid snapping distance");
        this.graph=graph; this.routing=routing; this.maxDistance=maxDistance;
        xScale=Math.cos(Math.toRadians(graph.getNodes().stream().mapToDouble(GraphNode::latitude).average().orElseThrow()));
        for (int i=0;i<graph.getEdges().size();i++) {
            GraphEdge e=graph.getEdges().get(i); GraphNode a=graph.getNode(e.fromNodeId()), b=graph.getNode(e.toNodeId());
            index.insert(new Envelope(x(a.longitude()),x(b.longitude()),y(a.latitude()),y(b.latitude())),i);
        }
        index.build();
    }
    private double x(double lon) { return Math.toRadians(lon)*6371000*xScale; }
    private double y(double lat) { return Math.toRadians(lat)*6371000; }
    public MapMatchResponse match(Double latitude, Double longitude) {
        Geo.validate(latitude,longitude);
        // Small venue local tangent-plane projection; final acceptance uses spherical distance.
        double px=x(longitude), py=y(latitude), radius=maxDistance*1.02;
        List<Integer> nearby=new ArrayList<>();
        for (Object item:index.query(new Envelope(px-radius,px+radius,py-radius,py+radius))) nearby.add((Integer)item);
        nearby.sort(Integer::compareTo);
        MapMatchResponse best=null;
        for (int i:nearby) {
            GraphEdge e=graph.getEdges().get(i); GraphNode a=graph.getNode(e.fromNodeId()),b=graph.getNode(e.toNodeId());
            double dx=x(b.longitude())-x(a.longitude()), dy=y(b.latitude())-y(a.latitude());
            double fraction=Math.max(0,Math.min(1,((px-x(a.longitude()))*dx+(py-y(a.latitude()))*dy)/(dx*dx+dy*dy)));
            double lat=a.latitude()+fraction*(b.latitude()-a.latitude()), lon=a.longitude()+fraction*(b.longitude()-a.longitude());
            double distance=Geo.meters(latitude,longitude,lat,lon);
            if (best==null || distance<best.distanceFromGpsMeters())
                best=new MapMatchResponse(lat,lon,distance,e.fromNodeId(),e.toNodeId(),fraction,e.distanceMeters(),e.bidirectional());
        }
        if (best==null || best.distanceFromGpsMeters()>maxDistance)
            throw new NavigationException(422,"Location outside supported navigation area");
        return best;
    }
    public Map<Long,Double> departures(MapMatchResponse p) { return endpoints(p,true); }
    private Map<Long,Double> endpoints(MapMatchResponse p, boolean leaving) {
        Map<Long,Double> result=new HashMap<>();
        if (p.fraction()==0) result.put(p.fromNodeId(),0.0);
        if (p.fraction()==1) result.put(p.toNodeId(),0.0);
        if (leaving || p.bidirectional()) result.merge(p.toNodeId(),(1-p.fraction())*p.edgeDistanceMeters(),Math::min);
        if (!leaving || p.bidirectional()) result.merge(p.fromNodeId(),p.fraction()*p.edgeDistanceMeters(),Math::min);
        return result;
    }
    public List<RoutePointResponse> pathFrom(MapMatchResponse start, RoutingService.SearchTree tree, Long end) {
        List<RoutePointResponse> path=new ArrayList<>(); path.add(point(start));
        for (RoutePointResponse p:routing.path(tree,end)) append(path,p);
        return List.copyOf(path);
    }
    public GpsRouteResponse route(GpsRouteRequest request) {
        MapMatchResponse start=match(request.start().latitude(),request.start().longitude());
        MapMatchResponse end=match(request.destination().latitude(),request.destination().longitude());
        RoutingService.SearchTree tree=routing.search(departures(start),null);
        double best=Double.POSITIVE_INFINITY; List<RoutePointResponse> path=null;
        boolean same=start.fromNodeId().equals(end.fromNodeId()) && start.toNodeId().equals(end.toNodeId());
        if (same && (end.fraction()>=start.fraction() || start.bidirectional())) {
            best=Math.abs(end.fraction()-start.fraction())*start.edgeDistanceMeters();
            path=new ArrayList<>();path.add(point(start));append(path,point(end));
        }
        for (var entry:endpoints(end,false).entrySet().stream().sorted(Map.Entry.comparingByKey()).toList()) {
            double distance=tree.distances().getOrDefault(entry.getKey(),Double.POSITIVE_INFINITY)+entry.getValue();
            if (distance<best) {
                best=distance;path=new ArrayList<>(pathFrom(start,tree,entry.getKey()));append(path,point(end));
            }
        }
        if (path==null) throw new NavigationException(422,"No route available between snapped positions");
        return new GpsRouteResponse(start,end,routing.response(nodeId(start),nodeId(end),best,path));
    }
    private Long nodeId(MapMatchResponse p) { return p.fraction()==0 ? p.fromNodeId() : p.fraction()==1 ? p.toNodeId() : null; }
    private RoutePointResponse point(MapMatchResponse p) { return new RoutePointResponse(nodeId(p),p.latitude(),p.longitude()); }
    private void append(List<RoutePointResponse> path,RoutePointResponse p) {
        RoutePointResponse last=path.getLast();
        if (!last.latitude().equals(p.latitude()) || !last.longitude().equals(p.longitude())) path.add(p);
    }
}
