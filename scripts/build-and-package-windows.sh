#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
source_root="$repo_root/src/jumpnbump-1.51"
dist_root="$repo_root/dist/jnb-windows-x64"

make -C "$source_root" clean
make -C "$source_root" -j2 all

fail() {
    echo "ERROR: $*" >&2
    exit 1
}

if [[ -f "$source_root/jumpnbump.exe" ]]; then
    game_executable="$source_root/jumpnbump.exe"
elif [[ -f "$source_root/jumpnbump" ]]; then
    game_executable="$source_root/jumpnbump"
else
    fail "The compiler completed, but no jumpnbump executable was produced."
fi

[[ -f "$source_root/data/jumpbump.dat" ]] || fail "The game data file was not produced."

rm -rf "$repo_root/dist"
mkdir -p "$dist_root/data" "$dist_root/levels" "$dist_root/licenses/game" "$dist_root/licenses/third-party"

cp "$game_executable" "$dist_root/jumpnbump.exe"
cp "$source_root/data/jumpbump.dat" "$dist_root/data/"
cp "$source_root/data/jumpbump.dat" "$dist_root/levels/Original.dat"
cp "$repo_root/launcher/JumpNBump-Launcher.cmd" "$dist_root/"
cp "$repo_root/launcher/JumpNBump-Launcher.ps1" "$dist_root/"
cp "$source_root/COPYING" "$dist_root/licenses/game/COPYING"
cp "$source_root/AUTHORS" "$dist_root/licenses/game/AUTHORS"
cp "$source_root/source.txt" "$dist_root/licenses/game/source.txt"
cp "$repo_root/SOURCE.md" "$dist_root/licenses/game/SOURCE.md"

# SDL_mixer loads its MOD decoder at runtime, so ldd does not report it as a
# direct dependency. Jump 'n Bump's music is stored in MOD files.
mikmod_runtime="$(find /mingw64/bin -maxdepth 1 -type f -iname 'libmikmod*.dll' -print -quit)"
[[ -n "$mikmod_runtime" ]] || fail "SDL_mixer's MOD music decoder (libmikmod) was not found."
cp "$mikmod_runtime" "$dist_root/"

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
The launcher remembers fullscreen, mirror, gore, flies, and sound choices.

This package uses the original standalone 1.51 game loop. The separate launcher
selects a .dat file and starts jumpnbump.exe with command-line options. The new
-nomusic option changes only the SDL music boundary and leaves effects enabled.

Source provenance and licenses are in the licenses folder.
EOF

require_runtime() {
    local pattern="$1"
    local description="$2"
    if ! find "$dist_root" -maxdepth 1 -type f -iname "$pattern" -print -quit | grep -q .; then
        fail "$description was not copied into the portable package (looked for $pattern)."
    fi
}

require_runtime 'SDL.dll' 'SDL'
require_runtime '*SDL_mixer*.dll' 'SDL_mixer'
require_runtime '*SDL_net*.dll' 'SDL_net'
require_runtime 'libmikmod*.dll' 'SDL_mixer MOD music decoder'

echo "Packaged runtime DLLs:"
find "$dist_root" -maxdepth 1 -type f -iname '*.dll' -printf '  %f\n' | sort

echo "Portable package prepared at: $dist_root"
