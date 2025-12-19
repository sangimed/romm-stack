#!/bin/sh

# -----------------------------------------------------------------------------
# @name init-romm.sh
# @description
#   Initializes the directory structure for the RoMM library based on a CSV list of platforms.
#   This script implements "Structure A" (Recommended by RoMM):
#     - /romm/library/roms/{platform}
#     - /romm/library/bios/{platform}
#
#   It reads platform slugs from /folder_names.csv (mounted into the container).
#   It checks if folders exist before creating them to provide a summary of actions.
#
# @env ROM_ROOT  The root directory for ROMs (default: /romm/library/roms)
# @env BIOS_ROOT The root directory for BIOS files (default: /romm/library/bios)
# @env CSV_FILE  The path to the CSV file containing platform names (default: /folder_names.csv)
# -----------------------------------------------------------------------------

echo "Initializing RoMM library structure (Structure A)..."

ROM_ROOT="/romm/library/roms"
BIOS_ROOT="/romm/library/bios"
CSV_FILE="/folder_names.csv"

# Create root folders
mkdir -p "$ROM_ROOT"
mkdir -p "$BIOS_ROOT"

if [ ! -f "$CSV_FILE" ]; then
    echo "Error: $CSV_FILE not found!"
    exit 1
fi

echo "Reading platforms from $CSV_FILE..."

# Use a block to keep variable scope for counters
tail -n +2 "$CSV_FILE" | tr -d '\r' | {
    total_platforms=0
    created_folders=0
    skipped_folders=0
    
    while IFS= read -r platform || [ -n "$platform" ]; do
        # Skip empty lines
        if [ -z "$platform" ]; then continue; fi
        
        total_platforms=$((total_platforms + 1))
        
        # --- ROMs Folder ---
        if [ -d "$ROM_ROOT/$platform" ]; then
            skipped_folders=$((skipped_folders + 1))
        else
            mkdir -p "$ROM_ROOT/$platform"
            created_folders=$((created_folders + 1))
        fi
        
        # --- BIOS Folder ---
        if [ -d "$BIOS_ROOT/$platform" ]; then
            skipped_folders=$((skipped_folders + 1))
        else
            mkdir -p "$BIOS_ROOT/$platform"
            created_folders=$((created_folders + 1))
        fi
    done
    
    echo "------------------------------------------------"
    echo "Initialization Summary:"
    echo "  Platforms processed : $total_platforms"
    echo "  Folders created     : $created_folders"
    echo "  Folders skipped     : $skipped_folders"
    echo "------------------------------------------------"
}

echo "Library structure check complete."
