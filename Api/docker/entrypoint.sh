#!/bin/sh
set -e
echo "→ Migrations Alembic"
alembic upgrade head
if [ "${SEED_DEMO:-true}" = "true" ]; then
  echo "→ Données de démo"
  python -m app.seed
fi
echo "→ API sur :8000"
exec uvicorn app.main:app --host 0.0.0.0 --port 8000 --proxy-headers
