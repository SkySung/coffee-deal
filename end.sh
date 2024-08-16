#!/bin/bash

# Get the absolute path of the directory containing this script
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Define absolute paths based on the script directory
DB_FILE="$SCRIPT_DIR/backend/database.db"
FRONTEND_DIR="$SCRIPT_DIR/frontend"
BACKEND_DIR="$SCRIPT_DIR/backend"

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

# Function to kill a process
kill_process() {
    pkill -f "$1"
    sleep 1  # 等待一段時間以確保進程停止
    if is_process_running "$1"; then
        echo "Failed to stop $2"
    else
        echo "Stopped $2"
    fi
}

# Function to kill a tmux session if it exists
kill_tmux_session() {
    local session_name="$1"
    if tmux has-session -t "$session_name" 2>/dev/null; then
        echo "Killing tmux session: $session_name"
        tmux kill-session -t "$session_name"
    else
        echo "No tmux session named $session_name found."
    fi
}

# Frontend Session Handling
if tmux has-session -t frontendSession 2>/dev/null; then
    # Stop React development server
    if is_process_running "node.*react-scripts start"; then
        kill_process "node.*react-scripts start" "React development server"
    else
        echo "React development server is not running"
    fi

    # Kill tmux session
    kill_tmux_session "frontendSession"
else
    echo "Tmux session 'frontendSession' not found."
fi

# Backend Session Handling
if tmux has-session -t backendSession 2>/dev/null; then
    # Stop Flask server
    if is_process_running "python3.*flask_server.py"; then
        kill_process "python3.*flask_server.py" "Flask server"
    else
        echo "Flask server is not running"
    fi

    # Kill tmux session
    kill_tmux_session "backendSession"
else
    echo "Tmux session 'backendSession' not found."
fi

# Database Session Handling
if tmux has-session -t databaseSession 2>/dev/null; then
    # Check if SQLite connection exists
    if is_process_running "sqlite3.*database.db"; then
        kill_process "sqlite3.*database.db" "SQLite connection"
    else
        echo "No active SQLite connection found"
    fi

    # Kill tmux session
    kill_tmux_session "databaseSession"
else
    echo "Tmux session 'databaseSession' not found."
fi

echo "All relevant sessions and processes have been handled."
