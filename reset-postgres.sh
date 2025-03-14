#!/bin/bash

echo "WARNING: This will delete all PostgreSQL data and reset the database."
echo "n8n workflows and credentials will need to be re-imported."
read -p "Are you sure you want to continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Operation cancelled."
  exit 1
fi

# Stop any running services
echo "Stopping running containers..."
podman compose down || podman-compose down

# Remove the PostgreSQL volume
echo "Removing PostgreSQL volume..."
podman volume rm postgres_storage

echo "PostgreSQL data has been reset."
echo "Run './startup.sh' to start the services with a fresh database."
