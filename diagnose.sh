#!/bin/bash

echo "=== Diagnostic Report ==="
echo "Running containers:"
podman ps -a

echo -e "\nContainer logs (may not work with remote podman):"
for container in postgres qdrant ollama n8n; do
  echo -e "\n--- ${container^} logs ---"
  podman logs $container --tail 10 2>/dev/null || echo "Could not get logs"
done

echo -e "\nNetworking tests:"
echo "--- Testing from host ---"
echo "N8N: $(curl -sI http://localhost:5678 2>/dev/null | head -1 || echo "Not responding")"
echo "Ollama: $(curl -sI http://localhost:11434/api/version 2>/dev/null | head -1 || echo "Not responding")"
echo "Qdrant: $(curl -sI http://localhost:6333/healthz 2>/dev/null | head -1 || echo "Not responding")"

echo -e "\n--- Testing endpoints ---"
echo "N8N UI: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:5678/ 2>/dev/null || echo "Failed")"
echo "Ollama API: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:11434/api/version 2>/dev/null || echo "Failed")"
echo "Qdrant API: $(curl -s -o /dev/null -w "%{http_code}" http://localhost:6333/healthz 2>/dev/null || echo "Failed")"

echo -e "\n--- Network configuration ---"
podman network inspect ai-network 2>/dev/null || echo "Network not found"
