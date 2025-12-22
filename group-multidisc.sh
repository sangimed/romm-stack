#!/bin/sh
# Groups multi-disc ROMs into per-game folders for selected platforms.

set -eu

ROM_ROOT="${1:-/romm/library/roms}"
ALLOWLIST_RAW="${ROMM_MULTIDISC_PLATFORMS:-}"
DRY_RUN_RAW="${ROMM_MULTIDISC_DRY_RUN:-true}"
PUID="${PUID:-}"
PGID="${PGID:-}"

normalize_bool() {
    val=$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')
    default=$(printf '%s' "$2" | tr '[:upper:]' '[:lower:]')
    case "$val" in
        1|true|yes|on) echo "true" ;;
        0|false|no|off) echo "false" ;;
        *) echo "$default" ;;
    esac
}

DRY_RUN=$(normalize_bool "$DRY_RUN_RAW" "true")

if [ -z "$ALLOWLIST_RAW" ]; then
    echo "Warning: ROMM_MULTIDISC_PLATFORMS not set; skipping multi-disc grouping."
    exit 0
fi

allowlist_tmp=$(mktemp)
created_dirs=""

cleanup() {
    rm -f "$allowlist_tmp"
}
trap cleanup EXIT

IFS=','
for platform in $ALLOWLIST_RAW; do
    clean=$(printf '%s' "$platform" | tr -d '\r' | sed 's/^ *//;s/ *$//')
    [ -n "$clean" ] && printf '%s\n' "$clean" >> "$allowlist_tmp"
done
unset IFS

if [ ! -s "$allowlist_tmp" ]; then
    echo "Warning: ROMM_MULTIDISC_PLATFORMS is empty after cleanup; skipping multi-disc grouping."
    exit 0
fi

while IFS= read -r platform; do
    platform_path="$ROM_ROOT/$platform"

    if [ ! -d "$platform_path" ]; then
        echo "Skipping $platform (missing path: $platform_path)"
        continue
    fi

    matches=$(mktemp)

    find "$platform_path" -maxdepth 1 -type f -print0 | while IFS= read -r -d '' file; do
        base=$(basename "$file")
        if printf '%s\n' "$base" | grep -Eq '^(.*)[[:space:]]*\(Disc[[:space:]]*[0-9]+\)\.[^.]+$'; then
            prefix=$(printf '%s\n' "$base" | sed -E 's/^(.*)[[:space:]]*\(Disc[[:space:]]*[0-9]+\)\.[^.]+$/\1/')
            printf '%s\t%s\n' "$prefix" "$file" >> "$matches"
        fi
    done

    if [ ! -s "$matches" ]; then
        echo "No multi-disc candidates in $platform."
        rm -f "$matches"
        continue
    fi

    dups=$(mktemp)
    cut -f1 "$matches" | sort | uniq -d > "$dups"

    if [ ! -s "$dups" ]; then
        echo "No multi-disc groups in $platform."
        rm -f "$matches" "$dups"
        continue
    fi

    while IFS= read -r prefix; do
        dest="$platform_path/$prefix"
        if [ ! -d "$dest" ]; then
            echo "Creating folder: $dest"
            if [ "$DRY_RUN" != "true" ]; then
                mkdir -p "$dest"
                if [ -z "$created_dirs" ]; then
                    created_dirs="$dest"
                else
                    created_dirs="$created_dirs
$dest"
                fi
            fi
        fi

        while IFS=$'\t' read -r match_prefix filepath; do
            [ "$match_prefix" = "$prefix" ] || continue
            target="$dest/$(basename "$filepath")"
            if [ "$DRY_RUN" = "true" ]; then
                echo "DRY-RUN: would move $filepath -> $dest/"
            else
                if [ -e "$target" ]; then
                    echo "Skip move (exists): $target"
                else
                    mv "$filepath" "$dest/"
                    echo "Moved: $filepath -> $dest/"
                fi
            fi
        done < "$matches"
    done < "$dups"

    rm -f "$matches" "$dups"
done < "$allowlist_tmp"

if [ "$DRY_RUN" != "true" ] && [ -n "$created_dirs" ] && [ -n "$PUID" ] && [ -n "$PGID" ]; then
    echo "Applying ownership: $PUID:$PGID to created folders..."
    printf '%s\n' "$created_dirs" | while IFS= read -r dir; do
        chown -R "$PUID:$PGID" "$dir"
    done
fi
