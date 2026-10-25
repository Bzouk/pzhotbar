# Popisky starých Workshop položek

Nové popisy tří položek, které už nedostanou build (#10). Uživatel je vloží na webu Steamu: stránka položky → Edit title & description → nahradit celý text blokem níže. Nahoře je nový blok s odkazem na BZQuickSlots / na plán pro B42, pod ním původní text z `docs/vyzkum/workshop/` beze změny. Patička „Workshop ID / Mod ID“ zůstává: editace na webu ji nepřidá a Mod ID potřebují správci serverů.

## Obsah

- [2434425002 — Bzouk Hotbar Mod B41](#2434425002-bzouk-hotbar-mod-b41)
- [3133189049 — BzoukPzHotBarNew](#3133189049-bzoukpzhotbarnew)
- [3139510653 — RecipeTweaks](#3139510653-recipetweaks)

## 2434425002 — Bzouk Hotbar Mod B41

```bbcode
[h1]For Build 42 use BZQuickSlots[/h1]
[b]This is the Build 41 version and is no longer updated.[/b] For Build 42 subscribe to [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3396010813]BZQuickSlots[/url] — no dependencies, and it imports the slots you set up here.
[b]Do not run this and BZQuickSlots at the same time.[/b]
Source of this version: [url=https://github.com/Bzouk/pz-bzoukhotbar]github.com/Bzouk/pz-bzoukhotbar (archived)[/url]

[h1] Hot bar mod [/h1]

Hi everybody,

this mod adds quick access bar for items from player inventory. The main reason I made this mod is because I'm lazy to go through the inventory and look for one item that I just need. Mod idea is based another mod [url=https://steamcommunity.com/sharedfiles/filedetails/?id=503645367] Hotbar for 5-20 often-used [/url] and also other games (Wow EFT etc.). Mod is also using library "Blindcoders Modding Utility".  This is my first mod for project zomboid so please test mod first.

[b] PZ: build 41 - tested with local hosted MP and singleplayer[/b]

The basic version of mod have one bar with 1 row and 8 columns. You can drag bar around. Bar is using same windows like inventory page (X for hide and pin for collapsable window).
Also you can use [url=https://steamcommunity.com/sharedfiles/filedetails/?id=2169435993]Mod Options[/url] to add more quick access bars. With modoptions mod you can set number of bars from 1 to 5. How many rows and columns for each bar will have. Also default key for toggle bars can be changed with modoptions ( default: tab )


[h2] Usage[/h2]
Pres "tab" for show/hide bars. Drag and drop item into slot. You dont need to have item in inventory to add it to slot. Slot counts non broken items in inventory ( number in slot example: (24) items in inventory  and in all containers that you have on you ( even in containers in containers like bandage in medkit in backpack))

Broken items are iqnored, you have to go into inventory to work with them.

[u]Right click[/u]: Same like in inventory window.

[u]Left click[/u]  have smart functions based on item in slot. Functions are using code already in project zomboid. Many function return used item into original container.


Example:
[code]
1) Click slot with Disinfectant ( item is inside medkit in backpack)
2) Disinfectant is moved to main inventory if needed
3) Disinfectant is used on damaged parts
4) Disinfectant is moved inside medkit in backpack if still exist.
[/code]
Note: If you cancel action, item will remain in main invetory (start running etc.).

- Food
  This works like double click in inventory (Cola, Chips, Cigarettes)
  If food is non posion eat half or use whole if cigarettes ( need lighter :-) ) etc.
  After use item returns to original container.

- Water
  If item contain water, player is thirsty and water is not tainted then drink.
  After use item returns to original container.

- Pills (BetaBlock, AntiDeb, SleepingTablets and Vitamins)
  Take pill. Same like right click but item is put in original container after use.

- Disinfectant and AlcoholWipes
  Apply alcohol on every damaged body part without alcohol.
  After use item returns to original container.

- DishCloth BathTowel
  Like right click option - dry yourself with a towel

- Thread
  If you have needle in inventory it will stitch all deep wounded body parts.
  After use item returns to original container. (needle and thread)

- Hand weapon
  If two handed then equip two handed else one hand. New feature: swap weapon and item in hand to weapon container
  Idea: spear -> broke -> click on slot with spears -> re equip new -> broke -> click on slot with spears -> re equip new

- Bandage (should work on any item that can bandage)
   Clean burns if bandage is strong or apply bandage on damaged part

- Clothing
  Equip right click - change to right etc.).

- Literature
  Start reading.

- Suture Needle Holder or Tweezers
  Remove all glass and bullets from damaged parts.
  After use item returns to original container.

- Suture needle
  Stitch one deep wounded body part.
  After use item returns to original container.

- Comfrey Cataplasm
  Apply to fractured body part without any comfrey.

- Wild Garlic Cataplasm
  Apply to one infected wound without any comfrey.

- Plantain Cataplasm
  Apply to one scratched, deep wounded or cut body part without any comfrey.

- Splint
  Apply to fractured body part without any splint.

- Other items
   Do nothing -> use right click

- Radio
  Equip/unequip radio

Tips and ideas for items :
- ammo -> counter how many bullets|shells
- ammo box - right click -> open box
- watches - Equip -> add to slot -> right click to set alarm etc.
- items for quick crafting
- do not forget items
- spears -> broke -> left click -> re equip -> broke -> left click -> re equip  (need to throw away broken ones)
- any item with info after right click (compass, radios gps...)
...


[h2] Summary [/h2]

[b] PZ: build 41 beta only [/b]
Required mods:
[url=https://steamcommunity.com/workshop/filedetails/?id=503640135] blindcoders Modding Utility (saving data to ini) [/url]

Optional mods:
[url=https://steamcommunity.com/sharedfiles/filedetails/?id=2169435993]Mod Options[/url]

Tab key for show/hide bar

[h2] Languages[/h2]
- english
- czech
- french - @Bobitec + google
- spanish - @WhiteLotus + google

[h2] Known issues[/h2]
- sometimes items are drop to ground when dragging
- some items in inventory have same name (group under same name), but they are different items
- right click crafting need items to be in main inventory or backpack (game mechanic)

For multiplayer:
"@Chubby Pillbug 
For people saying that this doesn't work on dedicated server: If you are using a web tool to get a list of mod names and workshop item tags-- copy and paste the actual name of this mod manually, the web tools are not copying the full name of the mod because IT HAS A HYPHEN IN IT. None of the web tools correctly grab the names of mods with hyphens in them"

Tags:B41,Interface

Workshop ID: 2434425002
Mod ID: pz-bzoukhotbar
```

## 3133189049 — BzoukPzHotBarNew

```bbcode
[h1]For Build 42 use BZQuickSlots[/h1]
[b]This is the Build 41 version and is no longer updated.[/b] For Build 42 subscribe to [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3396010813]BZQuickSlots[/url] — no dependencies, and it imports the slots you set up here.
[b]Do not run this and BZQuickSlots at the same time.[/b]
Source of this version: [url=https://github.com/Bzouk/pzhotbar/tree/v0.1.4-b41]github.com/Bzouk/pzhotbar, tag v0.1.4-b41[/url]

[h1] Hot bar mod v2 [/h1]
Hi everybody,

This is new version of my [url=https://steamcommunity.com/sharedfiles/filedetails/?id=2434425002] old mod [/url] The functionality is essentially the same.
[h3]Do not use the old and new mod at the same time. !!![/h3]

New stuff:
- Code is in Typescript and then it's transcribed into Lua. Thank to [url=https://github.com/asledgehammer/PipeWrench-Template]PipeWrench[/url]
- Same info panel about the item as in the inventory when hover over slot.
- Hide delete button option
- The mod imports settings from the old mod. (Old file name:bzhotbar.ini, new file name: pzhotbar.ini)
- no HYPHEN in mod ID

[h2] Same old description[/h2]

This mod adds quick access bar for items from player inventory. The main reason I made this mod is because I'm lazy to go through the inventory and look for one item that I just need. Mod idea is based another mod [url=https://steamcommunity.com/sharedfiles/filedetails/?id=503645367] Hotbar for 5-20 often-used [/url] and also other games (Wow EFT etc.). Mod is also using library "Blindcoders Modding Utility".

[b] PZ: build 41 - singleplayer[/b]

The basic version of mod have one bar with 1 row and 8 columns. You can drag bar around. Bar is using same windows like inventory page (X for hide and pin for collapsable window).
Also you can use [url=https://steamcommunity.com/sharedfiles/filedetails/?id=2169435993]Mod Options[/url] to add more quick access bars. With modoptions mod you can set number of bars from 1 to 5. How many rows and columns for each bar will have. Also default key for toggle bars can be changed with modoptions ( default: tab )


[h2] Usage[/h2]
Pres "tab" for show/hide bars. Drag and drop item into slot. You dont need to have item in inventory to add it to slot. Slot counts non broken items in inventory ( number in slot example: (24) items in inventory  and in all containers that you have on you ( even in containers in containers like bandage in medkit in backpack))

Broken items are iqnored, you have to go into inventory to work with them.

[u]Right click[/u]: Same like in inventory window.

[u]Left click[/u]  have smart functions based on item in slot. Functions are using code already in project zomboid. Many function return used item into original container.


Example:
[code]
1) Click slot with Disinfectant ( item is inside medkit in backpack)
2) Disinfectant is moved to main inventory if needed
3) Disinfectant is used on damaged parts
4) Disinfectant is moved inside medkit in backpack if still exist.
[/code]
Note: If you cancel action, item will remain in main invetory (start running etc.).

- Food
  This works like double click in inventory (Cola, Chips, Cigarettes)
  If food is non posion eat half or use whole if cigarettes ( need lighter :-) ) etc.
  After use item returns to original container.

- Water
  If item contain water, player is thirsty and water is not tainted then drink.
  After use item returns to original container.

- Pills (BetaBlock, AntiDeb, SleepingTablets and Vitamins)
  Take pill. Same like right click but item is put in original container after use.

- Disinfectant and AlcoholWipes
  Apply alcohol on every damaged body part without alcohol.
  After use item returns to original container.

- DishCloth BathTowel
  Like right click option - dry yourself with a towel

- Thread
  If you have needle in inventory it will stitch all deep wounded body parts.
  After use item returns to original container. (needle and thread)

- Hand weapon
  If two handed then equip two handed else one hand. New feature: swap weapon and item in hand to weapon container
  Idea: spear -> broke -> click on slot with spears -> re equip new -> broke -> click on slot with spears -> re equip new

- Bandage (should work on any item that can bandage)
   Clean burns if bandage is strong or apply bandage on damaged part

- Clothing
  Equip right click - change to right etc.).

- Literature
  Start reading.

- Suture Needle Holder or Tweezers
  Remove all glass and bullets from damaged parts.
  After use item returns to original container.

- Suture needle
  Stitch one deep wounded body part.
  After use item returns to original container.

- Comfrey Cataplasm
  Apply to fractured body part without any comfrey.

- Wild Garlic Cataplasm
  Apply to one infected wound without any comfrey.

- Plantain Cataplasm
  Apply to one scratched, deep wounded or cut body part without any comfrey.

- Splint
  Apply to fractured body part without any splint.

- Other items
   Do nothing -> use right click

- Radio
  Equip/unequip radio

Tips and ideas for items :
- ammo -> counter how many bullets|shells
- ammo box - right click -> open box
- watches - Equip -> add to slot -> right click to set alarm etc.
- items for quick crafting
- do not forget items
- spears -> broke -> left click -> re equip -> broke -> left click -> re equip  (need to throw away broken ones)
- any item with info after right click (compass, radios gps...)
...


[h2] Summary [/h2]

[b] PZ: build 41 beta only [/b]
Required mods:
[url=https://steamcommunity.com/workshop/filedetails/?id=503640135] blindcoders Modding Utility (saving data to ini) [/url]

Optional mods:
[url=https://steamcommunity.com/sharedfiles/filedetails/?id=2169435993]Mod Options[/url]

Tab key for show/hide bar

[h2] Languages[/h2]
- english
- czech
- french - @Bobitec + google
- spanish - @WhiteLotus + google
- chinese
- russian

[h2] Known issues - game features[/h2]
- some items in inventory have same name (group under same name), but they are different items
- right click crafting need items to be in main inventory or backpack (game mechanic)

Tags:B41,Interface

Workshop ID: 3133189049
Mod ID: pzhotbar
```

## 3139510653 — RecipeTweaks

```bbcode
[h1]Build 41 only[/h1]
[b]This version works with Build 41 only.[/b] Build 42 changed the recipe system (craftRecipe), so a Build 42 version needs a rewrite — it is planned, but separately from this item.

[h1] Recipe tweaks [/h1]
Hi everybody,

This mod add api for adding alternatives to source item in recipes. Api is primarily for mod creators.
The main reason I created this api is because I found an item from one mod, but I couldn't use it in a recipe from another mod.
It is similar to https://steamcommunity.com/sharedfiles/filedetails/?id=566115016&searchtext=item+tweaker but for recipes.
Mod was written in Typescript and compiled into Lua using PipeWrench and TypescriptToLua projects.

[h2] Api for other modders !!![/h2]

[h2] How to Use RecipeTweaks:[/h2]
- make sure that recipeapi is near start of mod order.
- code
[code]
if getActivatedMods():contains("recipetweaks") then
    -- Import RecipeTweaks API
    local ____RecipeAPi = require("recipetweaks/api/RecipeAPi")

    -- Use the API functions to add tweaks to recipes
    -- (Example tweaks are provided in the code in example mod)
    local AddTweakAllRecipe = ____RecipeAPi.AddTweakAllRecipe
    local CreateRecipeSourceChanges = ____RecipeAPi.CreateRecipeSourceChanges

    -- Add your custom changes here
    -- Example: Add alternative item to all recipes with Base.Needle
    AddTweakAllRecipe(CreateRecipeSourceChanges("Base.Needle", { "Hydrocraft.HCBoneneedle" }))

    -- Example: Add Hydrocraft.HCTincan as an alternative to Base.TinCanEmpty
    AddTweakAllRecipe(CreateRecipeSourceChanges("Base.TinCanEmpty", { "Hydrocraft.HCTincan" }))

    -- Example: Reverse the alternative, adding Base.TinCanEmpty as an alternative to Hydrocraft.HCTincan
    AddTweakAllRecipe(CreateRecipeSourceChanges("Hydrocraft.HCTincan", { "Base.TinCanEmpty" }))
end
[/code]

More you can find if example mod and in repo.

[h2] Multiplayer [/h2]
I have no idea if it works in Multiplayer. In singleplayer is working fine.

[h2] Repo [/h2]
[url=https://github.com/Bzouk/recipetweaks] GitHub recipetweaks [/url]



Workshop ID: 3139510653
Mod ID: recipeteaksexample
Mod ID: recipetweaks
```
