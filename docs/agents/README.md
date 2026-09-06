# Agent guide

This section is for automated contributors. Human setup starts at [Installation](../INSTALLATION.md); contributor expectations are in [Contributing](../../CONTRIBUTING.md).

## Start with the requested change

Read the relevant source and tests, `playerbots.module.json`, and [Architecture](../ARCHITECTURE.md). Establish the requested Git baseline and understand existing changes before editing. Keep task notes and generated evidence in ignored artifacts or the task's external workspace, not in this guide.

AAEmu 1.2 is the active feature target. AAEmu 3.0 is a frozen compatibility boundary. Neither a passing build nor an old gameplay receipt accepts a new behavior candidate.

## Code map

| Location | Responsibility |
| --- | --- |
| `src/AAEmu.Game/Bots/Host` | Scheduling, ownership, cadence, and metrics |
| `Bots/Kernel` and `Bots/Content` | Actions, triggers, values, strategies, and rotations |
| `Bots/Questing` | Native quest discovery, objectives, reporting, and ownership |
| `Bots/Navigation` | Road graph, route composition, and local path classification |
| `Bots/Body` and `Models/Tasks/Bots` | Skill execution, movement, and recovery |
| `Bots/Social` and `Core/Managers/Bots` | Party orders and persistent bot lifecycle |
| `Scripts/Commands`, `Configurations`, and `Data` | Operator controls and tunable behavior |
| `tests/AAEmu.UnitTests` | Tests compiled into the pinned AAEmu test host |
| `build`, `compatibility`, and `scripts` | Source imports, host patches, and installation/packaging |

Abbreviated production paths above are relative to `src/AAEmu.Game/`.

## Implementation rules

Keep the existing kernel and controllers. Add the smallest seam needed to test the changed behavior; avoid a second AI framework or harness-specific production policy. Bound scans and retries, cache expensive world queries, and measure hot paths before redesigning them.

A nonempty path is not proof of arrival. Preserve its actual endpoint and distinguish missing, partial, and complete local results. Native range and interaction checks decide gameplay success. The legacy shared travel caller still permits an explicitly labeled unverified direct fallback; removing it requires coordinated movement-owner handling, not just returning an empty route. See [World navigation](../WORLD-NAVIGATION.md).

Use [reviewed upstream references](../UPSTREAM-PLAYERBOTS-REFERENCE.md) for design ideas. Any direct translation needs file-specific origin, revision, and notices. Keep ArcheAge data and native AAEmu authority.

## Validate and hand off

Follow [Testing](../TESTING.md): focused compiled tests while iterating; one full 1.2 regression for the final shared-infrastructure candidate or release boundary. Use an isolated pinned host and retain failed attempts. Do not operate a runtime or database unless the current task authorizes it.

Run the cross-ref packaging regression when changing preview generation. Review the final diff for scope, secrets, machine paths, unsupported claims, and lost tests or provenance.

Report the exact source commit, host base, changed behavior, checks and failures, and the next integration action. Separate source validation from server/client observations. Keep operational ownership and deployment history outside the public repository.
