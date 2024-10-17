#!/bin/bash

if [ -n "$INPUT_WEBHOOK_PRODUCTION" ]; then
    webhook_url=$INPUT_WEBHOOK_PRODUCTION
elif [ -n "$WEBHOOK_PRODUCTION" ]; then
    webhook_url=$WEBHOOK_PRODUCTION
fi

if [ -z "$webhook_url" ]; then
    echo "No webhook_url configured"
    exit 1
fi

echo "response-body=$(webhook_url)" >> "$GITHUB_OUTPUT"

exit 0
