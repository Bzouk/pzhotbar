/**
 *
 * NOTE: Use this at the top of your TypeScript files. This prevents functions & methods
 *       from prepending a 'self' reference, which is usually not necessary and complicates
 *       rendered Lua code.
 */
declare namespace ISCollapsableWindow {
    /**
     * @noSelf
     */
    export function derive(this:any,type: string): any;
  }

export const ISBzHotBarWindow = ISCollapsableWindow.derive("ISBzHotBarWindow");
