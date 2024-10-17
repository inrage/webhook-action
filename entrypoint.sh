#!/bin/sh -l

if [ -n "$INPUT_WEBHOOK_PRODUCTION" ]; then
    webhook_url=$INPUT_WEBHOOK_PRODUCTION
elif [ -n "$WEBHOOK_PRODUCTION" ]; then
    webhook_url=$WEBHOOK_PRODUCTION
fi

# If the current branch is the same as $INPUT_RELEASE_BRANCH, use the release webhook if defined
if [ -n "$INPUT_RELEASE_BRANCH" ] && [ "$GITHUB_REF" = "refs/heads/$INPUT_RELEASE_BRANCH" ]; then
    if [ -n "$INPUT_WEBHOOK_RELEASE" ]; then
        webhook_url=$INPUT_WEBHOOK_RELEASE
    fi
fi

if [ -z "$webhook_url" ]; then
    echo "No webhook_url configured"
    exit 1
fi

if [ -n "$INPUT_SILENT" ]; then
    silent=$INPUT_SILENT
elif [ -n "$SILENT" ]; then
    silent=$SILENT
fi

REQUEST_ID=$(cat /dev/urandom | tr -dc '0-9a-f' | fold -w 32 | head -n 1)
EVENT_NAME=$GITHUB_EVENT_NAME

if [ "$silent" != true ]; then
    echo "Webhook Request ID: $REQUEST_ID"
fi

WEBHOOK_DATA=$(jo event="$EVENT_NAME" repository="$GITHUB_REPOSITORY" commit="$GITHUB_SHA" ref="$GITHUB_REF" head="$GITHUB_HEAD_REF" workflow="$GITHUB_WORKFLOW")
WEBHOOK_DATA=$(jq -s '.[0] * .[1]' <(echo $WEBHOOK_DATA) <(jo requestID="$REQUEST_ID"))

WEBHOOK_SIGNATURE=$(echo -n "$WEBHOOK_DATA" | openssl dgst -sha1 -hmac "$webhook_secret" -binary | xxd -p)
WEBHOOK_SIGNATURE_256=$(echo -n "$WEBHOOK_DATA" | openssl dgst -sha256 -hmac "$webhook_secret" -binary | xxd -p |tr -d '\n')
WEBHOOK_ENDPOINT=$webhook_url

options="--http1.1 --fail-with-body"

if [ "$verbose" = true ]; then
    options="$options -v"
    options="$options -sS"
elif [ "$silent" = true ]; then
    options="$options -s"
else
    options="$options -sS"
fi

if [ "$verbose" = true ]; then
    echo "curl $options \\"
    echo "-H 'Content-Type: $CONTENT_TYPE' \\"
    echo "-H 'User-Agent: GitHub-Hookshot/760256b' \\"
    echo "-H 'X-Hub-Signature: sha1=$WEBHOOK_SIGNATURE' \\"
    echo "-H 'X-Hub-Signature-256: sha256=$WEBHOOK_SIGNATURE_256' \\"
    echo "-H 'X-GitHub-Delivery: $REQUEST_ID' \\"
    echo "-H 'X-GitHub-Event: $EVENT_NAME' \\"
    echo "--data '$WEBHOOK_DATA'"
fi

set +e

response=$(curl $options \
    -H "Content-Type: $CONTENT_TYPE" \
    -H "User-Agent: GitHub-Hookshot/760256b" \
    -H "X-Hub-Signature: sha1=$WEBHOOK_SIGNATURE" \
    -H "X-Hub-Signature-256: sha256=$WEBHOOK_SIGNATURE_256" \
    -H "X-GitHub-Delivery: $REQUEST_ID" \
    -H "X-GitHub-Event: $EVENT_NAME" \
    --data "$WEBHOOK_DATA" \
    "$WEBHOOK_ENDPOINT")

CURL_STATUS=$?

# echo "response-body=$response" >> $GITHUB_OUTPUT
echo "response-body<<$REQUEST_ID" >> $GITHUB_OUTPUT
echo "$response" >> $GITHUB_OUTPUT
echo "$REQUEST_ID" >> $GITHUB_OUTPUT

if [ "$verbose" = true ]; then
    echo "Webhook Response [$CURL_STATUS]:"
    echo "${response}"
fi

exit $CURL_STATUS
