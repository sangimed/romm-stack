# romm-stack

Docker Compose stack to run RoMM + MariaDB + Syncthing.

## Requirements

- Docker + Docker Compose v2 (`docker compose`)

## Configuration

- Copy `.env.example` to `.env`
- At minimum, set: `MARIADB_ROOT_PASSWORD`, `DB_*`, `ROMM_AUTH_SECRET_KEY`, and the `*_PATH` bind mounts
- Create the directories referenced by `ROMM_LIBRARY_PATH`, `ROMM_ASSETS_PATH`, `ROMM_CONFIG_PATH`, `SAVES_SYNC_PATH` if needed

## Run

- Start: `docker compose up -d`
- Logs: `docker compose logs -f`
- Stop: `docker compose down`

## Access

- RoMM: `http://localhost:${ROMM_PORT:-8080}`
- Syncthing UI: `http://localhost:8384` (note: exposed to your network if you keep `8384:8384`)

## Persistent data

- MariaDB: named volume `mariadb_data`
- RoMM resources + redis: `romm_resources`, `romm_redis_data`
- Syncthing config: `syncthing_config`
