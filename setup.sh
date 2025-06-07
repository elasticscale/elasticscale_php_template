#!/bin/bash

LOG_FILE="/tmp/setup.log"

echo "Starting setup at $(date)" > "$LOG_FILE"

# Verify working directory
cd /var/www/laravel || { echo "Error: Failed to cd to /var/www/laravel" >> "$LOG_FILE"; exit 1; }
echo "Working directory: $(pwd)" >> "$LOG_FILE"
echo "Directory contents before setup: $(ls -la)" >> "$LOG_FILE"

# Check for existing Laravel project
if [ -f composer.json ] && [ -f artisan ]; then
  echo "Existing Laravel project detected, skipping initialization" >> "$LOG_FILE"
  # Ensure storage directories exist
  echo "Ensuring storage directories exist..." >> "$LOG_FILE"
  mkdir -p storage/app/public storage/framework/cache storage/framework/sessions storage/logs bootstrap/cache >> "$LOG_FILE" 2>&1 || { echo "Error: Failed to create storage directories" >> "$LOG_FILE"; exit 1; }
  # Set permissions
  echo "Setting permissions..." >> "$LOG_FILE"
  chown -R www-data:www-data /var/www/laravel >> "$LOG_FILE" 2>&1 || { echo "Error: Failed to set chown permissions" >> "$LOG_FILE"; exit 1; }
  chmod -R 775 /var/www/laravel/storage /var/www/laravel/bootstrap/cache >> "$LOG_FILE" 2>&1 || { echo "Error: Failed to set chmod permissions" >> "$LOG_FILE"; exit 1; }
  # Validate Redis connectivity
  echo "Validating Redis connectivity..." >> "$LOG_FILE"
  php artisan cache:clear >> "$LOG_FILE" 2>&1 || { echo "Error: Failed to connect to Redis" >> "$LOG_FILE"; exit 1; }
  echo "Setup skipped, existing project preserved at $(date)" >> "$LOG_FILE"
  exit 0
fi

# No Laravel project detected, proceed with initialization
echo "No Laravel project detected, initializing new project..." >> "$LOG_FILE"

# Unmount storage/logs/ volume to allow clearing (required due to Docker volume mount)
if mountpoint -q /var/www/laravel/storage/logs; then
  echo "Unmounting storage/logs/ volume..." >> "$LOG_FILE"
  umount /var/www/laravel/storage/logs >> "$LOG_FILE" 2>&1 && echo "Successfully unmounted storage/logs" >> "$LOG_FILE" || { echo "Error: Failed to unmount storage/logs" >> "$LOG_FILE"; exit 1; }
else
  echo "No volume mount detected at storage/logs" >> "$LOG_FILE"
fi

# Clear /var/www/laravel/
echo "Clearing /var/www/laravel/..." >> "$LOG_FILE"
rm -rf * .[^.]* >> "$LOG_FILE" 2>&1 || { echo "Error: Failed to clear /var/www/laravel" >> "$LOG_FILE"; exit 1; }
echo "Directory contents after clear: $(ls -la)" >> "$LOG_FILE"

# Verify directory is empty
if [ "$(ls -A . | wc -l)" -gt 0 ]; then
  echo "Error: Directory not empty after clear" >> "$LOG_FILE"
  exit 1
fi

# Create Laravel project
echo "Creating Laravel project..." >> "$LOG_FILE"
composer create-project laravel/laravel . --prefer-dist >> "$LOG_FILE" 2>&1 || { echo "Error: Failed to create Laravel project" >> "$LOG_FILE"; exit 1; }
if [ ! -f composer.json ]; then
  echo "Error: No composer.json found after project creation" >> "$LOG_FILE"
  exit 1
fi

# Install Predis for Redis connectivity
echo "Installing Predis package..." >> "$LOG_FILE"
composer require predis/predis >> "$LOG_FILE" 2>&1 || { echo "Error: Failed to install Predis package" >> "$LOG_FILE"; exit 1; }

# Copy configs
echo "Copying configs..." >> "$LOG_FILE"
cp -r /var/www/config-stateless/*.php config/ >> "$LOG_FILE" 2>&1 || { echo "Error: Failed to copy configs" >> "$LOG_FILE"; exit 1; }
cp /var/www/.env.example .env >> "$LOG_FILE" 2>&1 || { echo "Error: Failed to copy .env" >> "$LOG_FILE"; exit 1; }

# Generate app key
echo "Generating app key..." >> "$LOG_FILE"
php artisan key:generate >> "$LOG_FILE" 2>&1 || { echo "Error: Failed to generate app key" >> "$LOG_FILE"; exit 1; }

# Create storage directories (including logs for volume mount)
echo "Creating storage directories..." >> "$LOG_FILE"
mkdir -p storage/app/public storage/framework/cache storage/framework/sessions storage/logs bootstrap/cache >> "$LOG_FILE" 2>&1 || { echo "Error: Failed to create storage directories" >> "$LOG_FILE"; exit 1; }
chown -R www-data:www-data /var/www/laravel/storage/logs >> "$LOG_FILE" 2>&1 || { echo "Error: Failed to set permissions for storage/logs" >> "$LOG_FILE"; exit 1; }
chmod -R 775 /var/www/laravel/storage/logs >> "$LOG_FILE" 2>&1 || { echo "Error: Failed to set chmod for storage/logs" >> "$LOG_FILE"; exit 1; }

# Initialize Git repository
echo "Initializing Git..." >> "$LOG_FILE"
git init >> "$LOG_FILE" 2>&1 || { echo "Error: Failed to initialize Git" >> "$LOG_FILE"; exit 1; }

# Set permissions
echo "Setting permissions..." >> "$LOG_FILE"
chown -R www-data:www-data /var/www/laravel >> "$LOG_FILE" 2>&1 || { echo "Error: Failed to set chown permissions" >> "$LOG_FILE"; exit 1; }
chmod -R 775 /var/www/laravel/storage /var/www/laravel/bootstrap/cache >> "$LOG_FILE" 2>&1 || { echo "Error: Failed to set chmod permissions" >> "$LOG_FILE"; exit 1; }

# Validate Redis connectivity
echo "Validating Redis connectivity..." >> "$LOG_FILE"
php artisan cache:clear >> "$LOG_FILE" 2>&1 || { echo "Error: Failed to connect to Redis" >> "$LOG_FILE"; exit 1; }

# Run migrations
echo "Running migrations..." >> "$LOG_FILE"
php artisan migrate >> "$LOG_FILE" 2>&1 || { echo "Error: Failed to run migrations" >> "$LOG_FILE"; exit 1; }

echo "Setup completed successfully at $(date)" >> "$LOG_FILE"