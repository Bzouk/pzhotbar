/**
 *  @noResolution
 *
 * NOTE: Use this at the top of your TypeScript files. This prevents functions & methods
 *       from prepending a 'self' reference, which is usually not necessary and complicates
 *   
*/

declare class GameModOptionsKeyBind extends LuaTable {
    type: string  
    id:string
    name:string
    tooltip:string
    key: number
    defaultkey:number 
    isEnabled:boolean
    getValue: () => number
}

declare class Slider extends LuaTable {
  type: string  
  id:string
  name:string
  tooltip:string
  isEnabled:boolean
  min: number
  max: number
  step:number
  getValue: () => number
  setValue: (value: number) => void
}

declare class TickBox extends LuaTable {
  type: string  
  id:string
  name:string
  tooltip:string
  isEnabled:boolean
  value: boolean
  getValue: () => boolean
  setValue: (value: boolean) => void
}

declare class ComboBox extends LuaTable {
  type: string  
  id:string
  name:string
  tooltip:string
  isEnabled:boolean
  value: number
  getValue: () => number
  addItem: (name:string,value: boolean) => void
}


declare namespace PZAPI.ModOptions {
  export function create(iniquieid: string, arg1: string): any;
  export function getOptions(iniquieid: string): any;
  export function addKeyBind(iniquieid: string, name: string,  keyData: any, tooltip:string): GameModOptionsKeyBind;
  export function addDescription(desc: string): any;
  export function addSeparator(): void;
  export function addTitle(desc: string): any;
  export function addSlider(iniquieid: string, name: string, min: number, max: number, step:number, value:number):Slider
  export function addTickBox(iniquieid: string, name: string, value: boolean, tooltip:string):TickBox
  export function addComboBox(iniquieid: string, name: string, tooltip:string):ComboBox
}
