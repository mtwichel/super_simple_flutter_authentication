#!/bin/bash

# Load environment variables from .demo.env
if [ -f ".demo.env" ]; then
    echo "Loading environment variables from .demo.env..."
    # Use a simple approach: source the file if it exists
    set -a  # automatically export all variables
    source .demo.env
    set +a  # turn off automatic export
    echo "Environment variables loaded successfully"
else
    echo "Warning: .demo.env file not found"
fi

# Run dart_frog dev
echo "Starting dart_frog dev..."
dart_frog dev -d 8183 -p 8083 
