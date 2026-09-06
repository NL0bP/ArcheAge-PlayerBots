# Upstream references

ArcheAge PlayerBots is an AAEmu-native implementation informed by the Playerbots family. These pinned references explain design ideas; they are not interchangeable host dependencies or a claim of feature parity.

| Reference | Reviewed revision | Useful ideas |
| --- | --- | --- |
| [AAEmu/AAEmu](https://github.com/AAEmu/AAEmu/tree/62e3eb1d87da01194802ac886cd500134facad28) | `62e3eb1d87da01194802ac886cd500134facad28` | Executable 1.2 host; native character, quest, combat, inventory, and movement authority |
| [mod-playerbots/mod-playerbots](https://github.com/mod-playerbots/mod-playerbots/tree/b949b50bfcdd4fab937781bac2d7765e39330e4b) | `b949b50bfcdd4fab937781bac2d7765e39330e4b` | Actions, triggers, cached values, strategies, travel commitment, and population cadence |
| [ike3/mangosbot](https://github.com/ike3/mangosbot/tree/455ebe80b65956eb09d8e349ee54b458ba2f7e12) | `455ebe80b65956eb09d8e349ee54b458ba2f7e12` (`trinity-wotlk-ai`) | Historical engine and behavior decomposition |
| [TrinityCore](https://github.com/TrinityCore/TrinityCore/tree/65f4f04650ae5c91bda174703d0043891d12b34d) | `65f4f04650ae5c91bda174703d0043891d12b34d` (`3.3.5`) | Movement ownership and missing/partial/complete path vocabulary |

The modern Playerbots module requires its [modified AzerothCore host](https://github.com/mod-playerbots/mod-playerbots#installation). Modular behavior and explicit host integration can coexist. Here, the host remains AAEmu and integration is recorded in versioned compatibility patches.

Keep the existing C# kernel and translate only a demonstrated behavior need. Use native ArcheAge progress and persistence; do not translate teleport recovery, injected quest credit, fake item/resource gains, or WoW world data.

For copied or directly translated code, record the exact upstream file and revision, preserve applicable attribution and license notices, and identify the changes. A general reference table does not replace file-specific provenance. Existing notices and [LICENSE.GPL](../LICENSE.GPL) / [LICENSE.MIT](../LICENSE.MIT) remain intact.

The [historical combined emulator repository](https://github.com/NulightJens/AAEmu-PlayerBots-Public) is retained integration history. This standalone repository is the canonical module source.
