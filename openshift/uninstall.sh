#!/bin/bash

# Uninstall script for Active Directory Demo on OpenShift
# Deletes YAML files in reverse order based on their numeric prefix

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "Uninstalling Active Directory Demo from OpenShift..."
echo "===================================================="
echo ""

# Get all YAML files starting with numbers, sorted numerically in reverse
# Use process substitution to handle filenames with spaces
while IFS= read -r yaml_file; do
    if [ -z "$yaml_file" ]; then
        continue
    fi
    
    filename=$(basename "$yaml_file")
    echo "Deleting resources from $filename..."
    oc delete -f "$yaml_file" --ignore-not-found=true
    
    if [ $? -eq 0 ]; then
        echo "✓ Successfully deleted resources from $filename"
    else
        echo "✗ Failed to delete resources from $filename"
        exit 1
    fi
    echo ""
done < <(find "$SCRIPT_DIR" -maxdepth 1 -name "[0-9][0-9]-*.yaml" -type f | sort -Vr)

# Check if any files were processed
if [ ! -f "$SCRIPT_DIR"/[0-9][0-9]-*.yaml ] 2>/dev/null; then
    echo "Error: No YAML files found matching pattern [0-9][0-9]-*.yaml"
    exit 1
fi

echo "===================================================="
echo "Uninstallation complete!"
echo ""
echo "To verify removal, run:"
echo "  oc get all -n ad"
echo "  oc get namespace ad"

# Made with Bob
