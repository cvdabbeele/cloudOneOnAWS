#!/bin/bash
#printf "Checking required variables..."
printf '%s\n' "--------------------------------------------------------"
printf '%s\n' " Adding ECR repository to Cloud One Container Security "
printf '%s\n' "--------------------------------------------------------"

varsok=true
if  [ -z "${DSSC_USERNAME}" ]; then echo DSSC_USERNAME must be set && varsok=false; fi
if  [ -z "${DSSC_PASSWORD}" ]; then echo DSSC_PASSWORD must be set && varsok=false; fi
if  [ -z "${DSSC_HOST}" ]; then echo DSSC_HOST must be set && varsok=false; fi
if  [ "$varsok" = false ]; then exit 1 ; fi

#printf "Get a DSSC_BEARERTOKEN \n"
#-------------------------------
DSSC_BEARERTOKEN=$(curl -s -k -X POST https://${DSSC_HOST}/api/sessions -H "Content-Type: application/json"  -H "Api-Version: 2018-05-01" -H "cache-control: no-cache" -d "{\"user\":{\"userid\":\"${DSSC_USERNAME}\",\"password\":\"${DSSC_PASSWORD}\"}}" | jq '.token' | tr -d '"')
#printf "Bearer Token = ${DSSC_BEARERTOKEN} \n"

#get all registries
#-------------------
#curl -k -X GET https://$DSSC_HOST/api/registries -H "Content-Type: application/json" -H "Api-Version: 2018-05-01" -H "Authorization: Bearer $DSSC_BEARERTOKEN" -H 'cache-control: no-cache'

#adding ECR registry
#-------------------
export DSSC_ECR_FILTER='*'
printf '%s' "    Adding ECR registry"
# not adding any AWS credentials here defaults SmartCheck to authenticate to ECR using the InstanceRole; which is the Role assigned to the EC2 instance on which SmartCheck is running (i.e. the EKS clusternode)
#export DSSC_ECR_REPOID=$(curl -s -k -X POST https://${DSSC_HOST}/api/registries?scan=true -H "Content-Type: application/json" -H "Api-Version: 2018-05-01" -H "Authorization: Bearer ${DSSC_BEARERTOKEN}" -H 'cache-control: no-cache' -d  "{  \"name\": \"ECR_${AWS_PROJECT}\",  \"description\": \"Added by  \n\",  \"credentials\": {     \"aws\": {       \"region\": \"${AWS_REGION}\",       \"accessKeyID\": \"${AWS_ACCESS_KEY_ID}\",       \"secretAccessKey\": \"${AWS_SECRET_ACCESS_KEY}\"     }  },  \"insecureSkipVerify\": true,   \"filter\": {    \"include\": [      \"*\"    ]  }, \"schedule\": true}" | jq '.id')
export DSSC_ECR_REPOID=$(curl -s -k -X POST https://${DSSC_HOST}/api/registries?scan=false -H "Content-Type: application/json" -H "Api-Version: 2018-05-01" -H "Authorization: Bearer ${DSSC_BEARERTOKEN}" -H 'cache-control: no-cache' -d  "{  \"name\": \"ECR_${AWS_PROJECT}_01\",  \"description\": \"Added by  \n\",  \"credentials\": {     \"aws\": {       \"region\": \"${AWS_REGION}\" }  },  \"insecureSkipVerify\": true,   \"filter\": {    \"include\": [      \"*\"    ]  }, \"schedule\": true}" | jq '.id')

echo $DSSC_ECR_REPOID
#trigger a scan on the registry

#TODO: write a test to verify if the Repository was successfully added
