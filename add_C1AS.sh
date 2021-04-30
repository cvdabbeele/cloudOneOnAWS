printf '%s\n' "--------------"
printf '%s\n' " Adding C1AS"
printf '%s\n' "--------------"


function create_c1as_group {
# parm = ${1} = name of the app"

# Creating groups

## groupname = ${AWS_PROJECT}${APP[$i]})

# if a group object for this project already exists in c1as, then delete it 
#AWS_PROJECT="test2"
TEMPJSON=(`\
curl --silent --location --request GET 'https://cloudone.trendmicro.com/api/application/accounts/groups' --header 'Content-Type: application/json' --header "api-secret-key: ${C1APIKEY}" --header 'api-version: v1' `)

C1ASGROUPS=(`echo "$TEMPJSON" | jq   -r ".[].name"`)
C1ASGROUPIDS=(`echo "$TEMPJSON" | jq   -r ".[].group_id"`)

for i in "${!C1ASGROUPS[@]}"
do
  #printf "%s\n" "C1AS: found group ${C1ASGROUPS[$i]} with ID ${C1ASGROUPIDS[$i]}"
  if [[ "${C1ASGROUPS[$i]}" == "${AWS_PROJECT^^}-${1^^}" ]]; 
  #if [[ "${C1ASGROUPS[$i]}" == "${AWS_PROJECT^^}" ]]; 
  then
    printf "%s\n" "Deleting old Group object ${AWS_PROJECT^^}-${1^^} in C1AS"
    curl --silent --location --request DELETE "https://cloudone.trendmicro.com/api/application/accounts/groups/${C1ASGROUPIDS[$i]}"   --header 'Content-Type: application/json' --header "api-secret-key: ${C1APIKEY}" --header 'api-version: v1' 
  fi
done 

PAYLOAD="{ \"name\": \"${AWS_PROJECT^^}-${1^^}\"  }"
printf "%s\n" "Creating Group object ${AWS_PROJECT^^}-${1^^} in C1AS"
TEMPJSON=(`\
curl --silent --location --request POST "https://cloudone.trendmicro.com/api/application/accounts/groups/"   --header 'Content-Type: application/json' --header "api-secret-key: ${C1APIKEY}" --header 'api-version: v1'  --data-raw "${PAYLOAD}" \
`)


APPKEY=`echo "$TEMPJSON" | jq   -r ".credentials.key"`
APPSECRET=`echo "$TEMPJSON" | jq   -r ".credentials.secret"`


} 
#end of function



create_c1as_group $APP1 1
APP1KEY=$APPKEY
APP1SECRET=$APPSECRET
echo APP1KEY=$APP1KEY
echo APP1SECRET=$APP1SECRET

create_c1as_group $APP2 2
APP2KEY=$APPKEY
APP2SECRET=$APPSECRET
echo APP2KEY=$APP2KEY
echo APP2SECRET=$APP2SECRET

create_c1as_group $APP3 3
APP3KEY=$APPKEY
APP3SECRET=$APPSECRET
echo APP3KEY=$APP3KEY
echo APP3SECRET=$APP3SECRET
