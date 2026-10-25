---
date: 2026-10-24
repos:
  - identifier: "Home/pzhotbar"
    sha: b881d44
  - identifier: "Home/recipetweaks"
    sha: 3a8ef19
  - identifier: "Home/pz-bzoukhotbar"
    sha: 361cd23
  - identifier: "Home/pz-recipetweaks"
    sha: 9b70525
  - identifier: "Home/recipetweaks-legacy"
    sha: bc06762
---

# Výzkum: stav PZ modů, toolchainu a vydávání (říjen 2026)

## Obsah

- [Otázky](#otázky)
- [Shrnutí](#shrnutí)
- [Zjištění](#zjištění)
  - [1. GitHub repa zaostávají za Forgejo, nic navíc nemají](#1-github-repa-zaostávají-za-forgejo-nic-navíc-nemají)
  - [2. TS toolchain je mrtvý a runtime závisí na loadstring](#2-ts-toolchain-je-mrtvý-a-runtime-závisí-na-loadstring)
  - [3. Build 42 je stable (42.21) a oba mody potřebují změny](#3-build-42-je-stable-42-21-a-oba-mody-potřebují-změny)
  - [4. Workshop stránka BZQuickSlots pořád popisuje Build 41](#4-workshop-stránka-bzquickslots-pořád-popisuje-build-41)
  - [5. Kontejner vidí host jen přes ~/claude-virt/home, pzpw-compiler B42 strukturu neumí](#5-kontejner-vidí-host-jen-přes-claude-virt-home-pzpw-compiler-b42-strukturu-neumí)
- [Zdroje](#zdroje)
- [Otevřené otázky](#otevřené-otázky)

## Otázky

1. V jakém stavu jsou GitHub repa (Bzouk/*) proti Forgejo (Home/*)?
2. Jaký je stav TS toolchainu (pzpw-compiler, PipeWrench, TSTL) a Lua alternativy pro B42?
3. Jaký je aktuální build PZ a co z jeho API změn zasahuje oba mody?
4. Co dnes stojí na čtyřech Workshop stránkách?
5. Jak se kontejner dostane k hostu, kde PZ čte mody, a jak se mod nahrává na Workshop?

## Shrnutí

Build 42 je od 2026-07-29 stable, aktuálně 42.21 (2026-09-28). pzhotbar (BZQuickSlots) byl naposledy nahrán 2025-03-07 (~42.4/42.5), tedy před velkými změnami 42.13 (ItemTag, CharacterTrait) a 42.15 (JSON překlady) — má nejméně dvě místa, která na 42.21 hodí Lua chybu, a staré překlady. recipetweaks je celý nad B41 `Recipe` API; v B42 jsou recepty `craftRecipe` a stávající API je potřeba přepsat, ne portovat.

TS toolchain je mrtvý: pzpw-compiler, PipeWrench i generátor typings archived, TS typings pro B42 neexistují. Starý kompilátor lokálně ještě běží, ale vyrábí plochou B41 strukturu (B42 ji nenačte) a přibaluje `PipeWrench.lua`, který 1906× volá `loadstring` — ten hra v 42.20.4 odebrala a v 42.21 vrátila. Pro Lua existuje aktivně udržovaný **PZ-Umbrella** (42.21), který pokrývá všech 15 API, jež PipeWrench pro pzhotbar chybí.

GitHub repa jsou čistě starší verze Forgejo rep (žádné commity navíc), chybí jim nové README, tag `v0.1.4-b41` a archivní větve; žádné není archived. Workshop popis BZQuickSlots je B41 text převzatý z `assets/workshop/description.txt`.

Kontejner sdílí s hostem jen `~/claude-virt/home` → `/home/bzouk`. Mod na hostu musí ležet v `~/Zomboid/Workshop/<Item>/Contents/mods/<Mod>/{common,42}/`; zda PZ následuje symlink, není ověřeno. Nahrává se in-game uploaderem nebo steamcmd (potřebuje přihlášení skutečným účtem).

## Zjištění

### 1. GitHub repa zaostávají za Forgejo, nic navíc nemají

Výchozí větev každého GitHub repa je předkem lokálního `main`. Žádné není archived, žádné nemá homepage ani topics.

| GitHub | Lokálně (Forgejo) | Lokálně napřed | Jen na GitHubu | Jen lokálně |
|---|---|---|---|---|
| pz-bzoukhotbar (`master`) | pz-bzoukhotbar | 2 | tagy 0.0.1, 0.0.2, 0.0.3, 0.0.6, 0.0.8 + 5 releases | větve `pre-git`, `snapshots` (bez společné historie s master) |
| pzhotbar (`main`) | pzhotbar | 6 (B42 port, README, LSP) | — | tag `v0.1.4-b41` (= tip GitHub main `afaf936`) |
| pz-recipetweaks | pz-recipetweaks | 1 | — | — |
| recipetweaks | recipetweaks | 6 | — | — |
| recipetweaks-old (`master`) | **recipetweaks-legacy** (společný kořen `9d5b72e`) | 2 | 5 dependabot větví + 5 otevřených dependabot PR | — |

README na GitHubu jsou všechna stará (PZPW/PipeWrench template hlavičky, „Same old description“); lokální jsou přepsaná a archivní mají banner „Archived“.

URL na github.com v živých repech: `pzhotbar/package.json:24,27,30`, `pzhotbar/pzpw-config.json:7`, `recipetweaks/pzpw-config.json:8,15`, `recipetweaks/assets/workshop/description.txt:42`; `recipetweaks/package.json` je dosud neupravený pzpw-template (name `pzpw-template`, author Konijima). Forgejo issues pzhotbar #7 a recipetweaks #6.

Zdroj: GitHub API `api.github.com/repos/Bzouk/<repo>` (2026-10-24), porovnání `git merge-base` v mirror klonech.

### 2. TS toolchain je mrtvý a runtime závisí na loadstring

**Archivováno:** `Konijima/pzpw-compiler` (push 2024-01-21), `Konijima/pzpw-template`, `asledgehammer-pz/PipeWrench`, `PipeWrench-Compiler` (2026-08-26), `Candle-Compiler` (2025-10). README PipeWrench uvádí jako důvod „hotfix patch of 42.20.4 and the knee-jerk removal of `loadstring`“.

**Nainstalováno v obou repech:** typescript 5.0.4 (npm latest 7.0.2), typescript-to-lua 1.14.0 (latest 1.37.1, vyžaduje TS 6), @asledgehammer/pipewrench 41.76.1 (B41 typings), pzpw-compiler 2.5.2-alpha (pinuje TSTL `~1.14.0`). CI `.github/workflows/Build.yml` jen typecheck na Node 18.

**Co ještě běží:**
- `tsc -p build.tsconfig.json --noEmit`: pzhotbar 15 chyb (vše `ISUI/ISBzHotSlot.ts` 213–604: `hasComponent`, `getFluidContainer`, `ComponentType`, `FluidCategory`, `getCurrentUsesFloat` — B42 API chybí v typings), recipetweaks 1 (`testrecapi.ts:15`, `import` uvnitř `if`, skutečná syntaktická chyba).
- `pzpw-compiler mods` lokálně proběhne za 3,5 s; holé TSTL taky (emituje i při typových chybách).

**Runtime:** každý build přibalí `lualib_bundle.lua` (2478 řádků, z 96 helperů se používá 4–5) a `PipeWrench.lua` (4006 řádků), který **1906×** volá `loadstring("return _G['X']")()` (ověřeno `grep -c` v `node_modules/@asledgehammer/pipewrench/PipeWrench.lua`). Mod tedy funguje jen, dokud hra `loadstring` nechá.

**Kvalita TSTL výstupu:** čitelná, blízko TS zdroji, komentáře zůstávají. UI třídy už dnes používají PZ idiom `ISPanel:derive` / `:new` + `setmetatable`. Úklid na ručně psané Lua je mechanický: zrušit `____pipewrench` nepřímost (globály), `__TS__ArrayForEach` → `for`, `Map` → tabulka, `Constants` → tabulka, přejmenovat `____exports`. Zároveň tím zmizí závislost na `loadstring`.

**Co TS v těchto repech dává:** pzhotbar 1698 řádků + 120 `.d.ts` — 0 tříd (kromě `Constants`), 0 enumů, 0 generik, 20× `any`, 38× `as`. Hlavní přínos je kontrola názvů Java/Lua API, a právě ta je pro B42 rozbitá. recipetweaks 489 + 72 `.d.ts` — ~8 interface popisujících veřejné API, 1 enum; v Lua by šly jako `---@class`.

**Lua nástroje pro B42:**

| Projekt | Stav | Poznámka |
|---|---|---|
| [PZ-Umbrella/Umbrella](https://github.com/PZ-Umbrella/Umbrella) | aktivní, release 42.21.0 (2026-09-28) | EmmyLua stuby: Java API (1291 souborů), vanilla Lua, events. Obsahuje všech 15 API, která chybí PipeWrench. README doporučuje EmmyLua analyzer, LuaLS označuje za slabší. |
| LuaLS addon `umbrella-unstable` | zastaralý (42.13, archived) | používá ho `pzhotbar/.vscode/settings.json` |
| TS typings pro B42 | neexistují | PipeWrench větev `42.0.0` archived, Candle-Compiler TS výstup netestován |

**Srovnání cest** (fakta pro rozhodnutí v `faze-navrh`):

| | Přejít na Lua | Zmrazit TS + lokální `.d.ts` | Převzít kompilátor + typings |
|---|---|---|---|
| Práce | ~2,2k řádků z TSTL výstupu vyčistit, anotace, balicí skript (`common/` + `42/`, `mod.info`). Dny. | ~15 deklarací v `B42.d.ts`, oprava `testrecapi.ts:15`, B42 layout post-build. Hodiny. | Fork ~920 ř. JS + generátor B42 typings + náhrada `PipeWrench.lua` + upgrade TSTL/TS 6. Týdny + údržba po patchích. |
| Riziko | jednorázové regrese, typová kontrola jen v editoru | trvalá závislost na `loadstring`, toolchain zamrzlý na TS 5.0/Node 18 | udržuje mrtvý ekosystém sám, TS 7 × TSTL nejisté |

Zdroje: `node_modules/pzpw-compiler/dist/lib/*` (viz §5), GitHub API (2026-10-24), npm registry.

### 3. Build 42 je stable (42.21) a oba mody potřebují změny

**Stav hry** (Steam news API, app 108600, ověřeno 2026-10-24):
- 2026-07-29 Build 42.20.0 Stable; B41 přešel na beta větev `legacy41`.
- Hotfixy 42.20.1–42.20.4; **42.20.4 (2026-08-26) odebral `loadstring`/`loadstream`**.
- **2026-09-28 Build 42.21 Stable** — `loadstring` vrácen (sekundární zdroje: jeu.video 2026-09-29, projectzomboid.wiki; oficiální patch notes jsem neměl). Proces dál: nejdřív Unstable, pak Stable.
- Multiplayer je součástí B42 stable od 42.20. Build 43 není ohlášen. 2026-10-21 „A Note on Java Mods and Modding“: oficiálně podporované jsou jen Lua mody.

**Struktura modu v B42** (PZwiki Mod_structure, Wayback 2026-07-11): `Contents/mods/<Mod>/common/` + `42/` (nebo `42.x`); hra načte `common` a pak nejbližší verzi. Od 42.15 stačí jedna z obou složek. Plochý B41 `media/` v kořeni modu B42 nenačte. `mod.info` patří do verzové složky; reálné mody na 42.21 používají `versionMin=42.21` a `require=\ModID` (zpětné lomítko).

**Překlady od 42.15:** `.json`, bez kódu jazyka v názvu (`Translate/EN/UI.json`), všechno UTF-8.

**Další změny API:** 42.13 — `InventoryItem.hasTag(ItemTag)` a `ScriptManager.getItemsTag(ItemTag)` už neberou string, `CharacterTraits` nemá `isX()` (náhrada `hasTrait(CharacterTrait.X)`). 42.21 — registr `KeybindId`. 42.18 — `CraftRecipe:getModTags()`, `setTags()`, `InputScript:getItems()`.

**Recepty v B42:** `recipe{}` nahrazeny `craftRecipe` skripty. JavaDocs 42.20: `ScriptManager.getAllCraftRecipes()`, `getCraftRecipe(String)`, `CraftRecipe.Load(name, body)`; `InputScript` má jen gettery. `getAllRecipes()` dál existuje, ale vrací starou třídu `Recipe`, ve které vanilla B42 recepty nejsou (odvozeno). Cesty k úpravě: override `craftRecipe` stejného jména v `module Base` ve skriptech modu, nebo `Load` z Lua (neověřeno ve hře).

**pzhotbar — co je zasaženo** (ověřené řádky v `src/pzhotbar42/client/pzhotbar/`):
- `ISUI/ISBzHotSlot.ts:560` `itemInInv.hasTag("Pills") || itemInInv.hasTag("Consumable")` — string místo `ItemTag`; `ItemTag.CONSUMABLE` existuje, PILLS ne.
- `ISUI/ISBzHotSlot.ts:676` `getCharacterTraits().isIlliterate()` — metoda v 42.20 neexistuje.
- `src/pzhotbar42/shared/Translate/*/UI_*.txt`, `IG_UI_*.txt` — starý formát, od 42.15 nahrazen JSON (CS soubory navíc Cp1250).
- V pořádku podle Umbrella 42.21: `ISInventoryPaneContextMenu.*` (`ISBzHotSlot.ts:260,471–677`), `instanceof` tříd, `PZAPI.ModOptions` (`BzHotBar.ts:395`), `addKeyBind(..., Keyboard.KEY_TAB)` (`BzHotBar.ts:398`, neověřeno, že string varianta zůstala).

**recipetweaks — celé B41 API** (`src/.../RecipeAPi.ts`): import `Recipe`, `Result`, `Source` (:8); `getRecipe` (:221) a `getAllRecipes` (:255) míří na starý seznam; `Result.setCount`, `Source.setCount`, `setUse`, `getItems().add` (:109–166) nemají v `InputScript` obdobu; `getItemsTag(string)` (:286); ladicí `OnKeyPressed` na `KEY_A` (:396–397); příkladový mod vyžaduje B41 mody `Hydrocraft,DLTS,sapphcooking`.

### 4. Workshop stránka BZQuickSlots pořád popisuje Build 41

| ID | Název | Tagy | Aktualizováno | Odběratelé (teď / celkem) |
|---|---|---|---|---|
| 3396010813 | BZQuickSlots | Build 42, Interface | 2025-03-07 | 8 842 / 29 984 |
| 3133189049 | BzoukPzHotBarNew | Build 41, Interface | 2024-07-03 | 33 299 / 78 368 |
| 2434425002 | Bzouk Hotbar Mod B41 | Build 41, Interface | 2023-02-16 | 416 391 / 789 494 |
| 3139510653 | RecipeTweaks | Build 41, Items, Framework | 2024-01-14 (nikdy neaktualizováno) | 114 / 472 |

- **3396010813** má text „Hot bar mod v2“, „PZ: build 41 - singleplayer“, „build 41 beta only“, vyžaduje Blindcoders, `Tags:B41,Interface` — totožný s 3133189049 až na patičku. Zdroj je `pzhotbar/assets/workshop/description.txt` (shoda bajt po bajtu bez patičky).
- **3133189049** odkazuje na starý mod, „Do not use the old and new mod at the same time“, seznam novinek + celý starý popis. Vyžaduje Blindcoders Modding Utility (503640135) a Mod Options B41 (2169435993).
- **2434425002** má „New version here“ s odkazem na 3133189049, návod a poznámku o pomlčce v mod ID pro MP. `pz-bzoukhotbar/workshop-history/2.03.2022/workshop.txt` se liší jen tímto odkazem, MP poznámkou a patičkou.
- **3139510653** má krátký popis API, Lua příklad, „no idea if it works in Multiplayer“, odkaz na GitHub. Shoda s `recipetweaks/assets/workshop/description.txt`.
- Každý popis končí patičkou „Workshop ID / Mod ID“, kterou přidává in-game uploader.

Surové BBCode popisy: [workshop/](workshop/) (`workshop-<id>.txt`, z `ISteamRemoteStorage/GetPublishedFileDetails`, 2026-10-24).

### 5. Kontejner vidí host jen přes ~/claude-virt/home, pzpw-compiler B42 strukturu neumí

**Kontejner** (`/proc/self/mountinfo`): jediný zapisovatelný host mount je `~/claude-virt/home` → `/home/bzouk` (rw), dál `~/llm-models` → `/models` (ro). Kontejner běží jako uid 1000. Není tu steamcmd ani globální pzpw-compiler (jen v `node_modules/.bin`). `/home/bzouk/Zomboid` neexistuje.

**Kde PZ na hostu čte mody** (PZwiki Mod_structure, Workshop.txt, Uploading_mods; Wayback 2026-02 až 2026-10):
- lokální mody: `~/Zomboid/mods/<Mod>/`
- vývoj a upload: `~/Zomboid/Workshop/<Item>/` s `workshop.txt`, `preview.png` a `Contents/mods/<Mod>/{common/,42/{mod.info,poster.png,media/}}`. Cokoli vedle `Contents` hra ignoruje.
- Stejné mod ID ve `mods/` i `Workshop/` (nebo odběr vlastního modu) koliduje.
- `workshop.txt`: `version=1`, `id=`, `title=`, řádek `description=` za každý řádek textu, `tags=a;b`, `visibility=` (0 public … 3 unlisted).
- `preview.png` 256×256, od 42.15 i 512×512.

**In-game uploader:** Main menu → Workshop → „Create and update items“ → seznam z `~/Zomboid/Workshop` → „Upload to Steam Workshop now!“. Přepíše celý popis na Steamu a přidá patičku Workshop ID / Mod ID. Soubory smazané lokálně zůstanou odběratelům.

**pzpw-compiler 2.5.2-alpha** (`node_modules/pzpw-compiler/dist/lib/`):
- cachedir výchozí `~/Zomboid` (`settings.js:8`), změna `pzpw-compiler cachedir set <path>` (`~/.pzpw/pzpw-compiler-settings.json`). V kontejneru = host `~/claude-virt/home/Zomboid`, ne host `~/Zomboid`.
- `mods`: `dist/<modId>/` s `mod.info`, png, `media/lua/...` v kořeni — **B41 layout bez `common/`/`42/`**, `mod.info` bez `versionMin` (`mods-compiler.js:57,116`, `compilers/utils.js:53–75`). README pzhotbar tvrdí B42 strukturu — publikovaný item uživatel přeskládal do `42/` ručně, aby mohl vydat hned po vyjití B42 (potvrzeno 2026-10-24). Postup není nikde zapsaný ani skriptovaný.
- Přepisuje require cesty regexem (`compilers/utils.js:81-97`) a přidává `OnPipeWrenchBoot` reimport do každého souboru (`constants.js:4-12`).
- `workshop`: nekompiluje, jen kopíruje z `dist` do `./workshop/Contents/mods/` a pak do `<cachedir>/Workshop/<title>` (`workshop-compiler.js:42–58`).
- **Chyba:** popis se dělí podle `"\r\n"` (`workshop-compiler.js:32`), repa mají `eol=lf`, takže `description=` dostane jen první řádek.
- **Chyba:** `clean workshop` maže `<cachedir>/workshop` malými písmeny (`compiler.js:169`), build píše do `Workshop`.

**Symlinky:** žádný zdroj nepotvrzuje ani nevyvrací, že PZ (Java) nebo Steam uploader na Linuxu následuje symlink v `~/Zomboid/Workshop`. Jediná zmínka (`Yoonutz/Project-Zomboid-mods` README:37–39, Windows junction) radí „Copy, never symlink“ kvůli MP version mismatch a mazání přes odkaz.

**steamcmd** (Valve, partner.steamgames.com/doc/features/workshop/implementation; PZwiki ho uvádí jako alternativu): VDF `"workshopitem" { "appid" "108600" "publishedfileid" "<id>" "contentfolder" "<abs>" "previewfile" … "changenote" … }`, `steamcmd +login <user> +workshop_build_item <vdf> +quit`. Potřebuje přihlášení skutečným účtem s hrou (anonym ne), Steam Guard kód při prvním přihlášení. Nepřidává patičku Workshop ID / Mod ID. `contentfolder` = `…/Workshop/<Item>/Contents` (odvozeno, netestováno).

## Zdroje

**Kód:** `pzhotbar/src/pzhotbar42/client/pzhotbar/ISUI/ISBzHotSlot.ts`, `BzHotBar.ts`, `pzhotbar/node_modules/pzpw-compiler/dist/lib/{settings,compiler,mods-compiler,workshop-compiler,constants,transpiler}.js`, `compilers/utils.js`; `recipetweaks/src/**/RecipeAPi.ts`, `testrecapi.ts`, `pzpw-config.json`.

**Web (ověřeno 2026-10-24):**
- Steam news: https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=108600
- Workshop detaily: `ISteamRemoteStorage/GetPublishedFileDetails/v1` pro 3396010813, 3133189049, 2434425002, 3139510653
- Migrační průvodce 42.15: https://theindiestone.com/forums/index.php?/topic/92433-modding-migration-guide-4215/ ; 42.13: https://theindiestone.com/forums/index.php?/topic/88499-modding-migration-guide-4213/ (PDF za loginem)
- PZwiki (Wayback): Mod_structure (2026-07-11), Mod.info (2026-07-29), Workshop.txt (2026-02-22), Uploading_mods a Translation (2026-10-16)
- Neoficiální JavaDocs 42.20: https://demiurgequantified.github.io/ProjectZomboidJavaDocs/
- Umbrella: https://github.com/PZ-Umbrella/Umbrella (13d01f9 „42.21.0“, 2026-09-28)
- PipeWrench: https://github.com/asledgehammer-pz/PipeWrench (archived 2026-08-26)
- TypeScriptToLua: https://github.com/TypeScriptToLua/TypeScriptToLua (1.37.1, 2026-07-09)
- Komunitní průvodce: https://github.com/gotmayonase/pz-modding-guide (`b42-changes.md`, ce2ec95)
- SteamCMD Workshop: https://partner.steamgames.com/doc/features/workshop/implementation
- 42.21 a loadstring (sekundární): https://jeu.video/en/article/project-zomboid-build-42-21-stable-zombie-fixes-lua-methods

## Otevřené otázky

- Zda PZ a Steam uploader na Linuxu následují symlink v `~/Zomboid/Workshop` — ověřit ve hře.
- Zda staré `.txt` překlady v 42.21 ještě vůbec načte; zda override `craftRecipe` plně nahradí vanilla recept a zda je `CraftRecipe:Load` volatelné z Lua — ověřit ve hře.
- Zda `loadstring` zůstane natrvalo — neznámé, oficiální patch notes 42.20.4/42.21 nečteny.
- Použitelnost PipeWrench větve `42.0.0` a TS výstupu Candle-Compileru — netestováno.
