# ExpoSpot — Flutter navigation integration instructions

Use this document as the implementation brief for a Flutter developer or coding agent. It reflects the current Flutter and Spring source inspected in this workspace. Implement the Flutter integration; do not invent backend endpoints or claim unsupported lifecycle transitions work.

## Objective and scope

Integrate the existing Flutter app at `frontend/expo_spot` with the navigation, live-location and isolated simulation APIs. Preserve its design, Arabic/English localization and Riverpod architecture. Reuse `http`, `flutter_riverpod`, `flutter_map` and `latlong2` already declared in pubspec. Do not rewrite the app, add authentication, or implement backend group/meeting business logic.

Deliver a working demo first, accessible without login or database users. Implement production navigation behind an explicit real-group context only where supported. Clearly mark the missing production integration points listed below. Do not silently mix mock, demo and real data.

Read these existing backend references before implementing:

- `backend/docs/navigation-api.md`
- `backend/docs/navigation-simulator.md`
- `backend/request.http`
- NavigationController, LocationController, NavigationWebSocketController, DemoNavigationController, DemoWebSocketController and their DTOs.

No automated tests are requested for this task. Use formatting, static analysis, compilation and the manual scenarios below; report exactly what was exercised.

## Findings in the current Flutter source

- `lib/core/constants/api_constants.dart`: `useMockBackend = true`; uses unconditional `dart:io` and platform-specific localhost URLs.
- `features/group/application/active_group_controller.dart`: hard-coded members, local `_optimalPoint()` centroid, straight-line `_withEtas()`, local confirmation and arrival toggles, and a fixed list of alternative meeting points.
- `features/group/domain/group_member.dart`: string IDs such as `self`/`m2`, required coordinates and translation-key names; these do not match backend numeric IDs, missing coordinates or literal venue names.
- `features/map/presentation/map_tab.dart`: routes are currently just `[member.position, group.meetPoint]`; initial map coordinates are hard-coded to Riyadh.
- `features/map/widgets/reunion_plan_sheet.dart`: confirmation merely sets a local boolean, and the alternative-point action cycles local coordinates.
- `features/auth/data/auth_api.dart`: expects `{id,name,email}` after POST `/api/v1/user/add`, but the existing backend returns an ApiResponse message. It also sends a password although this backend is not a login system. Do not turn off mock auth and assume this provides a valid production identity.

Remove those mock calculations from connected navigation paths. Keep a preview/mock mode only if explicitly labeled and isolated. Backend route and recommendation data must be authoritative.

## Backend readiness — do not skip

The following currently work:

- Graph retrieval, node/GPS routing and explicit-coordinate optimization.
- Full demo-session creation, spawning, optimization, movement, synchronization and arrival without persisted identities.
- Real-group location updates and group recommendations when actual User/Group/GroupMember records already exist.

The following are missing or not integrated:

1. GroupController and GroupMemberController are empty shells: no create/join/member-list contracts are available.
2. There is no endpoint that persists a recommended point into a Meeting. `start-navigation` rejects meetings whose coordinates have not been set. A recommendation broadcast alone does not save those coordinates.
3. MeetingService does not call RealtimeEventPublisher, so existing lifecycle endpoints do not automatically emit meeting updates.
4. There is no participant-arrival confirmation endpoint. A UI toggle cannot complete this backend workflow.
5. There is no production GET endpoint for the latest shared recommendation/participant routes, nor a sharing-disable endpoint. REST location snapshots exist; navigation events are not durable.
6. Meeting REST responses expose JPA entities rather than a stable, fully integrated Flutter DTO contract. Validate and coordinate that response contract with the meeting owner before relying on it.

Keep unsupported production confirmation, arrival and alternate-point selection disabled or clearly labeled as unavailable. Do not show success after changing only Flutter state. Ask the owning backend developers for these integration contracts; do not fabricate paths or insert fake records. Real production workflow cannot be certified complete until these dependencies are delivered.

## Configuration and connectivity

Add explicit `NavigationMode.demo` and `NavigationMode.production`. Do not reuse `useMockBackend` as a global switch for navigation and auth. Provide a debug/demo entry point that does not pass through login or registration.

Use build configuration, for example:

```dart
const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8080',
);
const navigationMode = String.fromEnvironment(
  'NAVIGATION_MODE',
  defaultValue: 'demo',
);
```

Derive `/ws` from the same base URI: http → ws, https → wss. Do not connect to `/app` as the WebSocket URL. Do not use SockJS; the backend exposes native STOMP on `/ws`.

- Android emulator: use `http://10.0.2.2:8080` to reach the host machine ([Android emulator networking](https://developer.android.com/studio/run/emulator-networking)).
- Local desktop/browser and typical iOS simulator setup: use the backend's reachable loopback URL.
- Physical device: supply the computer's reachable LAN address; phone localhost refers to the phone. Keep development HTTP exceptions narrowly scoped. Do not enable broad release cleartext exceptions.
- Flutter web: avoid unconditional `dart:io` imports. Browser origin must match the current backend localhost/127.0.0.1 origin policy; coordinate an explicit development origin change if using a LAN hostname. Do not indiscriminately allow all origins.

Add a compatible STOMP dependency after checking the actual installed Flutter/Dart SDK. Use the native `StompConfig`, subscribe in `onConnect`, retain unsubscribe callbacks and deactivate on disposal. Follow the package's [official documentation](https://pub.dev/packages/stomp_dart_client), rather than copying a SockJS example. Current backend heartbeat negotiation is 0,0; connection health must also account for socket closure and state recovery.

Only production location mode needs a location plugin. Add a compatible `geolocator` version and follow its [platform permission instructions](https://pub.dev/packages/geolocator) for service availability, denied permission and permanently denied permission. Do not request GPS permission in demo mode. Start with foreground sharing; background tracking is separate work.

Example local launch:

```sh
# Backend (from backend/)
./mvnw -Dmaven.test.skip=true spring-boot:run '-Dspring-boot.run.arguments=--app.simulator.enabled=true'

# Flutter (from frontend/expo_spot/, Android emulator)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080 --dart-define=NAVIGATION_MODE=demo
```

## Architecture to implement

Follow the existing feature layout and StateNotifierProvider style. Suggested additions, adapting names to the repository:

```text
lib/features/navigation/
  domain/navigation_models.dart
  data/navigation_api.dart
  data/demo_simulation_api.dart
  data/navigation_realtime.dart
  application/navigation_controller.dart
  application/navigation_state.dart
  presentation/navigation_demo_screen.dart
```

- API classes own HTTP calls, JSON parsing, timeouts and ApiResponse error conversion.
- A single realtime service owns the active STOMP connection and subscription lifetimes.
- A Riverpod controller coordinates current context, loading/error state, visitor/member state, recommendation, routes, connection status and pending commands.
- Existing map widgets render state; no HTTP, socket or route calculations inside build methods.
- Demo state is keyed by simulationId; production state by groupId and, when integrated, meetingId. Clear state and subscriptions when changing mode/context.
- Track a context generation/request token. Ignore asynchronous results from a previous group/session and stale results from superseded requests.
- Prevent duplicate command submissions. Do not blindly retry non-idempotent session creation or lifecycle operations after timeouts.

## DTO parsing rules

Use typed Dart models matching the existing JSON contracts. Separate production and demo event envelopes.

- Java Integer/Long IDs → Dart `int`, except meeting-point IDs and simulation UUIDs → `String`.
- Parse coordinates, distances and durations through `num` before converting to `double`; JSON can encode a zero as either integer or decimal.
- `RouteResponse`: `fromNodeId`, `toNodeId`, `distanceMeters`, `estimatedDurationSeconds`, `path`.
- `GpsRouteResponse`: `{start: MapMatchResponse, destination: MapMatchResponse, route: RouteResponse}`. Do not parse this as a plain RouteResponse.
- `ParticipantRouteResponse`: `userId`, `distanceMeters`, `etaSeconds`, `path`.
- `MeetingOptimizationResponse`: `meetingPoint`, `maxEtaSeconds`, `totalEtaSeconds`, `totalDistanceMeters`, `participants`.
- Route-point and GPS route endpoint node IDs may be null for edge projections. Preserve every ordered coordinate.
- Production location coordinates, accuracy and updatedAt can be null when MISSING. Never turn null coordinates into (0,0).
- Parse updatedAt/occurredAt as UTC. Seconds are not minutes; meters are not kilometers. Convert only for display and do not clamp ETA to 1–15 minutes.
- Names received from the backend are literal text, not `easy_localization` keys. Keep UI labels localized in both existing translation files.
- Keep location availability (ACTIVE/STALE/MISSING), socket connection state and travel status distinct. An ACTIVE GPS sample does not prove an online connection or arrival.

## Workflow A — demo integration that works now

1. Open demo mode without authentication. GET `/api/v1/navigation/graph`; fit the map to returned graph bounds.
2. Create a session using POST `/api/v1/demo/navigation/simulations` with `{}`, or join using GET `/api/v1/demo/navigation/simulations/{simulationId}`. Preserve the UUID for an explicit reconnect/join action; do not create a new session on every widget rebuild.
3. Connect STOMP `/ws`. In onConnect subscribe to the demo topics below, then GET a full snapshot to recover state. Continue a five-second snapshot refresh while the demo screen is active; this also refreshes the session inactivity timer.
4. Send commands via POST `/api/v1/demo/navigation/simulations/{simulationId}/commands`. Use REST responses for acknowledgments and errors; consume STOMP broadcasts for remote changes. The same result can arrive through both channels—apply it idempotently.
5. SPAWN creates visitors, OPTIMIZE chooses a point and returns routes, START begins server-controlled movement, PAUSE stops it, and START resumes it. ROUTES recalculates to the currently selected destination; OPTIMIZE recalculates the destination itself. Both route operations pause the session; require an explicit START afterward.
6. Render server locations and remaining ETAs. Do not run another Dart movement timer that advances coordinates. Animation is optional and must stay on the assigned path without cutting corners.
7. On authoritative ARRIVED state, update each visitor and show the celebration once for that run. Never send production meeting completion from a demo event.
8. RESET removes visitors and recommendation. SPAWN restarts. A second client joining the same UUID must show the same state. A different UUID must remain isolated.

Commands:

```json
{"action":"SPAWN","count":3}
```
```json
{"action":"OPTIMIZE"}
```
```json
{"action":"ROUTES"}
```
```json
{"action":"START"}
```
```json
{"action":"PAUSE"}
```
```json
{"action":"SPEED","speed":30}
```
```json
{"action":"RESET"}
```

Count is 3 or 4; speed is 0.2–100 m/s. Simulated speed affects movement and remaining ETA, while optimizer metrics use the backend's configured walking speed. Label them separately.

Demo subscriptions:

| Destination | Events |
|---|---|
| `/topic/demo/{simulationId}/locations` | LOCATIONS_UPDATED |
| `/topic/demo/{simulationId}/navigation` | VISITORS_SPAWNED, MEETING_POINT_RECOMMENDED, NAVIGATION_UPDATED, SIMULATION_STARTED, SIMULATION_PAUSED, SIMULATION_RESET, SPEED_CHANGED |
| `/topic/demo/{simulationId}/updates` | MEETING_ARRIVED |
| `/user/topic/demo/errors` | `{message}` for STOMP command errors |

Optional STOMP command send: `/app/demo/{simulationId}/command`. Do not send every command over both REST and STOMP.

Demo envelope: `{event, occurredAt, data: DemoState}`. DemoState fields are documented in `navigation-simulator.md` and DemoDtos.java.

Reducer invariants:

- Reject another simulationId and any revision lower than the applied revision.
- Compact location snapshots contain `path: null`: retain routes only when routeRevision matches. Null does not mean clear route; an empty list means no route.
- If routeRevision changes and paths are absent, fetch full state; do not combine new positions with obsolete paths.
- A full REST snapshot can enrich an equal revision. MEETING_ARRIVED can share its revision with the final location message; do not accidentally drop the celebration event just because the revision is equal.
- Deduplicate side effects by session/run/event; reset that bookkeeping for a new routeRevision/run.
- On a missing session (404), offer Create new / Join. Do not silently attach the user to a different session.

## Workflow B — production navigation with existing memberships

Do not use demo IDs or mock `self`/`m2` IDs here. Require actual backend userId and groupId from the owning modules. No user identity is proven by these APIs; this integration does not introduce authentication.

1. Load graph/candidates and current group context. Subscribe to group location/navigation topics, then GET `/api/v1/group/{groupId}/locations`.
2. Ask for foreground location permission. Show denied/unavailable states. Obtain latitude, longitude, accuracy and original observation timestamp.
3. Persist the first location with PUT `/api/v1/group/{groupId}/locations` and await success before allowing optimization. A STOMP SEND is not a persistence acknowledgment. Other selected participants must also have ACTIVE locations.
4. Send subsequent samples primarily to `/app/groups/{groupId}/location`, with the same JSON. Throttle updates (e.g. at most once per 2 seconds) while ensuring a stationary heartbeat within the default 120-second freshness window. Retain the original measurement timestamp on retries; do not make an old sample appear new. Future timestamps are rejected—show a device-clock error rather than silently rewriting the sample time.
5. Use the REST PUT fallback when STOMP is unavailable. Coalesce to the latest observation; do not replay an unbounded backlog of stale positions.
6. On explicit Find Best Meeting Point, POST `/api/v1/navigation/groups/{groupId}/recommendation` with selected participant IDs. The response is the complete recommendation and the group receives MEETING_POINT_RECOMMENDED. Do not immediately request all routes again; they are included.
7. Display the candidate and each participant's ordered path. If the user only needs a local preview, POST `/api/v1/navigation/optimize` instead; it does not broadcast or save meeting state.
8. When a reroute is explicitly requested, POST `/api/v1/navigation/groups/{groupId}/routes` for that user's current GPS and the chosen destination. This returns GpsRouteResponse and broadcasts NAVIGATION_UPDATED. Replace only that participant's route. Recompute remaining route distance/ETA using the backend when required; do not subtract straight-line distance from the route total.
9. Do not optimize on every GPS sample. A changed location does not mean the shared destination should move. If automatically rerouting later, debounce/throttle and serialize it, and keep the selected destination unless the user explicitly recalculates it.
10. Stop the GPS stream and dispose subscriptions when leaving/sharing is stopped. Note that local stopping does not revoke an already stored location server-side; it becomes stale. A real sharing-disable contract is still needed for immediate revocation.

Initial location / REST fallback payload:

```json
{
  "groupId":1,
  "userId":7,
  "latitude":24.957803,
  "longitude":55.1562148,
  "accuracyMeters":4.0,
  "updatedAt":"<current UTC observation timestamp>"
}
```

Replace the timestamp placeholder with an actual ISO string, e.g. `position.timestamp.toUtc().toIso8601String()`. The IDs above are illustrative and must exist in the chosen group.

Recommendation request:

```json
{"groupId":1,"participants":[{"userId":7},{"userId":8}]}
```

Group reroute request:

```json
{
  "userId":7,
  "route":{
    "start":{"latitude":24.957803,"longitude":55.1562148},
    "destination":{"latitude":24.9670353,"longitude":55.1530789}
  }
}
```

Production subscriptions and payloads:

| Destination | Event | data |
|---|---|---|
| `/topic/groups/{groupId}/locations` | LOCATION_UPDATED | One MemberLocationResponse |
| same | LOCATIONS_CHANGED | Full member-location list |
| `/topic/groups/{groupId}/navigation` | MEETING_POINT_RECOMMENDED | MeetingOptimizationResponse |
| same | NAVIGATION_UPDATED | List of ParticipantRouteResponse; may contain only one participant |
| `/topic/meetings/{meetingId}/navigation` | Recommendation/routes | Only when meeting owner publishes these |
| `/topic/meetings/{meetingId}/updates` | MEETING_STATUS_UPDATED | MeetingStatusResponse; currently not emitted by MeetingService |
| `/user/topic/errors` | no event wrapper | `{message}` |

Production event envelope: `{event, groupId, meetingId, occurredAt, data}`. Filter context IDs before applying it. Unlike demo messages, production messages have no revision/routeRevision fields.

Production reducer/recovery rules:

- Merge LOCATION_UPDATED by userId; compare updatedAt to prevent older samples overwriting newer ones. Equal timestamps can carry freshness changes—do not discard STALE solely because its timestamp equals the last ACTIVE observation.
- Treat LOCATIONS_CHANGED as a membership/availability snapshot, not an append-only delta. Preserve newer per-user observations where an older snapshot arrives late; remove members absent from an authoritative current snapshot.
- Compute local sample age as well, so a missed stale broadcast does not leave a member ACTIVE forever. Keep server-reported availability separate from network connection indicators.
- Missing/stale participants block optimization for that selected list. Ask for fresh positions or let the user explicitly change participants; do not silently drop people to obtain a favorable recommendation.
- Subscribe before snapshot recovery and buffer incoming events during the fetch. Merge buffered samples by timestamp after the response; use a context token to discard responses for an old group.
- Use occurredAt to reject clearly older navigation events; serialize local requests. The current production API lacks a durable revisioned route snapshot, so it cannot guarantee perfect navigation replay after disconnect. On reconnect, reload locations and mark prior navigation as potentially outdated; offer explicit recalculation. Do not silently broadcast a new recommendation merely because a connection reopens.
- When REST and STOMP both deliver your recommendation, merge rather than duplicate dialogs or routes.

## Meeting lifecycle boundary

The intended production sequence is:

```text
Existing user + real group membership
→ POST /api/v1/meeting/create/{groupId}/{userId}
→ PUT /api/v1/meeting/{meetingId}/start-locating
→ collect and persist fresh participant locations
→ calculate/show recommendation
→ persist selected meeting point [MISSING BACKEND CONTRACT]
→ PUT /api/v1/meeting/{meetingId}/start-navigation
→ route tracking
→ participant arrival confirmation [MISSING BACKEND CONTRACT]
→ PUT /api/v1/meeting/{meetingId}/complete under the owning module's rules
```

Do not call start-navigation immediately after recommendation and assume success. The current recommendation service deliberately does not mutate Meeting. Do not interpret `confirmReunionPoint()`'s local boolean as persisted selection or the existing local arrival toggle as a server-confirmed arrival. Wire those UI actions only after the missing contracts are delivered. Until then, keep them unavailable in production and fully usable only with authoritative demo session state.

## Map and UI integration

- Replace the local centroid and `_withEtas()` with backend results. Remove fixed alternate points from connected mode; there is no ranked-alternatives API.
- Replace every two-point straight-line member route with the complete backend path, converting each item to `LatLng(latitude, longitude)` in order.
- Use a distinct stable color per participant. Render meeting candidates and highlight the selected candidate; show current position and last known stale markers distinctly.
- Fit initial camera bounds to the returned graph. Current Flutter Riyadh fixtures near longitude 46.64 are outside the backend graph near 55.15 and will be rejected by map matching.
- Real phone GPS outside the supported graph should show a 422 error with a useful message; never silently substitute demo coordinates in production.
- Keep graph/route rendering functional without tiles: use existing flutter_map polyline/marker layers over a plain background or a CustomPainter for graph geometry. External basemap tiles are optional.
- Show loading/pending and retry states; preserve the last valid route after a failed recalculation but label it outdated. Do not render an unreachable route as a straight line.
- Disable Start until routes exist. In demo, disable Start when already RUNNING/ARRIVED; enable Pause only while RUNNING. In production, distinguish route preview from persisted meeting navigation.
- Update reunion sheet, member sheet, arrival overlay, header and celebration dialog to derive from the same navigation state instead of separate mock booleans.
- Keep labels and errors in Arabic/English. Display server names literally and user-friendly translations for known functional failures; retain server messages in developer logs.

Error behavior: 400 invalid input/clock, 404 missing context, 409 stale/missing locations or invalid demo sequence, 422 off-graph/unreachable, 429 demo capacity. Show network timeouts separately from functional server errors. When demo is disabled, explain the flag instead of treating a 404 response as an empty graph.

## Manual acceptance checklist

Complete these before claiming the Flutter workflow is integrated:

1. Launch demo from a clean app without login. Graph and candidates load; no registration API is called.
2. Spawn 3 visitors, optimize, and compare IDs/distances/paths with the browser simulator for the SAME simulation ID. The backend is the sole recommendation source.
3. Start, pause and resume at 1.4 m/s; set 30 m/s and observe faster movement. Remaining distance decreases and no marker cuts across disconnected segments.
4. Join the same UUID in Flutter and the browser. A command in either client updates both. Join a different UUID in another client and confirm isolation.
5. Pause midway and recalculate; routeRevision changes, old paths are replaced, and movement remains paused until Start.
6. Reach ARRIVED and show celebration once. Replay/recover the final snapshot without repeating celebration.
7. Lose the socket, reconnect and resubscribe. A full snapshot restores routes; a compact path=null update does not clear them. Leave the screen and confirm there are no duplicate subscriptions or timers.
8. Reset and respawn. Join an expired UUID and handle 404 with an explicit recovery action.
9. Pick identical graph nodes, then a disconnected pair. Show zero-distance route and unreachable error respectively; no fake fallback path.
10. Disable the backend simulator flag; show the feature-disabled error clearly.
11. For production mode ONLY when real memberships are available: persist one sample, retrieve it, receive a second client's updates, retry an older timestamp and observe no regression. Exercise stale/missing samples and outside-venue GPS.
12. Confirm that unsupported production confirmation/arrival/group creation actions cannot present fake success. List the backend blockers in the final handoff.
13. Run `dart format` on changed Dart files, `flutter analyze`, and compile the chosen supported target. Do not claim iOS/Android/web verification for targets not actually checked. No automated tests are part of this instruction.

Final implementation handoff must include changed files, dependency additions, launch configuration, APIs/topics used, manual results, and remaining backend dependencies. Clearly distinguish "demo works end to end" from "production lifecycle awaits integration".
