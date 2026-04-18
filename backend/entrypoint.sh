#!/bin/sh

# Exit immediately if a command exits with a non-zero status
set -e

echo "Running Database Seeding..."
./seeder

echo "Starting API Server..."
exec ./api
