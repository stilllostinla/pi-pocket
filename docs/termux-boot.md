# Running Pi Pocket at boot on Android (Termux:Boot)

Pi Pocket ships a Termux:Boot script at
[`contrib/termux-boot/start-pi-pocket.sh`](../contrib/termux-boot/start-pi-pocket.sh).
It grabs a wake lock so Android does not kill the server, then starts
Pi Pocket on port 8788 if it is not already answering there.

## New phone: bring it with you

1. Set up Pi Pocket once ([README](../README.md#quick-start), Android section):
   ```bash
   pkg update && pkg upgrade && pkg install nodejs git curl
   git clone https://github.com/TannerMidd/pi-pocket.git
   cd pi-pocket && npm install --ignore-scripts
   ```
2. Install the [Termux:Boot app](https://f-droid.org/packages/com.termux.boot/)
   and open it once, so Android allows boot scripts to run.
3. Copy the script into place:
   ```bash
   mkdir -p ~/.termux/boot
   cp contrib/termux-boot/start-pi-pocket.sh ~/.termux/boot/
   chmod +x ~/.termux/boot/start-pi-pocket.sh
   ```
4. Start it now (the same command the boot script runs):
   ```bash
   termux-wake-lock
   npm start -- --port 8788
   ```
5. Optional, recommended: enable crash restarts and restore your data:
   ```bash
   pkg install -y termux-services sqlite
   ln -s ~/pi-pocket/contrib/termux-services/pi-pocket $PREFIX/var/service/pi-pocket
   service-daemon start && sv up pi-pocket
   git clone https://github.com/stilllostinla/pi-pocket-backup.git ~/pi-pocket-backup
   # copy instance/* back to ~/.pi-pocket while the server is stopped, then start it
   ```

Reboot to test: `curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8788/`
should print `200`, and `~/.pi-pocket/boot.log` gets one `=== boot ... ===`
block per boot.

## Notes

- The port is 8788 in the script (the default is 8787). Edit the
  `--port 8788` in both the `curl` check and the `npm start` line to change it.
- The wake lock does not survive a reboot; the script re-acquires it every
  boot with `termux-wake-lock`.
- Termux:Boot runs every file in `~/.termux/boot/` in sorted order. Keep logs
  out of that folder (this script logs to `~/.pi-pocket/boot.log`), so the
  logger output is never executed as a script.
## Crash restarts (termux-services)

Termux:Boot only starts the server once. For restarts on crash, the repo
ships a supervised service in [`contrib/termux-services/pi-pocket/`](../contrib/termux-services/pi-pocket/)
(`run` + `log/run` via `svlogger`, same layout as the `sshd` service):

```bash
pkg install -y termux-services
ln -s ~/pi-pocket/contrib/termux-services/pi-pocket $PREFIX/var/service/pi-pocket
termux-wake-lock
service-daemon start
sv up pi-pocket
sv status pi-pocket   # should print: run: pi-pocket: (pid N) ...
```

The service definition is a symlink into this repo, so it travels with
`git` like everything else. The boot script above already prefers this
supervised path and only falls back to a one-shot `npm start` when the
supervisor is missing. Logs go to `$PREFIX/var/log/sv/pi-pocket/`.

## Full-instance backup (private repo)

Code is backed up by pushing this repo. The database, settings, and
uploads live outside it in `~/.pi-pocket`, so the repo also ships
[`contrib/backup/backup.sh`](../contrib/backup/backup.sh): a consistent
`sqlite3 .backup` snapshot plus configs, extensions, themes, gallery, and
boot scripts, pushed to a **private** backup repo
(`pi-pocket-backup`). Install and run it with:

```bash
ln -s ~/pi-pocket/contrib/backup/backup.sh ~/.local/bin/pi-pocket-backup
pi-pocket-backup
```

The backup repo must stay private: it holds the owner token, API keys,
and session contents. Never push `~/.pi-pocket` to the public code repo.
