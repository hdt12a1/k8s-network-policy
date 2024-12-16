#!/bin/bash

# This script helps maintain the network policy diagrams

# Set up error handling
set -e

# Get the absolute path of the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
IMAGES_DIR="$PROJECT_ROOT/images"
DOCS_DIR="$PROJECT_ROOT"

# Check for required commands
if ! command -v mmdc &> /dev/null; then
    echo "Error: mmdc (Mermaid CLI) is not installed"
    echo "Please install it using: npm install -g @mermaid-js/mermaid-cli"
    exit 1
fi

# Create images directory if it doesn't exist
mkdir -p "$IMAGES_DIR"

# Function to convert a single Mermaid diagram to PNG
convert_diagram() {
    local name=$1
    local diagram=$2
    local output_file="$IMAGES_DIR/policy${name}.png"
    
    echo "Converting diagram ${name} to ${output_file}"
    
    # Create a temporary file for the Mermaid content
    local temp_file=$(mktemp)
    echo -e "$diagram" > "$temp_file"
    
    # Convert to PNG using mmdc
    mmdc -i "$temp_file" -o "$output_file" -b transparent
    
    # Clean up
    rm "$temp_file"
    
    echo "Created: $output_file"
}

# Process the markdown file and extract diagrams
process_markdown() {
    local md_file="$DOCS_DIR/network-policy-flows.md"
    local current_diagram=""
    local diagram_count=0
    local in_diagram=false
    
    echo "Processing $md_file..."
    
    while IFS= read -r line; do
        if [[ $line == '```mermaid' ]]; then
            in_diagram=true
            current_diagram=""
            ((diagram_count++))
        elif [[ $line == '```' && $in_diagram == true ]]; then
            in_diagram=false
            convert_diagram "$diagram_count" "$current_diagram"
        elif [[ $in_diagram == true ]]; then
            current_diagram+="$line"$'\n'
        fi
    done < "$md_file"
}

echo "Starting diagram generation..."
process_markdown

echo "Done! Generated diagrams in: $IMAGES_DIR"
echo "Please check the quality of the generated images."
