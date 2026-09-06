using System.Numerics;
using AAEmu.Game.Models.Game.AI.AStar;
using AAEmu.Game.Models.Game.Char;

namespace AAEmu.Game.Bots.Navigation;

public sealed record BotTravelRoute(
    string Mode,
    IReadOnlyList<Vector3> Waypoints,
    int RoadSteps,
    string Detail);

/// <summary>Combines transfer roads with AAEmu's local pathfinder.</summary>
public static class BotTravelRoutePlanner
{
    private const float RoadMinimumTravelDistance = 18f;
    private const float RoadMaximumProjectionDistance = 200f;
    private const float RoadWaypointSegmentLength = 8f;
    private const float DuplicatePointTolerance = BotLocalPathResult.EndpointTolerance;
    private const float MaximumRouteStretch = 5f;
#if !PLAYERBOTS_AAEMU_3_0
    private static readonly IWorldRoadGraphProvider RoadGraphs =
        new TransferRoadGraphProvider(new AaemuTransferRoadSnapshotProvider());
    private static readonly WorldRoadRoutePlanner RoadPlanner = new(new WorldRoadRoutePlannerOptions
    {
        MaximumProjectionDistance = RoadMaximumProjectionDistance,
        MaximumProjectionVerticalGap = 8f,
        // Projection may be wider than the local movement segment.
        MaximumLocalSegmentLength = RoadMaximumProjectionDistance
    });
#endif

    public static BotTravelRoute Plan(Character bot, Vector3 destination)
    {
        if (bot?.ParentWorld == null || bot.Transform?.World == null ||
            !IsFinite(destination))
        {
            return Direct(destination, "world_unavailable_unverified_direct_compatibility");
        }

        var start = bot.Transform.World.Position;
        if (!IsFinite(start))
            return Direct(destination, "start_invalid_unverified_direct_compatibility");

        return Plan(start, destination, (from, goal) => FindBaiPath(bot, from, goal),
#if PLAYERBOTS_AAEMU_3_0
            null);
#else
            () => RoadPlanner.Plan(
                RoadGraphs.Capture(),
                new RoadRouteEndpoint(bot.ParentWorld.Template.Id, start),
                new RoadRouteEndpoint(bot.ParentWorld.Template.Id, destination)));
#endif
    }

    // Keep host access at the edge so composition is tested with native results,
    // including missing paths and paths snapped short of the requested endpoint.
    internal static BotTravelRoute Plan(
        Vector3 start,
        Vector3 destination,
        Func<Vector3, Vector3, IReadOnlyList<Vector3>> findLocalPath,
        Func<RoadRouteResult> findRoadRoute = null)
    {
        if (!IsFinite(start) || !IsFinite(destination))
            return new BotTravelRoute("unavailable", [], 0, "invalid_endpoint");

        var directDistance = Vector3.Distance(start, destination);
        if (directDistance <= DuplicatePointTolerance)
            return new BotTravelRoute("local", [start], 0, "already_within_endpoint_tolerance");

        if (directDistance >= RoadMinimumTravelDistance && findRoadRoute != null)
        {
            try
            {
                var road = findRoadRoute();
                if (road is { IsSuccess: true } && road.Waypoints.Count > 0)
                {
                    var points = new List<Vector3>();
                    if (AppendLocalConnector(points, start, road.StartProjection.Position, findLocalPath))
                    {
                        AppendBounded(points, start, road.Waypoints, RoadWaypointSegmentLength);
                        // Use the emitted road endpoint, not an assumed projection.
                        var endpoint = points.Count > 0 ? points[^1] : start;
                        if (AppendLocalConnector(points, endpoint, destination, findLocalPath))
                        {
                            RemoveOrigin(points, start);
                            var routeLength = Length(start, points);
                            var maximumReasonableLength = Math.Max(100f, directDistance * MaximumRouteStretch);
                            if (points.Count > 0 && routeLength <= maximumReasonableLength)
                            {
                                return new BotTravelRoute(
                                    "road+bai", points, road.Steps.Count,
                                    $"graph={road.GraphGenerationId} component={road.ComponentId}");
                            }
                        }
                    }
                }
            }
            catch
            {
                // The road layer is optional. Try the native local route next.
            }
        }

        var failure = "missing";
        try
        {
            var result = BotLocalPathResult.Classify(findLocalPath(start, destination), destination);
            if (result.Status == BotLocalPathStatus.Complete)
            {
                var points = new List<Vector3>();
                Append(points, result.Waypoints);
                RemoveOrigin(points, start);
                if (points.Count > 0)
                    return new BotTravelRoute("bai", points, 0, "native_local_path");
            }
            failure = result.Status.ToString().ToLowerInvariant();
        }
        catch
        {
            failure = "exception";
        }

        // The legacy shared caller requires a destination and restores one for
        // empty routes. Preserve that compatibility explicitly; this is neither
        // a verified native path nor proof of arrival. Strict quest failure must
        // be wired through the movement owner before this fallback can be removed.
        return Direct(destination, $"native_local_path_{failure}_unverified_direct_compatibility");
    }

    private static bool AppendLocalConnector(
        ICollection<Vector3> points,
        Vector3 start,
        Vector3 goal,
        Func<Vector3, Vector3, IReadOnlyList<Vector3>> findLocalPath)
    {
        if (Vector3.Distance(start, goal) <= DuplicatePointTolerance)
            return true;

        var result = BotLocalPathResult.Classify(findLocalPath(start, goal), goal);
        if (result.Status != BotLocalPathStatus.Complete)
            return false;

        Append(points, result.Waypoints);
        return true;
    }

    private static IReadOnlyList<Vector3> FindBaiPath(Character bot, Vector3 start, Vector3 goal)
    {
#if PLAYERBOTS_AAEMU_3_0
        var startPoint = new Point(start.X, start.Y, start.Z);
        var goalPoint = new Point(goal.X, goal.Y, goal.Z);
        var oldPath = new PathNode
        {
            ZoneKey = bot.Transform.ZoneId,
            pos1 = startPoint,
            pos2 = goalPoint
        }.FindPath(startPoint, goalPoint);
        return oldPath?.Select(point => new Vector3(point.X, point.Y, point.Z)).ToArray();
#else
        return new PathNode { ZoneKey = bot.Transform.ZoneId }
            .FindPath(bot.ParentWorld, start, goal);
#endif
    }

    private static void Append(ICollection<Vector3> destination, IEnumerable<Vector3> source)
    {
        foreach (var point in source)
        {
            if (!IsFinite(point))
                continue;
            if (destination.LastOrDefault() is var previous && destination.Count > 0 &&
                previous == point)
            {
                continue;
            }
            destination.Add(point);
        }
    }

    private static void AppendBounded(
        ICollection<Vector3> destination,
        Vector3 origin,
        IEnumerable<Vector3> source,
        float maximumSegmentLength)
    {
        var previous = destination.Count > 0 ? destination.Last() : origin;
        foreach (var point in source)
        {
            if (!IsFinite(point))
                continue;

            var distance = Vector3.Distance(previous, point);
            var divisions = Math.Max(1, (int)Math.Ceiling(distance / maximumSegmentLength));
            for (var part = 1; part <= divisions; part++)
                Append(destination, [Vector3.Lerp(previous, point, part / (float)divisions)]);
            previous = point;
        }
    }

    private static void RemoveOrigin(IList<Vector3> points, Vector3 origin)
    {
        while (points.Count > 0 && Vector3.Distance(points[0], origin) <= DuplicatePointTolerance)
            points.RemoveAt(0);
    }

    private static float Length(Vector3 start, IReadOnlyList<Vector3> points)
    {
        var length = 0f;
        var previous = start;
        foreach (var point in points)
        {
            length += Vector3.Distance(previous, point);
            previous = point;
        }
        return length;
    }

    private static BotTravelRoute Direct(Vector3 destination, string detail) =>
        new("direct", [destination], 0, detail);

    private static bool IsFinite(Vector3 value) =>
        float.IsFinite(value.X) && float.IsFinite(value.Y) && float.IsFinite(value.Z);
}
