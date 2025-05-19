# Joplin Exporter

This repository provides a Dockerized solution to automatically export specified Joplin notebooks to a local directory (with cron support). It uses the Joplin CLI.

## Features

* **Automated Hourly Exports:** Uses `cron` to run the export script every hour (customizable).
* **Joplin CLI:** Utilizes the official `joplin-cli` for interacting with Joplin.
* **Dockerized:** Easy to deploy and manage, ensuring a consistent environment.
* **Configurable:**
  * Specify which notebook to export.
  * Define the output directory for exported files.

**Note:** This only supports syncing with a Joplin server, because I have no need for the other sync targets. However, since it uses the official Joplin cli, it should be easy to support other targets. I'd probably do it if anyone asks for it.

## Prerequisites

1. **Docker:** Docker must be installed and running on your host machine.
2. **Joplin Setup:**
    * A Joplin server that this script will sync with.

## File Structure

```txt
.
├── Dockerfile          # Defines the Docker image
├── entrypoint.sh       # Starts cron within the container
├── export_joplin.sh    # The main Bash script for Joplin export
├── joplin_cron         # Crontab file for scheduling the export
└── README.md           # This file
```

## Setup & Installation

1. **Clone the Repository (or create the files):**

    ```bash
    git clone <your-repo-url>
    cd <your-repo-directory>
    ```

    Or, manually create the `Dockerfile`, `entrypoint.sh`, `export_joplin.sh`, and `joplin_cron` files with the content provided in the previous responses.

2. **Build the Docker Image:**

    ```bash
    docker build -t joplin-exporter .
    ```

    You can choose a different tag if you prefer.

## Configuration & Usage

The container is configured primarily through environment variables passed during `docker run`.

### Environment Variables

* **`JOPLIN_SYNC_TARGET_ID` (Required):** The Joplin sync target ID.
  * `9`: Joplin Server (the official Joplin Server application)
* **`JOPLIN_PATH` (Required):** The URL for the sync target.
* **`JOPLIN_USER` (Required):** Username for Joplin Server.
* **`JOPLIN_PASSWORD` (Required):** Password for Joplin Server.
* **`JOPLIN_NOTEBOOK_NAME` (Required):** The exact name of the Joplin notebook to export (e.g., `"My Notes"` or `"Wiki"`).
* **`JOPLIN_OUTPUT_DIR` (Required):** The path *inside the container* where the notes will be exported (e.g., `/exported_notes`).
* **`TZ` (Optional):** Set the timezone for the container and cron jobs (e.g., `America/New_York`).
  * Default: UTC

### Running the Container

Here's an example `docker run` command. Adjust paths and variables according to
your setup.

```bash
docker run -d --name my-joplin-exporter \
  -e JOPLIN_PATH="https://joplin.example.com" \
  -e JOPLIN_USER="your_joplin_server_email" \
  -e JOPLIN_PASSWORD="your_joplin_server_password" \
  -e CRON_NOTEBOOK_NAME="Important Project" \
  -e CRON_OUTPUT_DIR="/exported_notes" \
  -v ./exports:/exported_notes \
  joplin-exporter
```

## License

This project is licensed under the MIT License - see the `LICENSE` file for details (you should create a `LICENSE` file with the MIT license text if you wish to use it).
