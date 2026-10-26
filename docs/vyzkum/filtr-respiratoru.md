---
date: 2026-10-26
repos:
  - identifier: "pzhotbar"
    sha: 1fba04b
  - identifier: "pz-reference/42.21 (vanilla Lua + scripts, kopie z hosta)"
    sha: n/a
---

# Výzkum: filtr respirátoru do masky levým klikem (#26)

## Obsah

- [Otázky](#otázky)
- [Shrnutí](#shrnutí)
- [Zjištění](#zjištění)
  - [1. Filtr se do masky vkládá craft receptem, logika je v Javě](#1-filtr-se-do-masky-vkládá-craft-receptem-logika-je-v-javě)
  - [2. Filtry a masky se poznají podle tagů](#2-filtry-a-masky-se-poznají-podle-tagů)
  - [3. Recept se z Lua spustí přes `ISInventoryPaneContextMenu.OnNewCraft`](#3-recept-se-z-lua-spustí-přes-isinventorypanecontextmenu-onnewcraft)
  - [4. Levý klik v pzhotbaru filtr dnes ignoruje](#4-levý-klik-v-pzhotbaru-filtr-dnes-ignoruje)
- [Zdroje](#zdroje)
- [Otevřené otázky](#otevřené-otázky)

## Otázky

1. Jak vanilla B42 (42.21) vkládá filtr do respirátoru / plynové masky?
2. Které předměty jsou filtry a masky a jak je hra rozlišuje?
3. Jak se ten úkon spouští z Lua (kontextové menu, dvojklik)?
4. Co dnes dělá levý klik v pzhotbaru na slotu s filtrem?

## Shrnutí

Vanilla nemá na filtr vlastní timed action. Vložení filtru je **craft recept** (`craftRecipe`) se
skriptem v Javě: `PutFiltersOnRespirator` pro respirátor, `PutFilterOnGasMask` pro plynovou a NBC
masku. Masku recept drží (`mode:keep`), filtr spotřebuje (`mode:destroy`). Jestli maska už filtr
má, kontroluje Java `OnTest` (`RecipeCodeOnTest.noFilter`).

Z Lua se recept spouští jedinou funkcí: `ISInventoryPaneContextMenu.OnNewCraft(item, recipe, playerNum)`.
Ta postaví `HandcraftLogic`, sama si dohledá zbylé vstupy, přenese je do inventáře a zařadí
`ISHandcraftAction`. Stejně to dělá vanilla dvojklik (`DoubleClickRecipe`) i kontextové menu.

pzhotbar dnes na filtr při levém kliku nereaguje. Filtr je `DrainableComboItem`, propadne do
větve pro drainables a žádná její podmínka (pilulky, dezinfekce, ručník, nit) na něj nesedí.

## Zjištění

### 1. Filtr se do masky vkládá craft receptem, logika je v Javě

`scripts/generated/recipes/recipes_gasmasks.txt` (42.21):

| Recept | Řádek | Maska (`mode:keep`) | Filtr (`mode:destroy`) |
| --- | --- | --- | --- |
| `PutFiltersOnRespirator` | 80 | `tags[base:respirator]` | `tags[base:respiratorfilter]` |
| `PutFilterOnGasMask` | 18 | `tags[base:gasmask]` | `tags[base:gasmaskfilter]` |
| `PutRagInImprovisedGasMask` | 49 | `tags[base:improvisedgasmask]` | `[Base.RippedSheets]` |

Všechny tři mají `OnCreate = RecipeCodeOnCreate.addGasFilter`, `OnTest = RecipeCodeOnTest.noFilter`,
`time = 30`, `Tags = InHandCraft;CanBeDoneInDark`, `AllowBatchCraft = false`. Filtr nese příznak
`flags[ItemCount;NotEmpty]`, takže prázdný filtr se nepočítá.

`RecipeCodeOnCreate` ani `RecipeCodeOnTest` nejsou ve vanilla Lua (grep v `lua/` nic nenajde), jsou
v Javě. Java API, které na ně navazuje, je v Umbrella typings `Clothing`: `hasFilter()`,
`getFilterType()`, `setFilterType()`, `setNoFilter()`.

Vstup s maskou **nemá** příznak `IsNotWorn`. Recepty na kyslíkovou bombu ho mají výslovně
(`recipes_gasmasks.txt:186`, `:202`). Recept tedy nejspíš bere i nasazenou masku. V `Translate/EN/Recipes.json:1481,1483`
zůstaly texty `PutFiltersOnWornRespirator` / `PutFilterOnWornNuclearBiochemicalMask`, ale recepty
s tímhle jménem ve skriptech 42.21 nejsou.

**Testy:** žádné (vanilla).

### 2. Filtry a masky se poznají podle tagů

Filtry (`scripts/generated/items/drainable.txt`), všechny `ItemType = base:drainable`, `KeepOnDeplete = true`:

| Předmět | Tag |
| --- | --- |
| `Base.RespiratorFilters` (ř. 1697), `Base.RespiratorFiltersRecharged` | `base:respiratorfilter` |
| `Base.GasmaskFilter` (ř. 1610), `Base.GasmaskFilterCrafted` | `base:gasmaskfilter` |
| `Base.RagFilter` (ř. 1625) | `base:ragfilter`, žádný recept na vložení ho nepoužívá |

Masky (`scripts/generated/items/clothing.txt`):

| Předmět | Tag | BodyLocation |
| --- | --- | --- |
| `Hat_BuildersRespirator` (ř. 8652) | `base:respirator` | `base:mask` |
| `Hat_GasMask` (ř. 8724), `Hat_NBCmask` (ř. 8925) | `base:gasmask` | `base:maskeyes` / `base:fullhat` |
| `Hat_ImprovisedGasMask` (ř. 9200) | `base:improvisedgasmask` | `base:maskeyes` |
| `*_nofilter` varianty | `base:respiratornofilter`, `base:gasmasknofilter` | stejné |

Masky s filtrem mají `WithoutDrainable = …_nofilter`, varianty bez filtru `WithDrainable = …`. Tagy
`*nofilter` nepoužívá žádný recept ani Lua kód (grep `scripts` + `lua`). Respirátor bez filtru
po `RemoveRespiratorFilters` tedy zůstává pod tagem `base:respirator` a stav filtru drží Java
(`Clothing:hasFilter()`). Kdy hra přepne na `_nofilter` předmět, z Lua zjistit nejde.

### 3. Recept se z Lua spustí přes `ISInventoryPaneContextMenu.OnNewCraft`

`lua/client/ISUI/ISInventoryPaneContextMenu.lua:3428`:

```lua
ISInventoryPaneContextMenu.OnNewCraft = function(selectedItem, recipe, player, all, eatPercentage)
    -- HandcraftLogic.new(playerObj) + setContainers(getContainers(playerObj))
    -- logic:setRecipeFromContextClick(recipe, selectedItem)
    -- if logic:canPerformCurrentRecipe(): přenese vstupy do inventáře, ISEntityUI.HandcraftStart(...)
    -- a vrátí přenesené předměty zpět (ISCraftingUI.ReturnItemsToOriginalContainer)
end
```

Recept se získá přes `getScriptManager():getCraftRecipe("PutFiltersOnRespirator")`. Takhle to dělá
vanilla dvojklik (`ISInventoryPane.lua:1122–1131`) i otevírání plechovek při jídle (`ISInventoryPaneContextMenu.lua:2262`, `:2361`, `:3631`).
Kontextové menu bere seznam receptů z `CraftRecipeManager.getUniqueRecipeItems(item, playerObj, containers)`
(`:390`) a pro každý dělá stejné `OnNewCraft` (`:3393`).

Volání `canPerformCurrentRecipe()` hlídá `OnTest`, takže maska, která filtr už má, recept neprojde.
Kterou masku `setRecipeFromContextClick` vybere, když vybraný předmět je filtr a hráč má masek víc
(nasazenou vs. v batohu), rozhoduje Java. Viz Otevřené otázky.

**Testy:** žádné (vanilla).

### 4. Levý klik v pzhotbaru filtr dnes ignoruje

`src/media/lua/client/pzhotbar/ISUI/ISBzHotSlot.lua`:

- `ISBzHotSlot:onMouseUp` (ř. 142) bez tažení volá `activeteSlot` (ř. 395).
- `activeteSlot` najde nejlepší kus podle `fullType` přes `getBestEvalArgRecurse` (ř. 408) a větví podle druhu.
- Filtr je `DrainableComboItem`, chytí ho větev na ř. 431. Ta zná jen `Pills*`, dezinfekci,
  `DishCloth`/`BathTowel` a `Thread`, takže pro filtr neudělá nic.
- Na masku samotnou (`getCategory() == "Clothing"`, ř. 526) levý klik nasadí nebo sundá.

Vzor pro vložení vstupu do nasazeného předmětu v pzhotbaru zatím není. Nejbližší jsou volání vanilla
helperů typu `ISInventoryPaneContextMenu.onDrinkFluid` / `onEatItems` a vracení předmětu do
původní tašky přes `returnItem` (ř. 89).

**Testy:** `tests/config_test.lua` a `tests/translations_test.lua`. Na `activeteSlot` žádné, ověřuje se ve hře.

## Zdroje

- Vanilla 42.21 (`~/pz-reference/42.21/`):
  - `scripts/generated/recipes/recipes_gasmasks.txt:18,49,80,186,202`
  - `scripts/generated/items/drainable.txt:1610,1625,1697`, `scripts/generated/items/clothing.txt:8652,8724,8925,9200`
  - `lua/client/ISUI/ISInventoryPaneContextMenu.lua:390,2262,3365,3393,3428`
  - `lua/client/ISUI/ISInventoryPane.lua:1122`
  - `lua/shared/Entity/TimedActions/ISHandcraftAction.lua`
  - `lua/shared/Translate/EN/Recipes.json:1479–1483`
- Umbrella 42.21.0: `java/zombie/inventory/types/Clothing.lua` (`hasFilter`, `getFilterType`, `setNoFilter`)
- pzhotbar `1fba04b`: `src/media/lua/client/pzhotbar/ISUI/ISBzHotSlot.lua:89,142,395,408,431,526`
- Návrh: Workshop 3396010813, komentář Furizu 2025-01-07 (podle #26)

## Otevřené otázky

Všechny tři leží v Javě (`RecipeCodeOnTest`, `HandcraftLogic`), kterou kontejner nemá. Ověří se ve hře.

1. Projde `PutFiltersOnRespirator` s **nasazeným** respirátorem? Chybějící `IsNotWorn` naznačuje, že ano.
2. Když má hráč dvě masky, kterou vybere `setRecipeFromContextClick(recipe, filtr)`? Nasazenou, nebo první v inventáři?
3. Bere recept i předmět `Hat_BuildersRespirator_nofilter` (tag `base:respiratornofilter`, ne `base:respirator`)? Podle tagů ne.
