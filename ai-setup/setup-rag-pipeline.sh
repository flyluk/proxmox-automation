#!/bin/bash

# Clone or update repository
if [ -d "rag_pipeline" ]; then
    echo "Repository already exists, updating..."
    cd rag_pipeline
    git pull
else
    git clone git@github.com:flyluk/rag_pipeline.git
    cd rag_pipeline
fi

# Create external volumes
docker volume create open-webui
docker volume create ollama
docker volume create postgres_data
docker volume create vllm_cache

# Run docker compose with basic services
export HF_TOKEN=""
docker compose --profile enabled up -d