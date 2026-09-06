# Contributing

Bug reports and focused pull requests are welcome. For a bug, include the module revision, AAEmu track/base, what you expected, what happened, and a small reproduction. Exclude credentials and player data.

For code changes:

1. Use the pinned AAEmu 1.2 host in the [installation guide](docs/INSTALLATION.md) and a focused module branch.
2. Keep module source and behavior tests here. Change host patches only when a new host boundary is needed.
3. Run focused compiled tests while iterating. Run the full 1.2 suite on the final candidate for shared infrastructure or a release; documentation-only edits need link and accuracy checks. See [Testing](docs/TESTING.md).
4. Describe the player-visible change, validation results, remaining limits, and any resource impact.

Prefer native ArcheAge systems, bounded work, and cached world queries. Preserve useful tests and upstream notices. New features target 1.2; the 3.0 adapter remains frozen.

See [Development](docs/DEVELOPMENT.md) for setup and [Architecture](docs/ARCHITECTURE.md) for the code structure. Automated contributors have a separate [agent guide](docs/agents/README.md).
