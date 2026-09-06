# Installation

PlayerBots compiles into AAEmu from `modules/archeage-playerbots`. You need the matching .NET SDK, client/server data, and database setup required by AAEmu. Build and test in a separate checkout before replacing an existing server.

## Supported versions

| Track | Exact host base | Status |
| --- | --- | --- |
| ArcheAge 1.2 r208022 | AAEmu/AAEmu `62e3eb1d87da01194802ac886cd500134facad28` | Active feature target |
| ArcheAge 3.0.4.2 r336598 | NL0bP/AAEmu `8c1c943bb2309eefffb9da2aa99a408d0acbb095` | Frozen experimental adapter |

The example below pins the public alpha.6 source baseline at `850c507faabf02a879b08771466c2e6181ea998b`. That identifies the existing alpha, not an accepted fresh-Nuian gameplay candidate. To test a newer reviewed change, substitute its exact module commit and retain both source identities. See `playerbots.module.json` for patch and migration identities.

## Clean 1.2 installation

Prepare a new host and module checkout:

```powershell
git clone https://github.com/AAEmu/AAEmu.git AAEmu-playerbots-v1
Set-Location AAEmu-playerbots-v1
git switch -c playerbots-host 62e3eb1d87da01194802ac886cd500134facad28
git clone https://github.com/NulightJens/ArcheAge-PlayerBots modules/archeage-playerbots
git -C modules/archeage-playerbots switch --detach 850c507faabf02a879b08771466c2e6181ea998b
```

From the AAEmu root, check compatibility, install, and build:

```powershell
& ./modules/archeage-playerbots/scripts/Install-PlayerBots.ps1 -AAEmuRoot $PWD -CheckOnly
& ./modules/archeage-playerbots/scripts/Install-PlayerBots.ps1 -AAEmuRoot $PWD
dotnet build AAEmu.slnx --no-incremental
& ./modules/archeage-playerbots/scripts/Install-PlayerBots.ps1 -AAEmuRoot $PWD -CheckOnly
```

On Linux or macOS, use the same Git revisions, `cd` into the host directory, and run:

```bash
./modules/archeage-playerbots/scripts/install-playerbots.sh "$PWD" --check-only
./modules/archeage-playerbots/scripts/install-playerbots.sh "$PWD"
dotnet build AAEmu.slnx --no-incremental
./modules/archeage-playerbots/scripts/install-playerbots.sh "$PWD" --check-only
```

The installer applies a versioned host patch with lifecycle, command, quest, and build hooks, and copies the module migration to `SQL/updates/`. It refuses unknown lineage, conflicting host edits, incompatible patches, and a different migration at the same path. `CheckOnly` makes no changes and reports `ready` or `installed`.

## Database and first bot

Provision the matching AAEmu assets and an isolated or versioned Game database using AAEmu's setup instructions. Never mix 1.2 and 3.0 data. Before using PlayerBots, apply `SQL/updates/2026-08-25_aaemu_game_bot_archetype_plans.sql` through AAEmu's normal database-update process.

Start the configured Login and Game services, log in as a GM, and follow [First companion](../README.md#first-companion). `/removebot <id>` saves and logs out the character; it does not delete it.

## Updating

Retain the existing installation and database. Create a successor directory such as `AAEmu-playerbots-v2`, repeat the clean installation with the new exact module revision, then validate the build and [relevant tests](TESTING.md). Review configuration and migration changes against a versioned test database before choosing a deployment window.

An installer is not a v3-to-v4 patch upgrader. If an older patched host rejects the new patch, use the fresh pinned-host replacement above and port only reviewed local host changes. Do not force-apply a new patch over the old one. Keeping the prior installation and data preserves a reviewable recovery path.

## Frozen 3.0 adapter

For explicitly scoped compatibility work, use its exact host base and add `-Track AAEmu30 -AllowExperimental` to the PowerShell installer (Bash: `--track aaemu30 --allow-experimental`). Build `AAEmu.sln` on that host.

Earlier startup and selected lifecycle, combat, class, and gear observations do not establish general gameplay support. New 3.0 feature work is frozen. The [retained runbook](AAEMU30-ACCEPTANCE.md) documents its remaining gates; do not use 1.2 data for them.

See [Troubleshooting](TROUBLESHOOTING.md) if installation fails. Historical compatibility patches and the optional dependency-security patch remain in `compatibility/`; the installer applies only the manifest's integration patch.
