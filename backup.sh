file="${EPOCHSECONDS}.sql"
pg_dump -U pxlshpr prep > $file
echo "💾 Backup saved to: ${file}"
