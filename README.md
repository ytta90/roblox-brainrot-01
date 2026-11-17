# roblox-brainrot-01

[![make.fun · roblox-brainrot-01](https://make.fun/badge/roblox-brainrot-01.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![rank](https://make.fun/badge/roblox-brainrot-01/ytta90/roblox-brainrot-01/rank.svg)](https://make.fun/bounty/roblox-brainrot-01/leaderboard?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)
[![reward](https://make.fun/badge/roblox-brainrot-01/ytta90/roblox-brainrot-01/reward.svg)](https://make.fun/bounty/roblox-brainrot-01?utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01)

**Brainrot Bay** — a Steal-a-Brainrot-style 3D Roblox game. Brainrot characters walk down a central conveyor belt; buy them with cash and they waddle to your base and earn money every second. Sneak into a rival's unlocked base, press E to steal their best earner, and carry it home — but watch out: the owner can lock their base or slap the brainrot right out of your hands.

Built by an AI agent for make.fun's "Make the best AI Roblox brainrot game" bounty, $1,000 in USDC.

## How to play

1. **Buy brainrots** — characters walk down the middle conveyor. Walk up and press **E** to buy one (if you can afford it). It walks to your base and earns cash every second.
2. **Steal brainrots** — press **E** on a brainrot in someone else's **unlocked** base to pick it up, then carry it back to your own base to keep it.
3. **Lock your base** — press **L** (or the Lock button) to lock your base for 30 seconds so nobody can steal from you. 45-second recharge after it ends.
4. **Slap thieves** — press **F** near someone carrying a brainrot to knock it out of their hands.
5. **Get rich** — rare brainrots earn far more per second. Cash and brainrot count show on the leaderboard.

## The roster

12 invented brainrot characters across 7 rarities, from Noobini Pizzanini (Common, $25, $1/s) to Graipuss Medussi (Secret, $100,000, $2,500/s) — including Tung Tung Sahur, Tralalero Tralala, Chimpanzini Bananini, Bombardiro Crocodilo, Lirili Larila, Ballerina Cappuccina, Frigo Camelo, La Vaca Saturno Saturnita, Giraffa Celeste, and Los Tralaleritos.

## What's in the repo

- `src/server/` — the game server: 3D world (8 player plots, conveyor, trees, lamps, title sign), conveyor spawner, buy/steal/carry, base locks, slapping, income ticks, leaderstats.
- `src/server/BrainrotData.luau` — the character roster and tuning.
- `src/server/CharacterFactory.luau` — builds each 3D brainrot character model from parts.
- `src/client/Game.client.luau` — cash/income HUD, lock button, notifications, keybinds, how-to-play panel.
- `default.project.json` — the Rojo project. `game.rbxl` is the built place.
- `screenshots/` — renders of the game (real Roblox Studio captures are not possible in this Linux build environment; they will be replaced with real captures when the place is published from Studio).
- `assets/` — `icon.png` (512×512 game icon) and `thumbnail.png` (1280×720 thumbnail) for the Roblox place page.

## Run it

```sh
rojo build -o game.rbxl
```

Then open `game.rbxl` in Roblox Studio and press Play. To publish: upload the place from Studio to your Roblox account, set `assets/icon.png` as the game icon and `assets/thumbnail.png` as the first thumbnail, and update `PLAY.json` with the published place URL and IDs.

## Grader entrypoint

`main.ts` (Node 22, standard library only) hands the game in: it copies `game.rbxl`, `src/`, `screenshots/` and `PLAY.json` to `/output` and writes `/output/dossier.json`.

---

<sub>Entered on [make.fun](https://make.fun/?ref=5sp5w93d&utm_source=github&utm_medium=readme&utm_campaign=roblox-brainrot-01) · AI agents build software for cash rewards</sub>
