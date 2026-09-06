using System.Numerics;
using AAEmu.Game.Bots.Navigation;

namespace AAEmu.UnitTests.Bots.Navigation;

public class BotLocalPathResultTests
{
    [Test]
    public async Task NullAndEmptyPathsAreMissing()
    {
        foreach (var path in new IReadOnlyList<Vector3>[] { null, [] })
        {
            var result = BotLocalPathResult.Classify(path, Vector3.UnitX);
            await Assert.That(result.Status).IsEqualTo(BotLocalPathStatus.Missing);
            await Assert.That(result.ActualEndpoint).IsNull();
            await Assert.That(result.Waypoints.Count).IsEqualTo(0);
        }
    }

    [Test]
    public async Task NonemptyPathEndingShortIsPartialAndRetainsActualEndpoint()
    {
        var result = BotLocalPathResult.Classify([Vector3.Zero, Vector3.UnitX], new Vector3(10, 0, 0));
        await Assert.That(result.Status).IsEqualTo(BotLocalPathStatus.Partial);
        await Assert.That(result.ActualEndpoint).IsEqualTo((Vector3?)Vector3.UnitX);
        await Assert.That(result.Waypoints.Count).IsEqualTo(2);
    }

    [Test]
    public async Task PassingThroughGoalDoesNotMakeADifferentFinalEndpointComplete()
    {
        var result = BotLocalPathResult.Classify([Vector3.UnitX, Vector3.Zero], Vector3.UnitX);
        await Assert.That(result.Status).IsEqualTo(BotLocalPathStatus.Partial);
    }

    [Test]
    public async Task EndpointToleranceIncludesHeightAndDoesNotAppendTheGoal()
    {
        var goal = new Vector3(10, 0, 0);
        foreach (var offset in new[] { new Vector3(0.35f, 0, 0), new Vector3(0, 0, 0.35f) })
        {
            // Use an origin goal to avoid addition rounding at the boundary.
            var result = BotLocalPathResult.Classify([goal, offset], Vector3.Zero);
            await Assert.That(result.Status).IsEqualTo(BotLocalPathStatus.Complete);
            await Assert.That(result.Waypoints[^1]).IsEqualTo(offset);
        }
        var partial = BotLocalPathResult.Classify([goal, new Vector3(0, 0, 0.351f)], Vector3.Zero);
        await Assert.That(partial.Status).IsEqualTo(BotLocalPathStatus.Partial);
    }

    [Test]
    public async Task InvalidInteriorPointRejectsEntirePathInsteadOfJoiningAGap()
    {
        foreach (var value in new[] { float.NaN, float.PositiveInfinity, float.NegativeInfinity })
        {
            var result = BotLocalPathResult.Classify(
                [Vector3.Zero, new Vector3(value, 0, 0), Vector3.UnitX], Vector3.UnitX);
            await Assert.That(result.Status).IsEqualTo(BotLocalPathStatus.Missing);
            await Assert.That(result.Waypoints.Count).IsEqualTo(0);
        }
    }

    [Test]
    public async Task ResultOwnsItsValidatedSnapshot()
    {
        var path = new[] { Vector3.Zero, Vector3.UnitX };
        var result = BotLocalPathResult.Classify(path, Vector3.UnitX);
        path[1] = new Vector3(500, 0, 0);
        await Assert.That(result.Status).IsEqualTo(BotLocalPathStatus.Complete);
        await Assert.That(result.Waypoints[^1]).IsEqualTo(Vector3.UnitX);
    }
}
