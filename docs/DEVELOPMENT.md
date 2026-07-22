# Development notes

State of the repo as of July 2026, after the initial build-out sessions. Read this before
touching anything — especially the first section.

## The prime directive: don't touch the engine

`index.html` contains a simulation engine + optimizer (`simulate`, `optimizeAsync`, `polish`,
`repair`, and the tie-break passes) authored and iterated **separately** by Marek. It is:

- **Deterministic** — fixed RNG seed (`mulberry32(1337)`), earliest-on-ties, whole-second
  snapping. Same inputs ⇒ byte-identical schedule.
- **Regression-guarded** — `window.GOLDEN_PRESETS` (the "Debugging presets" strip) is a frozen
  exact-match suite; the author verifies against a headless wowsims build.
- **Off-limits to this repo's changes.** Everything we add is additive: UI panels, data
  (BUFFS entries, presets), integrations. Engine feature requests go to
  [issue #1](https://github.com/deanyo/arcane-tbc-tools/issues/1). The author is separately
  working on mana modeling (conserve-rotation placement) — stay out of that area entirely.

**Determinism guard** (run before merging anything): load the baseline and modified files,
run golden preset "5:00 lust 0:05" on both, compare `JSON.stringify(window.__run.best.s)` and
rounded totals. They must be identical. (Automating this is
[issue #5](https://github.com/deanyo/arcane-tbc-tools/issues/5).)

## What was built on top (session log, July 2026)

| Feature | Where in index.html | Notes |
|---|---|---|
| Real WoW icons | `ICON_IMG` table | base64 from zamimg CDN; regenerate with `tools/fetch-icons.sh`; offline-capable |
| Boss preset refresh | `BOSS_PRESETS` | July 2026 kill times; commented `T6_DRAFT_PRESETS` block below it (estimates) |
| Fight-facts learning | `fightFacts()` / `goldenToState(p, fightOnly)` | Boss presets set the FIGHT only (length/Lust/phases) and leave kit+gear alone; facts learned from logs live in localStorage `abp-fight-facts` |
| Kill-time explorer | `/* kill-time explorer */` section | re-optimizes across T−60..T+90, cliff markers from `unlockThresholds`, logged-kill dots (localStorage `abp-kills`), verdict line |
| WCL integration | `/* warcraftlogs (POC) */` section | v2 GraphQL client-credentials, straight from the browser (CORS is open); credentials in localStorage `abp-wcl` |
| — guild kills fetch | `wclFetchKills` | durations + when Lust actually went out; ⚠ flag when preset pin disagrees >15s; import button saves kill history + fight facts |
| — My stats | `wclFillStats` | SP from first cast's `spellPower`, haste from `combatantinfo.hasteSpell`, crit estimated (see below), trinket toggles from `gear[]` item ids |
| — Review a kill | `wclReview` / `wclRunReview` | click a kill duration: your actual presses (buff events + Cold Snap/gem casts) scored via `simulate()` vs a plan re-optimized for that kill's real length; externals the raid never gave are excluded |
| Reset button | `#btn-reset` / `FACTORY_STATE` | factory inputs (Icon+SCB trinkets, no Berserking); keeps presets/history/facts/credentials |
| Assumptions subpage | `assumptions.html` | full engine-behavior prose lives there (single source of truth); index footer is a 3-line summary |

## WCL API facts (verified live)

- v2 GraphQL client-credentials works from a static page — CORS is open on
  `https://www.warcraftlogs.com/oauth/token` and `/api/v2/client` (even for `file://`).
  The HTML site itself is Cloudflare-blocked; the API is the only programmatic route.
- One shared backend across retail/classic/fresh — fresh data is just different
  encounter IDs (classic ID + 100000). Guild id: **807668**.
- Rate budget ~3600 points/hour; an events request ≈ 2 points. Batch subqueries.
- Classic `combatantinfo` has crit/haste/hit **ratings** + int/spirit + `gear[]` + `auras[]`,
  but **no spell power** — SP rides on `cast` events (`spellPower` field, value at that cast;
  take the earliest cast, before on-use trinkets inflate it).
- Trinket presses are read as `applybuff` (dataType: Buffs); Cold Snap (11958) and
  Mana Emerald (27103) are casts with no aura.

### Verified spell/aura IDs

| Effect | ID |
|---|---|
| Icy Veins | 12472 |
| Arcane Power | 12042 |
| Blessing of the Silver Crescent (Icon) | 35163 |
| Fel Infusion (Skull of Gul'dan) | 40396 |
| Bloodlust / Heroism | 2825 / 32182 |
| Power Infusion | 10060 |
| Drums of Battle | 35476 |
| Berserking (caster/energy/rage) | 20554 / 26297 / 26296 |
| Cold Snap (cast) | 11958 |
| Replenish Mana (Mana Emerald, cast) | 27103 |
| Molten Armor (+3% crit aura) | 30482 |
| Moonkin Aura (+5%) | 24907 |
| Totem of Wrath (+3% crit, +3% hit) | 30708 |
| Chain of the Twilight Owl (+2%, JC neck party buff — no "Trance of" spell exists in TBC) | 31035 |
| Destruction Potion buff (+2% crit, +120 dmg) | 28508 |

Crit% estimate = 0.91 base + int/80 + critSpell/22.08 + detected percent auras. Rating-based
buffs (Songflower 15366, Power of the Guardian 28142) are already inside `critSpell` — do NOT
add them again. Aura-granted int (Brilliance/Kings/GotW) is already in the int snapshot.

### Trinket item ids (gear detection)

Icon 29370 · Skull 32483 · Ashtongue 32488 · Serpent-Coil Braid 30720 · MQG 19339.

## localStorage keys

| Key | Contents |
|---|---|
| `abp-presets` | user's custom presets (author's original feature) |
| `abp-kills` | `{bossName: [seconds,...]}` kill history for the explorer dots |
| `abp-fight-facts` | `{presetName: {T, lustAt}}` learned from logs, merged over boss presets on load |
| `abp-wcl` | `{id, secret, token, tokenId, exp, char}` WCL credentials + cached token |

## Deployment

GitHub Pages off `main` (legacy build). Live at https://dnyo.co.uk/arcane-tbc-tools/
(custom domain; deanyo.github.io/arcane-tbc-tools redirects). Push to `main` = deploy.
No build step: `python3 -m http.server` and open, or open `index.html` from disk.

After editing the `<script>` block, syntax-check with:
`node --check <(sed -n '/<script>/,/<\/script>/p' index.html | sed '1d;$d')`

## Open roadmap (GitHub issues)

1. **#1 Engine extensions for T6+** — silence/no-cast/immunity phase types, Naaru Sliver
   (90s cd, position-locked), Sextant proc ICD. For the author.
2. **#2 Derive phase timings from logs** — boss-damage gaps ⇒ learned intermission rows
   (extends the fight-facts pattern; matters most for Illidan/RoS).
3. **#3 Kill-time distribution objective** — optimize expected damage over the empirical
   kill spread instead of a point T. Engine change, for the author; kill history already exists.
4. **#4 Shareable state via URL fragment** — `#s=<base64>` so plans survive browsers and
   reach the guild's other mage.
5. **#5 CI golden runner** — Playwright + GitHub Actions automation of the determinism guard.

Also pending: T6 presets go live when the guild first logs Hyjal/BT (uncomment
`T6_DRAFT_PRESETS`, replace estimates with logged timings — or land #2 first and let the
tool learn them). The review-a-kill trinket detection assumption (trinkets as applybuff)
should be sanity-checked against a real report the first time it's used in anger.
