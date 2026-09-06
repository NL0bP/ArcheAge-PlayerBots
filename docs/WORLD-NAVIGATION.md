# World navigation

PlayerBots combines a shared transfer-road graph with AAEmu local paths. Movement follows bounded waypoints; native quest range and interaction checks decide whether an activity succeeds.

## Roads and destinations

`WorldRoadGraphBuilder` captures transfer-road data. `WorldRoadRoutePlanner` respects world, component, direction, and projection limits and divides long edges into local segments.

The 1.2 quest destination index combines authored markers with matching static NPC spawns. A marker identifies an area, not a reachable path or a live target. The bot must find and revalidate the real target.

## Native path results

`BotLocalPathResult` distinguishes missing, partial, and complete native results. A nonempty path is partial if its actual final point lies outside the goal's 0.35 m endpoint tolerance, including height. Invalid points reject the result rather than being skipped to join a gap.

`BotTravelRoutePlanner` accepts a road route only when both local connectors reach their goals. It checks the emitted road endpoint for the final connector and preserves the native final point instead of appending the requested destination. A complete path describes planned points, not observed arrival.

## Compatibility limit

The existing shared travel caller still restores a destination when given no waypoints. Until that ownership contract is changed, failed local planning retains `direct` movement with an `unverified_direct_compatibility` detail. It is never labeled `bai` or `native_local_path`. Quest travel uses this shared caller too; fully fail-closed autonomous navigation is not established by the classifier fix.

Road sessions and movement recovery remain bounded, but a rejected road plan may fall back to local or compatibility movement. This is not a full navmesh. Sparse geodata, rocks, cliffs, caves, interiors, bridges, and water can still cause unsafe or failed routes.

AAEmu's pinned pathfinder can snap endpoints to geodata and does not expose all internal failure states. Endpoint validation cannot prove collision-free traversal or detect every shortcut returned by the host. No route plan grants quest credit or teleports a character.

See [Testing](TESTING.md) for deterministic path regressions and client-visible navigation checks.
