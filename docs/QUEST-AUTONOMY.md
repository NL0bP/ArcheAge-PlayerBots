# Quest autonomy

Quest autonomy is an opt-in AAEmu 1.2 feature. It uses the server's normal quest, combat, loot, and report APIs; it does not grant progress directly.

## Enable it

Both switches ship disabled:

```json
{
  "QuestIntakeEnabled": true,
  "QuestCompletionEnabled": true
}
```

Reload with `/reloadbotconfig`.

## Try a fresh Nuian

Use an isolated 1.2 server with matching starter-area data and a [dedicated bot account](BOT-IDENTITIES.md). This is an experimental walkthrough, separate from the existing-character companion commands.

1. Log in as a GM at the Nuian starter area and configure the two switches above.
2. Create a fresh character at the observed location:

   ```text
   /createbot FreshNuian Nuian Female Abolisher 1 here
   ```

3. Note the returned character ID and use `/botstate <id> free` to release forced state control. Leave it out of a follow order so eligible quest work can own movement.
4. Observe `/botdebug <id>` and the client while it discovers and attempts supported quests. Do not select targets, increase its level, generate gear, teleport it, or grant quest credit as part of a fresh-character test.
5. To end the experiment, disable the quest switches and reload configuration, then `/removebot <id>` for normal saving and logout. The switches apply to the server's bots, not just this character.

Five automatic native completions and persistence across a graceful restart are the acceptance target. A diagnostic state or one earlier successful run does not establish that result on the final candidate.

## Decision order

The bot keeps valid current work instead of changing goals every tick. When it needs new work, it groups destinations within 500 metres as local, then orders by distance, ready-to-report state, main-story status, and quest ID. Regional work is considered after local work.

Intake discovers eligible NPC and doodad starters, approaches through normal movement, and accepts through AAEmu. Completion supports:

- exact monster-hunt objectives;
- quest-linked item gathering from corpses owned by the bot;
- supported NPC, doodad, and journal reporting;
- waiting for respawns and native quest-state updates.

Quest markers and static spawns locate objectives. Transfer roads guide long travel, while local movement handles the final approach. See [World navigation](WORLD-NAVIGATION.md).

## Safety and limits

Ambiguous, mixed, unsupported, or cross-world work can suspend with a reason. The bot revalidates live targets before combat or interaction and never teleports to complete a quest. Unreachable travel is not fully fail closed: the shared movement caller retains an explicitly labeled unverified direct fallback, as described in [World navigation](WORLD-NAVIGATION.md).

This is not universal quest support. Scripted item use, conversations, vehicles, complex gathering, caves, and sparse navigation data may require new objective handlers.

Use `/botdebug <id>` for the current intake, lifecycle, target, and route decisions. The optional [live monitor](../scripts/autonomy/README.md) presents the same state as a static board.
