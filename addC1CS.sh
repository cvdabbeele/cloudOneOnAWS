printf '%s\n' "----------------------------------"
printf '%s\n' " Adding CLoudOneContainerSecurity"
printf '%s\n' "----------------------------------"
# Creating a Cluster
## Creating a cluster object in C1Cs and get an API key to deploy C1CS to the K8S cluster
printf '%s\n' "Creating a cluster object in C1Cs and get an API key to deploy C1CS to the K8S cluster"
export C1CSAPIKEYforCLUSTERS=`\
curl --silent --location --request POST 'https://cloudone.trendmicro.com/api/container/clusters' \
--header 'Content-Type: application/json' \
--header "api-secret-key: ${C1APIKEY}"  \
--header 'api-version: v1' \
--data-raw "{
    \"name\": \"${AWS_PROJECT}\",
    \"description\": \"EKS cluster added by the CloudOneOnAWS project ${AWS_PROJECT}\",
    \"policyID\": \"TO DO\",
    \"runtimeEnabled\": true
}" | jq -r ".apiKey"\
`

## deploy C1CS to the K8S cluster of the CloudOneOnAWS project
printf '%s\n' "deploy C1CS to the K8S cluster of the CloudOneOnAWS project"

cat << EOF >overrides.addC1csToK8s.yml
cloudOne:
   admissionController:
     apiKey: ${C1CSAPIKEYforCLUSTERS}
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
printf '%s\n' "Creating a Scanner object in C1Cs and get an API key to grant C1CS rights to push scanresults to C1CS"
export C1CSAPIKEYforSCANNERS=`\
curl --silent --location --request POST 'https://cloudone.trendmicro.com/api/container/scanners' \
--header 'Content-Type: application/json' \
--header "api-secret-key: ${C1APIKEY}"  \
--header 'api-version: v1' \
--data-raw "{
    \"name\": \"${AWS_PROJECT}\",
    \"description\": \"The SmartCheck scanner added by the CloudOneOnAWS project ${AWS_PROJECT}\"
}" | jq -r ".apiKey"\
`

## add C1CS to smartcheck
printf '%s\n' "add C1CS to smartcheck"
cat << EOF >overrides.smartcheck.yml
cloudOne:
     apiKey: ${C1CSAPIKEYforSCANNERS}
EOF

helm upgrade \
          deepsecurity-smartcheck \
          --reuse-values \
          --values overrides.smartcheck.yml \
          -n ${DSSC_NAMESPACE} \
          https://github.com/deep-security/smartcheck-helm/archive/master.tar.gz

# Creating an Admission Policy
# TODO
printf '%s\n' "Creating an Admission Policy in C1Cs"


export POLICYID=`curl --silent --location --request POST 'https://cloudone.trendmicro.com/api/container/policies' \
--header 'Content-Type: application/json' \
--header "api-secret-key: ${C1APIKEY}"  \
--header 'api-version: v1' \
--data-raw "{
    \"name\": \"${AWS_PROJECT}TEST\",
    \"description\": \"Policy created by CloudOneOnAWS project ${AWS_PROJECT}\",
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


# AssignAdmission Policy to Clusterf
# TODO to test 
curl --request POST \
  --url https://cloudone.trendmicro.com/api/container/clusters/{id} \
  --header 'api-secret-key: REPLACE_KEY_VALUE' \
  --header 'content-type: application/json' \
  --data '{"description":"My cluster description","policyID":"$POLICYID"}'





# Whitelist smartcheck namespace
# ------------------------------
kubectl label namespace smartcheck ignoreAdmissionControl=ignore
kubectl run busybox  --image=busybox --namespace busybox

kubectl run busybox  --image=busybox   # will fail if "not scanned"
kubectl create namespace mywhitelistednamespace
#whitelist that namespace for C1CS
kubectl label namespace mywhitelistednamespace ignoreAdmissionControl=ignore
#deploying busybox in the "mywhitelistednamespace" will work:
kubectl run busybox  --image=busybox --namespace mywhitelistednamespace
kubectl get namespaces --show-labels
