# Development

Use the [pinned installation](INSTALLATION.md) in an isolated AAEmu checkout, with this repository at `modules/archeage-playerbots`. Keep the host integration on its own branch. Module source and tests compile through the conditional targets in `build/`; they remain owned by this repository.

## Work on one behavior

Put production code in `src/AAEmu.Game`, tests in `tests/AAEmu.UnitTests`, and tunable rotations or archetypes in the existing data files. Preserve the kernel, native game authority, and useful behavior tests. Keep scans and retries bounded.

See [Architecture](ARCHITECTURE.md) for boundaries and [Testing](TESTING.md) for build commands and the focused/full-suite cadence.

## Host changes

Use a fresh checkout of the manifest's AAEmu base when changing integration. Add a versioned compatibility patch and document the contract; retain released patches. Do not hide host changes in the installer or copy host-owned code into the module.

AAEmu 3.0 remains frozen. Preserve its compile guards and adapters when changing shared code; repeat its regression at an authorized compatibility or release boundary.

## Review

Explain the changed behavior, its tests, and remaining gameplay evidence. Check legal skill execution, movement ownership, recovery, native authority, and resource cost where relevant. Preserve [upstream provenance](UPSTREAM-PLAYERBOTS-REFERENCE.md).

Use isolated, versioned test data. Keep credentials, client assets, databases, private operations, recordings, and raw logs outside Git. Agent-specific working instructions live in [the agent section](agents/README.md).
