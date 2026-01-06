# Backups Directory

This directory contains backups of website files before deployment.

## Backup Naming Convention

```
<site-name>-<YYYYMMDD>-<HHMMSS>
```

Examples:
- `site1-20260106-143145/`
- `site2-20260106-143145/`

## Backup List

The file `backup_list.txt` contains paths to all created backups, one per line.

## Restoring from Backup

### Manual Restore

```bash
# List available backups
ls -lt backups/

# Restore Site 1
sudo cp -r backups/site1-YYYYMMDD-HHMMSS/* /var/www/site1/

# Restore Site 2
sudo cp -r backups/site2-YYYYMMDD-HHMMSS/* /var/www/site2/

# Fix permissions
sudo chown -R www-data:www-data /var/www/site1 /var/www/site2
sudo chmod -R 755 /var/www/site1 /var/www/site2
```

### Automated Restore Script

```bash
#!/bin/bash
# Quick restore from latest backup

SITE=$1  # site1 or site2
LATEST_BACKUP=$(ls -t backups/${SITE}-* 2>/dev/null | head -1)

if [[ -z "$LATEST_BACKUP" ]]; then
    echo "No backup found for $SITE"
    exit 1
fi

echo "Restoring from: $LATEST_BACKUP"
sudo cp -r "$LATEST_BACKUP"/* "/var/www/$(basename $LATEST_BACKUP | cut -d'-' -f1)/"
echo "Restore complete"
```

## Backup Retention

Backups are created automatically before each deployment. Clean up old backups manually:

```bash
# Remove backups older than 30 days
find backups/ -type d -mtime +30 -exec rm -rf {} +

# Keep only the last 5 backups
ls -t backups/site1-* | tail -n +6 | xargs rm -rf
```

## Backup Verification

```bash
# Check backup size
du -sh backups/site1-*

# Verify backup contents
ls -la backups/site1-YYYYMMDD-HHMMSS/

# Compare backup with current
diff -r backups/site1-YYYYMMDD-HHMMSS/ /var/www/site1/
```
