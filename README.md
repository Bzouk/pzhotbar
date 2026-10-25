# BZQuickSlots

Quick access bars for Project Zomboid. Drag items from anywhere in your inventory into a
slot and use them with one click — no more digging through a backpack inside a backpack
for the one bandage you need.

Mod ID `pzhotbar42` · Build 42 · [Steam Workshop 3396010813](https://steamcommunity.com/sharedfiles/filedetails/?id=3396010813)

![Five bars placed around the screen](docs/screenshots/overview.jpg)

## Contents

- [What it does](#what-it-does)
- [Using it](#using-it)
- [Settings](#settings)
- [Installing](#installing)
- [Versions](#versions)
- [Languages](#languages)
- [Known issues](#known-issues)
- [Building](#building)
  - [Testing in the game](#testing-in-the-game)
- [Credits](#credits)

## What it does

A slot holds an *item type*, not an item. The item itself can stay wherever it lives —
in your main inventory, in a bag, or in a first aid kit inside that bag. The slot counts
every usable copy you are carrying and left-click reaches in and uses one.

![The default bar](docs/screenshots/default-bar.jpg)

Drag any item into a slot. You do not need to own the item to bind it.

![Dragging items into slots](docs/screenshots/drag-and-drop.jpg)

The number on a slot counts non-broken items across every container on you, nested ones
included. Broken items are ignored — handle those in the inventory window.

![Counting items in nested containers](docs/screenshots/item-count-nested.jpg)

Nested really does mean nested — bandages in a first aid kit in a school bag still count.

![Items inside a container inside a container](docs/screenshots/items-in-containers.jpg)

Hovering a slot shows the same info panel as the inventory.

![Item tooltip](docs/screenshots/item-tooltip.jpg)

> The screenshots are from the earlier Build 41 version. The layout and behaviour are the
> same; some Build 42 additions are not pictured yet.

## Using it

**Tab** shows and hides the bars. Bars drag around freely and use the same window frame as
the inventory panel (X to hide, pin to collapse).

**Right click** behaves exactly like right-clicking the item in the inventory.

**Left click** does the sensible thing for that item type, using the game's own actions.
Most actions put the item back where it came from when they finish:

```
1) Click a slot holding Disinfectant (the bottle is in a medkit in your backpack)
2) The bottle moves to your main inventory
3) It is applied to your damaged body parts
4) It goes back into the medkit in your backpack
```

If you cancel the action (start running, etc.) the item stays in your main inventory.

| Item | Left click |
|---|---|
| Food | Same as double-click in the inventory. Eats half, or the whole thing for cigarettes (needs a lighter). |
| Water and beverages | Drinks if you are thirsty and the fluid is not tainted. |
| Pills (BetaBlock, AntiDeb, Sleeping Tablets, Vitamins) | Takes one pill. |
| Disinfectant, Alcohol Wipes | Applies to every damaged body part that has no alcohol yet. |
| Dish Cloth, Bath Towel | Dries you off. |
| Thread | With a needle in your inventory, stitches all deep wounds. |
| Hand weapon | Equips it — two-handed if the weapon is. Optionally swaps whatever is in your hands into the weapon container. |
| Bandage (any bandaging item) | Cleans burns if the bandage is sterilised, otherwise bandages a damaged part. |
| Clothing | Equips it. |
| Literature | Starts reading. |
| Suture Needle Holder, Tweezers | Removes all glass and bullets from damaged parts. |
| Suture Needle | Stitches one deep wound. |
| Comfrey Cataplasm | Applies to a fractured part that has none. |
| Wild Garlic Cataplasm | Applies to one infected wound. |
| Plantain Cataplasm | Applies to one scratched, deep wounded or cut part. |
| Splint | Applies to a fractured part that has none. |
| Radio | Equips or unequips. |
| Anything else | Nothing — use right click. |

When several copies qualify, the mod picks the best one: for fluid containers it prefers
the ones you can actually pour from.

Ideas worth binding: ammo (the count tells you how many rounds you have), an ammo box
(right click to open), a watch (equip, then right click to set the alarm), crafting
materials, and spears — click the slot to re-equip a fresh one the moment the old one
breaks.

## Settings

Everything lives in the game's built-in **Mod Options** screen, under *Bz Quick slot mod*.
Build 42 provides that screen itself, so no extra mod is needed.

![Mod options](docs/screenshots/mod-options.jpg)

| Setting | Range | Default |
|---|---|---|
| Toggle keybind | any key | Tab |
| Number of bars | 1–5 | 1 |
| Rows / columns per bar | 1–10 each | bar 1 is 2×8, the rest 1×1 |
| Slot size | 45–90 px, step 5 | 65 |
| Bar opacity | 0–1, step 0.1 | 1 |
| Move weapons to the weapon container | on/off | on |
| Simple delete button | on/off | off |
| Show delete button | on/off | on |
| Show tooltip | on/off | on |
| Hide bars in a vehicle | on/off | off |
| Per-slot keybinds, bar 1 slots 1–9 | any key | unbound |

![Keybind in the options screen](docs/screenshots/mod-options-keybind.jpg)

Settings are stored in `pzhotbar.ini`. On first run the mod imports the original Lua
mod's `bzhotbar.ini` if it finds one.

## Installing

Subscribe on the workshop, then enable **BZQuickSlots** in the mod list. No dependencies —
Blindcoder's Modding Utility is no longer required, its INI helpers ship inside the mod.

**Do not run this alongside the older versions of the mod.** They fight over the same bars.

## Versions

| Version | Build | Workshop | Source |
|---|---|---|---|
| BZQuickSlots (this one) | B42 | [3396010813](https://steamcommunity.com/sharedfiles/filedetails/?id=3396010813) | `main` |
| BzoukPzHotBarNew | B41 | [3133189049](https://steamcommunity.com/sharedfiles/filedetails/?id=3133189049) | tag `v0.1.4-b41` |
| Original Lua mod | B41 | [2434425002](https://steamcommunity.com/sharedfiles/filedetails/?id=2434425002) | archived repo `pz-bzoukhotbar` |

What Build 42 changed: the mod moved to the [B42 folder structure](https://pzwiki.net/wiki/Folders_structure),
switched to the built-in Mod Options API, gained per-slot keybinds, bar opacity, a
hide-in-vehicle option, and it now understands the B42 fluid system — slots show the fill
level of bottles and drinking goes through the fluid API.

## Languages

English, Czech, French (@Bobitec + Google), Spanish (@WhiteLotus + Google), Chinese, Russian.

## Known issues

- Items that share a display name are grouped together by the game even when they are
  different items.
- Right-click crafting needs the items in your main inventory or a bag — a game mechanic,
  not something the bar can work around.

## Building

Plain Lua. `src/` holds the content of the mod's Build 42 folder (`mod.info`, images,
`media/`). Up to 0.2.3 the mod was written in TypeScript with PipeWrench and PZPW; that
code is kept under the tag `v0.2.3-ts`.

Type checking runs [lua-language-server](https://github.com/LuaLS/lua-language-server)
against the [Umbrella](https://github.com/PZ-Umbrella/Umbrella) typings, expected in
`~/.local/share/umbrella` (see `.luarc.json`):

```bash
scripts/check.sh
```

`scripts/build.sh` builds the Workshop item into `build/Workshop/BZQuickSlots`:
`workshop.txt` (fixed keys from `assets/workshop/workshop.txt`, the description from
`assets/workshop/description.txt`), `preview.png` and `Contents/mods/pzhotbar42/42/`.

### Testing in the game

The game reads items under development from `~/Zomboid/Workshop`. Link the build there
once; after that every `scripts/build.sh` is live on the next game start:

```bash
ln -s /path/to/pzhotbar/build/Workshop/BZQuickSlots ~/Zomboid/Workshop/BZQuickSlots
```

If the game does not follow the link, copy instead after each build:

```bash
rsync -a --delete /path/to/pzhotbar/build/Workshop/BZQuickSlots/ ~/Zomboid/Workshop/BZQuickSlots/
```

Unsubscribe from the Workshop item and keep no `pzhotbar42` in `~/Zomboid/mods` while
testing, or the game loads two copies. Lua errors land in `~/Zomboid/console.txt`.
Uploading goes through the in-game uploader (main menu → Workshop), which replaces the
whole Steam description with the one in `workshop.txt`.

## Credits

The idea comes from [Hotbar for 5-20 often-used](https://steamcommunity.com/sharedfiles/filedetails/?id=503645367)
by Blindcoder, and from quickbars in other games.

MIT © Bzouk
