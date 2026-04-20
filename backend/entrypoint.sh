#!/bin/sh

# Exit immediately if a command exits with a non-zero status
set -e

echo "Initializing Upload Directories..."
mkdir -p uploads/attachments uploads/faces uploads/selfies uploads/files
chmod -R 777 uploads

echo "Running Database Seeding..."
./seeder

echo "Starting API Server..."
exec ./api
