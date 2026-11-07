#!/data/data/com.termux/files/usr/bin/sh
# Back up this Pi Pocket instance into the private pi-pocket-backup repo.
# This script holds no secrets, so it can live in the code repo.
# The backup repo itself MUST stay private: database, tokens, API keys.
set -u

DATA="$HOME/.pi-pocket"
BOOT="$HOME/.termux/boot"
CODE="$HOME/pi-pocket"
WORK="$HOME/pi-pocket-backup"
REMOTE="https://github.com/stilllostinla/pi-pocket-backup.git"
SNAP="$WORK/instance"

if ! command -v sqlite3 >/dev/null 2>&1; then
  echo "need sqlite3: pkg install sqlite" >&2
  exit 1
fi

if [ ! -d "$WORK/.git" ]; then
  echo "cloning backup repo..."
  git clone "$REMOTE" "$WORK" 2>/dev/null || mkdir -p "$WORK"
  git -C "$WORK" rev-parse --git-dir >/dev/null 2>&1 \
    || { git init -b main "$WORK" && git -C "$WORK" remote add origin "$REMOTE"; }
fi

mkdir -p "$SNAP"

# Consistent database snapshot while the server keeps running.
if ! sqlite3 "$DATA/pocket.sqlite" ".backup '$SNAP/pocket.sqlite'" 2>/dev/null; then
  cp "$DATA/pocket.sqlite" "$SNAP/pocket.sqlite" 2>/dev/null || true
fi

# Settings and content. Never sockets, locks, or write-ahead leftovers.
for f in config.json launcher.json push.json; do
  [ -f "$DATA/$f" ] && cp "$DATA/$f" "$SNAP/$f"
done
for d in extensions themes gallery; do
  if [ -d "$DATA/$d" ]; then
    rm -rf "$SNAP/$d"
    cp -r "$DATA/$d" "$SNAP/$d"
  fi
done
rm -f "$SNAP"/*.shm "$SNAP"/*.wal "$SNAP"/*.sock \
      "$SNAP"/harness.lock "$SNAP"/harness.lock.identity 2>/dev/null || true
# Reinstallable bulk never belongs in a backup.
find "$SNAP" -name node_modules -type d -prune -exec rm -rf {} + 2>/dev/null || true

# Termux setup: boot scripts only, never the boot log.
mkdir -p "$SNAP/termux-boot"
rm -f "$SNAP"/termux-boot/*.sh 2>/dev/null || true
cp "$BOOT"/start-*.sh "$SNAP/termux-boot/" 2>/dev/null || true

# Which code this data belongs to, and how the service looked.
git -C "$CODE" rev-parse HEAD >"$SNAP/pi-pocket.rev" 2>/dev/null || true
export SVDIR="/data/data/com.termux/files/usr/var/service"
sv status pi-pocket >"$SNAP/service-status.txt" 2>/dev/null || true

date -u +"backup: %Y-%m-%d %H:%M UTC" >"$SNAP/BACKED_UP.txt"

cd "$WORK" || exit 1
git add -A
if git diff --cached --quiet; then
  echo "nothing new to back up"
  exit 0
fi
git commit -q -m "backup $(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  && git push -q -u origin HEAD:main 2>&1 | tail -n 3
echo "backup pushed"
