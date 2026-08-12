/**
 * @noSelfInFile  @noResolution 
 *
 * NOTE: Use this at the top of your TypeScript files. This prevents functions & methods
 *       from prepending a 'self' reference, which is usually not necessary and complicates
 *   
*/

//declare namespace bcUtils{
   /** @noSelf */
  export function readINI(filename:string): LuaTable;
   /** @noSelf */
  export function writeINI(filename:string,data:any): void;
   /** @noSelf */
  export function tableIsEmpty(table:LuaTable): boolean;
//}
 