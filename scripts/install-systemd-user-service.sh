#!/bin/sh
set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
service_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
mkdir -p "$service_dir"

cat > "$service_dir/buddha-livestream.service" <<EOF
[Unit]
Description=24/7 Buddha music livestream
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$project_dir
ExecStart=/usr/bin/docker compose up --build
ExecStop=/usr/bin/docker compose down
Restart=always
RestartSec=15

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now buddha-livestream
echo 'Installed buddha-livestream. Check it with: systemctl --user status buddha-livestream'
