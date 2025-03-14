#!/bin/bash

echo "Checking service availability..."

# Check postgres
echo "Testing postgres..."
podman exec -it postgres pg_isready -h localhost -U postgres && echo "✅ Postgres is ready" || echo "❌ Postgres is not ready"

# Check qdrant using curl inside the container
echo "Testing qdrant..."
podman exec -it qdrant curl -s localhost:6333/health | grep -q status && echo "✅ Qdrant is ready" || echo "❌ Qdrant is not ready"

# Check ollama
echo "Testing ollama..."
podman exec -it ollama curl -s localhost:11434/api/version | grep -q version && echo "✅ Ollama is ready" || echo "❌ Ollama is not ready"

# Check n8n
echo "Testing n8n..."
podman exec -it n8n curl -s localhost:5678 | grep -q n8n && echo "✅ N8N is ready" || echo "❌ N8N is not ready"

echo "To test from your host, run the following commands:"
echo "  curl http://localhost:5678 (for N8N)"
echo "  curl http://localhost:11434/api/version (for Ollama)"
echo "  curl http://localhost:6333/healthz (for Qdrant)"
