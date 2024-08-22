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
    if ps aux | grep "$1" | grep -v grep > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}



# Create tmux sessions and windows
# Frontend Session
if ! tmux has-session -t frontendSession 2>/dev/null; then
    tmux new-session -d -s frontendSession -n frontend "cd $FRONTEND_DIR && npm start"
fi

# Backend Session
if ! tmux has-session -t backendSession 2>/dev/null; then
    tmux new-session -d -s backendSession -n backend "cd $BACKEND_DIR; source venv/bin/activate; python3 flask_server.py"
fi

# Database Session
if ! tmux has-session -t databaseSession 2>/dev/null; then
    tmux new-session -d -s databaseSession -n database "sqlite3 $DB_FILE"
fi

echo "Waiting for sessions to start..."
sleep 1

# Frontend Session Handling
if tmux has-session -t frontendSession 2>/dev/null; then
    if is_process_running "[n]ode.*react-scripts start"; then
        echo "React development server is running"
    else
        echo "React development server is not running"
    fi
else
    echo "Tmux session 'frontendSession' not found."
fi

# Backend Session Handling
if tmux has-session -t backendSession 2>/dev/null; then
    if is_process_running "[p]ython.*flask_server.py"; then
        echo "Flask server is running"
    else
        echo "Flask server is not running"
    fi
else
    echo "Tmux session 'backendSession' not found."
fi

# Database Session Handling
if tmux has-session -t databaseSession 2>/dev/null; then
    if is_process_running "[s]qlite3.*database.db"; then
        echo "SQLite database is running"
    else
        echo "SQLite database is not running"
    fi
else
    echo "Tmux session 'databaseSession' not found."
fi

echo "Use 'tmux attach -t frontendSession' or other session names to connect."
