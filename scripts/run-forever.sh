#!/bin/sh
set -eu

if [ -f .env ]; then
  set -a
  . ./.env
  set +a
fi

RESTART_DELAY="${RESTART_DELAY:-10}"
case "$RESTART_DELAY" in ''|*[!0-9]*) echo 'RESTART_DELAY must be a non-negative integer.' >&2; exit 2;; esac

while :; do
  date +%s > /tmp/ffmpeg-heartbeat
  (
    while :; do date +%s > /tmp/ffmpeg-heartbeat; sleep 20; done
  ) &
  heartbeat_pid=$!

  set +e
  sh scripts/start-live.sh
  status=$?
  set -e
  kill "$heartbeat_pid" 2>/dev/null || true
  wait "$heartbeat_pid" 2>/dev/null || true
  rm -f /tmp/ffmpeg-heartbeat

  echo "FFmpeg exited (status $status); reconnecting in ${RESTART_DELAY}s." >&2
  sleep "$RESTART_DELAY"
done
