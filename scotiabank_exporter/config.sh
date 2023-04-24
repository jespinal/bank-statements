#!/usr/bin/env bash
#

ENDPOINT_URL="https://banking.online.scotiabank.com/account/api/creditcards"

# Credit card ID (available via web portal)
CREDITCARD_ID="13139574-8bc2-4968-989g-19g16b679bbeDOP0";
FROM_DATE="2023-04-21"
TO_DATE="2023-04-24"

# There's really no reason to modify these lines unless you know exactly what
# you are doing
TRANSACTIONS_DUMP="./reports/transactions-${FROM_DATE}-to-${TO_DATE}_${UNIQUE_ID}.json"
DOP_REPORT="./reports/transactions-DOP-report-${FROM_DATE}-to-${TO_DATE}_${UNIQUE_ID}.csv"
USD_REPORT="./reports/transactions-USD-report-${FROM_DATE}-to-${TO_DATE}_${UNIQUE_ID}.csv"

read -r -d '' COOKIE <<COOKIE_CONTENT
# cookie content goes here
COOKIE_CONTENT
