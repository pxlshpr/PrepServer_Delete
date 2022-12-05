unixtime=$(date +%s)
file="/home/ahmed/PrepBackups/prep-backup-${unixtime}.sql"
pg_dump -U pxlshpr prep > $file
echo "             💾 Backup saved to: ${file}"
