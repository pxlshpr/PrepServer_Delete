unixtime=$(date +%s)
cd /home/ahmed/PrepBackups
file="prep-backup-${unixtime}.sql"
pg_dump -U pxlshpr prep > $file
echo "         💾 Backup saved to: ${file}"
git add .
git commit -a -m "added backup"
git push
