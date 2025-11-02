#!/bin/bash

# Clone repository
git clone git@github.com:flyluk/rag_pipeline.git
cd rag_pipeline

# Create external volumes from docker-compose.yml
if [ -f docker-compose.yml ]; then
    grep -A 10 "^volumes:" docker-compose.yml | grep "external: true" -B 1 | grep -v "external: true" | grep -v "--" | sed 's/:$//' | sed 's/^[[:space:]]*//' | while read volume; do
        [ -n "$volume" ] && docker volume create "$volume"
    done
fi

# Run docker-compose
docker-compose up -d