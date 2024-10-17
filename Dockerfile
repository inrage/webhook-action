FROM alpine

RUN apk add --no-cache bash curl openssl xxd jq jo

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
