#!/bin/bash

BUCKET="redmine-backups-20260218124929600400000001"
echo "Backup Bot started. Target: $BUCKET"

while true; do
    echo "Creating backup..."
    
    # Filename with date
    FILE="backup_$(date +%Y%m%d_%H%M%S).sql.gz"
    
    # Dump DB and upload to S3
    PGPASSWORD=$POSTGRES_PASSWORD pg_dump -h redmine_db -U $POSTGRES_USER $POSTGRES_DB | gzip | aws s3 cp - s3://$BUCKET/$FILE
    
    echo "Backup $FILE uploaded. Sleeping for 24 hours..."
    
    # 1 day interval
    sleep 86400
done
