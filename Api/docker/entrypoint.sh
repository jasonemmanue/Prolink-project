#!/bin/sh
set -e
echo "→ Migrations Alembic"
alembic upgrade head
if [ "${SEED_DEMO:-true}" = "true" ]; then
  echo "→ Données de démo"
  python -m app.seed
fi
PORT="${PORT:-8000}"  # Railway injecte $PORT
echo "→ API sur :$PORT"
exec uvicorn app.main:app --host 0.0.0.0 --port "$PORT" --proxy-headers --forwarded-allow-ips "*"
