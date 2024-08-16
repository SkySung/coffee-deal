#!/bin/bash

# Function to display usage information
show_usage() {
    echo "Usage: ./script_name.sh [depth]"
    echo "  [depth]: Optional. The number of levels to recurse into. Default is 3 if not provided."
    echo "  [depth] must be a positive integer."
    echo "A file named structure.txt will be generated with the directory structure."
}

# Check if help is requested
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    show_usage
    exit 0
fi

# Validate and set depth
if [ -z "$1" ]; then
    depth=2
elif [[ "$1" =~ ^[0-9]+$ ]]; then
    depth="$1"
else
    echo "Error: Invalid depth parameter. It must be a positive integer."
    show_usage
    exit 1
fi

# Function to print structure
print_structure() {
    local prefix="$1"
    local path="$2"
    local level="$3"
    local current_level="$4"

    if [ "$current_level" -ge "$level" ]; then
        return
    fi

    local entries=("$path"/*)
    local dirs=()
    local files=()

    # Separate directories and files
    for entry in "${entries[@]}"; do
        if [ -d "$entry" ]; then
            dirs+=("$entry")
        else
            files+=("$entry")
        fi
    done

    # Print directories first
    local count=${#dirs[@]}
    local i=0
    for entry in "${dirs[@]}"; do
        i=$((i + 1))
        local name=$(basename "$entry")
        local new_prefix="$prefix"

        if [ "$i" -eq "$count" ]; then
            echo "${prefix}└── $name"
            new_prefix="${prefix}    "
        else
            echo "${prefix}├── $name"
            new_prefix="${prefix}│   "
        fi

        print_structure "$new_prefix" "$entry" "$level" "$((current_level + 1))"
    done

    # Print files
    count=${#files[@]}
    i=0
    for entry in "${files[@]}"; do
        i=$((i + 1))
        local name=$(basename "$entry")
        if [ "$i" -eq "$count" ]; then
            echo "${prefix}└── $name"
        else
            echo "${prefix}├── $name"
        fi
    done
}

# Inform the user about the output file
echo "Generating directory structure and saving it to structure.txt."

# Redirect output to a file
{
    echo "my-project/"
    print_structure "    " "." "$depth" 0
} >structure.txt
