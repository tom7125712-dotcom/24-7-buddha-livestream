#!/bin/sh
# Run a bounded segment on a GitHub-hosted runner.  The workflow dispatches
# its successor after this script returns, before the runner time limit.
set -eu

if [ -f .env ]; then
  set -a
  . ./.env
  set +a
fi

STREAM_MINUTES="${STREAM_MINUTES:-285}"
RESTART_DELAY="${RESTART_DELAY:-10}"
RESERVE_SECONDS="${RESERVE_SECONDS:-120}"

case "$STREAM_MINUTES,$RESTART_DELAY,$RESERVE_SECONDS" in
  *[!0-9,]*|,,*|,*|*,) echo 'Stream timing values must be non-negative integers.' >&2; exit 2 ;;
esac

deadline=$(( $(date +%s) + STREAM_MINUTES * 60 ))

while :; do
  now=$(date +%s)
  remaining=$(( deadline - now ))
  if [ "$remaining" -le "$RESERVE_SECONDS" ]; then
    echo 'Segment complete; reserving time to dispatch the successor.'
    exit 0
  fi

  # Leave a small margin so the next iteration can reconnect after an RTMP
  # failure without exceeding the segment deadline.
  DURATION_SECONDS=$(( remaining - RESERVE_SECONDS ))
  export DURATION_SECONDS

  set +e
  sh scripts/start-live.sh
  status=$?
  set -e
  echo "FFmpeg exited with status $status; reconnecting if segment time remains." >&2
  sleep "$RESTART_DELAY"
done
