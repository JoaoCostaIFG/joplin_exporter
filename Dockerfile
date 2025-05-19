# Use a Node.js base image that includes npm and npx
# Choose a version appropriate for Joplin CLI compatibility. LTS versions are good.
FROM node:22-slim

# Install cron and any other system dependencies
# (git might be needed by some npx packages, but often not for joplin-cli directly)
RUN apt-get update && \
  apt-get install -y --no-install-recommends cron \
  && rm -rf /var/lib/apt/lists/* \
  && npx -y -- joplin version

# Set a working directory
WORKDIR /app

# Copy your export script into the image
COPY export_joplin.sh .
RUN chmod +x export_joplin.sh

# Create a crontab file
# Note: Environment variables for cron jobs need special handling (see entrypoint.sh)
COPY joplin_cron /etc/cron.d/joplin_cron

# Give execution rights on the cron job
RUN chmod 0644 /etc/cron.d/joplin_cron

# Copy the entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

# Command to run cron in the foreground and log to stdout/stderr
CMD ["cron", "-f"]
