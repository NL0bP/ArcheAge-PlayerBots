# Changelog

Release notes describe behavior and compatibility. Historical measurements remain in the [original alpha.6 notes](https://github.com/NulightJens/ArcheAge-PlayerBots/blob/850c507faabf02a879b08771466c2e6181ea998b/CHANGELOG.md); they are not acceptance evidence for later candidates.

## Unreleased

- Simplified installation, contribution, testing, and roadmap guidance, with a separate public agent section.
- Preview metadata and patch/migration hashes now come from the requested archived revision. Added cross-ref and corrupt-archive regressions.
- Native navigation distinguishes missing, partial, and complete paths by the actual endpoint. Road connectors require a complete local result; native routes no longer append an unverified final destination.
- The shared movement caller's unverified direct compatibility fallback remains explicitly labeled. Fully fail-closed quest movement and the final client/restart acceptance remain pending.
- AAEmu 1.2 remains the active feature target; the experimental 3.0 adapter is frozen.

## 0.2.0-alpha.6 — 2026-09-03

### Characters and quests

- Added persistent 1.2 bot creation under a configured server-owned account.
- Added learned-skill-aware combat using native range, cooldown, and resource checks.
- Added opt-in NPC/doodad quest intake, supported monster-hunt and corpse-gather objectives, native reporting, and quest-marker/road routing.
- Kept valid current quest work sticky, considered nearby work before regional work, and waited for native progress and respawns.
- Added a static decision monitor for quest, combat, navigation, and runtime state.
- Consolidated 1.2 integration in the v4 compatibility patch.

Earlier client observations included native starter-quest completions. The final candidate still requires a client-witnessed repeat and graceful-restart persistence gate; the feature remains experimental.

### Companion control and combat

- Restored class selection with learned/passive skills and persistent archetypes.
- Added equipment inspection, evaluation, and generated Magnificent loadouts with reported data-pack fallbacks. Successful class and gear changes refresh clients through normal logout/login.
- Integrated native kit equipment with bot evaluation and saving; corrected equipment-container slot reporting and 3.0 public equipment visibility.
- Fixed attack, follow, state, and party commands failing to wake brains detached after inactive-duel cleanup.
- Refined melee legal-range approaches, archer escape and moving-target attacks, caster filler availability, and party healing while following a moving owner.
- Added stealth-loss search transitions, bounded search diagnostics, and buff tools for controlled testing. Client-visible stealth release/reacquisition remains a separate acceptance case.

### Experimental 3.0 adapter

- Added the pinned NL0bP/AAEmu adapter, version-specific targets and patches, and explicit experimental installer opt-in.
- Added asset-provenance checks and host tests for lifecycle, combat attribution, persisted resources, metrics, administrative commands, and class/gear behavior.
- Recorded isolated startup and selected client/lifecycle/class/gear observations. These do not establish general gameplay support; remaining gates are preserved in the [3.0 runbook](docs/AAEMU30-ACCEPTANCE.md).

## 0.1.0-rc.2 — 2026-08-29

- Corrected CI test execution to use AAEmu's Microsoft Testing Platform configuration.
- Made Unix test-artifact paths portable and added command compilation and dependency-audit release checks.
- No bot runtime behavior changed from rc.1.

## 0.1.0-rc.1 — 2026-08-29

- Established the standalone module repository, manifest, installers, conditional source/test imports, and clean-host CI.
- Added persistent connectionless characters, seven archetypes, data-driven rotations, native-party roles/orders, and GM diagnostics.
- Added activity budgets, cached scans, timing and resource metrics, and isolated lifecycle/scale tools.
- Retained the former combined emulator repository as integration history.

Direct movement is not a full navmesh, jump presentation remains experimental, and historical population exercises do not define a supported server capacity.
