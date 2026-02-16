#!/bin/bash
set -e

# Map Redmine Secret to Rails Secret
if [ -n "$REDMINE_SECRET_KEY_BASE" ] && [ -z "$SECRET_KEY_BASE" ]; then
  export SECRET_KEY_BASE="$REDMINE_SECRET_KEY_BASE"
fi

# Wait for database connection
echo "Waiting for database..."
until bundle exec rake db:version > /dev/null 2>&1; do
  echo "Database not ready yet. Sleeping 5s..."
  sleep 5
done

# Run Migrations
echo "Running database migrations..."
bundle exec rake db:migrate RAILS_ENV=production
bundle exec rake redmine:plugins:migrate RAILS_ENV=production

# Clear Cache
bundle exec rake tmp:clear

# Start Redmine
echo "Starting Redmine..."
exec "$@"
