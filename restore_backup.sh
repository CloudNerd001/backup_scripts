#!/bin/bash


BACKUP_DIR="$HOME/MySQL_Backups"
DB_NAME="my_first_db"
DB_USER="root"

echo "Looking for backups in: $BACKUP_DIR"

# List all backup files
echo ""
echo "Available backups:"
ls -lh "$BACKUP_DIR"/*.sql 2>/dev/null

# Find the latest backup (by filename with date)
LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/*.sql 2>/dev/null | head -1)

if [ -z "$LATEST_BACKUP" ]; then
    echo ""
    echo "❌ No backup files found in $BACKUP_DIR!"
    echo ""
    echo "Your backups might be in a different location."
    echo "Try: find ~ -name '*.sql' 2>/dev/null"
    exit 1
fi

echo ""
echo "📂 Latest backup found: $LATEST_BACKUP"
echo "📊 File size: $(du -h "$LATEST_BACKUP" | cut -f1)"

# Ask for confirmation
echo ""
read -p "This will OVERWRITE database '$DB_NAME'. Continue? (y/n): " CONFIRM

if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
    echo "❌ Restore cancelled."
    exit 0
fi

# Restore
echo ""
echo "🗑️  Dropping existing database (if it exists)..."
sudo mysql -u "$DB_USER" -e "DROP DATABASE IF EXISTS $DB_NAME;"

echo "🆕 Creating fresh database: $DB_NAME..."
sudo mysql -u "$DB_USER" -e "CREATE DATABASE $DB_NAME;"

echo "🔄 Restoring from backup..."
sudo mysql -u "$DB_USER" "$DB_NAME" < "$LATEST_BACKUP"

if [ $? -eq 0 ]; then
    echo "✅ Restore completed successfully!"
    echo ""
    echo "📊 Restored data preview:"
    sudo mysql -u "$DB_USER" -e "USE $DB_NAME; SELECT * FROM users;"
else
    echo "❌ Restore failed!"
    exit 1
fi
