#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
source_root="$repo_root/src/jumpnbump-1.51"
dist_root="$repo_root/dist/jnb-windows-x64"

make -C "$source_root" clean
make -C "$source_root" -j2 all

test -f "$source_root/jumpnbump.exe"
test -f "$source_root/data/jumpbump.dat"

rm -rf "$repo_root/dist"
mkdir -p "$dist_root/data" "$dist_root/levels" "$dist_root/licenses/game" "$dist_root/licenses/third-party"

cp "$source_root/jumpnbump.exe" "$dist_root/"
cp "$source_root/data/jumpbump.dat" "$dist_root/data/"
cp "$source_root/data/jumpbump.dat" "$dist_root/levels/Original.dat"
cp "$repo_root/launcher/JumpNBump-Launcher.cmd" "$dist_root/"
cp "$repo_root/launcher/JumpNBump-Launcher.ps1" "$dist_root/"
cp "$source_root/COPYING" "$dist_root/licenses/game/COPYING"
cp "$source_root/AUTHORS" "$dist_root/licenses/game/AUTHORS"
cp "$source_root/source.txt" "$dist_root/licenses/game/source.txt"
cp "$repo_root/SOURCE.md" "$dist_root/licenses/game/SOURCE.md"

for pass in 1 2 3 4 5; do
    while IFS= read -r binary; do
        while IFS= read -r dependency; do
            cp -n "$dependency" "$dist_root/" || true
        done < <(ldd "$binary" | awk '$3 ~ /^\/mingw64\/bin\// { print $3 }')
    done < <(find "$dist_root" -maxdepth 1 -type f \( -iname '*.exe' -o -iname '*.dll' \))
done

license_names=(
    SDL2 sdl12-compat SDL_mixer SDL_net bzip2 zlib libiconv
    libmikmod libogg libvorbis flac libmad mpg123 opus
)
for license_name in "${license_names[@]}"; do
    license_path="/mingw64/share/licenses/$license_name"
    if [[ -d "$license_path" ]]; then
        cp -R "$license_path" "$dist_root/licenses/third-party/"
    fi
done

cat > "$dist_root/README.txt" <<'EOF'
JUMP 'N BUMP 1.51 FOR WINDOWS - FIRST TEST BUILD

Double-click JumpNBump-Launcher.cmd, choose a level, and press Play.
Put additional .dat files in the levels folder and press Refresh.

This package uses the original standalone 1.51 game loop. The separate launcher
only selects a .dat file and starts jumpnbump.exe with the existing -dat option.

Source provenance and licenses are in the licenses folder.
EOF

test -f "$dist_root/SDL.dll"
test -f "$dist_root/libSDL_mixer-1-2-0.dll"
test -f "$dist_root/libSDL_net-1-2-0.dll"

echo "Portable package prepared at: $dist_root"

