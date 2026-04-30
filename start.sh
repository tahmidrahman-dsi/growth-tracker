#!/usr/bin/env bash
set -e

ROOT="$(cd "$(dirname "$0")" && pwd)"

echo "==> Seeding .env files from .env.example (skipping if already present)..."
if [ ! -f "$ROOT/.env.example" ]; then
  echo "ERROR: .env.example not found at $ROOT" && exit 1
fi
# Server env
if [ ! -f "$ROOT/packages/server/.env" ]; then
  cp "$ROOT/.env.example" "$ROOT/packages/server/.env"
  echo "    Created packages/server/.env"
fi

echo "==> Starting Docker services..."
docker compose -f "$ROOT/docker-compose.yml" up -d

echo "==> Waiting for Postgres to be healthy..."
until docker compose -f "$ROOT/docker-compose.yml" exec -T postgres pg_isready -U postgres > /dev/null 2>&1; do
  sleep 1
done
echo "    Postgres is ready."

echo "==> Installing dependencies..."
cd "$ROOT" && pnpm install

echo "==> Running Prisma migrations..."
cd "$ROOT/packages/server" && pnpm exec prisma migrate dev --name init

echo "==> Starting client and server..."
cd "$ROOT" && pnpm dev
