#!/bin/bash

# ==========================================
# SRE PROJECT - TRAFFIC GENERATOR
# ==========================================

URL="http://localhost:5000"

# Test configuration
SUCCESS_REQUESTS=20
ERROR_REQUESTS=5
INTERVAL=30

echo "Starting Flask traffic generator..."
echo "Press Ctrl+C to stop."
echo ""

while true; do

    echo "=================================="
    echo "Starting test at $(date)"
    echo "=================================="

    # Generate successful requests
    echo "Generating successful requests..."

    for ((i=1; i<=SUCCESS_REQUESTS; i++)); do
        curl -fsS --max-time 5 "$URL/store" > /dev/null || \
            echo "Request to /store failed"
    done

    # Generate HTTP 500 errors
    echo "Generating HTTP 500 errors..."

    for ((i=1; i<=ERROR_REQUESTS; i++)); do
        curl -s --max-time 5 -o /dev/null \
            -w "%{http_code}\n" "$URL/error"
    done

    echo ""
    echo "Test cycle completed!"
    echo "Waiting $INTERVAL seconds..."
    echo ""

    sleep "$INTERVAL"

done
