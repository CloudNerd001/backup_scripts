#!/bin/bash

# ================================================
# PostgreSQL Database Backup Script
# Database: my-3mtt-db
# EC2 Instance: Ubuntu
# ================================================

# Configuration
DB_NAME="my-3mtt-db"
BACKUP_DIR="/home/ubuntu/PostgreSQL_Backups"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_backup_$TIMESTAMP.sql.gz"
LOG_FILE="/var/log/postgres-backup.log"
S3_BUCKET="s3://my-3mtt-db-backups"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Start logging
echo "[$(date)] ==========================================" >> "$LOG_FILE"
echo "[$(date)] Starting backup of $DB_NAME" >> "$LOG_FILE"

# Perform backup
if sudo -u postgres pg_dump "$DB_NAME" | gzip > "$BACKUP_FILE"; then
    echo "[$(date)] ✅ Backup created: $BACKUP_FILE" >> "$LOG_FILE"
    
    # Get backup size
    BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "[$(date)] 📊 Backup size: $BACKUP_SIZE" >> "$LOG_FILE"
    
    # Upload to S3
    echo "[$(date)] 📤 Uploading to S3..." >> "$LOG_FILE"
    aws s3 cp "$BACKUP_FILE" "$S3_BUCKET/Automated_Backups/" >> "$LOG_FILE" 2>&1
    
    if [ $? -eq 0 ]; then
        echo "[$(date)] ✅ Uploaded to S3 successfully!" >> "$LOG_FILE"
    else
        echo "[$(date)] ❌ S3 upload failed!" >> "$LOG_FILE"
    fi
    
    # Clean up old backups (keep last 7 days)
    echo "[$(date)] 🧹 Cleaning up backups older than 7 days..." >> "$LOG_FILE"
    find "$BACKUP_DIR" -name "*.sql.gz" -type f -mtime +7 -delete
    
    echo "[$(date)] ✅ Backup completed successfully!" >> "$LOG_FILE"
    echo "[$(date)] ==========================================" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    
    # Show success on terminal
    echo "✅ Backup completed: $(basename "$BACKUP_FILE")"
    echo "📊 Size: $BACKUP_SIZE"
    echo "📤 Uploaded to S3: my-3mtt-db-backups"
    
else
    echo "[$(date)] ❌ Backup failed!" >> "$LOG_FILE"
    echo "[$(date)] ==========================================" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "❌ Backup failed! Check log: $LOG_FILE"
    exit 1
fi

