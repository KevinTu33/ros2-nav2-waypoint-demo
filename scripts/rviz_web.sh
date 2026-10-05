#!/usr/bin/env bash
set -euo pipefail

export DISPLAY=:1
export LIBGL_ALWAYS_SOFTWARE=1
export GALLIUM_DRIVER=llvmpipe
export QT_X11_NO_MITSHM=1
export XDG_RUNTIME_DIR=/tmp/runtime-root

mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"
source /opt/ros/jazzy/setup.bash

if pgrep -f '[w]ebsockify.*6080' >/dev/null; then
  exit 0
fi

if ! pgrep -x Xvfb >/dev/null; then
  Xvfb :1 -screen 0 1600x900x24 -ac +extension GLX +render -noreset \
    >/tmp/xvfb.log 2>&1 &
  sleep 2
fi

if ! pgrep -x openbox >/dev/null; then
  openbox >/tmp/openbox.log 2>&1 &
fi

if ! pgrep -x rviz2 >/dev/null; then
  rviz2 -d /opt/ros/jazzy/share/nav2_bringup/rviz/nav2_default_view.rviz \
    >/tmp/rviz2.log 2>&1 &
fi

if ! pgrep -x x11vnc >/dev/null; then
  x11vnc -display :1 -forever -shared -nopw -noxdamage \
    -listen 127.0.0.1 -rfbport 5900 >/tmp/x11vnc.log 2>&1 &
fi

exec websockify --web=/usr/share/novnc 0.0.0.0:6080 127.0.0.1:5900 \
  >/tmp/websockify.log 2>&1
