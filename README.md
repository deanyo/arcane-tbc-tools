# Arcane TBC Tools

Cooldown-overlay planning tools for a TBC Classic (Anniversary / "fresh" realms, 2.4.3 ruleset) Arcane mage.

**Live tool: https://deanyo.github.io/arcane-tbc-tools/**

## Arcane Burn Planner (`index.html`)

A single-file, zero-dependency planner that finds the optimal cooldown overlay for a fight and prints a press-by-press plan:

- **Setup** — gear (haste rating, spell damage, crit), fight length, your cooldown kit (spells, two trinket slots, raid externals), and pins for anything the raid controls (Bloodlust call, Drums rotation, Power Infusion).
- **Complicated fights** — intermission / burn / AoE phases painted over the base fight.
- **Optimizer** — a deterministic multi-start search over a continuous cast-rate damage model (steady 3-stack Arcane Blast, GCD floor, Ashtongue proc dynamics, trinket lockouts, Cold Snap chains), with tie-breaks that prefer *pressable* plans: windows that complete before the kill, presses anchored to things you can see, co-pressed macros over scattered seconds.
- **Outputs** — a pressboard you can follow live at the pull, a burn timeline (haste curve + buff lanes), an activation schedule with copy-as-text, a haste cap sheet, and kill-time sensitivity notes.
- **Presets** — baked boss presets (real SSC/TK pulls), sim-verified debugging presets (the exact-match regression suite), and your own saved setups (localStorage).

Everything runs client-side; the file also works opened directly from disk (offline at the raid).

Additions built on top of the engine (see [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) for the full map):

- **Kill-time explorer** — after each run, the plan is re-optimized across nearby fight lengths and drawn as a gain-vs-kill-time chart, with cliff markers where an extra cooldown use fits and your logged kills overlaid. Answers "is my kill time near a breakpoint?" at a glance.
- **Warcraft Logs integration** — guild kill times (with when Bloodlust actually went out, flagged if a preset's pin disagrees), one-click gear-stat fill from your latest logged kill, and *review a kill*: your actual presses scored against the optimal plan for that fight.
- **Learning presets** — boss presets describe the fight only (length, Lust call, phases) and leave your character setup alone; importing from Warcraft Logs teaches them your guild's real timings. No hand-edited data.
- **Model assumptions** live on [assumptions.html](https://dnyo.co.uk/arcane-tbc-tools/assumptions.html).

### Engine provenance

The simulation engine and optimizer are authored and iterated separately, verified against a headless [wowsims](https://wowsims.github.io/tbc/) build, and guarded by a frozen golden-preset regression suite (`window.GOLDEN_PRESETS` — a confirmed preset *is* the test). Changes in this repo stay out of the engine: UI panels, data (presets, item definitions), and integrations only. The `docs/` and `tests/` referenced in engine comments live with the author and can land here later.

## Development

No build step. Edit `index.html`, open it in a browser (or `python3 -m http.server`), test with a boss preset. `tools/fetch-icons.sh` regenerates the embedded icon data from the Wowhead CDN.
