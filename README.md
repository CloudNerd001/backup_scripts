# MySQL Backup and Restore Scripts

Simple bash scripts to automate MySQL database backups and restores.

## Scripts

### backup_database.sh
Creates a timestamped backup of the `my_first_db` database.
- Saves to `~/MySQL_Backups/`
- Includes date/time in filename
- Shows success/failure status

### restore_backup.sh
Restores the database from the latest backup file.
- Finds the newest backup automatically
- Asks for confirmation before overwriting
- Shows restored data after completion

## Requirements

- MySQL 8.4+
- Bash
- Ubuntu 26.04 LTS

## Installation

Clone this repository:
\`\`\`bash
git clone https://github.com/CloudNerd001/backup_scripts.git
\`\`\`

Make scripts executable:
\`\`\`bash
chmod +x *.sh
\`\`\`

## Usage

\`\`\`bash
# Create a backup
./backup_database.sh

# Restore from latest backup
./restore_backup.sh
\`\`\`

## Author

CloudNerd001
