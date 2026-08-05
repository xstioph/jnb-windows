# Jump 'n Bump 1.51 for Windows

This repository prepares the standalone Jump 'n Bump 1.51 source for a portable
64-bit Windows build. It keeps the original game loop intact and adds a separate
level launcher that starts the existing executable with its existing `-dat`
option.

## First build target

The GitHub Actions workflow builds with MinGW-w64 and the original SDL 1.2 API.
At runtime, `sdl12-compat` provides that API on top of SDL2. The result is packed
as `jnb-windows-x64.zip` and uploaded as a workflow artifact.

The first workflow is intentionally manual (`workflow_dispatch`) as well as
available on pushes and pull requests. It does not publish a GitHub Release.

## Portable package layout

```text
JumpNBump-Launcher.cmd
JumpNBump-Launcher.ps1
jumpnbump.exe
data/jumpbump.dat
levels/Original.dat
licenses/
```

Place additional `.dat` levels in `levels`, then double-click
`JumpNBump-Launcher.cmd`.

## Scope of the first version

- Preserve the original gameplay and frame loop.
- Build the original SDL 1.2 code through `sdl12-compat`.
- Keep level discovery and process launching outside the game.
- Do not add two-button mouse support.
- Treat modern gamepad remapping as a later, separately testable change.

See `SOURCE.md` for provenance and `LEVEL-LAUNCHER-PLAN.md` for the launcher
boundary.

