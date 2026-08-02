# Scheduling on Linux (cron)

The runners are plain shell scripts, so cron works fine.

```bash
crontab -e
```

```cron
# Daily discovery at 10:00
0 10 * * *  CONFIG=/path/to/config.yml /path/to/product-discovery-agents/scripts/run_daily.sh

# Weekly digest on Friday at 12:05
5 12 * * 5  CONFIG=/path/to/config.yml /path/to/product-discovery-agents/scripts/run_weekly.sh
```

Two things that bite people:

- **cron has almost no PATH.** The scripts set a sane one, but if `claude` lives somewhere
  unusual, add it explicitly at the top of the crontab: `PATH=/usr/local/bin:/usr/bin:/bin:/home/you/.local/bin`
- **cron does not load your shell profile**, so anything your Claude Code login depends on must
  be available non-interactively. Test with `env -i /path/to/scripts/run_daily.sh` before
  trusting the schedule.

## systemd timer

If you prefer timers, the same two commands work as `ExecStart=` in a service unit with a
matching `.timer`. Use `Persistent=true` so a missed run fires when the machine wakes — though
the ledger already makes missed runs self-healing.
