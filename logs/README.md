# Logs Directory

This directory contains execution logs from deployment scripts.

## Log File Naming Convention

```
<script-number>-<script-name>-<YYYYMMDD>-<HHMMSS>.log
```

Examples:
- `01-install-nginx-20260106-143022.log`
- `02-deploy-websites-20260106-143145.log`
- `03-configure-virtual-hosts-20260106-143230.log`

## Log File Contents

Each log file contains:
- Timestamp for each operation
- Success/failure status
- Error messages and stack traces
- Command output
- Configuration values used

## Viewing Logs

```bash
# View most recent log
tail -f logs/$(ls -t logs/*.log | head -1)

# View specific script logs
tail -f logs/01-install-nginx-*.log

# Search for errors
grep -i error logs/*.log

# View all logs from today
grep -l "$(date +%Y-%m-%d)" logs/*.log | xargs tail -f
```

## Log Rotation

Logs are automatically created with timestamps. Clean up old logs manually:

```bash
# Remove logs older than 30 days
find logs/ -name "*.log" -mtime +30 -delete

# Archive old logs
tar -czf logs-archive-$(date +%Y%m%d).tar.gz logs/*.log
```

## Troubleshooting with Logs

When something goes wrong:
1. Check the most recent log file
2. Look for ERROR or WARNING messages
3. Check the line number where the error occurred
4. Review the command that failed
