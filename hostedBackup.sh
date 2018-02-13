#!/bin/bash
# Backup a mysql database to s3

DATE=`date +"%Y%m%d"`
BUCKET="s3://hosted-mysql-backup"
function alertPagerDuty {

curl -H "Content-type: application/json" -X POST \
    -d '{    
      "service_key": "427a5560c3cc4086a6ceb7d4d936c671",
      "incident_key": "MySQL/BACKUP",
      "event_type": "trigger",
      "description": "'"$ERROR"' - '"${HOSTNAME}"'"
    }' \
    "https://events.pagerduty.com/generic/2010-04-15/create_event.json"

}


   FILE=${DATE}."sql.gz"
   TMP="${FILE}"
   OBJECT=${BUCKET}/"Dump"${DATE}/${FILE}
   DUMPERROR=/var/log/dumps/${DATE}"_dump_error.txt"
   S3ERROR=/var/log/dumps/${DATE}"_s3_error.txt"

   mysqldump  --all-databases--lock-tables=FALSE 2> ${DUMPERROR} | gzip > ${TMP}
   if [[ -s ${DUMPERROR} ]]; then
        ERROR="Mysqldump error in ${FILE}"
        alertPagerDuty
   fi

   s3cmd put "${TMP}" "${OBJECT}" 2> ${S3ERROR}
   if grep --quiet "/^\(.*Warning\)\@!.*$" ${S3ERROR}; then
        ERROR="S3 error in ${FILE}"
        alertPagerDuty
   fi
   rm -rf "${TMP}"
