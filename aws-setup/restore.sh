#!/bin/bash

# ================================================
# PostgreSQL Database Restore Script
# Database: my-3mtt-db
# Supports restoring from local or S3 backups
# ================================================

# Configuration
DB_NAME="my-3mtt-db"
BACKUP_DIR="/home/ubuntu/PostgreSQL_Backups"
LOG_FILE="/var/log/postgres-restore.log"
S3_BUCKET="s3://my-3mtt-db-backups"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "PostgreSQL Database Restore Tool"
echo "Database: $DB_NAME"
echo "=========================================="
echo ""

# ================================================
# LIST AVAILABLE BACKUPS
# ================================================

echo -e "${YELLOW}📂 Local Backups:${NC}"
echo "----------------------------------------"

LOCAL_BACKUPS=()
index=1

if [ -d "$BACKUP_DIR" ]; then
    for file in $(ls -t "$BACKUP_DIR"/*.sql.gz 2>/dev/null); do
        filename=$(basename "$file")
        size=$(du -h "$file" | cut -f1)
        date=$(stat -c %y "$file" | cut -d' ' -f1)
        echo "  [$index] $filename ($size) - $date"
        LOCAL_BACKUPS+=("$file")
        ((index++))
    done
fi

if [ ${#LOCAL_BACKUPS[@]} -eq 0 ]; then
    echo "  ❌ No local backups found!"
fi

echo ""
echo -e "${YELLOW}📦 S3 Backups:${NC}"
echo "----------------------------------------"

# Check if AWS CLI is installed
if command -v aws &> /dev/null; then
    S3_BACKUPS=$(aws s3 ls "$S3_BUCKET/Automated_Backups/" 2>/dev/null | grep ".sql.gz" | awk '{print $4}' | nl)
    if [ -n "$S3_BACKUPS" ]; then
        echo "$S3_BACKUPS"
    else
        echo "  ❌ No S3 backups found!"
    fi
else
    echo "  ❌ AWS CLI not installed!"
fi

echo ""
echo "----------------------------------------"

# ================================================
# SELECT BACKUP SOURCE
# ================================================

echo ""
echo "Select backup source:"
echo "  1) Local backup"
echo "  2) S3 backup"
echo "  3) Cancel"
read -p "Enter your choice (1-3): " SOURCE_CHOICE

if [ "$SOURCE_CHOICE" == "3" ] || [ -z "$SOURCE_CHOICE" ]; then
    echo -e "${RED}❌ Restore cancelled.${NC}"
    exit 0
fi

# ================================================
# SELECT BACKUP FILE
# ================================================

BACKUP_FILE=""

if [ "$SOURCE_CHOICE" == "1" ]; then
    # Local backup
    if [ ${#LOCAL_BACKUPS[@]} -eq 0 ]; then
        echo -e "${RED}❌ No local backups available!${NC}"
        exit 1
    fi
    
    read -p "Enter the serial number to restore: " CHOICE
    
    if [ "$CHOICE" -le ${#LOCAL_BACKUPS[@]} ] && [ "$CHOICE" -gt 0 ]; then
        BACKUP_FILE="${LOCAL_BACKUPS[$CHOICE-1]}"
        echo -e "${GREEN}✅ Selected: $(basename "$BACKUP_FILE")${NC}"
    else
        echo -e "${RED}❌ Invalid selection!${NC}"
        exit 1
    fi

elif [ "$SOURCE_CHOICE" == "2" ]; then
    # S3 backup
    echo ""
    read -p "Enter the S3 backup filename (e.g., my-3mtt-db_backup_2026-08-17_14-21-38.sql.gz): " S3_FILE
    
    if [ -z "$S3_FILE" ]; then
        echo -e "${RED}❌ No filename provided!${NC}"
        exit 1
    fi
    
    # Download from S3
    echo -e "${YELLOW}📥 Downloading from S3...${NC}"
    aws s3 cp "$S3_BUCKET/Automated_Backups/$S3_FILE" "$BACKUP_DIR/"
    
    if [ $? -eq 0 ]; then
        BACKUP_FILE="$BACKUP_DIR/$S3_FILE"
        echo -e "${GREEN}✅ Downloaded: $S3_FILE${NC}"
    else
        echo -e "${RED}❌ Failed to download from S3!${NC}"
        exit 1
    fi
else
    echo -e "${RED}❌ Invalid choice!${NC}"
    exit 1
fi

# Verify backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo -e "${RED}❌ Backup file not found: $BACKUP_FILE${NC}"
    exit 1
fi

# ================================================
# CONFIRM RESTORE
# ================================================

echo ""
echo -e "${RED}⚠️  WARNING: This will OVERWRITE database '$DB_NAME'${NC}"
echo "Backup file: $(basename "$BACKUP_FILE")"
echo ""
read -p "Are you sure you want to continue? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo -e "${RED}❌ Restore cancelled.${NC}"
    exit 0
fi

# ================================================
# PERFORM RESTORE
# ================================================

echo ""
echo -e "${YELLOW}🔄 Restoring database...${NC}"

# Log the restore
echo "[$(date)] ==========================================" >> "$LOG_FILE"
echo "[$(date)] Starting restore from: $BACKUP_FILE" >> "$LOG_FILE"

# Drop database if exists
echo "🗑️  Dropping existing database..."
sudo -u postgres psql -c "DROP DATABASE IF EXISTS \"$DB_NAME\";" 2>&1 | tee -a "$LOG_FILE"

# Create fresh database
echo "🆕 Creating fresh database..."
sudo -u postgres psql -c "CREATE DATABASE \"$DB_NAME\";" 2>&1 | tee -a "$LOG_FILE"

# Restore from backup
echo "📥 Restoring data..."
if gunzip -c "$BACKUP_FILE" | sudo -u postgres psql "$DB_NAME" 2>&1 | tee -a "$LOG_FILE"; then
    echo -e "${GREEN}✅ Restore completed successfully!${NC}"
    echo "[$(date)] ✅ Restore completed successfully!" >> "$LOG_FILE"
    
    # Show restored data
    echo ""
    echo -e "${YELLOW}📊 Restored data preview:${NC}"
    echo "----------------------------------------"
    sudo -u postgres psql -d "$DB_NAME" -c "SELECT * FROM users;"
    
    echo "[$(date)] ==========================================" >> "$LOG_FILE"
else
    echo -e "${RED}❌ Restore failed! Check log: $LOG_FILE${NC}"
    echo "[$(date)] ❌ Restore failed!" >> "$LOG_FILE"
    echo "[$(date)] ==========================================" >> "$LOG_FILE"
    exit 1
fi
