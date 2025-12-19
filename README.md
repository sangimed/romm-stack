# romm-stack

<p align="center">
  <img src="logo.png" alt="RoMM Stack logo" width="520" />
</p>
<p align="center">Docker Compose stack for RoMM + MariaDB + Syncthing, with automatic ROM/BIOS folder bootstrap.</p>

## What's inside
- `romm`: RoMM app; waits for the database and the init job before starting.
- `romm-db`: MariaDB with healthcheck.
- `init-romm`: one-shot Alpine job that builds the ROM/BIOS folder tree from `folder_names.csv`.
- `syncthing`: optional save-sync service mounted on `${SAVES_SYNC_PATH}`.

## Requirements
- Docker + Docker Compose v2 (`docker compose`)

## Configuration
- Copy `.env.example` to `.env`.
- Fill required secrets: `MARIADB_ROOT_PASSWORD`, `DB_*`, `ROMM_AUTH_SECRET_KEY`.
- Point bind mounts to real host paths (absolute paths recommended on Windows): `ROMM_LIBRARY_PATH`, `ROMM_ASSETS_PATH`, `ROMM_CONFIG_PATH`, `SAVES_SYNC_PATH`.
- Optional: metadata provider keys (`IGDB_*`, `SCREENSCRAPER_*`, `RETROACHIEVEMENTS_API_KEY`, `STEAMGRIDDB_API_KEY`) and `HASHEOUS_API_ENABLED`.

## Library bootstrap (`init-romm.sh`)
- Runs automatically via the `init-romm` service before RoMM starts (see `depends_on`).
- Reads platform slugs from `./folder_names.csv` (first line is a header) and creates:
  - `/romm/library/roms/{platform}`
  - `/romm/library/bios/{platform}`
- These map to `${ROMM_LIBRARY_PATH}` on your host; existing folders are skipped safely.
- To customize, edit `folder_names.csv` to match the platforms you keep. Re-run with `docker compose run --rm init-romm` after edits.
- The script prints a summary of processed/created/skipped folders.

## Run
- Start: `docker compose up -d`
- Logs: `docker compose logs -f`
- Stop: `docker compose down`

## Access
- RoMM: `http://localhost:${ROMM_PORT:-8080}`
- Syncthing UI: `http://localhost:8384` (exposed to your network if you keep `8384:8384`)

## Persistent data
- MariaDB: named volume `mariadb_data`
- RoMM resources + redis: `romm_resources`, `romm_redis_data`
- Syncthing config: `syncthing_config`
- Library + assets + config + saves: host bind mounts defined in `.env`
