/**
 * @noSelfInFile  @noResolution 
 *
 * NOTE: Use this at the top of your TypeScript files. This prevents functions & methods
 *       from prepending a 'self' reference, which is usually not necessary and complicates
 *   
*/
declare namespace bcUtils{
  export function readINI(filename:string): LuaTable;
  export function writeINI(filename:string,data:any): void;
  export function tableIsEmpty(table:LuaTable): boolean;
}