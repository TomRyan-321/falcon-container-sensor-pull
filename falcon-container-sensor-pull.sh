#!/bin/bash
: <<'#DESCRIPTION#'
File: falcon-container-sensor-pull.sh
Description: Bash script to pull Falcon Container Sensor image from CrowdStrike Container Registry, users must first set their CS_CLIENT_ID, CS_CLIENT_SECRET & CID variables before use and set region using CS_REGION if not using US-1.
#DESCRIPTION#

#Check if CS_REGION variable set, if not use US-1
if [[ -z "${CS_REGION}" ]]; then
    echo "\$CS_REGION variable not set, assuming US-1"
    REGION="US-1"
    API="api"
else
    REGION=$(echo "${CS_REGION}" | tr '[:lower:]' '[:upper:]') #Convert to UPPERCASE if user entered as lower case
    API="api.${CS_REGION}"
fi

#Convert region to lowercase
REGIONLOWER=$(echo "${REGION}" | tr '[:upper:]' '[:lower:]')
#Convert CID to lowercase
CIDLOWER=$(echo "${CID}" | cut -d'-' -f1 | tr '[:upper:]' '[:lower:]')
#Checkout a bearer using the client id+secret
BEARER=$(curl \
--data "client_id=${CS_CLIENT_ID}&client_secret=${CS_CLIENT_SECRET}" \
--request POST \
--silent \
https://"${API}".crowdstrike.com/oauth2/token | jq -r '.access_token')

#Set Docker token using the BEARER token captured earlier
ART_PASSWORD=$(curl -X GET -H "authorization: Bearer ${BEARER}" \
https://"${API}".crowdstrike.com/container-security/entities/image-registry-credentials/v1 | \
jq -r '.resources[].token')

#Gets name of latest sensor, to pull N-1 or N-2 change the value in the JQ statement from resources[0] LATEST to [1] for N-1 or [2] for N-2
LATESTSENSOR=$(curl -X GET "https://${API}.crowdstrike.com/sensors/combined/installers/v1?limit=3&sort=version%7Cdesc&filter=os%3A%22Container%22" \
-H  "accept: application/json" -H  "authorization: Bearer ${BEARER}" | \
jq -r '.resources[0].name' | \
awk 'sub(/.*falcon-sensor-*/,""){f=1} f{if ( sub(/ *.container.*/,"") ) f=0; print}') 
#Set latest image in same format the CS registry uses (slightly different to sensor downloads name)
LATESTIMAGE="registry.crowdstrike.com/falcon-container/${REGIONLOWER}/release/falcon-sensor:${LATESTSENSOR}.container.x86_64.Release.${REGION}"
#Set docker login
docker login --username  "fc-${CIDLOWER}" --password "${ART_PASSWORD}" registry.crowdstrike.com
#Pull the container image locally
docker pull "${LATESTIMAGE}"
