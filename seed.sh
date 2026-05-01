#!/bin/bash

# Script to seed the database inside the Docker container
echo "Initializing database seeding..."

# Check if docker is running
if ! docker info > /dev/null 2>&1; then
  echo "Error: Docker is not running."
  exit 1
fi

# Run the seeder
docker exec -it hris_backend /app/seeder

if [ $? -eq 0 ]; then
  echo "Database seeded successfully!"
else
  echo "Error: Failed to seed database."
  exit 1
fi
