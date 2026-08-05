# First level-launcher plan

## Boundary

The launcher is a separate process. It does not link to game objects and does
not run inside the game's frame, input, rendering, sound, or state loops.

## Version 1 behavior

1. Resolve its own portable package directory.
2. Enumerate `.dat` files below `levels`.
3. Display their relative names in a simple Windows list.
4. Start `jumpnbump.exe -dat "<absolute level path>"` with the package directory
   as the working directory.
5. Hide while the game is running and return when the game process exits.
6. Offer the already-supported `-fullscreen` switch as a checkbox.

## Later work

- Friendly level titles and thumbnails.
- Remember the last selected level and fullscreen preference.
- Keyboard and controller navigation in a compiled launcher.
- Gamepad remapping, handled separately from level selection.

The PowerShell/WinForms implementation is intentionally replaceable. Its process
contract is the durable part: executable plus `-dat`, optional `-fullscreen`,
and a controlled working directory.

