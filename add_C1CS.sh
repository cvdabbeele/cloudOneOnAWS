printf '%s\n' "----------------------------------"
printf '%s\n' " Adding CLoudOneContainerSecurity"
printf '%s\n' "----------------------------------"

#delete old c1cs deployment 
kubectl delete deployment trendmicro-admission-controller -n c1cs  &>/dev/null
# delete old c1cs daemonset 
kubectl delete daemonset  trendmicro-runtime-protection -n c1cs  &>/dev/null

# Creating a Cluster
## Creating a cluster object in C1Cs and getting an API key to deploy C1CS to the K8S cluster

# if a cluster object for this project already exists in c1cs, then delete it 
C1CSCLUSTERS=(`\
curl --silent --location --request GET 'https://cloudone.trendmicro.com/api/container/clusters' \
--header 'Content-Type: application/json' \
--header "api-secret-key: ${C1APIKEY}"  \
--header 'api-version: v1' \
 | jq -r ".clusters[] | select(.name == \"${AWS_PROJECT}\").id"`)

for i in "${!C1CSCLUSTERS[@]}"
do
  printf "%s\n" "C1CS: found cluster ${C1CSCLUSTERS[$i]}"
  if [[ "${C1CSCLUSTERS[$i]}" =~ "${AWS_PROJECT}" ]]; 
  then
    printf "%s\n" "Deleting old Cluster object (${C1CSCLUSTERS[$i]}) in C1CS"
    curl --silent --location --request DELETE "https://cloudone.trendmicro.com/api/container/clusters/${C1CSCLUSTERS[$i]}" \
       --header 'Content-Type: application/json' \
       --header "api-secret-key: ${C1APIKEY}"  \
       --header 'api-version: v1' 
  fi
done 

printf '%s\n' "Creating a cluster object in C1Cs and get an API key to deploy C1CS to the K8S cluster"
export TEMPJSON=`\
curl --silent --location --request POST 'https://cloudone.trendmicro.com/api/container/clusters' --header 'Content-Type: application/json' --header "api-secret-key: ${C1APIKEY}"  --header 'api-version: v1' --data-raw "{    \"name\": \"${AWS_PROJECT}\",
  \"description\": \"EKS cluster added by the CloudOneOnAWS project ${AWS_PROJECT}\",
  \"policyID\": \"TO DO\",
  \"runtimeEnabled\": true }" `
#echo $TEMPJSON | jq
export C1APIKEYforCLUSTERS=`echo ${TEMPJSON}| jq -r ".apiKey"`
#echo  $C1APIKEYforCLUSTERS
export C1CSCLUSTERID=`echo ${TEMPJSON}| jq -r ".id"`
#echo $C1CSCLUSTERID


## deploy C1CS to the K8S cluster of the CloudOneOnAWS project
printf '%s\n' "Deploying C1CS to the K8S cluster of the CloudOneOnAWS project"
cat << EOF >overrides.addC1csToK8s.yml
cloudOne:
   admissionController:
     apiKey: ${C1APIKEYforCLUSTERS}
   runtimeSecurity:
     enabled: true
     apiKey: ${TREND_AP_KEY}
     secret: ${TREND_AP_SECRET}
EOF

helm upgrade \
     trendmicro-c1cs \
     --values overrides.addC1csToK8s.yml \
     --namespace c1cs \
     --install \
     --create-namespace \
     https://github.com/trendmicro/cloudone-container-security-helm/archive/master.tar.gz

# Creating a Scanner
## Creating a Scanner object in C1Cs and get an API key to grant C1CS rights to push scanresults to C1CS

# if a Scanner object for this project already exists in c1cs, then delete it 
C1CSSCANNERS=(`\
curl --silent --location --request GET 'https://cloudone.trendmicro.com/api/container/scanners' \
--header 'Content-Type: application/json' \
--header "api-secret-key: ${C1APIKEY}"  \
--header 'api-version: v1' \
 | jq -r ".scanners[] | select(.name == \"${AWS_PROJECT}\").id"`)

for i in "${!C1CSSCANNERS[@]}"
do
  printf "%s\n" "C1CS: deleting old scanner object ${C1CSSCANNERS[$i]} from C1CS"
  curl --silent --location --request DELETE "https://cloudone.trendmicro.com/api/container/scanners/${C1CSSCANNERS[$i]}" \
--header 'Content-Type: application/json' \
--header "api-secret-key: ${C1APIKEY}"  \
--header 'api-version: v1' 
done 

printf '%s\n' "Creating a Scanner object in C1Cs and get an API key to grant C1CS rights to push scanresults to C1CS"
export TEMPJSON=`\
curl --silent --location --request POST 'https://cloudone.trendmicro.com/api/container/scanners' \
--header 'Content-Type: application/json' \
--header "api-secret-key: ${C1APIKEY}"  \
--header 'api-version: v1' \
--data-raw "{
    \"name\": \"${AWS_PROJECT}\",
    \"description\": \"The SmartCheck scanner added by the CloudOneOnAWS project ${AWS_PROJECT} \"
}" `
#echo $TEMPJSON | jq
export C1APIKEYforSCANNERS=`echo ${TEMPJSON}| jq -r ".apiKey"`
echo  $C1APIKEYforSCANNERS
export C1CSSCANNERID=`echo ${TEMPJSON}| jq -r ".id"`
echo $C1CSSCANNERID


## add C1CS to smartcheck
printf '%s\n' "add C1CS to smartcheck"
cat << EOF >overrides.smartcheck.yml
cloudOne:
     apiKey: ${C1APIKEYforSCANNERS}
EOF

helm upgrade \
          deepsecurity-smartcheck \
          --reuse-values \
          --values overrides.smartcheck.yml \
          -n ${DSSC_NAMESPACE} \
          https://github.com/deep-security/smartcheck-helm/archive/master.tar.gz

# Creating an Admission Policy
# remove this project's Policy from c1cs
# if a Policy object for this project already exists in c1cs, then delete it 

C1CSPOLICIES=(`\
curl --silent --location --request GET 'https://cloudone.trendmicro.com/api/container/policies' \
--header 'Content-Type: application/json' \
--header "api-secret-key: ${C1APIKEY}"  \
--header 'api-version: v1' \
 | jq -r ".policies[] | select(.name == \"${AWS_PROJECT}\").id"`)

for i in "${!C1CSPOLICIES[@]}"
do
  printf "%s\n" "C1CS: deleting old policy objecy ${C1CSPOLICIES[$i]} from C1CS"
  curl --silent --location --request DELETE "https://cloudone.trendmicro.com/api/container/policies/${C1CSPOLICIES[$i]}" \
--header 'Content-Type: application/json' \
--header "api-secret-key: ${C1APIKEY}"  \
--header 'api-version: v1' 
done 

printf '%s\n' "Creating Admission Policy in C1Cs"
export POLICYID=`curl --silent --location --request POST 'https://cloudone.trendmicro.com/api/container/policies' \
--header 'Content-Type: application/json' \
--header "api-secret-key: ${C1APIKEY}"  \
--header 'api-version: v1' \
--data-raw "{
    \"name\": \"${AWS_PROJECT}\",
    \"description\": \"Policy created by the CloudOneOnAWS project ${AWS_PROJECT}\",
    \"default\": {
        \"rules\": [
            {
                \"type\": \"registry\",
                \"enabled\": true,
                \"action\": \"block\",
                \"statement\": {
                    \"key\": \"equals\",
                    \"value\": \"docker.io\"
                }
             },   
            {
              \"action\": \"block\",
              \"type\": \"unscannedImage\",
              \"enabled\": true
            },
            {
              \"action\": \"block\",
              \"type\": \"malware\",
              \"enabled\": true,
              \"statement\": {
                \"key\": \"count\",
                \"value\": \"0\"
              }
            }

          ],
        \"exceptions\": [
            {
                \"type\": \"registry\",
                \"enabled\": true,
                \"statement\": {
                    \"key\": \"equals\",
                    \"value\": \"gcr.io\"
                }
            }
        ]
    }
}" \
| jq -r ".id"`
echo $POLICYID


# get all policies
# curl --silent --location --request GET 'https://cloudone.trendmicro.com/api/container/policies' \
# --header 'Content-Type: application/json' \
# --header "api-secret-key: ${C1APIKEY}"  \
# --header 'api-version: v1' \
# | jq -r ".policies[].id"


# AssignAdmission Policy to Cluster
curl --request POST \
  --url https://cloudone.trendmicro.com/api/container/clusters/${C1CSCLUSTERID} \
  --header "api-secret-key: ${C1APIKEY}" \
  --header 'content-type: application/json' \
  --data "{\"description\":\"EKS cluster added and Policy Assigned by the CloudOneOnAWS project ${AWS_PROJECT}\",\"policyID\":\"${POLICYID}\"}" | jq


# testing C1CS (admission control)
# --------------------------------
printf '%s\n' "Whitelisting namespace smartcheck for Admission Control"
kubectl label namespace smartcheck ignoreAdmissionControl=ignore

printf '%s\n' "Deploying nginx pod in its own namspace --- this will fail"
kubectl create namespace nginx
kubectl run --generator=run-pod/v1 --image=nginx --namespace nginx nginx

printf '%s\n' "Deploying nginx pod in whitelisted namspace --- this will work"
kubectl create namespace mywhitelistednamespace
#whitelist that namespace for C1CS
kubectl label namespace mywhitelistednamespace ignoreAdmissionControl=ignore
#deploying nginx in the "mywhitelistednamespace" will work:
kubectl run --generator=run-pod/v1 --image=nginx --namespace mywhitelistednamespace nginx

kubectl run nginx  --image=nginx --namespace mywhitelistednamespace
kubectl get namespaces --show-labels
kubectl get pods -A | grep nginx