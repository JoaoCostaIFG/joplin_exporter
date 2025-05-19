#!/bin/bash

# Strict mode
set -euo pipefail

# --- Configuration & Constants ---
JOPLIN_SYNC_TARGET_ID="9" # 9 is for Joplin server sync target

# --- Helper Functions ---
log_info() {
  echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') $1"
}

log_error() {
  echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') $1" >&2
}

usage() {
  echo "Usage: $0 <notebook_name> <output_directory>"
  echo "Exports a Joplin notebook to a local directory."
  echo ""
  echo "Arguments:"
  echo "  <notebook_name>    The name of the Joplin notebook to export (e.g., \"Wiki\" or \"My Notes\")."
  echo "  <output_directory> The local path where the notebook will be exported (e.g., ./exported_notes)."
  echo ""
  echo "Required Environment Variables:"
  echo "  JOPLIN_PATH        URL Joplin's sever (e.g., \"https://joplin.example.com\")."
  echo "  JOPLIN_USER        Username for Joplin sync."
  echo "  JOPLIN_PASSWORD    Password for Joplin sync."
  exit 1
}

check_dependencies() {
  if ! command -v npx &>/dev/null; then
    log_error "npx command not found. Please install Node.js and npm."
    exit 1
  fi
  # We can also try to see if joplin-cli is accessible via npx
  if ! npx joplin version &>/dev/null; then
    log_error "Joplin CLI (via npx) does not seem to be working. Ensure it can be run with 'npx joplin'."
    exit 1
  fi
}

check_env_vars() {
  local missing_vars=0
  required_vars=("JOPLIN_PATH" "JOPLIN_USER" "JOPLIN_PASSWORD")

  for var_name in "${required_vars[@]}"; do
    if [[ -z "${!var_name}" ]]; then # Indirect expansion to get value of var_name
      log_error "Environment variable $var_name is not set."
      missing_vars=1
    fi
  done

  if [[ "$missing_vars" -eq 1 ]]; then
    log_error "Please set the required environment variables."
    exit 1
  fi
}

# --- Main Script Logic ---
main() {
  # Argument parsing
  if [[ $# -eq 2 ]]; then
    notebook_name="$1"
    output_dir="$2"
  elif [[ $# -eq 0 ]]; then
    log_info "No command-line arguments provided. Trying environment variables JOPLIN_NOTEBOOK_NAME and JOPLIN_OUTPUT_DIR."
    notebook_name="${JOPLIN_NOTEBOOK_NAME:-}"
    output_dir="${JOPLIN_OUTPUT_DIR:-}"
    if [[ -z "$notebook_name" || -z "$output_dir" ]]; then
      log_error "JOPLIN_NOTEBOOK_NAME or JOPLIN_OUTPUT_DIR environment variables are not set."
      usage
    fi
  else
    usage
  fi

  # Checks
  check_dependencies
  check_env_vars

  log_info "Starting Joplin export process..."
  log_info "Notebook to export: '$notebook_name'"
  log_info "Output directory: '$output_dir'"

  # --- Joplin Configuration ---
  log_info "Configuring Joplin sync target..."
  if ! npx joplin config sync.target "$JOPLIN_SYNC_TARGET_ID"; then
    log_error "Failed to set Joplin sync target."
    exit 1
  fi
  if ! npx joplin config "sync.${JOPLIN_SYNC_TARGET_ID}.path" "$JOPLIN_PATH"; then
    log_error "Failed to set Joplin sync path."
    exit 1
  fi
  if ! npx joplin config "sync.${JOPLIN_SYNC_TARGET_ID}.username" "$JOPLIN_USER"; then
    log_error "Failed to set Joplin sync username."
    exit 1
  fi
  if ! npx joplin config "sync.${JOPLIN_SYNC_TARGET_ID}.password" "$JOPLIN_PASSWORD"; then
    log_error "Failed to set Joplin sync password."
    exit 1
  fi

  # --- Joplin Sync ---
  log_info "Synchronizing with Joplin server..."
  if ! npx joplin sync; then
    log_error "Joplin synchronization failed."
    exit 1
  fi
  log_info "Synchronization complete."

  # --- Prepare Output Directory ---
  log_info "Preparing output directory: $output_dir"
  if [ -d "$output_dir" ]; then
    log_info "Output directory '$output_dir' exists. Removing its contents."
    rm -rf "${output_dir:?}"/* # Protect against empty output_dir and rm -rf /*
  else
    log_info "Creating output directory: $output_dir"
  fi
  mkdir -p "$output_dir" # Ensure it exists

  # --- Joplin Export ---
  log_info "Exporting notebook '$notebook_name' to '$output_dir' (Markdown format)..."
  # Note: Joplin export will create subdirectories within $output_dir based on notebook structure
  if ! npx joplin export --format md --notebook "$notebook_name" "$output_dir"; then
    log_error "Joplin export failed for notebook '$notebook_name'."
    # Consider cleaning up the partially created output_dir if needed,
    # though joplin export might handle this or leave partial data.
    exit 1
  fi

  log_info "Export successful!"
  log_info "Files exported to: $(realpath "$output_dir")"
}

main "$@"
