# Agent entry point

Read [the agent guide](docs/agents/README.md) before changing code. It maps the source, host boundary, and validation workflow.

- Keep public documentation useful to a person installing or contributing to the mod. Put agent workflow details under `docs/agents/`.
- Develop against the exact AAEmu 1.2 base in `playerbots.module.json`. The 3.0 adapter is frozen; preserve its released patches and compile guards.
- Keep behavior in this module and host integration in reviewed compatibility patches. Preserve native quest, movement, combat, inventory, and persistence authority.
- Make focused, testable changes. Preserve useful tests, upstream notices, existing work, and historical patches.
- Keep machine paths, private task records, credentials, client assets, databases, and raw runtime evidence out of public source.
- Follow the current task's write and runtime scope. Source tests do not authorize deployment, runtime control, publication, or gameplay acceptance.
