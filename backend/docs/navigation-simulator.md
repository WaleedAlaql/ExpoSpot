# Navigation & real-time simulator

## Start

The feature is **disabled by default**, including access to the static page. Enable it for a local run:

```sh
./mvnw -Dmaven.test.skip=true spring-boot:run '-Dspring-boot.run.arguments=--app.simulator.enabled=true'
```

Alternatively set `APP_SIMULATOR_ENABLED=true` in the process environment or `app.simulator.enabled=true` in your local configuration. No changes to the existing application.properties are required. Use the application's configured MySQL/MariaDB connection: Spring's existing JPA startup still requires the database, but the simulator needs no registered users, groups, memberships or meetings and creates none.

Open **http://localhost:8080/navigation-simulator.html**. The page uses inline HTML/CSS/JavaScript and Canvas; it downloads no scripts, map tiles, fonts or other external assets. Run it through Spring Boot, not as a `file://` page. Use localhost or 127.0.0.1 to match the existing WebSocket allowed-origin policy.

For a separate local instance without schema updates:

```sh
./mvnw -Dmaven.test.skip=true spring-boot:run '-Dspring-boot.run.arguments=--server.port=8081 --app.simulator.enabled=true --spring.jpa.hibernate.ddl-auto=none'
```

Then use http://localhost:8081/navigation-simulator.html.

## Manual walkthrough

1. The page loads the graph and creates an isolated session. **Load Graph** reloads the current dataset. Scroll to zoom, drag to pan, or use **Fit**.
2. Choose 3 or 4 visitors and click **Spawn Visitors**. They start on graph nodes verified by the routing service to reach a meeting candidate.
3. Click **Find Best Meeting Point**. The backend optimizer supplies the selected point and every visitor's route, distance and ETA. The selected candidate is highlighted in mint and each visitor has a distinct route color.
4. Click a visitor card or marker to see coordinates, current graph segment, destination, route distance, remaining distance and ETA.
5. **Calculate Routes** recalculates routes to the already selected destination. **Recalculate Meeting Point** reruns minimax optimization from current positions and may choose a different destination. Both pause movement so the new result can be inspected; click Start to continue.
6. Set simulated walking speed (0.2–100 m/s). Default 1.4 m/s is a normal walk; use 30–100 m/s to reach arrival quickly in a demonstration. **Start Simulation**, **Pause**, and Start again support pause/resume.
7. Watch the event log for actual STOMP location messages. All visitors stop at their route endpoint; the session becomes ARRIVED and emits a demo meeting-arrival event.
8. Click **Copy shared link** and open it in a second tab. Both tabs join the same session and show the same visitors, recommendations, controls and movement. No tab independently advances visitors. A new simulation gets a separate UUID; changes do not cross sessions. You can also paste a session UUID and click **Join**.
9. In **Point-to-point route explorer**, enter two node IDs or click **Pick on map** then click a graph location (the nearest graph node is selected). **Find Route** calls the backend node-route API and draws the result as a dashed white line. Try identical nodes for zero distance, or disconnected components to see a backend error. This exploratory route is local to the current tab and does not replace visitor routes.
10. **Reset** removes the session's visitors and recommendation in every tab. Spawn again to restart. **New simulation** creates an independent session and updates the browser URL.

If a session expires or the server restarts, create a new simulation. On connection loss the badge switches to HTTP recovery; snapshots refresh every five seconds and the client attempts STOMP reconnect every three seconds. Rejoining/reconnecting fetches full state; route revisions prevent compact location messages from being paired with old paths. The browser log retains the most recent 100 entries.

## REST contracts

Existing production read/calculation APIs are reused without modification:

- `GET /api/v1/navigation/graph`: nodes, original edges, meeting candidates.
- `POST /api/v1/navigation/route`: `{ "fromNodeId": 3206, "toNodeId": 1081 }`; returns the existing route response for the explorer.

Demo-only APIs (all require the flag):

- `POST /api/v1/demo/navigation/simulations`: create a session, returns 201 and a full snapshot. No request body required (the page sends `{}`).
- `GET /api/v1/demo/navigation/simulations/{simulationId}`: get a full snapshot and refresh the session's inactivity timer.
- `POST /api/v1/demo/navigation/simulations/{simulationId}/commands`: execute a command, returns 200 and the resulting full snapshot.

Command examples:

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

The response has `simulationId`, monotonically increasing `revision`, `routeRevision`, `status`, `speed`, `meetingPoint`, `optimizerMaxEtaSeconds`, `optimizerTotalDistanceMeters` and `visitors`. Each visitor has `id`, `name`, `latitude`, `longitude`, `position`, `status`, `distanceMeters`, `remainingMeters`, `etaSeconds`, and `path` using the existing ordered route-point schema.

Session statuses: EMPTY, PAUSED, RUNNING, ARRIVED. Visitor statuses: WAITING, PAUSED, WALKING, ARRIVED. Waiting visitors have no assigned path; their zero distance/ETA must not be presented as a computed arrival estimate.

Functional errors reuse the existing `ApiResponse` envelope. Examples: 404 for missing/expired sessions, 409 for starting without routes, 400 for invalid count/speed, 422 for graph reachability failures, 429 for the session cap.

## STOMP

Uses the **existing** native WebSocket endpoint `/ws`, `/app` application prefix, and `/topic` broker. No second WebSocket configuration is introduced.

Subscribe to:

- `/topic/demo/{simulationId}/locations`: `LOCATIONS_UPDATED` every 500 ms while moving. Compact snapshot; visitor `path` is null, meaning retain the path from the same routeRevision.
- `/topic/demo/{simulationId}/navigation`: full state after commands, with events `VISITORS_SPAWNED`, `MEETING_POINT_RECOMMENDED`, `NAVIGATION_UPDATED`, `SIMULATION_STARTED`, `SIMULATION_PAUSED`, `SIMULATION_RESET`, or `SPEED_CHANGED`.
- `/topic/demo/{simulationId}/updates`: `MEETING_ARRIVED`, a demo event only; no persisted Meeting is changed.
- `/user/topic/demo/errors`: session-local functional/validation errors for inbound STOMP commands.

Optional client SEND mapping: `/app/demo/{simulationId}/command`, using the same command JSON as REST. The UI submits commands over REST for immediate response/error handling and receives real broadcast messages over STOMP. Movement is server-generated; clients cannot inject arbitrary off-route location coordinates into the demo.

Event envelope:

```json
{"event":"LOCATIONS_UPDATED","occurredAt":"2026-10-15T12:00:00Z","data":{"simulationId":"...","revision":10,"routeRevision":2,"status":"RUNNING","speed":1.4,"meetingPoint":{},"optimizerMaxEtaSeconds":150,"optimizerTotalDistanceMeters":500,"visitors":[]}}
```

The nested example is abbreviated; actual snapshots include the full meeting-point response and all visitors. The small inline JSON-only STOMP client supports connection, subscriptions, frame buffering, reconnect and message handling. Its framing follows the [STOMP 1.2 specification](https://stomp.github.io/stomp-specification-1.2.html); it is not intended as a general-purpose binary STOMP library. It requests no protocol heartbeats; periodic HTTP recovery handles missed state.

## Algorithms and isolation

`DemoSimulationService` delegates to `GraphService`, `RoutingService`, `MapMatchingService` and `MeetingOptimizerService`. Optimization uses explicit GPS timestamps and a null group context, an already supported stateless path. It does not call production location updates or bypass their membership rules. The simulator implements no shortest-path or minimax algorithm.

The server has one authoritative 500 ms movement clock. Each step interpolates along the returned route's ordered segments. Geometric segment lengths are scaled to the backend's total route distance, preserving the total walking distance while accommodating rounded graph weights. Position and remaining distance are derived from progress, not recomputed routing searches on each tick. Large scheduler delays are capped to one second of progress per tick, so a machine suspension cannot jump everyone to the destination. Actual scheduling may therefore run slower than wall time under heavy load.

Simulated speed changes only movement and displayed remaining ETA. Optimizer metrics continue to use the production `navigation.walking-speed-mps` setting (default 1.4); the interface labels these separately. Because all simulated visitors share a single speed, changing it would scale all candidate ETAs equally and would not change the minimax winner.

All demo beans except the feature-gate filter use `@ConditionalOnProperty(name="app.simulator.enabled", havingValue="true")`. Missing flag means false. The filter returns 404 for the simulator page and demo REST namespace when disabled. STOMP handlers are absent when disabled. The filter is a feature gate, not a new security framework.

Sessions use UUIDs and independent synchronized in-memory state, with a cap of 50 sessions and one-hour inactivity expiry. Only snapshot reads and commands refresh inactivity; ticking alone does not retain abandoned sessions. State is lost on restart and is not shared between server instances. The existing simple broker has no durable replay or cross-instance delivery. This is an unauthenticated local demonstration: anyone who knows a session UUID can control it. UUID separation is not authorization.

The production database still has to be available for the application to start. The demo does not create or update any database rows. Production users, group logic, membership validation, location persistence, meeting lifecycle, AI, graph loader and graph JSON are unchanged.

The current dataset has disconnected components and provisional meeting points outside Riyadh. Spawning deliberately chooses reachable nodes; the route explorer can expose unreachable pairs. No actual venue access or accessibility guarantee is implied.

## Files

Created:

- `src/main/java/com/nawaf/meetingpoint/Demo/DemoDtos.java`
- `src/main/java/com/nawaf/meetingpoint/Demo/DemoSimulationService.java`
- `src/main/java/com/nawaf/meetingpoint/Demo/DemoRealtimePublisher.java`
- `src/main/java/com/nawaf/meetingpoint/Demo/DemoNavigationController.java`
- `src/main/java/com/nawaf/meetingpoint/Demo/DemoWebSocketController.java`
- `src/main/java/com/nawaf/meetingpoint/Demo/DemoAccessFilter.java`
- `src/main/resources/static/navigation-simulator.html`
- `docs/navigation-simulator.md`

No pre-existing source, configuration, dependency, graph data, or frontend files were modified for the simulator.

## Verification performed

- `./mvnw -Dmaven.test.skip=true compile`: passed (Java 21 target).
- Extracted inline JavaScript and ran `node --check`: syntax passed.
- Started an enabled local instance on port 8081 with schema updates disabled; `GET /navigation-simulator.html` returned 200 and `text/html`.
- Manually created a demo session, spawned three visitors and requested optimization. The existing optimizer chose Sun Plaza with three nonempty paths (27, 8 and 19 points).
- Used two interactive WebSocket/STOMP clients subscribed to the same session. Both received matching location revisions. Sent SPEED and START through the demo STOMP mapping; all three visitors reached zero remaining distance and `MEETING_ARRIVED` was received.
- Started a separate instance on port 8082 without the simulator flag. Both the page and session creation endpoint returned 404 with the disabled-feature message.
- `git diff --check`: passed.

No automated tests or test infrastructure were created or run. Browser visual layout, pointer controls and full click-through behavior were not exercised in a graphical browser. The temporary verification instances were stopped afterward.
