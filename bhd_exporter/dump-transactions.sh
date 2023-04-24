#!/usr/bin/env bash
#
# This small script will allow you to fetch your credit cards transactions from
# your Banco BHD (DO) account, and export it to convenient JSON and CSV files.
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

# ==============================================================================
# URLEncode:
# Credits: https://gist.github.com/magnetikonline/b9f32aaa31d7dad6dd6cdd0babc4414e
# ==============================================================================
function URLEncode {
    local dataLength="${#1}"
    local index

    for ((index = 0;index < dataLength;index++)); do
        local char="${1:index:1}"
        case $char in
            [a-zA-Z0-9.~_-])
                printf "$char"
                ;;
            *)
                printf "%%%02X" "'$char"
                ;;
        esac
    done
}

START_DATE=$(URLEncode "${START_DATE}");
END_DATE=$(URLEncode "${END_DATE}");
PAGE=${PAGE:-1};
PAGE_SIZE=${PAGE_SIZE:-100};

echo "== Fetching transactions for credit card ID: ${PRODUCT_NUMBER: -4} from ${START_DATE_STR} to ${END_DATE_STR}: ==";

PAGE=1;
PAGE_SIZE=${PAGE_SIZE:-100};
PANTALLA_PAG=001;
PAGINA="S";

echo " - Generating ${TRANSACTIONS_DUMP} file.";

# For this provider, transactions should be fetched in a paginated fashion.
while [ ${PAGINA} = "S" ]; do
    echo " - Feching page num. ${PAGE}.";

    if [ ${PAGE} -eq 1 ]; then
        PAYLOAD=$(\
            http GET "${ENDPOINT_URL}?page=${PAGE}&pageSize=${PAGE_SIZE}&startDate=${START_DATE}&endDate=${END_DATE}&productNumber=${PRODUCT_NUMBER}&productType=TC&lastRecord=0&refresh=Y" Cookie:"${COOKIE}"
        );
    else
        PAYLOAD=$(\
            http GET "${ENDPOINT_URL}?page=${PAGE}&pageSize=${PAGE_SIZE}&startDate=${START_DATE}&endDate=${END_DATE}&productNumber=${PRODUCT_NUMBER}&productType=TC&lastRecord=0&refresh=N&claveFin=${CLAVE_FIN}&claveInicio=${CLAVE_INICIO}&pantallaPag=${PANTALLA_PAG}&pagina=${PAGINA}" Cookie:"${COOKIE}"
        );
    fi

    TRANSACTIONS=$(printf '%s' ${PAYLOAD} | jq -rc '.data[]');

    CLAVE_FIN=$(printf '%s' ${PAYLOAD} | jq -rc '.pagination.claveFin');
    CLAVE_FIN=$(URLEncode "${CLAVE_FIN}");

    CLAVE_INICIO=$(printf '%s' ${PAYLOAD} | jq -rc '.pagination.claveInicio');
    CLAVE_INICIO=$(URLEncode "${CLAVE_INICIO}");

    PAGINA=$(printf '%s' ${PAYLOAD} | jq -rc '.pagination.pagina');
    PANTALLA_PAG=$(printf '%s' ${PAYLOAD} | jq -rc '.pagination.pantallaPag');

    printf '%s' "${TRANSACTIONS}" >> ${TRANSACTIONS_DUMP};

    (( PAGE++ ));

    sleep 2;
done

echo
echo " - Processing ${TRANSACTIONS_DUMP} file.";

for JSON_ENTRY in $(cat ${TRANSACTIONS_DUMP}); do
    TXN_ID=$(printf "%s" ${JSON_ENTRY} | jq -rc '.Voucher' | tr -d ' ');
    TXN_TYPE="";

    # This is already in MM/DD/YYYY format.
    TXN_DATE=$(printf "%s" ${JSON_ENTRY} | jq -rc '.BillingDate');
    TXN_DATE=$(date --date="${TXN_DATE}" +%D);

    # This comes in DD/MM/YYYY format. Needs parsing.
    POSTING_DATE=$(printf "%s" ${JSON_ENTRY} | jq -rc '.ApplicationDate' | awk -F"/" '{ print $2"/"$1"/"$3 }');
    POSTING_DATE=$(date --date="${POSTING_DATE}" +%D);

    DESCRIPTION=$(printf "%s" ${JSON_ENTRY} | jq -rc '.Description');

    DEBIT_AMOUNT=$(printf "%s" ${JSON_ENTRY} | jq -rc '.Debit');
    CREDIT_AMOUNT=$(printf "%s" ${JSON_ENTRY} | jq -rc '.Credit');

    CURRENCY=$(printf "%s" ${JSON_ENTRY} | jq -rc '.ProductCurrency');

    MERCHANT_NAME="";

    if [ ${CREDIT_AMOUNT} != 'null' ]; then
        AMOUNT=${CREDIT_AMOUNT};
        IS_CREDIT=1;
    else
        AMOUNT=${DEBIT_AMOUNT};
        IS_CREDIT=0;
    fi

    if [ ${IS_CREDIT} -eq 1 ]; then
        TXN_TYPE="INCOME";
    else
        TXN_TYPE="EXPENSE";
    fi

    if [ "${CURRENCY}" = 'RD$' ]; then
        DST_FILE=${DOP_REPORT};
    else
        DST_FILE=${USD_REPORT};
    fi

    echo " > Found transaction ID ${TXN_ID} of type ${TXN_TYPE} on date ${TXN_DATE}."
    cat <<REPORT_CONTENT >> ${DST_FILE}
${TXN_ID:-0000};${POSTING_DATE};${TXN_DATE};${TXN_TYPE};${DESCRIPTION};${AMOUNT};${MERCHANT_NAME}
REPORT_CONTENT
done
