#!/bin/sh

# Exit immediately if a command exits with a non-zero status
set -e

echo "Initializing Upload Directories..."
mkdir -p uploads/attachments uploads/faces uploads/selfies uploads/files
chmod -R 777 uploads

echo "Running Database Migrations..."
./migrate -path config/migrations -database "postgres://$DB_USER:$DB_PASSWORD@$DB_HOST:$DB_PORT/$DB_NAME?sslmode=disable" up

if [ "$SKIP_SEED" != "true" ]; then
    echo "Running Database Seeding..."
    ./seeder
else
    echo "Skipping Database Seeding..."
fi

echo "Starting API Server..."
exec ./api
