#!/bin/bash
#printf "Checking required variables..."
printf '%s\n' "--------------------------------------------------------"
printf '%s\n' " Adding Demo repository to SmartCheck "
printf '%s\n' "--------------------------------------------------------"
. ./cloudOneCredentials.txt
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
#add Demo Registry with PhotoApp
#---------------------------------
#be aware: lots of images in this registry
#the JSON file below has only Read-Only rights
#printf '%s' "Creating JSON authentication file for GCR..."
read -r -d '' DSSC_REG_GCR_JSON <<'EOF'
{  \"type\": \"service_account\",  \"project_id\": \"argus-deploy\",  \"private_key_id\": \"bddb75c455b481340aef0b7afc59efbaf156eeb6\",  \"private_key\": \"-----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDbSjk+X7lUUQT4\nw+G8Vmrl84n/GYR2UmJUN/LPUK/hCXjw7SZzpMMnkvJCP6kDKxeTBvf5wDKkVwXl\n9E3qJQgT274hPSxFNoZd0LBMoMdehhoOOyN3oM7mFFyZaQ5jkucPF3JwhC9rAm+u\nsxU/VfRIJo0T6rBZm2HpOo7oEgn9F3D3dHQIvRMdNcp+wrfBB5cQoiTDsxLdbtLR\nZtjE2tTLJe1H+YA06bezTHXfI5kvdadmuChuJTckggxq4pkiG6DxxlnF2Ff2QlDG\ny7YEApNAihzKylLEiRQQjBMreBUNUDdLzhUaDyDYir0LtBf1FS92EMPEY/sCqCLv\nZdXjtP3bAgMBAAECggEASPqeK2JrCKL//xQdg3LVF5shwUqKOWB4heOqxJDrP37K\nB5A8/D6IjhqK0j5iboIAUfd/PlhW4jdt6JYR+gsB8a3vTBuSKKSZOg6SJaZaQ1xo\nvnSy/ISBZrO/D3UVi1Df4bdhaA2txDSm22KQ/yeJaRufVtIDh4a9IoPQ/G3Icjgl\nS2n79DkYOdzyJaDZxK5uVMWqLqtcpIpzrVpLTLufqPMkMkdzeBGn4gKlbLwVLjzF\nUNyDjMECg1tWNupqOndrxppY+qbFY77V4nck2KQsiwujfyJRAkJiNeJ2Z43UTlmm\nCvQ6Ogjr/XkvtjLQr23vlt5NdCboYOZYV07ur9UsWQKBgQD+u7vEC5UQTI6paxW/\nTi77d/psvalzg2FBYPySk/zF7WZjZz51SARBmgUwt43RnBbQ4v185fusO5ymwia5\nNi+AA3gCqzA8R0HWqsDaSWotZFdB6UUbd7zmoBi6vYBNMHJbbJYZANOJojXAUgd3\nw81JFx13t8YaDZaBw5KSrJp2OQKBgQDcYV84XTQSZCNRPZ0Yx3KLZW7Sb1D3CaN1\neJWx9Ub2gpXr84DDZCLCxBNnLVSaOWXBrdPdlUo48tboB7G/2zBZjVjkKj24IdCr\nNC4gMK+KwRm/gYcXoyU/Y3kHYdWgVzHuAtC0Za1ZkvxHdYa6EhxQBaosu/hfzm0v\nUmQvYzb0swKBgQCe3yNqT/b2JWlMjLcRi4eN2vRa4adPnf8IMZ8VJCsgnsGe+YNg\nzjupVpAqJDDVLE6mlQuX3DAs6Tj4YFqaZQsXAhLVR0NcNO0BH5oMCoGoMc6iEwTA\n7trn063YudvNSIvqLT0n9vX3/y0a944kyf+8uCfuxLVPBm56HCnMRM5JMQKBgA95\nnvAcS13HPlukEfX9e2Oiece5HVxbhujm0MwwRw1kWha5gJ831uEKV7p1Cm3R/f09\nsZTruMyK8OBWOfsY7yo6rLVI6hCV/0smXN7RzGHX8XDrLYtRX3o2B/emvROHS/BE\nrlcclLGniqOR8yX5w5cy7qI5iNVhb3VVOcfCFcfVAoGBAIL8BosQxRvq4iURAQ3u\n532QVpi/7cfz9XG9Ro8C/QwC3oKDzh3HRVE9pjST1gjeR0zOWT5FYiGbMOtSenIq\n0Rig6DYgIK9pUa5bQ2b1rooiYP/ANhDfmZxnDyCL4pQWeGhStfCgXCT1TWT6s57e\nHDk6D8KVPJsOoW2JMt8Cy2L1\n-----END PRIVATE KEY-----\n\",  \"client_email\": \"argus-deploy-gcr-pull-account@argus-deploy.iam.gserviceaccount.com\",  \"client_id\": \"116064264027792600530\",  \"auth_uri\": \"https://accounts.google.com/o/oauth2/auth\",  \"token_uri\": \"https://accounts.google.com/o/oauth2/token\",  \"auth_provider_x509_cert_url\": \"https://www.googleapis.com/oauth2/v1/certs\",  \"client_x509_cert_url\": \"https://www.googleapis.com/robot/v1/metadata/x509/argus-deploy-gcr-pull-account%40argus-deploy.iam.gserviceaccount.com\"}
EOF
DSSC_FILTER='*photo*'
printf '%s' "    Adding demo repository with filter: "
printf '%s \n' "${DSSC_FILTER}"
#curl -s -k -X POST https://$DSSC_HOST/api/registries -H "Content-Type: application/json" -H "Api-Version: 2018-05-01" -H "Authorization: Bearer $DSSC_BEARERTOKEN" -H 'cache-control: no-cache' -d "{\"name\":\"DemoRegistry with PhotoApp\",\"description\":\"Test by  ChrisV\n\",\"host\":\"us.gcr.io\",\"credentials\":{\"username\":\"_json_key\",\"password\":\"$DSSC_REG_GCR_JSON\"},\"filter\":{\"include\":[\"$DSSC_FILTER\"]},\"insecureSkipVerify\":true}"
DSSC_REPOID=$(curl -s -k -X POST https://$DSSC_HOST/api/registries?scan=true -H "Content-Type: application/json" -H "Api-Version: 2018-05-01" -H "Authorization: Bearer $DSSC_BEARERTOKEN" -H 'cache-control: no-cache' -d "{\"name\":\"DemoRegistry with PhotoApp\",\"description\":\"Test by  ChrisV\n\",\"host\":\"us.gcr.io\",\"credentials\":{\"username\":\"_json_key\",\"password\":\"$DSSC_REG_GCR_JSON\"},\"filter\":{\"include\":[\"$DSSC_FILTER\"]},\"insecureSkipVerify\":true}" | jq '.id')
#trigger a scan on the registry

#TODO: write a test to verify if the Repository was successfully added
