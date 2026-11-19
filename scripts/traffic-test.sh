#!/bin/bash

# ==========================================
# SRE PROJECT - TRAFFIC GENERATOR
# ==========================================

URL="http://localhost:5000"

# Test configuration
SUCCESS_REQUESTS=20
MAX_NUM=10
MIN_NUM=1

INTERVAL=5

echo "Starting Flask traffic generator..."
echo "Press Ctrl+C to stop."
echo ""

while true; do
    ERROR_REQUESTS=$((MIN_NUM + RANDOM % (MAX_NUM - MIN_NUM + 1)))
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
    echo "================================="
    echo "Generating $ERROR_REQUESTS errors"
    echo "================================="
    for ((i=1; i<=ERROR_REQUESTS; i++)); do
        curl -s -o /dev/null http://localhost:5000/error
        echo "Generating HTTP 500 errors..."
    done

    echo ""
    echo "Test cycle completed!"
    echo "Waiting $INTERVAL seconds..."
    echo ""

    sleep "$INTERVAL"

done
