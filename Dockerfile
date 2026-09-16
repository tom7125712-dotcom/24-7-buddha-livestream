FROM alpine:3.21

RUN apk add --no-cache ffmpeg tini

WORKDIR /app
COPY . .
RUN chmod +x scripts/*.sh

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["sh", "scripts/run-forever.sh"]
