<p align="center">
  <img src="assets/playerbots-readme-banner.png" alt="ArcheAge PlayerBots companions overlooking an ArcheAge coastline" width="100%" />
</p>

# ArcheAge PlayerBots

PlayerBots adds server-controlled player characters to [AAEmu](https://github.com/AAEmu/AAEmu). Bring an offline character into the world, invite it to your party, and give it simple orders.

- Persistent characters with normal saving and logout.
- Follow, stay, attack, and passive party commands.
- Melee, archer, mage, healer, and tank behavior using native skills.
- Configurable archetypes, rotations, startup bots, and diagnostics.
- Experimental creation of fresh characters and automatic starter quests on ArcheAge 1.2.

## Installation

PlayerBots is a source module compiled with a compatible AAEmu host. Start with the [installation guide](docs/INSTALLATION.md) for the exact host and module revisions, setup commands, and database migration.

| Track | Status |
| --- | --- |
| ArcheAge 1.2 r208022 | Active development; pinned host required |
| ArcheAge 3.0.4.2 r336598 | Frozen experimental adapter; retained for compatibility |

The repository's alpha features and published releases may differ. Choose an exact module revision when installing or updating.

## First companion

After installation, log in as a GM and choose an existing offline character. Replace `2` with its character ID:

```text
/addbot 2
```

Invite the bot through the normal party UI, then issue an order:

```text
/botcontrol 2 role attacker
/botcontrol 2 follow
```

Use `/botcontrol 2 attack` to enable party combat, or `/botcontrol 2 passive` to stop attacking. When finished, `/removebot 2` saves and logs out the character.

See [commands](docs/COMMANDS.md) for other roles, class and gear tools, and diagnostics. Fresh-character questing has a separate [experimental walkthrough](docs/QUEST-AUTONOMY.md#try-a-fresh-nuian).

## Guides

| I want to… | Read |
| --- | --- |
| Install or update | [Installation](docs/INSTALLATION.md) |
| Change bot behavior | [Configuration](docs/CONFIGURATION.md) |
| Control bots in game | [Commands](docs/COMMANDS.md) |
| Solve a problem | [Troubleshooting](docs/TROUBLESHOOTING.md) |
| See what comes next | [Roadmap](docs/ROADMAP.md) |
| Contribute code or report a bug | [Contributing](CONTRIBUTING.md) |

## Current limits

Quest autonomy is opt-in and supports only selected native objective types. The fresh-Nuian five-quest scenario still needs repeatable client and restart acceptance on the final candidate. Roads and local paths do not guarantee safe travel through every obstacle, cave, or interior. There is no accepted living-world population or server-capacity target yet.

## For agents

The dedicated [agent guide](docs/agents/README.md) contains the code map, working rules, and validation workflow.

## Acknowledgements

This ArcheAge implementation draws on the [Playerbots family](docs/UPSTREAM-PLAYERBOTS-REFERENCE.md), with AAEmu providing the native game systems. PlayerBots is distributed under [GPL-3.0-or-later](LICENSE.GPL); retained file-specific notices still apply. AAEmu and PlayerBots are not affiliated with XLGames.
