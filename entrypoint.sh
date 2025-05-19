#!/bin/bash
set -e

# Create a file with current environment variables for cron to source
# Only include variables that are relevant for the cron job
echo "Exporting environment variables for cron..."
printenv | grep -E '^JOPLIN_' | sed 's/^\(.*\)$/export \1/g' >/etc/cron_env.sh
chmod +x /etc/cron_env.sh

echo "Starting cron daemon..."
# Execute the command passed to the entrypoint (which will be "cron -f" from the Dockerfile CMD)
exec "$@"
