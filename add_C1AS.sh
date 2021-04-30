printf '%s\n' "----------------------------------"
printf '%s\n' " Adding CLoudOneWorkloadSecurity"
printf '%s\n' "----------------------------------"


function create_c1as_group {

echo "in function"
echo "with parm = ${1} = name of the app"
echo "with parm = ${2} = number of the app"

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
  printf "%s\n" "C1AS: found group ${C1ASGROUPS[$i]} with ID ${C1ASGROUPIDS[$i]}"
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


declare APP${2}KEY=`echo "$TEMPJSON" | jq   -r ".credentials.key"`
temp=APP${2}KEY
echo xxxxxxxxxxxxxxxxx ${temp}=${!temp}
declare APP${2}SECRET=`echo "$TEMPJSON" | jq   -r ".credentials.secret"`
temp=APP${2}SECRET
echo xxxxxxxxxxxxxxxxx  ${temp}=${!temp}

} #end of function



AWS_PROJECT="project1"
create_c1as_group dummytest1 1
create_c1as_group dummytest2 2
create_c1as_group dummytest3 3




# ${APP1}
echo returned from function
APP1_key=$APPKEY
echo APP1_key=$APP1_key

APP1_secret=$APPSECRET
echo APP1_secret=$APP1_secret


create_c1as_group dummytest2
# ${APP1}
echo returned from function
APP2_key=$APPKEY
echo APP2_key=$APP2_key

APP2_secret=$APPSECRET
echo APP2_secret=$APP2_secret


create_c1as_group dummytest3
# ${APP1}
echo returned from function
APP3_key=$APPKEY
echo APP3_key=$APP3_key

APP3_secret=$APPSECRET
echo APP3_secret=$APP3_secret


echo 'all together-----------------------------------------------------' 
# ${APP1}
echo APP1_key=$APP1_key
echo APP1_secret=$APP1_secret
echo APP2_key=$APP2_key
echo APP2_secret=$APP2_secret
echo APP3_key=$APP3_key
echo APP3_secret=$APP3_secret


#. create_c1as_group  ${APP2}
#. create_c1as_group  ${APP3}

#simmulating an array (as arrays could not be exported)
for i in {1..3}; do 
  #echo in the loop $i
  CURRENTAPP=APP${i}
  create_c1as_group $CURRENTAPP ${i}
  echo returned from function APP${i}
  
  #echo currentapp = APP$i
  CURRENTAPPKEY=APP${i}KEY
  echo $CURRENTAPPKEY=${!CURRENTAPPKEY}
  #echo APP1_secret=${APP{$i}_secret
done

