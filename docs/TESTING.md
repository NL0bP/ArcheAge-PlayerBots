# Testing

Tests compile into the pinned AAEmu host; this module has no standalone solution. Use an isolated [1.2 installation](INSTALLATION.md). Keep build output and evidence outside tracked source.

## Choose the right check

| Change | Validation |
| --- | --- |
| Documentation only | Check accuracy, examples, and links |
| Local behavior | Build, then run the affected compiled tests while iterating |
| Shared navigation, host, or scheduler behavior | Focused tests during development; one full 1.2 suite on the final candidate |
| Preview packaging | Cross-ref regression and validation of the final produced archive |
| Release boundary | Full build/tests, installer check, command compilation, and relevant gameplay acceptance |

Preserve behavioral tests for native credit, target selection, corpse ownership, reporting, movement ownership, and recovery. Source-text assertions can supplement them but do not prove compiled behavior.

## Build and focused tests

Run from the AAEmu root:

```powershell
dotnet build AAEmu.slnx --no-incremental
./AAEmu.UnitTests/bin/Debug/net10.0/AAEmu.UnitTests.exe --treenode-filter '/*/AAEmu.UnitTests.Bots.Navigation/*/*'
```

This example runs the compiled navigation suite. Use `--list-tests` to discover tests and `--filter-uid` for an exact test. On Unix, invoke the test DLL with `dotnet` and the same arguments.

For the final full 1.2 regression, run from the host root so its Microsoft Testing Platform configuration is found:

```powershell
dotnet test --project AAEmu.UnitTests/AAEmu.UnitTests.csproj --no-build
& ./modules/archeage-playerbots/scripts/Install-PlayerBots.ps1 -AAEmuRoot $PWD -CheckOnly
./AAEmu.Game/bin/Debug/net10.0/AAEmu.Game.exe compiler-check
```

`compiler-check` compiles command scripts and exits; it is not a server startup. Preserve failures and intentional skips in the result.

## Packaging

From the module root:

```powershell
& ./scripts/Test-PlayerBotsPreview.ps1 -OutputDirectory ./artifacts/preview-tests
```

The regression creates a retained Git fixture with differing requested and checkout metadata, patches, and migration bytes. It checks archived bytes and sidecars, corrupt requested-ref rejection, and preservation of existing outputs. See [Preview archives](PREVIEW.md) for final packaging.

## Gameplay checks

Automated tests do not prove client presentation or a native quest outcome. Use an explicitly authorized isolated runtime and matching client. Pick cases affected by the change:

| Behavior | Observe |
| --- | --- |
| Companion lifecycle | Spawn an offline character, perform one native activity, then normal logout and reload with saved state |
| Party roles | Follow a moving owner, enter combat, heal an injured party member, and regroup without losing ownership |
| Brain reactivation | Idle/duel cleanup may shed a brain; subsequent attack, follow, or party work must wake it |
| Skill use | Learned skills respect native range, facing, cooldown, and resources; ranged fillers and healing remain usable |
| Stealth | Target loss starts bounded search; return permits reacquisition, timeout permits clean release |
| Natural sustainability | Exhaust resources, rest, recover, and resume without administrator healing during the sample |
| Quest autonomy | A fresh level-one Nuian completes five native starter quests without directed targets or injected credit, then retains identity, progress, and position across a graceful restart |
| Navigation | Missing/partial paths stay distinguishable from complete native paths; obstacles and failed interactions never count as quest success |

Use isolated targets appropriate to the active data pack. Controlled gear, levels, buffs, or healing are valid fixture tools, but must be labeled and kept separate from fresh-character or natural-sustainability claims.

## Evidence and scale

Record module commit, host base and patches, built assembly hashes, relevant configuration/data identity, commands, expected behavior, observed server result, client observation, and remaining failures. Earlier results belong to their original candidate.

Increase populations only after the underlying activities work. The retained `scripts/scale/` harness measures resources and lifecycle behavior; a population count alone is not a capacity claim. Compare with an empty/Idle baseline and agreed whole-server limits.

Keep raw logs, recordings, and databases outside Git. AAEmu 3.0 is frozen; its [historical runbook](AAEMU30-ACCEPTANCE.md) is for separately scoped compatibility or release regression.
