#!/data/data/com.termux/files/usr/bin/sh
# Termux:Boot script — Pi Pocket on port 8788, with wake lock and crash restarts.
# Needs the Termux:Boot app (open it once) and the termux-services package.
# Files in ~/.termux/boot/ run in sorted order.

export PATH="/data/data/com.termux/files/usr/bin:$HOME/.local/bin:$PATH"
export HOME="${HOME:-/data/data/com.termux/files/home}"
export TERM="${TERM:-xterm-256color}"
export SVDIR="/data/data/com.termux/files/usr/var/service"
export LOGDIR="/data/data/com.termux/files/usr/var/log"

# Keep the CPU alive so Android doesn't kill the server right after boot.
termux-wake-lock 2>/dev/null || true

APP_ROOT="$HOME/pi-pocket"
SERVICE_SRC="$APP_ROOT/contrib/termux-services/pi-pocket"
SERVICE_DIR="$SVDIR/pi-pocket"
LOG="$HOME/.pi-pocket/boot.log"
mkdir -p "$HOME/.pi-pocket" 2>/dev/null

{
echo "=== boot $(date '+%Y-%m-%d %H:%M:%S') pi-pocket ==="

# Skip starting if it's already answering on 8788.
if command -v curl >/dev/null 2>&1; then
  if curl -s -m 3 -o /dev/null -w "%{http_code}" http://127.0.0.1:8788/ 2>/dev/null | grep -q "200"; then
    echo "pi-pocket already running on :8788"
    echo "=== boot done ==="
    exit 0
  fi
fi

# Supervised path: runit restarts it on crash.
if [ -d "$SERVICE_SRC" ] && command -v service-daemon >/dev/null 2>&1; then
  if [ ! -e "$SERVICE_DIR" ]; then
    ln -s "$SERVICE_SRC" "$SERVICE_DIR" 2>/dev/null \
      && echo "linked service: $SERVICE_DIR" \
      || echo "WARN: cannot link $SERVICE_DIR"
  fi
  service-daemon start >/dev/null 2>&1
  sv up pi-pocket >/dev/null 2>&1 || true
  sleep 3
  if curl -s -m 3 -o /dev/null -w "%{http_code}" http://127.0.0.1:8788/ 2>/dev/null | grep -q "200"; then
    echo "pi-pocket up on :8788 (supervised)"
    echo "=== boot done ==="
    exit 0
  fi
  echo "WARN: supervised start did not answer; falling through"
fi

# Fallback: one-shot start when the supervisor is unavailable.
if [ ! -d "$APP_ROOT" ]; then
  echo "WARN: $APP_ROOT missing, skipping pi-pocket start"
  echo "=== boot done ==="
  exit 0
fi
echo "starting pi-pocket on :8788 (unsupervised fallback)..."
cd "$APP_ROOT" || exit 0
# nohup so it survives the boot handler finishing.
nohup npm start -- --port 8788 >>"$LOG" 2>&1 &
echo "pi-pocket start issued (pid $!)"
echo "=== boot done ==="
} >>"$LOG" 2>&1

exit 0
