---
date: 2026-10-26
repos:
  - identifier: "pzhotbar"
    sha: b64ee88
  - identifier: "pz-reference/42.21 (vanilla Lua, kopie z hosta)"
    sha: n/a
---

# Výzkum: proč slot nepřepočítá počet po craft receptu (#43)

## Otázky

1. Kdy slot přepočítává počet kusů?
2. Co vanilla dělá s inventářem a UI, když dokončí craft recept (`ISHandcraftAction`)?
3. Proč se po receptu počet nepřepočítá, ale po pohybu hráče nebo změně venkovního inventáře ano?

## Shrnutí

Slot přepočítá počet (`updateItem`) jen ve dvou případech. Prvním je nastavený příznak `isDrawDirty()`
**hlavního** inventáře, který slot kontroluje při vykreslení. Druhým je událost
`OnRefreshInventoryWindowContainers` se stavem `"end"` pro inventář postavy.

`ISHandcraftAction:perform` volá `ISInventoryPage.dirtyUI()` **před** `performRecipe()`. `dirtyUI`
synchronně obnoví seznam tašek a vyvolá `OnRefreshInventoryWindowContainers "end"`, takže slot se
přepočítá ve chvíli, kdy filtr ještě existuje. Recept ho zničí až potom, v Javě
(`processDestroyAndUsedItems`). Další obnova přijde až s dalším `refreshBackpacks`, tedy po pohybu
nebo změně venkovního kontejneru. Proto to uživatel vidí právě takhle.

Příznak `isDrawDirty()` tuhle situaci nezachrání. Buď ho Java při zničení předmětu nenastaví, nebo ho
vanilla `ISInventoryPane` smaže dřív, než se slot vykreslí. Které z toho platí, z Lua zjistit nejde.

## Zjištění

### 1. Slot se přepočítá jen na drawDirty hlavního inventáře nebo na obnovu tašek

- `ISBzHotSlot:prerender` (`ISBzHotSlot.lua:286`): když `playerInventory:isDrawDirty()` (ř. 308),
  nastaví `updatePending`. Nejvýš jednou za `UPDATE_MS` = 500 ms pak volá `updateItem`.
  Kontroluje se jen hlavní inventář postavy, ne tašky v něm.
- `updateItem` (ř. 222) počítá `getItemCountRecurse(fullType)` (ř. 235), tedy včetně tašek.
- `BzHotBar.lua:384`: `OnRefreshInventoryWindowContainers` s `onCharacter` a stavem `"end"` volá
  `updateAllSlots` (ř. 227) pro všechna viditelná okna.
- Jiný spouštěč není. Časovač ani `OnContainerUpdate` mod nepoužívá.

**Testy:** žádné, chování se ověřuje ve hře.

### 2. Vanilla oznámí změnu UI dřív, než recept zničí vstupy

`lua/shared/Entity/TimedActions/ISHandcraftAction.lua`:

```lua
function ISHandcraftAction:perform()
    ...
    ISInventoryPage.dirtyUI();          -- ř. 189
    if not isClient() then
        self:performRecipe();           -- ř. 192: performCurrentRecipe(), processDestroyAndUsedItems()
    end
    ISBaseTimedAction.perform(self);
```

`ISInventoryPage.dirtyUI` (`ISInventoryPage.lua:1330`) volá `refreshBackpacks()` pro inventář
i okolí každého hráče. `refreshBackpacks` (ř. 1537) vyvolá `OnRefreshInventoryWindowContainers`
synchronně: `"begin"` na ř. 1560 a `"end"` na ř. 1906. Událost tedy proběhne celá ještě před
`performRecipe`.

Zničení vstupů (`mode:destroy`) dělá Java `RecipeData:processDestroyAndUsedItems`. Lua po něm
`setDrawDirty` nevolá.

Pro srovnání `ISEatFoodAction:perform` (`ISEatFoodAction.lua:166`) volá výslovně
`self.container:setDrawDirty(true)`.

**Testy:** žádné (vanilla).

### 3. drawDirty maže vanilla inventář, když se kreslí

`ISInventoryPane:renderdetails` (`ISInventoryPane.lua:2211`) při `isDrawDirty()` zavolá
`refreshContainer`. Ten na konci příznak smaže (`setDrawDirty(false)`, ř. 2190).

Když se otevřený inventář vykreslí před lištou, slot příznak nikdy neuvidí. Když je inventář sbalený,
příznak zůstane nastavený a slot ho chytí. Tuhle past popisuje wiki „Modding pro Build 42“ › Pasti.

**Testy:** žádné.

## Zdroje

- pzhotbar `b64ee88`:
  - `src/media/lua/client/pzhotbar/ISUI/ISBzHotSlot.lua:222,235,286,308`
  - `src/media/lua/client/pzhotbar/BzHotBar.lua:227,384`
- Vanilla 42.21 (`~/pz-reference/42.21/lua/`):
  - `shared/Entity/TimedActions/ISHandcraftAction.lua:173–262`
  - `client/ISUI/ISInventoryPage.lua:1330,1537,1560,1906`
  - `client/ISUI/ISInventoryPane.lua:2190,2211`
  - `shared/TimedActions/ISEatFoodAction.lua:166`

## Otevřené otázky

1. Nastaví Java `processDestroyAndUsedItems` / `ItemContainer.Remove` příznak drawDirty kontejneru? Kód Javy tu není, ověřit by šlo jen ve hře.
2. V multiplayeru běží `performRecipe` na serveru (`complete()`, ř. 212). Klient se o změně dozví přes serverový příkaz `ui.DirtyUI` (`ServerCommands.lua:145–146`), a to nejspíš už po zničení předmětu. Netestováno.
3. Týká se to i jiných akcí, které vstupy ničí v Javě mimo `ISHandcraftAction`? Nezkoumáno.
