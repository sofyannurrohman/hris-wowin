#!/bin/bash

# Configuration
DOMAINS=("hris.wowinapps.cloud")
EMAIL="your-email@example.com"
STAGING=0 # Set to 1 for testing with Let's Encrypt staging environment

if [ -z "$1" ]; then
    echo "Usage: ./init-ssl.sh <domain> <email>"
    echo "Example: ./init-ssl.sh example.com admin@example.com"
    exit 1
fi

DOMAIN=$1
EMAIL=$2

echo "### Starting SSL setup for $DOMAIN ###"

# 1. Start Nginx to handle the challenge
echo "### Starting Nginx ###"
docker compose up -d nginx

# 2. Request certificate
echo "### Requesting Let's Encrypt certificate for $DOMAIN ###"

# Enable staging mode if requested
if [ $STAGING != "0" ]; then staging_arg="--staging"; fi

docker compose run --rm --entrypoint "\
  certbot certonly --webroot -w /var/www/certbot \
    $staging_arg \
    --email $EMAIL \
    -d $DOMAIN \
    --rsa-key-size 4096 \
    --agree-tos \
    --force-renewal \
    --non-interactive" certbot

echo "### Reloading Nginx to apply certificates ###"
docker compose exec nginx nginx -s reload

echo "### SSL Setup Complete! ###"
echo "Don't forget to uncomment the SSL lines in deploy/nginx/nginx.conf and restart Nginx."
