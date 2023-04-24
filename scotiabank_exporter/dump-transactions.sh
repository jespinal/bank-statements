#!/usr/bin/env bash
#
# This small script will allow you to fetch your credit cards transactions from
# your ScotiaBank (DO) account, and export it to convenient JSON and CSV files.
#
# Pavel Espinal <jose@pavelespinal.com>
#
# ==============================================================================

LC_ALL=C;
export IFS=$'\n;';
UNIQUE_ID=$(date +"%F-%s")

if [ -f ./config.sh ]; then
    source ./config.sh;
else
    echo "== Unable to load config file. Aborting. ==";
    exit 1;
fi

if [ -f ./config-local.sh ]; then
    source ./config-local.sh;
fi

echo "== Fetching transactions for credit card ID: ${CREDITCARD_ID} from ${FROM_DATE} to ${TO_DATE}:";
TRANSACTIONS=$(http GET "${ENDPOINT_URL}/${CREDITCARD_ID}/transactions?from_date=${FROM_DATE}&to_date=${TO_DATE}&status=SETTLED&all=true" Cookie:"${COOKIE}");

echo " - Generating ${TRANSACTIONS_DUMP} file.";
printf "%s" ${TRANSACTIONS} | jq -rc '.data.records[]' > ${TRANSACTIONS_DUMP};

for JSON_ENTRY in $(cat ${TRANSACTIONS_DUMP}); do
    TXN_ID=$(printf "%s" ${JSON_ENTRY} | jq -rc '.id');
    TXN_TYPE=$(printf "%s" ${JSON_ENTRY} | jq -rc '.transactionType');

    TXN_DATE=$(printf "%s" ${JSON_ENTRY} | jq -rc '.transactionDate');
    TXN_DATE=$(date --date="${TXN_DATE}" +%D);

    POSTING_DATE=$(printf "%s" ${JSON_ENTRY} | jq -rc '.postingDate');
    POSTING_DATE=$(date --date="${POSTING_DATE}" +%D);

    DESCRIPTION=$(printf "%s" ${JSON_ENTRY} | jq -rc '.description');
    AMOUNT=$(printf "%s" ${JSON_ENTRY} | jq -rc '.amount.amount');
    CURRENCY=$(printf "%s" ${JSON_ENTRY} | jq -rc '.amount.currencyCode');
    MERCHANT_NAME=$(printf "%s" ${JSON_ENTRY} | jq -rc '.merchantName');

    # For credit cards, negative transactions are debit.
    IS_DEBIT=$(echo "${AMOUNT} < 0" | bc);

    if [ ${IS_DEBIT} -eq 1 ]; then
        TXN_TYPE="INCOME";
    else
        TXN_TYPE="EXPENSE";
    fi

    if [ "${CURRENCY}" = "DOP" ]; then
        DST_FILE=${DOP_REPORT};
    else
        DST_FILE=${USD_REPORT};
    fi

    echo " > Found transaction ID ${TXN_ID} of type ${TXN_TYPE} on date ${TXN_DATE}."
    cat <<REPORT_CONTENT >> ${DST_FILE}
${TXN_ID};${POSTING_DATE};${TXN_DATE};${TXN_TYPE};${DESCRIPTION};${AMOUNT};${MERCHANT_NAME}
REPORT_CONTENT
done
