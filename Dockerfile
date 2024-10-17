FROM alpine:3.10

COPY entrypoint.sh /entrypoint.sh

RUN cat /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
