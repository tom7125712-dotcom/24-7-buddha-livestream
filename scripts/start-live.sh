#!/bin/sh
set -eu

IMAGE_FILE="${IMAGE_FILE:-assets/background.png}"
AUDIO_FILE="${AUDIO_FILE:-assets/music.mp3}"
WIDTH="${WIDTH:-1920}"
HEIGHT="${HEIGHT:-1080}"
FPS="${FPS:-30}"
VIDEO_BITRATE="${VIDEO_BITRATE:-3500k}"
AUDIO_BITRATE="${AUDIO_BITRATE:-192k}"

if [ -n "${FULL_RTMP_URL:-}" ]; then
  OUTPUT_URL="$FULL_RTMP_URL"
else
  if [ -z "${RTMP_URL:-}" ] || [ -z "${STREAM_KEY:-}" ]; then
    echo 'Set FULL_RTMP_URL or both RTMP_URL and STREAM_KEY.' >&2
    exit 2
  fi
  OUTPUT_URL="${RTMP_URL%/}/$STREAM_KEY"
fi

test -f "$IMAGE_FILE" || { echo "Image not found: $IMAGE_FILE" >&2; exit 2; }
test -f "$AUDIO_FILE" || { echo "Audio not found: $AUDIO_FILE" >&2; exit 2; }

case "$FPS" in ''|*[!0-9]*) echo 'FPS must be a positive integer.' >&2; exit 2;; esac
case "$WIDTH,$HEIGHT" in *[!0-9,]*|,*) echo 'WIDTH and HEIGHT must be positive integers.' >&2; exit 2;; esac

GOP_SIZE=$((FPS * 2))
BITRATE_NUMBER=${VIDEO_BITRATE%k}
case "$BITRATE_NUMBER" in ''|*[!0-9]*) echo 'VIDEO_BITRATE must use the form 3500k.' >&2; exit 2;; esac
BUF_SIZE="$((BITRATE_NUMBER * 2))k"

echo "Starting ${WIDTH}x${HEIGHT}/${FPS}fps livestream (RTMP target redacted)."

exec ffmpeg \
  -hide_banner -nostdin -loglevel warning -stats \
  -re -loop 1 -framerate "$FPS" -i "$IMAGE_FILE" \
  -stream_loop -1 -re -i "$AUDIO_FILE" \
  -map 0:v:0 -map 1:a:0 \
  -vf "scale=${WIDTH}:${HEIGHT}:force_original_aspect_ratio=decrease:force_divisible_by=2,pad=${WIDTH}:${HEIGHT}:(ow-iw)/2:(oh-ih)/2:color=black,format=yuv420p" \
  -c:v libx264 -preset veryfast -tune stillimage \
  -b:v "$VIDEO_BITRATE" -maxrate "$VIDEO_BITRATE" -bufsize "$BUF_SIZE" \
  -g "$GOP_SIZE" -keyint_min "$GOP_SIZE" -sc_threshold 0 \
  -c:a aac -b:a "$AUDIO_BITRATE" -ar 48000 -ac 2 \
  -af aresample=async=1:first_pts=0 \
  -flvflags no_duration_filesize \
  -f flv "$OUTPUT_URL"
