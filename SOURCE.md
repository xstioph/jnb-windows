# Source provenance

The game source is Fabian Greffrath's standalone Jump 'n Bump 1.51 tree.

- Repository: https://github.com/fabiangreffrath/jumpnbump
- Tag archive: https://github.com/fabiangreffrath/jumpnbump/archive/refs/tags/1.51.zip
- Local input filename: `jumpnbump-1.51.zip`
- SHA-256: `c8b686e7d261124d595fa145b0f5149553ca2bf18c633ef9319af9d942e0f861`
- License: GPL-2.0-or-later; see `src/jumpnbump-1.51/COPYING`

## Deliberate source change

The upstream game link command put libraries before `sdl.a`. Modern linkers may
discard those libraries before seeing the symbols that need them. The two items
were reordered in `src/jumpnbump-1.51/Makefile`:

```make
$(CC) -o $(TARGET) $(OBJS) $(SDL_TARGET) $(LIBS)
```

No game-loop, gameplay, input, graphics, sound, or level-loading source has been
changed.
