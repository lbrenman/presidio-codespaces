#!/bin/bash
set -e

echo ""
echo "============================================="
echo "  Microsoft Presidio - Starting up..."
echo "============================================="

# Start Presidio containers
echo ""
echo "Starting Presidio containers via Docker Compose..."
docker compose up -d

wait_for_service() {
  local name=$1
  local url=$2
  local max_attempts=30
  local attempt=1

  echo ""
  echo "Waiting for $name to be ready..."
  while [ $attempt -le $max_attempts ]; do
    if curl -sf "$url/health" > /dev/null 2>&1; then
      echo "✅ $name is ready!"
      return 0
    fi
    echo "  Attempt $attempt/$max_attempts - not ready yet, retrying in 5s..."
    sleep 5
    attempt=$((attempt + 1))
  done

  echo "❌ $name did not become ready in time."
  return 1
}

wait_for_service "Presidio Anonymizer" "http://localhost:5001"
wait_for_service "Presidio Analyzer"   "http://localhost:5002"

echo ""
echo "============================================="
echo "  Presidio is ready! 🎉"
echo ""
echo "  Analyzer  → http://localhost:5002"
echo "  Anonymizer → http://localhost:5001"
echo ""
echo "  Run 'bash test.sh' to verify the APIs."
echo "============================================="
echo ""
