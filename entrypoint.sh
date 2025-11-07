#!/bin/bash
set -e

# Remove a potentially pre-existing server.pid for Rails
rm -f /app/tmp/pids/server.pid

echo "Waiting for MySQL to be ready..."
until nc -z $DATABASE_HOST 3306; do
  sleep 1
done
echo "MySQL is up!"

echo "Waiting for Redis to be ready..."
until nc -z redis 6379; do
  sleep 1
done
echo "Redis is up!"

# Run migrations and start Rails
bundle exec rails db:prepare
bundle exec rails s -b 0.0.0.0 -p 3000
