#!/bin/bash

if [ -z "$1" ]; then
  echo "Available models:"
  echo "  gemma       - Google Gemma (smaller, faster)"
  echo "  llama3      - Meta Llama 3 (larger, more powerful)"
  echo "  phi3        - Microsoft Phi-3 (smaller, faster)"
  echo "  mistral     - Mistral AI (good balance of speed/performance)"
  echo "  tinyllama   - Very small and fast model"
  echo ""
  echo "Usage: ./change-model.sh MODEL_NAME"
  exit 1
fi

MODEL=$1

# Update the environment variable for the model
sed -i "s/MODEL=.*/MODEL=$MODEL/" .env
echo "Updated .env file with MODEL=$MODEL"

# Pull the new model
echo "Pulling $MODEL model to Ollama..."
podman exec -e MODEL=$MODEL ollama sh -c "ollama pull $MODEL"

echo "Model $MODEL is now available."
echo "Don't forget to update your n8n workflows to use this model!"
