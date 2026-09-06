using System.Numerics;
using AAEmu.Game.Bots.Navigation;

namespace AAEmu.UnitTests.Bots.Navigation;

public class BotTravelRoutePlannerTests
{
    private static readonly Vector3 Start = new(0, 5, 0);
    private static readonly Vector3 Goal = new(100, 5, 0);

    [Test]
    public async Task MissingAndPartialPathsNeverBecomeNativeSuccess()
    {
        foreach (var path in new IReadOnlyList<Vector3>[] { null, [], [Start], [Start, Goal - Vector3.UnitX] })
        {
            var route = BotTravelRoutePlanner.Plan(Start, Goal, (_, _) => path);
            await Assert.That(route.Mode).IsEqualTo("direct");
            await Assert.That(route.Detail).Contains("unverified_direct_compatibility");
            await Assert.That(route.Detail == "native_local_path").IsFalse();
        }
    }

    [Test]
    public async Task NativeExceptionIsExplicitCompatibilityFallback()
    {
        var route = BotTravelRoutePlanner.Plan(Start, Goal, (_, _) => throw new InvalidOperationException());
        await Assert.That(route.Mode).IsEqualTo("direct");
        await Assert.That(route.Detail).Contains("exception_unverified_direct_compatibility");
    }

    [Test]
    public async Task CompletePathKeepsActualEndpointWithoutAnExtraFinalConnection()
    {
        var endpoint = Goal - new Vector3(0.25f, 0, 0);
        var route = BotTravelRoutePlanner.Plan(Start, Goal, (_, _) => [Start, endpoint]);
        await Assert.That(route.Mode).IsEqualTo("bai");
        await Assert.That(route.Waypoints).IsEquivalentTo(new[] { endpoint });
    }

    [Test]
    public async Task NearbyPreviousWaypointCannotReplaceTheValidatedEndpoint()
    {
        var endpoint = Goal - new Vector3(0.3f, 0, 0);
        var route = BotTravelRoutePlanner.Plan(Start, Goal,
            (_, _) => [Start, Goal - new Vector3(0.6f, 0, 0), endpoint]);
        await Assert.That(route.Mode).IsEqualTo("bai");
        await Assert.That(route.Waypoints[^1]).IsEqualTo(endpoint);
    }

    [Test]
    public async Task AlreadyNearGoalDoesNotClaimANativePathOrQueryOne()
    {
        var route = BotTravelRoutePlanner.Plan(Start, Start + new Vector3(0.1f, 0, 0),
            (_, _) => throw new InvalidOperationException("Should not query"));
        await Assert.That(route.Mode).IsEqualTo("local");
        await Assert.That(route.Waypoints).IsEquivalentTo(new[] { Start });
    }

    [Test]
    public async Task RoadRequiresBothCompleteLocalConnectors()
    {
        var road = Road();
        await Assert.That(road.IsSuccess).IsTrue();
        foreach (var failStart in new[] { true, false })
        foreach (var partial in new[] { true, false })
        {
            var route = BotTravelRoutePlanner.Plan(Start, Goal, (from, to) =>
            {
                if (from == Start && to == Goal) return [Start, Goal]; // verified local fallback
                if ((to == road.StartProjection.Position) == failStart)
                    return partial ? [from, to - Vector3.UnitZ] : [];
                return [from, to];
            }, () => road);
            await Assert.That(route.Mode).IsEqualTo("bai");
            await Assert.That(route.RoadSteps).IsEqualTo(0);
            await Assert.That(route.Waypoints).IsEquivalentTo(new[] { Goal });
        }
    }

    [Test]
    public async Task RoadWithVerifiedConnectorsPreservesNativeFinalEndpoint()
    {
        var endpoint = Goal - new Vector3(0, 0.25f, 0);
        var route = BotTravelRoutePlanner.Plan(Start, Goal,
            (from, to) => [from, to == Goal ? endpoint : to], Road);
        await Assert.That(route.Mode).IsEqualTo("road+bai");
        await Assert.That(route.Waypoints[^1]).IsEqualTo(endpoint);
        await Assert.That(route.Waypoints.Contains(Goal)).IsFalse();
        await Assert.That(route.Waypoints.Zip(route.Waypoints.Skip(1), Vector3.Distance)
            .All(distance => distance <= 8.001f)).IsTrue();
    }

    [Test]
    public async Task RoadExceptionStillAllowsACompleteLocalPath()
    {
        var route = BotTravelRoutePlanner.Plan(Start, Goal, (_, _) => [Start, Goal],
            () => throw new InvalidOperationException());
        await Assert.That(route.Mode).IsEqualTo("bai");
    }

    [Test]
    public async Task InvalidDestinationDoesNotEmitANativeRoute()
    {
        var route = BotTravelRoutePlanner.Plan(Start, new Vector3(float.NaN, 0, 0), (_, _) => [Goal]);
        await Assert.That(route.Mode).IsEqualTo("unavailable");
        await Assert.That(route.Waypoints.Count).IsEqualTo(0);
    }

    private static RoadRouteResult Road()
    {
        var graph = new WorldRoadGraphBuilder().Build(new TransferRoadNetworkSnapshot(1,
            [new RoadPolylineSnapshot(1, 1, "road", 0, 0, 0, RoadTravelDirection.Bidirectional,
                [new RoadPoint(0, 0, 0), new RoadPoint(100, 0, 0)])]));
        return new WorldRoadRoutePlanner().Plan(graph,
            new RoadRouteEndpoint(1, Start), new RoadRouteEndpoint(1, Goal));
    }
}
