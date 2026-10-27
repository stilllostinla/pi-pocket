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
- Files in `~/.termux/boot/` are outside this repo and do not transfer with
  `git clone`. The copy in `contrib/termux-boot/` is the backup: copy it back
  as in step 3 on each new phone.
