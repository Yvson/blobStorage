#!/bin/bash

# URL for the POST request
URL="https://colaboragov.sei.gov.br/sei/modulos/pesquisa/md_pesq_processo_exibir.php?FPWf5H7A2cVMiAtzZwygexREg6bL0LbNgvUE4YEJCnGtPHCdgfU85G2dEaFHn66TKJEeFfp+kVnEa77aEgyvc0Frsj0Lp/vUZz6rDUN0bt22M35BnhC/5T1bmDosTnxN"

# Number of requests to make
NUM_REQUESTS=50000

# Starting number for the parameter
START_NUM=57582910

# String to search for in the response
SEARCH_STRING="50461101"

# Loop through the requests
for ((i=0; i<NUM_REQUESTS; i++))
do
    # Calculate the current number
    CURRENT_NUM=$((START_NUM - i))
    
    # Make the POST request and store the response
    RESPONSE=$(curl --request POST \
        --url $URL \
        --header 'Content-Type: multipart/form-data' \
        --form hdnCId=PESQUISA_PROCESSUAL1752676824289 \
        --form hdnInfraTipoPagina=3 \
        --form hdnInfraNroItens=1 \
        --form hdnInfraItensSelecionados=$CURRENT_NUM \
        --form hdnInfraCampoOrd= \
        --form hdnInfraTipoOrd=ASC \
        --form hdnFlagGerar=1 \
        --form txtInfraCaptcha= \
        --form hdnInfraCaptcha=1 \
        --form hdnInfraSelecoes=Infra \
        --form hdnInfraItensHash= \
        --form hdnInfraItemId= \
        --form hdnInfraItens=$CURRENT_NUM
    )
    echo "Current index: $CURRENT_NUM"
    
    # Check if the response contains the search string
    if echo "$RESPONSE" | grep -q "$SEARCH_STRING"; then
        echo "Request $CURRENT_NUM: Found '$SEARCH_STRING' in response"
        break
    # else
    #     echo "Request $CURRENT_NUM: '$SEARCH_STRING' not found in response"
    fi
    
    # echo "Response for request $CURRENT_NUM:"
    # echo "$RESPONSE"
    # Optional: Add a small delay to avoid overwhelming the server
    sleep 0.2
done