/**
 *  @noResolution 
 *
 * NOTE: Use this at the top of your TypeScript files. This prevents functions & methods
 *       from prepending a 'self' reference, which is usually not necessary and complicates
 *   
*/

declare namespace ModOptions {
  export function getInstance(data: LuaTable): void;
  export function AddKeyBinding(category: string, keyData: any): void;
  export function loadFile(): void;
}