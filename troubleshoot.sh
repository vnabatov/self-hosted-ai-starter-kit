#!/bin/bash

echo "Self-hosted AI Starter Kit Troubleshooter"
echo "========================================"
echo

# Check if podman is running
echo "Checking podman status..."
if ! command -v podman &> /dev/null; then
  echo "ERROR: podman is not installed or not in PATH!"
  exit 1
else
  echo "✅ podman is installed"
fi

# Load environment variables
source .env 2>/dev/null || true

# Check running containers
echo
echo "Checking container status..."
running_containers=$(podman ps --format "{{.Names}}" | wc -l)
echo "Running containers: $running_containers"
podman ps

# Check if core services are running
echo
echo "Checking core services..."
for service in postgres qdrant ollama n8n; do
  if podman ps --format "{{.Names}}" | grep -q "$service"; then
    echo "✅ $service is running"
    
    # Extra checks for PostgreSQL
    if [ "$service" = "postgres" ]; then
      echo "   Checking PostgreSQL connection..."
      if podman exec postgres pg_isready -U ${POSTGRES_USER:-root} -d ${POSTGRES_DB:-n8n} &> /dev/null; then
        echo "   ✅ PostgreSQL is accepting connections"
      else
        echo "   ❌ PostgreSQL is NOT accepting connections"
        echo "      - Check logs: podman logs postgres"
        echo "      - Reset PostgreSQL: ./reset-postgres.sh"
      fi
    fi
  else
    echo "❌ $service is NOT running"
    
    # Specific advice for PostgreSQL
    if [ "$service" = "postgres" ]; then
      echo "   - PostgreSQL is not running, which will prevent n8n from starting"
      echo "   - Check the .env file for correct PostgreSQL credentials"
      echo "   - Try running: podman-compose up -d postgres"
      echo "   - If still failing, reset PostgreSQL: ./reset-postgres.sh"
    fi
  fi
done

# Check service health
echo
echo "Testing service connectivity..."

# Check n8n
echo -n "n8n (http://localhost:5678): "
if curl -s http://localhost:5678/healthz &> /dev/null; then
  echo "✅ Accessible"
else
  echo "❌ Not accessible"
  echo "  - Check logs: podman logs n8n"
  echo "  - n8n requires PostgreSQL to be running and accessible"
fi

# Check Ollama
echo -n "Ollama (http://localhost:11434): "
if curl -s http://localhost:11434/api/health &> /dev/null; then
  echo "✅ Accessible"
else
  echo "❌ Not accessible"
  echo "  - Check logs: podman logs ollama"
fi

# Check Qdrant
echo -n "Qdrant (http://localhost:6333): "
if curl -s http://localhost:6333/health &> /dev/null; then
  echo "✅ Accessible"
else
  echo "❌ Not accessible"
  echo "  - Check logs: podman logs qdrant"
fi

echo
echo "Possible issues and resolutions:"
echo "1. If PostgreSQL is not running, n8n will fail to start"
echo "   - Run ./reset-postgres.sh if you suspect PostgreSQL data corruption"
echo "2. If n8n is not accessible, check its logs and ensure PostgreSQL is running"
echo "3. If Ollama is not accessible, it might be still initializing (can take a few minutes)"
echo "4. Try restarting the affected service: podman restart <service-name>"
echo "5. For complete reset: ./startup.sh"
echo
echo "For more detailed logs:"
echo "podman logs -f <container-name>"
