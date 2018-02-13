#!/bin/bash

DATABASE=heyloyalty
DATE=`date +"%Y%m%d"`
BUCKET="s3://hl-mysql-backup"
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

INCLUDE_TABLES=(
account_notes
accounts
api_credentials
applications
autoresponder_actions
autoresponder_index
autoresponder_intervals
autoresponder_messages
autoresponder_sent_by_date
autoresponder_webhook_data
begin_and_end_date
campaign_exports
campaign_intervals
campaigns
campaign_stat
campaign_tags
campaign_tag_values
countries
dashboard_messages
email_identities
email_messages
email_retentions
es_snapshots
export_jobs
failed_jobs
failed_webhooks
field_options
field_options_fixed
fields
field_types
files
filter_operators
filters
folders
identities
import_jobs
integrations
links
list_integrations
list_options
list_page_fields
list_pages
list_page_terms
lists
list_stats
litmus_test_images
litmus_tests
litmus_test_spam_filters
message_modules
messages
migrations
news
open_graphs
opt_in_fields
opt_in_pages
plan_limits
plans
product_feed_mappings
product_feeds
property_fields
queue_priorities
rendered_messages
reseller_plans
resellers
rss_feeds
segments
selected_webhook_triggers
shop_module_users
shops
shop_settings
shop_users
short_urls
system_languages
templates
test_list_recipients
test_lists
tests
test_sent_mails
test_sent_smss
timezones
trigger_actions
trigger_conditions
trigger_rules
trigger_settings
url_parameters
users
voucher_feeds
webhooks
)
for TABLE in "${INCLUDE_TABLES[@]}"
do :
   FILE=${TABLE}."sql.gz"
   TMP="${FILE}"
   OBJECT=${BUCKET}/"Dump"${DATE}/${FILE}
   DUMPERROR=/var/log/dumps/${TABLE}${DATE}"_dump_error.txt"
   S3ERROR=/var/log/dumps/${TABLE}${DATE}"_s3_error.txt"

   mysqldump ${DATABASE} ${TABLE} --lock-tables=FALSE 2> ${DUMPERROR} | gzip > ${TMP}
 
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
done