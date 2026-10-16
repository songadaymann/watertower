# Water Tower Smash

A Roblox game for little kids who love water towers. You start small in a new land with a water tower far off on the horizon. Bump into things to smash them and grow. Grow big enough to break through the walls into bigger areas, then knock down the water tower for a giant splash. Then jump through the rainbow ring to a brand new land.

**Live:** not published yet.

## How it plays

- **Smash to grow.** Walk into anything that sparkles. It pops, stars fly into you, and you get bigger. Things that are still too big just wobble and say "💪 Grow more!"
- **Three areas per land**, each bigger than the last, with a wall in between. You must be big enough to smash each wall.
- **The water tower** stands at the far end, visible from the start. The meter in the top-left is a little water tower that fills with water as you grow. When it's full, go knock the real one down: it falls, bursts, leaves a swimmable pond and a rainbow, and you get a trophy.
- **A new land every time.** Five biomes (Town, Farm, Snow, Beach, Candy), each laid out randomly, with five water tower styles: classic legged tank, candy-stripe, spheroid, hydropillar, and a Peachoid.
- No way to lose, no reading required. Banners are there for grown-ups to read aloud.

## Run it locally

You need [Roblox Studio](https://create.roblox.com/). The game world is built by scripts at runtime, so all the place needs is the code in `src/`.

**With [Rojo](https://rojo.space/)** (builds a fresh place file):

```bash
rojo build -o WaterTower.rbxl
```

Open `WaterTower.rbxl` in Studio and press Play.

**Without Rojo** (sync into a place you already have open):

```bash
python3 tools/dev-sync-server.py
```

Then paste `tools/studio-sync.luau` into Studio's command bar. It pulls every script from `src/` into the place, turning HttpEnabled on only for the fetch. In that place, also delete the default Baseplate and SpawnLocation, and set `Workspace.StreamingEnabled` to false so the faraway tower always loads.

## How it's built

Luau, laid out Rojo-style:

| Path | What's there |
| --- | --- |
| `src/shared/Config.luau` | Tuning: tier sizes, growth rate, speeds, sound IDs, music |
| `src/server/Land.luau` | Generates a land: zones, cliffs, walls, path, scattered stuff |
| `src/server/Items.luau` | Every smashable thing, built from primitive parts |
| `src/server/Towers.luau` | The water tower styles |
| `src/server/Biomes.luau` | What each biome looks like and what shows up in it |
| `src/server/Smash.luau` | Touch detection, growing, flinging debris, the tower fall and splash |
| `src/server/Main.server.luau` | Players, smooth scaling, the portal to the next land |
| `src/client/` | HUD, sparkles, camera zoom, effects, music, the far-away tower picture |

Easy things to change:

- **Town names** painted on the towers: `names` in `src/server/Biomes.luau`. Put your kid's name on one.
- **How fast you grow:** `Config.GROWTH` in `src/shared/Config.luau`.
- **Sound:** the 🔊 button in the top-right corner. Sound starts muted in Studio playtests and on in the real game.

## License

Code: [MIT](LICENSE). Sounds and music: see [ASSETS.md](ASSETS.md).

Made by [Jonathan Mann](https://jonathanmann.net) (Song A Day).
