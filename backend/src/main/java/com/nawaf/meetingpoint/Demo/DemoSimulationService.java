package com.nawaf.meetingpoint.Demo;

import com.nawaf.meetingpoint.Api.NavigationException;
import com.nawaf.meetingpoint.DTO.Meeting.MeetingPointResponse;
import com.nawaf.meetingpoint.DTO.Navigation.*;
import com.nawaf.meetingpoint.Navigation.Geo;
import com.nawaf.meetingpoint.Service.*;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ThreadLocalRandom;

@Service
@RequiredArgsConstructor
@Slf4j
@ConditionalOnProperty(name = "app.simulator.enabled", havingValue = "true")
public class DemoSimulationService {
    private static final int MAX_SESSIONS = 50;
    private static final long IDLE_MILLIS = 60 * 60 * 1000;
    private final GraphService graph;
    private final RoutingService routing;
    private final MapMatchingService matching;
    private final MeetingOptimizerService optimizer;
    private final DemoRealtimePublisher publisher;
    private final Map<String, Session> sessions = new ConcurrentHashMap<>();

    public synchronized DemoDtos.State create() {
        if (sessions.size() >= MAX_SESSIONS) throw new NavigationException(429, "Demo session limit reached; idle sessions expire after one hour");
        Session session = new Session(UUID.randomUUID().toString());
        sessions.put(session.id, session);
        return snapshot(session, true);
    }

    public DemoDtos.State get(String id) {
        Session session = session(id);
        synchronized (session) {
            session.lastAccess = System.currentTimeMillis();
            return snapshot(session, true);
        }
    }

    public DemoDtos.State command(String id, DemoDtos.Command command) {
        Session session = session(id);
        synchronized (session) {
            session.lastAccess = System.currentTimeMillis();
            String event;
            switch (command.action()) {
                case SPAWN -> { spawn(session, command.count() == null ? 3 : command.count()); event = "VISITORS_SPAWNED"; }
                case OPTIMIZE -> { optimize(session); event = "MEETING_POINT_RECOMMENDED"; }
                case ROUTES -> { routes(session); event = "NAVIGATION_UPDATED"; }
                case START -> {
                    if (session.visitors.isEmpty() || session.visitors.stream().anyMatch(v -> v.path.isEmpty()))
                        throw new NavigationException(409, "Calculate visitor routes first");
                    if (session.visitors.stream().allMatch(v -> v.remaining() <= 0))
                        throw new NavigationException(409, "All visitors have arrived; spawn visitors to begin again");
                    session.running = true;
                    session.lastTick = System.nanoTime();
                    event = "SIMULATION_STARTED";
                }
                case PAUSE -> { session.running = false; event = "SIMULATION_PAUSED"; }
                case RESET -> {
                    session.running = false; session.visitors = new ArrayList<>(); session.meetingPoint = null;
                    session.maxEta = null; session.totalDistance = null; session.routeRevision++;
                    event = "SIMULATION_RESET";
                }
                case SPEED -> {
                    if (command.speed() == null || !Double.isFinite(command.speed()) || command.speed() < 0.2 || command.speed() > 100)
                        throw new NavigationException(400, "Demo walking speed must be between 0.2 and 100 m/s");
                    session.speed = command.speed(); event = "SPEED_CHANGED";
                }
                default -> throw new NavigationException(400, "Unknown simulation action");
            }
            session.revision++;
            DemoDtos.State state = snapshot(session, true);
            publisher.publish("navigation", event, state);
            return state;
        }
    }

    private Session session(String id) {
        Session session = sessions.get(id);
        if (session == null) throw new NavigationException(404, "Simulation not found or expired; create a new simulation");
        return session;
    }

    private void spawn(Session session, int count) {
        if (count < 3 || count > 4) throw new NavigationException(400, "Choose three or four visitors");
        var candidate = graph.getMeetingPoints().stream().findFirst()
                .orElseThrow(() -> new NavigationException(422, "Graph has no meeting-point candidates"));
        // Reuse the routing engine to choose reachable nodes; no second graph algorithm.
        var tree = routing.search(Map.of(candidate.nodeId(), 0.0), null);
        List<Long> nodes = tree.distances().entrySet().stream()
                .filter(e -> e.getValue() > 0).sorted(Map.Entry.<Long, Double>comparingByValue().thenComparing(Map.Entry.comparingByKey()))
                .map(Map.Entry::getKey).toList();
        if (nodes.size() < count) throw new NavigationException(422, "Not enough reachable nodes to spawn visitors");
        List<Long> pool = new ArrayList<>(nodes);
        Collections.shuffle(pool, ThreadLocalRandom.current());
        List<Walker> visitors = new ArrayList<>();
        Set<Long> used = new HashSet<>();
        for (int i = 0; i < count; i++) {
            Long selected = null;
            for (Long nodeId : pool) {
                if (used.contains(nodeId)) continue;
                try {
                    routing.route(nodeId, candidate.nodeId());
                    selected = nodeId;
                    break;
                } catch (NavigationException e) {
                    if (e.getStatus() != 422) throw e;
                }
            }
            if (selected == null) throw new NavigationException(422, "Not enough nodes can reach the meeting point");
            used.add(selected);
            var node = graph.getNode(selected);
            visitors.add(new Walker(i + 1, node.latitude(), node.longitude(), "Node " + selected));
        }
        session.running = false; session.visitors = visitors; session.meetingPoint = null;
        session.maxEta = null; session.totalDistance = null; session.routeRevision++;
    }

    private void optimize(Session session) {
        if (session.visitors.isEmpty()) throw new NavigationException(409, "Spawn visitors first");
        Instant now = Instant.now();
        // Null group context plus explicit coordinates uses the existing optimizer's
        // stateless path: no User, Group, GroupMember, or location persistence.
        var result = optimizer.optimize(new MeetingOptimizationRequest(null, session.visitors.stream()
                .map(v -> new ParticipantLocationDTO(v.id, v.latitude, v.longitude, now)).toList()));
        session.running = false;
        session.meetingPoint = result.meetingPoint(); session.maxEta = result.maxEtaSeconds();
        session.totalDistance = result.totalDistanceMeters();
        for (var route : result.participants()) {
            Walker visitor = session.visitors.stream().filter(v -> v.id == route.userId()).findFirst().orElseThrow();
            assign(visitor, route.path(), route.distanceMeters());
        }
        session.routeRevision++;
    }

    private void routes(Session session) {
        if (session.meetingPoint == null) throw new NavigationException(409, "Find a meeting point first");
        List<GpsRouteResponse> results = session.visitors.stream().map(v -> matching.route(new GpsRouteRequest(
                new GpsPosition(v.latitude, v.longitude),
                new GpsPosition(session.meetingPoint.latitude(), session.meetingPoint.longitude())))).toList();
        // Apply only after all calculations succeed, keeping failed commands atomic.
        session.running = false;
        for (int i = 0; i < results.size(); i++) {
            var route = results.get(i).route();
            assign(session.visitors.get(i), route.path(), route.distanceMeters());
        }
        session.routeRevision++;
    }

    private void assign(Walker visitor, List<RoutePointResponse> path, double distance) {
        visitor.path = List.copyOf(path); visitor.distance = distance; visitor.travelled = 0;
        visitor.segmentLengths = new double[Math.max(0, path.size() - 1)];
        double geometryLength = 0;
        for (int i = 0; i < visitor.segmentLengths.length; i++) {
            var a = path.get(i); var b = path.get(i + 1);
            double length = Geo.meters(a.latitude(), a.longitude(), b.latitude(), b.longitude());
            visitor.segmentLengths[i] = length; geometryLength += length;
        }
        // Scale the polyline's geometric lengths to its authoritative backend distance.
        // This interpolates a returned route; it never computes or selects a path.
        for (int i = 0; i < visitor.segmentLengths.length; i++)
            visitor.segmentLengths[i] = geometryLength == 0 ? 0 : visitor.segmentLengths[i] / geometryLength * distance;
        locate(visitor);
    }

    @Scheduled(fixedDelay = 500)
    public void tick() {
        long now = System.nanoTime();
        for (Session session : sessions.values()) {
            synchronized (session) {
                if (System.currentTimeMillis() - session.lastAccess > IDLE_MILLIS) {
                    sessions.remove(session.id, session); continue;
                }
                if (!session.running) continue;
                // Bound delays so a suspended machine cannot jump visitors to arrival.
                double elapsed = Math.min(1, Math.max(0, (now - session.lastTick) / 1_000_000_000.0));
                session.lastTick = now;
                for (Walker visitor : session.visitors) {
                    visitor.travelled = Math.min(visitor.distance, visitor.travelled + session.speed * elapsed);
                    locate(visitor);
                }
                boolean arrived = session.visitors.stream().allMatch(v -> v.remaining() <= 0);
                if (arrived) session.running = false;
                session.revision++;
                try {
                    publisher.publish("locations", "LOCATIONS_UPDATED", snapshot(session, false));
                    if (arrived) publisher.publish("updates", "MEETING_ARRIVED", snapshot(session, true));
                } catch (RuntimeException e) { log.warn("Demo broadcast failed for {}", session.id, e); }
            }
        }
    }

    private void locate(Walker visitor) {
        if (visitor.path.isEmpty()) return;
        if (visitor.remaining() <= 0) {
            var end = visitor.path.getLast(); visitor.latitude = end.latitude(); visitor.longitude = end.longitude();
            visitor.position = end.nodeId() == null ? "Destination" : "Node " + end.nodeId(); return;
        }
        double progress = visitor.travelled;
        for (int i = 0; i < visitor.segmentLengths.length; i++) {
            double length = visitor.segmentLengths[i];
            if (length <= 0) continue;
            if (progress <= length) {
                var a = visitor.path.get(i); var b = visitor.path.get(i + 1);
                double t = progress / length;
                visitor.latitude = a.latitude() + t * (b.latitude() - a.latitude());
                visitor.longitude = a.longitude() + t * (b.longitude() - a.longitude());
                visitor.position = (a.nodeId() == null ? "Projection" : a.nodeId()) + " → "
                        + (b.nodeId() == null ? "projection" : b.nodeId()); return;
            }
            progress -= length;
        }
    }

    private DemoDtos.State snapshot(Session session, boolean paths) {
        String status = session.visitors.isEmpty() ? "EMPTY" : session.running ? "RUNNING"
                : session.visitors.stream().allMatch(v -> !v.path.isEmpty() && v.remaining() <= 0) ? "ARRIVED" : "PAUSED";
        return new DemoDtos.State(session.id, session.revision, session.routeRevision, status, session.speed,
                session.meetingPoint, session.maxEta, session.totalDistance,
                session.visitors.stream().map(v -> new DemoDtos.Visitor(v.id, "Visitor " + (char) ('A' + v.id - 1),
                        v.latitude, v.longitude, v.position, v.path.isEmpty() ? "WAITING" : v.remaining() <= 0 ? "ARRIVED"
                        : session.running ? "WALKING" : "PAUSED", v.distance, v.remaining(), v.remaining() / session.speed,
                        paths ? v.path : null)).toList());
    }

    private static final class Session {
        final String id;
        long revision, routeRevision, lastTick;
        long lastAccess = System.currentTimeMillis();
        boolean running;
        double speed = 1.4;
        MeetingPointResponse meetingPoint;
        Double maxEta, totalDistance;
        List<Walker> visitors = new ArrayList<>();
        Session(String id) { this.id = id; }
    }
    private static final class Walker {
        final int id;
        double latitude, longitude, distance, travelled;
        String position;
        List<RoutePointResponse> path = List.of();
        double[] segmentLengths = new double[0];
        Walker(int id, double latitude, double longitude, String position) {
            this.id = id; this.latitude = latitude; this.longitude = longitude; this.position = position;
        }
        double remaining() { return Math.max(0, distance - travelled); }
    }
}
