#!/bin/bash
BACKUP_DIR="$HOME/MySQL_Backups"
DB_NAME="my_first_db"
DB_USER="root"
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_backup_$DATE.sql"

mkdir -p "$BACKUP_DIR"

echo "Backing up $DB_NAME to $BACKUP_FILE ..."

sudo mysqldump -u "$DB_USER" "$DB_NAME" > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
	echo "Backup Successful!"
	echo "File: $BACKUP_FILE"
ls -lh "$BACKUP_FILE"
else
	echo "Backup Failed!!"
fi

