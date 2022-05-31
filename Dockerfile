FROM ghcr.io/lanelewis/exius:latest
COPY ["./rclone.conf","/root/.config/rclone/rclone.conf"]
