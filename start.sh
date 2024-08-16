#!/bin/bash

# Get the absolute path of the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Define absolute paths based on the script directory
DB_FILE="$SCRIPT_DIR/backend/database.db"
FRONTEND_DIR="$SCRIPT_DIR/frontend"
BACKEND_DIR="$SCRIPT_DIR/backend"
LOG_FILE="$BACKEND_DIR/logs/flask.log"

# Check if tmux is installed
if ! command -v tmux &> /dev/null; then
    echo "tmux could not be found, please install tmux first."
    exit 1
fi

# Check if SQLite3 is installed
if ! command -v sqlite3 &> /dev/null; then
    echo "sqlite3 could not be found, please install sqlite3 first."
    exit 1
fi

# Check if database file exists, if not, create it
if [ ! -f "$DB_FILE" ]; then
    sqlite3 "$DB_FILE" "VACUUM;"
    echo "Database file created: $DB_FILE"
    # Optionally initialize the database here
    # python3 "$BACKEND_DIR/init_database.py"
fi

# Function to check if a process is running
is_process_running() {
    pgrep -f "$1" > /dev/null 2>&1
}

# Create tmux sessions and windows
# Frontend Session
if ! tmux has-session -t frontendSession 2>/dev/null; then
    tmux new-session -d -s frontendSession -n frontend "cd $FRONTEND_DIR && npm start"
fi

# Backend Session
if ! tmux has-session -t backendSession 2>/dev/null; then
    tmux new-session -d -s backendSession -n backend "cd $BACKEND_DIR && source $BACKEND_DIR/venv/bin/activate && zsh"
    tmux send-keys -t backendSession:backend "python3 flask_server.py" C-m
    tmux new-window -t backendSession -n logs "tail -f $LOG_FILE"
fi

# Database Session
if ! tmux has-session -t databaseSession 2>/dev/null; then
    tmux new-session -d -s databaseSession -n sqlite "sqlite3 $DB_FILE"
fi

# Frontend Session Handling
if tmux has-session -t frontendSession 2>/dev/null; then
    if ! is_process_running "node.*react-scripts start"; then
        echo "React development server is not running"
    fi
else
    echo "Tmux session 'frontendSession' not found."
fi

# Backend Session Handling
if tmux has-session -t backendSession 2>/dev/null; then
    if ! is_process_running "python3.*flask_server.py"; then
        echo "Flask server is not running"
    fi
else
    echo "Tmux session 'backendSession' not found."
fi

# Database Session Handling
if tmux has-session -t databaseSession 2>/dev/null; then
    if ! is_process_running "sqlite3.*database.db"; then
        echo "No active SQLite connection found"
    fi
else
    echo "Tmux session 'databaseSession' not found."
fi

echo "All sessions and windows have been created or already exist. Use 'tmux attach-session -t frontendSession' or other session names to connect."
