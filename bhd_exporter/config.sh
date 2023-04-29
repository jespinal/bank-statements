#!/usr/bin/env bash
#

BASE_URL="https://ib.bhd.com.do/IBPTheme/myservices/ibp/BHDLO_Back_Bancasa_ProductDetails/rest/productDetail"
TC_DETAILS_ENDPOINT_URL="${BASE_URL}/creditCards"
CA_DETAILS_ENDPOINT_URL="${BASE_URL}/savingAccounts"
TRANSACTIONS_ENDPOINT_URL="${BASE_URL}/detailTransactionHistory"

# Credit card ID (available via web portal)
PRODUCT_NUMBER="4111111111111111";

START_DATE="03/29/2023"
END_DATE="04/24/2023"

# TC/CA
# PRODUCT_TYPE="TC"
PRODUCT_TYPE="TC"

START_DATE_STR=$(date --date="${START_DATE}" +%F);
END_DATE_STR=$(date --date="${END_DATE}" +%F);

LAST_FOUR=${PRODUCT_NUMBER: -4}

# There's really no reason to modify these lines unless you know exactly what
# you are doing
DETAILS_DUMP="./reports/details-${LAST_FOUR}__${START_DATE_STR}-to-${END_DATE_STR}_${UNIQUE_ID}.json"
TRANSACTIONS_DUMP="./reports/transactions-${LAST_FOUR}__${START_DATE_STR}-to-${END_DATE_STR}_${UNIQUE_ID}.json"
DOP_REPORT="./reports/transactions-DOP-${LAST_FOUR}-report__${START_DATE_STR}-to-${END_DATE_STR}_${UNIQUE_ID}.csv"
USD_REPORT="./reports/transactions-USD-${LAST_FOUR}-report__${START_DATE_STR}-to-${END_DATE_STR}_${UNIQUE_ID}.csv"

read -r -d '' COOKIE <<COOKIE_CONTENT
# Put the cookie value here
COOKIE_CONTENT
