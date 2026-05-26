#!/bin/bash

# Install script for Active Directory Demo on OpenShift
# Applies YAML files in order based on their numeric prefix

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Installing Active Directory Demo to OpenShift..."
echo "================================================"
echo ""

# Get all YAML files starting with numbers, sorted numerically
# Use process substitution to handle filenames with spaces
while IFS= read -r yaml_file; do
    if [ -z "$yaml_file" ]; then
        continue
    fi
    
    filename=$(basename "$yaml_file")
    echo "Applying $filename..."
    oc apply -f "$yaml_file"
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully applied $filename"
    else
        echo "✗ Failed to apply $filename"
        exit 1
    fi
    echo ""
done < <(find "$SCRIPT_DIR" -maxdepth 1 -name "[0-9][0-9]-*.yaml" -type f | sort -V)

# Check if any files were processed
if [ ! -f "$SCRIPT_DIR"/[0-9][0-9]-*.yaml ] 2>/dev/null; then
    echo "Error: No YAML files found matching pattern [0-9][0-9]-*.yaml"
    exit 1
fi

echo "================================================"
echo "Installation complete!"
echo ""
echo "To check the deployment status, run:"
echo "  oc get all -n ad"
echo ""
echo "To view logs, run:"
echo "  oc logs -f deployment/activedirectory-demo -n ad"

# Made with Bob
