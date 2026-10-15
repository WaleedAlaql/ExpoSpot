# ExpoSpot navigation and live location integration

## Scope and existing architecture

Java 21 target, Spring Boot 4.1.1, Jackson 3, JPA/MySQL, existing simple STOMP broker and JTS 1.20.0. Existing `GraphLoader` loads immutable graph/adjacency once. Existing `GraphService`, navigation records, meeting point response, `/ws` configuration, `ApiResponse` error envelope and group membership repository are reused. No entity/schema changes, lifecycle changes, AI changes, dependencies, frontend, security, or tests were added. The existing application.properties edits were preserved.

Implemented node routing, GPS projection and routing, minimax optimization, persisted latest locations, freshness transitions, typed group messages, and reusable meeting event publication. New success responses are plain DTOs, matching existing controllers. Errors retain `{"message":"..."}`.

## Data and algorithm assumptions

The checked-in graph has 4,705 nodes, 4,813 edges, 57 disconnected components and three meeting-point candidates. All current edges are bidirectional; the implementation also supports directed edges. Edges describe straight segments between graph nodes. The supplied coordinates span latitude 24.9496171–24.972146 and longitude 55.1353919–55.1707365, **not Riyadh**. Meeting points are explicitly provisional and access-unverified in the source JSON. Replace/verify venue data before use at Expo 2030; routing does not establish real-world access or accessibility. Source metadata is tolerated by the loader but not exposed as internal adjacency maps.

The loader now honors positive finite `distanceMeters` from JSON, falling back to Haversine only when absent. Node-to-node routing uses a priority queue with predecessor reconstruction and ignores obsolete queue entries. Haversine is used only if **every** loaded edge weight is at least the corresponding Haversine distance; otherwise its heuristic is zero (Dijkstra). Rounded weights in this dataset require the safe fallback. Identical endpoints produce a one-point, zero-distance route. There are no database queries inside graph traversal.

Map matching builds one JTS STRtree of edges. It projects onto nearby segments in a local metric plane and uses Haversine for the final maximum-distance check. This approximation is intended for a small venue, not a global/antimeridian graph. A snapped position has a fraction from 0 (from-node) to 1 (to-node). Departures and arrivals include proportional edge weights, honor directions, and allow all incident paths at an exact endpoint. GPS-to-GPS routing also considers a direct partial segment on the same edge. No shared graph mutation or request-time JSON loading occurs. GPS route endpoint IDs and projected path point IDs are null when inside an edge. Off-graph distance from raw GPS to the snapped position is reported separately and is **not** counted as walkable distance or drawn as a route.

Optimization resolves fresh locations once, matches each participant, and performs one multi-source Dijkstra traversal per participant. All candidate costs reuse those distance trees; complete paths are reconstructed only for the winner. Complexity is approximately O(participants × (V+E) log V), plus candidate scoring. It excludes any candidate unreachable by a participant and orders candidates by maximum unrounded ETA, total unrounded ETA, total distance, then lexical meeting-point ID. Participant output is sorted by user ID. A single participant is supported; empty lists, duplicates and lists over 100 are rejected. Candidate coordinates use the linked navigable node; no off-graph connection is invented for a label whose coordinates differ.

## Configuration

Defaults are in constructor annotations; no application.properties edit is required. Optional properties:

```properties
navigation.walking-speed-mps=1.4
navigation.max-snap-distance-meters=50
navigation.location-freshness-seconds=120
navigation.location-broadcast-interval-ms=10000
```

Distances are meters. The existing `RouteResponse.estimatedDurationSeconds` remains a whole number rounded upward. Optimization and participant navigation `etaSeconds` are unrounded seconds, preserving minimax tie-breaking precision.

## REST contract and examples

All examples below are JSON. Use `Content-Type: application/json`. `groupId` and `userId` must identify existing memberships for contextual operations. Graph node IDs are Java `Long`; user/group/meeting IDs are `Integer`.

### POST /api/v1/navigation/route

Request:
```json
{"fromNodeId":3206,"toNodeId":3206}
```
Response 200 (named `R` in the examples below):
```json
{"fromNodeId":3206,"toNodeId":3206,"distanceMeters":0.0,"estimatedDurationSeconds":0,"path":[{"nodeId":3206,"latitude":24.957803,"longitude":55.1562148}]}
```
Use different IDs for a nonzero route; the path includes all ordered intermediate nodes.

### POST /api/v1/navigation/map-match

Request:
```json
{"latitude":24.957803,"longitude":55.1562148}
```
Response 200 shape (edge IDs/fraction depend on the selected incident edge):
```json
{"latitude":24.957803,"longitude":55.1562148,"distanceFromGpsMeters":0.0,"fromNodeId":3206,"toNodeId":3210,"fraction":0.0,"edgeDistanceMeters":12.5,"bidirectional":true}
```
The edge fields above are illustrative, not a claim about this node's actual incident edge. At interior projections, `fraction` is between zero and one and `distanceFromGpsMeters` may be nonzero.

### POST /api/v1/navigation/route/gps

Request (named `G` below):
```json
{"start":{"latitude":24.957803,"longitude":55.1562148},"destination":{"latitude":24.957803,"longitude":55.1562148}}
```
Response 200: `{"start": <MapMatchResponse>, "destination": <MapMatchResponse>, "route": <R>}`. Both map matches use the shape above with actual incident-edge values. For this identical-point example the route is `R`. Both endpoints can be interior edge positions.

### POST /api/v1/navigation/optimize

Request using persisted active locations (named `O` below):
```json
{"groupId":1,"participants":[{"userId":7}]}
```
Alternatively provide explicit GPS observations. Replace `updatedAt` with a current UTC instant within the freshness window:
```json
{"participants":[{"userId":7,"latitude":24.957803,"longitude":55.1562148,"updatedAt":"2026-10-15T10:30:00Z"}]}
```
`groupId` is optional with explicit GPS; when provided, every participant must belong to that group. Coordinate pairs must be complete. Explicit GPS requires `updatedAt`; future timestamps are rejected. Omitted coordinates require group context and an ACTIVE stored location.

Response 200 for the participant located at Earth Plaza (named `M` below):
```json
{"meetingPoint":{"id":"mp-986398789","name":"Earth Plaza","nodeId":3206,"latitude":24.957803,"longitude":55.1562148},"maxEtaSeconds":0.0,"totalEtaSeconds":0.0,"totalDistanceMeters":0.0,"participants":[{"userId":7,"distanceMeters":0.0,"etaSeconds":0.0,"path":[{"nodeId":3206,"latitude":24.957803,"longitude":55.1562148}]}]}
```
This endpoint calculates only; it does not broadcast or change a meeting.

### GET /api/v1/navigation/meeting-points

No request body. Response 200:
```json
[
  {"id":"mp-986398789","name":"Earth Plaza","nodeId":3206,"latitude":24.957803,"longitude":55.1562148},
  {"id":"mp-986398790","name":"Sea Plaza","nodeId":1081,"latitude":24.9566629,"longitude":55.1462239},
  {"id":"mp-986398791","name":"Sun Plaza","nodeId":2387,"latitude":24.9670353,"longitude":55.1530789}
]
```

### GET /api/v1/navigation/graph

No request body. Response 200 shape (lists abbreviated here):
```json
{"nodes":[{"id":3206,"latitude":24.957803,"longitude":55.1562148}],"edges":[{"fromNodeId":3074,"toNodeId":3045,"distanceMeters":24.119,"bidirectional":true}],"meetingPoints":[{"id":"mp-986398789","name":"Earth Plaza","nodeId":3206,"latitude":24.957803,"longitude":55.1562148}]}
```
The actual response includes every node, original edge, and meeting point. Reverse adjacency duplicates and source metadata are omitted.

### PUT /api/v1/group/{groupId}/locations

REST fallback for location sharing. Request for group 1 (named `L` below):
```json
{"groupId":1,"userId":7,"latitude":24.957803,"longitude":55.1562148,"accuracyMeters":4.0}
```
Optional `updatedAt` is an ISO UTC measurement timestamp; omitted means server receipt time. Supply it for clients that queue/retry observations, so out-of-order measurements can be detected. Group ID must match the URL or STOMP destination.

Response 200 (named `U` below; timestamp is generated by the server):
```json
{"groupId":1,"userId":7,"latitude":24.957803,"longitude":55.1562148,"accuracyMeters":4.0,"status":"ACTIVE","updatedAt":"2026-10-15T10:30:00.123456Z"}
```
Submitting a location explicitly enables `locationSharingEnabled` for that membership. Older or equal timestamps are ignored, returning the current location. Rejected or ignored updates emit no change event. Updates outside the graph can be stored; routing and optimization subsequently enforce snapping limits.

### GET /api/v1/group/{groupId}/locations

No request body. Response 200 includes every current group member, sorted by user ID:
```json
[
  {"groupId":1,"userId":7,"latitude":24.957803,"longitude":55.1562148,"accuracyMeters":4.0,"status":"ACTIVE","updatedAt":"2026-10-15T10:30:00.123456Z"},
  {"groupId":1,"userId":8,"latitude":null,"longitude":null,"accuracyMeters":null,"status":"MISSING","updatedAt":null}
]
```
`STALE` retains coordinates/timestamp for display but is rejected for optimization. `MISSING` covers no observation or disabled sharing and hides the stored coordinates. These are location availability statuses, separate from `GroupMember.status` (IDLE/NAVIGATING/ARRIVED).

### POST /api/v1/navigation/groups/{groupId}/recommendation

Request: `O`, or the explicit-participant variant above. Response 200: `M`. Also publishes `MEETING_POINT_RECOMMENDED` on the group navigation topic. The path group is used if the body's groupId is omitted. Conflicting group IDs are rejected.

### POST /api/v1/navigation/groups/{groupId}/routes

Request:
```json
{"userId":7,"route":{"start":{"latitude":24.957803,"longitude":55.1562148},"destination":{"latitude":24.957803,"longitude":55.1562148}}}
```
Response 200 is the same `GpsRouteResponse` as `/route/gps`. Also publishes `NAVIGATION_UPDATED` with the user's recalculated route on the group navigation topic. Membership is checked; no meeting state is changed.

### Errors

| Status | Conditions |
|---|---|
| 400 | Invalid coordinates, IDs, payload, timestamp, duplicate/empty participants, mismatched group context |
| 404 | Unknown node, group, or membership |
| 409 | Missing or stale participant observation for optimization |
| 422 | GPS beyond snapping limit, unreachable route, no candidate reachable by everyone |

Example: `{"message":"No meeting point is reachable by all participants"}`. Existing unrelated exception behavior is unchanged.

## STOMP destinations and examples

Connect with native STOMP over WebSocket at `ws://localhost:8080/ws` (no SockJS). Existing allowed-origin policy is unchanged. Application prefix is `/app`, broker prefix is `/topic`. Send JSON with content type `application/json`.

| Client SEND destination | JSON body | Effect |
|---|---|---|
| `/app/groups/1/location` | `L` above, optionally `updatedAt` | Persist latest location; publish material change after commit |
| `/app/groups/1/recommendation` | `O` above | Explicit optimization; publish recommendation |
| `/app/groups/1/routes` | Routes request above | Recalculate and publish participant route |

Subscribe destinations:

| Destination | Events and `data` payload |
|---|---|
| `/topic/groups/1/locations` | `LOCATION_UPDATED`: `U`; `LOCATIONS_CHANGED`: array from group locations GET |
| `/topic/groups/1/navigation` | `MEETING_POINT_RECOMMENDED`: `M`; `NAVIGATION_UPDATED`: array of participant route responses |
| `/topic/meetings/2/navigation` | Same recommendation/route events, published when another developer supplies a meetingId |
| `/topic/meetings/2/updates` | `MEETING_STATUS_UPDATED`: existing `MeetingStatusResponse` |
| `/user/topic/errors` | Session-only `{"message":"..."}` for validation/conversion/functional message errors |

Full location message:
```json
{"event":"LOCATION_UPDATED","groupId":1,"meetingId":null,"occurredAt":"2026-10-15T10:30:00.123456Z","data":{"groupId":1,"userId":7,"latitude":24.957803,"longitude":55.1562148,"accuracyMeters":4.0,"status":"ACTIVE","updatedAt":"2026-10-15T10:30:00.123456Z"}}
```
Availability message: same envelope with `event: "LOCATIONS_CHANGED"`, and `data: [U, ...]` as in the GET response. This is a full membership/location snapshot, including missing/stale members.

Recommendation message: same envelope with `event: "MEETING_POINT_RECOMMENDED"`, `data: M` and the selected context IDs.

Full navigation message:
```json
{"event":"NAVIGATION_UPDATED","groupId":1,"meetingId":null,"occurredAt":"2026-10-15T10:30:00Z","data":[{"userId":7,"distanceMeters":0.0,"etaSeconds":0.0,"path":[{"nodeId":3206,"latitude":24.957803,"longitude":55.1562148}]}]}
```
Full meeting update message (published by the meeting module):
```json
{"event":"MEETING_STATUS_UPDATED","groupId":1,"meetingId":2,"occurredAt":"2026-10-15T10:30:00Z","data":{"meetingId":2,"status":"NAVIGATING","meetingPoint":{"id":"mp-986398789","name":"Earth Plaza","nodeId":3206,"latitude":24.957803,"longitude":55.1562148},"maxEtaSeconds":0}}
```

Location broadcasts occur for changed availability, movement of at least one meter from the last published snapshot, changed accuracy, or a newer observation after 30 seconds. Availability snapshots (including first appearance, membership changes and stale transitions) are polled every 10 seconds by default and have up to one polling interval of broadcast delay. Location deltas are sent immediately after commit. REST freshness is evaluated immediately. Timestamp-only updates are persisted even when broadcasts are suppressed. GPS updates never invoke optimization.

## Public integration methods

- `GraphService.getGraph/getNode/getNodes/getEdges/getNeighbors/getMeetingPoints/getMeetingPoint`: existing immutable graph access.
- `RoutingService.route(Long from, Long to)`: node route.
- `RoutingService.search(Map<Long,Double> starts, Long target)`: weighted starting endpoints; null target computes all reachable nodes. `SearchTree` is immutable. `path(tree,end)`, `seconds(distance)`, `response(...)` support reuse.
- `MapMatchingService.match(Double latitude, Double longitude)`: bounded edge projection; `route(GpsRouteRequest)` handles GPS endpoints. `departures(match)` and `pathFrom(match,tree,end)` support optimization. Use match objects returned by this service, not fabricated client edge data.
- `MeetingOptimizerService.optimize(MeetingOptimizationRequest)`: recommendation without lifecycle mutation/broadcast; `meetingPoints()` returns navigable candidates.
- `LocationService.update(LocationUpdateRequest)`: transactional latest-location storage; `getGroupLocations(Integer)`, `resolve(Integer,ParticipantLocationDTO)`, `resolveParticipants(Integer,List<ParticipantLocationDTO>)`, `requireMembership(Integer,Integer)` for lookup and freshness/membership checks.
- `NavigationService.recommend(Integer groupId,MeetingOptimizationRequest)` and `recalculate(Integer groupId,NavigationUpdateRequest)`: explicit group broadcast orchestration.
- `RealtimeEventPublisher.publishLocation(MemberLocationResponse)` / `publishLocations(Integer,List<MemberLocationResponse>)`.
- `RealtimeEventPublisher.publishRecommendation(Integer groupId,Integer meetingId,MeetingOptimizationResponse)` and `publishRoutes(Integer groupId,Integer meetingId,List<ParticipantRouteResponse>)`: publish to either or both contexts; at least one ID is required.
- `RealtimeEventPublisher.publishMeetingStatus(Integer groupId,MeetingStatusResponse)`: meeting updates topic. Other modules should call publishers only after their state transaction commits.

Public DTO-taking services expect validated structural input, as enforced on controllers; optimizer also guards empty/duplicate participant input and location/routing services validate their functional invariants.

## Persistence, concurrency and remaining integration

Locations reuse existing `GroupMember.latitude/longitude/accuracyMeters/lastLocationAt/locationSharingEnabled`; no parallel in-memory location source is introduced. Time is stored as UTC in the existing `LocalDateTime` column at microsecond precision and exposed as ISO `Instant`. Historical values previously written in another timezone need interpretation by their owner. Row locking serializes concurrent updates across backend instances. The membership lookup uses native `SELECT ... FOR UPDATE` inside the update transaction, avoiding the dialect-generated `FOR UPDATE OF alias` form rejected by the reported MariaDB server. Latest observation wins; equal timestamps are treated as duplicate. Client clocks must be synchronized; future observations are rejected. Without client timestamps only arrival ordering can be established.

The location store survives restarts and is shared through MySQL. Only broadcast-deduplication snapshots and the existing simple STOMP broker are process-local. This broker does not distribute messages between instances, does not provide durable delivery/replay, and a broker failure can lose an event; GET provides recovery on reconnect. Polling can recover current location snapshots, not every intermediate observation. Multi-instance real-time fanout would need infrastructure outside this task. The small MVP broadcaster serializes snapshot publication and polls sharing groups; large deployments will need a different scheduling/fanout strategy.

No authentication or subscription authorization was added by request. Membership checks establish group consistency, but client-asserted user IDs do not prove identity, and topics are not protected. Existing WebSocket/CORS origin configuration remains in place.

Meeting developers still own selection persistence, lifecycle transitions, arrival, completion, membership changes and sharing controls. They can call the optimizer, persist its chosen point, and publish after commit. No meetingId is accepted by the new public recommendation APIs because meeting-context validation and lifecycle integration belong to that module. Meeting topics are ready through publisher methods. Member removal or disabling sharing is reflected by polling for groups already observed by this instance; new clients should always GET the current group snapshot when connecting.

## Verification

Compilation only: `./mvnw -Dmaven.test.skip=true compile`. No tests were added, compiled, or run; no live database/server/WebSocket execution was performed. Compilation validates Java integration, not runtime database configuration, messaging delivery, or route correctness against real-world venue paths.

## File manifest

Modified existing files:

- `src/main/java/com/nawaf/meetingpoint/Advice/ControllerAdvice.java`
- `src/main/java/com/nawaf/meetingpoint/Config/WebSocketConfig.java`
- `src/main/java/com/nawaf/meetingpoint/DTO/Location/LocationUpdateRequest.java`
- `src/main/java/com/nawaf/meetingpoint/DTO/Location/MemberLocationResponse.java`
- `src/main/java/com/nawaf/meetingpoint/Navigation/Graph/GraphNode.java`
- `src/main/java/com/nawaf/meetingpoint/Navigation/Graph/MeetingPoint.java`
- `src/main/java/com/nawaf/meetingpoint/Navigation/Loader/GraphLoader.java`
- `src/main/java/com/nawaf/meetingpoint/Repository/GroupMemberRepository.java`
- `src/main/java/com/nawaf/meetingpoint/Service/GraphService.java`

Created files:

- `src/main/java/com/nawaf/meetingpoint/Api/NavigationException.java`
- `src/main/java/com/nawaf/meetingpoint/Config/LocationSchedulingConfig.java`
- `src/main/java/com/nawaf/meetingpoint/Controller/LocationController.java`
- `src/main/java/com/nawaf/meetingpoint/Controller/NavigationController.java`
- `src/main/java/com/nawaf/meetingpoint/Controller/NavigationWebSocketController.java`
- `src/main/java/com/nawaf/meetingpoint/DTO/Navigation/GpsPosition.java`
- `src/main/java/com/nawaf/meetingpoint/DTO/Navigation/GpsRouteRequest.java`
- `src/main/java/com/nawaf/meetingpoint/DTO/Navigation/GpsRouteResponse.java`
- `src/main/java/com/nawaf/meetingpoint/DTO/Navigation/GraphResponse.java`
- `src/main/java/com/nawaf/meetingpoint/DTO/Navigation/MapMatchResponse.java`
- `src/main/java/com/nawaf/meetingpoint/DTO/Navigation/MeetingOptimizationRequest.java`
- `src/main/java/com/nawaf/meetingpoint/DTO/Navigation/MeetingOptimizationResponse.java`
- `src/main/java/com/nawaf/meetingpoint/DTO/Navigation/NavigationUpdateRequest.java`
- `src/main/java/com/nawaf/meetingpoint/DTO/Navigation/ParticipantLocationDTO.java`
- `src/main/java/com/nawaf/meetingpoint/DTO/Navigation/ParticipantRouteResponse.java`
- `src/main/java/com/nawaf/meetingpoint/DTO/Navigation/RealtimeEventDTO.java`
- `src/main/java/com/nawaf/meetingpoint/Navigation/Geo.java`
- `src/main/java/com/nawaf/meetingpoint/Service/LocationBroadcastService.java`
- `src/main/java/com/nawaf/meetingpoint/Service/LocationService.java`
- `src/main/java/com/nawaf/meetingpoint/Service/MapMatchingService.java`
- `src/main/java/com/nawaf/meetingpoint/Service/MeetingOptimizerService.java`
- `src/main/java/com/nawaf/meetingpoint/Service/NavigationService.java`
- `src/main/java/com/nawaf/meetingpoint/Service/RealtimeEventPublisher.java`
- `src/main/java/com/nawaf/meetingpoint/Service/RoutingService.java`
- `docs/navigation-api.md`
