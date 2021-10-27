#!/bin/bash

printf '%s\n' "--------------------------------------------------"
printf '%s\n' "     Adding internal repository to SmartCheck     "
printf '%s\n' "--------------------------------------------------"

varsok=true
if  [ -z "${DSSC_USERNAME}" ]; then echo DSSC_USERNAME must be set && varsok=false; fi
if  [ -z "${DSSC_PASSWORD}" ]; then echo DSSC_PASSWORD must be set && varsok=false; fi
if  [ -z "${DSSC_HOST}" ]; then echo DSSC_HOST must be set && varsok=false; fi
if  [ "$varsok" = false ]; then 
   printf "%s\n" "Check the above-mentioned variables"; 
   read -p "Press CTRL-C to exit script, or Enter to continue anyway (script will fail)"
fi
# Getting a DSSC_BEARERTOKEN 
#-----------------------------
DSSC_BEARERTOKEN=$(curl -s -k -X POST https://${DSSC_HOST}/api/sessions -H "Content-Type: application/json"  -H "Api-Version: 2018-05-01" -H "cache-control: no-cache" -d "{\"user\":{\"userid\":\"${DSSC_USERNAME}\",\"password\":\"${DSSC_PASSWORD}\"}}" | jq '.token' | tr -d '"')
#printf "Bearer Token = ${DSSC_BEARERTOKEN} \n"
#get all registries
#-------------------
#curl -k -X GET https://$DSSC_HOST/api/registries -H "Content-Type: application/json" -H "Api-Version: 2018-05-01" -H "Authorization: Bearer $DSSC_BEARERTOKEN" -H 'cache-control: no-cache'
#add Demo Registry with PhotoApp
#---------------------------------
#be aware: lots of images in this registry
#the JSON file below has only Read-Only rights
#printf '%s' "Creating JSON authentication file for GCR..."

# Adding internal repository to SmartCheck:
# ------------------------------------------
#curl -s -k -X POST https://$DSSC_HOST/api/registries -H "Content-Type: application/json" -H "Api-Version: 2018-05-01" -H "Authorization: Bearer $DSSC_BEARERTOKEN" -H 'cache-control: no-cache' -d "{\"name\":\"DemoRegistry with PhotoApp\",\"description\":\"Test by  ChrisV\n\",\"host\":\"us.gcr.io\",\"credentials\":{\"username\":\"_json_key\",\"password\":\"$DSSC_REG_GCR_JSON\"},\"filter\":{\"include\":[\"$DSSC_FILTER\"]},\"insecureSkipVerify\":true}"
DSSC_REPOID=$(curl -s -k -X POST https://$DSSC_HOST/api/registries?scan=true -H "Content-Type: application/json" -H "Api-Version: 2018-05-01" -H "Authorization: Bearer $DSSC_BEARERTOKEN" -H 'cache-control: no-cache' -d "{\"name\":\"Internal Registry\",\"description\":\"added by  ChrisV\n\",\"host\":\"${DSSC_HOST}:5000\",\"credentials\":{\"username\":\"${DSSC_REGUSER}\",\"password\":\"$DSSC_REGPASSWORD\"},\"insecureSkipVerify\":"true"}" | jq '.id')


#TODO: write a test to verify if the Repository was successfully added
