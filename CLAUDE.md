# CLAUDE.md — disable_kneeboard_maps

Project-specific context for Claude. Extends the general rules in `~/.claude/CLAUDE.md`.

---

## What This Project Is

An OVGME mod for DCS World that suppresses the automatic per-waypoint map page generation
built into the kneeboard system. The target file is:

```
DCS World\Scripts\Aircrafts\_Common\Cockpit\KNEEBOARD\device\init.lua
```

This project's directory structure mirrors the DCS install root so OVGME can merge it
directly on top of the game files. **Do not add an `override/` prefix or any wrapper
directory.** The path `Scripts/Aircrafts/...` must start at the project root.

---

## Hard Constraints — Do Not Repeat These Mistakes

### `mount_vfs_path` does not exist

DCS's tech mod API (`declare_plugin` in `entry.lua`) only exposes:
- `mount_vfs_model_path`
- `mount_vfs_texture_path`
- `mount_vfs_liveries_path`
- `mount_vfs_sound_path`

None of these reach `Scripts/Aircrafts/`. Calling `mount_vfs_path()` crashes DCS on startup
with: `attempt to call global 'mount_vfs_path' (a nil value)`. **There is no VFS mount
function for cockpit scripts.** Do not suggest it. Do not add an `entry.lua`.

### DCS uses Lua 5.1

Hex escapes like `\xe2\x80\x94` are Lua 5.2+ syntax. They silently produce wrong output
or errors in DCS. Use ASCII equivalents (`--` instead of an em dash, etc.).

### This mod does not suppress everything

The first kneeboard page (`pages = {{BASE,MAP,OVERLAY}}` in `indicator/init.lua`) is
rendered by the `ccKneeboard` C++ indicator — a separate pipeline from `avKneeboard`.
This mod removes it via a second override file: `Scripts/Aircrafts/_Common/Cockpit/KNEEBOARD/indicator/init.lua`.
That file sets `pages = {}` and removes the `Add_Map_Page` call. The rest of the file
(page scanner, viewport config) is preserved so custom pages still load.

---

## How the Mod Works

`device/init.lua` runs inside the `avKneeboard` C++ device context. The C++ driver calls
Lua callbacks after reading the mission flight plan:

| Callback / variable        | Normal behavior                          | This mod          |
|----------------------------|------------------------------------------|-------------------|
| `on_waypoint_adding(x,z,c)`| Appends an entry to `map_pages`          | Replaced: no-op   |
| `generate_maps()`          | Appends 3 fixed overview pages           | Replaced: `map_pages = {}` |
| `note_generate_template`   | Lua string template for note pages       | Set to `nil`      |
| `number_of_additional_pages` | Count C++ reads before rendering       | Set to `0`        |

Lua function definition is assignment — redefining a function later in the same file
overwrites the earlier definition. The override file preserves all original setup code
(`chart_defaults`, `need_to_be_closed`, etc.) and appends the no-ops at the bottom.

**Do not remove the setup code from `init.lua`.** `avKneeboard` reads those variables
before calling the callbacks. If they're missing, behavior is undefined.

---

## Installation Method

OVGME only. There is no DCS-native tech mod path for cockpit scripts (see constraints above).

OVGME operates at the OS level: it copies files from this mod folder into the DCS install
tree, backing up originals, and restores them on disable. The directory structure of this
project is the OVGME package layout — it is not a source-to-build pipeline.

---

## Verifying the Mod Works

1. Enable the mod in OVGME, launch DCS, load any mission with a flight plan.
2. Open the kneeboard in-cockpit.
3. Cycle through all pages — no per-waypoint map pages should appear.
4. The `ccKneeboard` overview page (first page, shows the route line) will still be present.
   That is expected and correct behavior for this mod.

---

## CLAUDE.md Best Practices

Guidelines for writing effective `CLAUDE.md` files in any project.

### Write constraints, not documentation

CLAUDE.md is for information Claude cannot derive from reading the code or README. Ask:
"Would Claude get this wrong without being told?" If yes, put it here. If no, leave it out.

**Put in CLAUDE.md:**
- Dead ends discovered through debugging or research ("X does not exist", "Y crashes because...")
- Non-obvious invariants Claude might silently violate ("do not add Z or W breaks")
- Hard platform or API constraints that contradict common web knowledge
- The authoritative reason *why* a constraint exists, so Claude can judge edge cases

**Do not put in CLAUDE.md:**
- What the project does — that belongs in README.md
- Code patterns derivable from reading the source
- Things documented in git history or commit messages
- Speculative future constraints

### Lead with the rule, follow with the reason

```
### Thing Claude Must Not Do

One-sentence rule. Then: why it matters, what breaks if violated.
```

The reason is load-bearing. Without it, Claude may apply the rule rigidly where it doesn't
apply or ignore it where it does.

### Use "Do not" and "Must" for hard stops

Soft language ("prefer", "try to", "consider") invites Claude to use judgment and override
the constraint. Use imperative language only when the constraint is genuinely non-negotiable.

### Keep it short

Every line Claude reads is context budget. A CLAUDE.md longer than one screen will be
skimmed. If a section could be cut without Claude making a mistake, cut it.

### Update when you find new dead ends

The most valuable CLAUDE.md entries come from debugging sessions. When something breaks
because Claude made a plausible-but-wrong assumption, add a constraint immediately.
That's the constraint's origin story — it belongs here.
