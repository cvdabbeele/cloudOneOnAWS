printf '%s\n' "----------------------------------"
printf '%s\n' "Addming CLoudOneContainerSecurity"
printf '%s\n' "----------------------------------"
# Create a Cluster
## Create a cluster object in C1Cs and get an API key to deploy C1CS to the K8S cluster
printf '%s\n' "Create a cluster object in C1Cs and get an API key to deploy C1CS to the K8S cluster"
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

# Create a Scanner
## Create a Scanner object in C1Cs and get an API key to grant C1CS to push scanresults to C1CS
printf '%s\n' "Create a Scanner object in C1Cs and get an API key to grant C1CS to push scanresults to C1CS"
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

# create Admission Policy
# TODO

# Assign Cluster to Admission Policy
# Todo  to do  TODO 

###TOTO### # Whitelist smartcheck namespace
###TOTO### # ------------------------------
###TOTO### kubectl label namespace smartcheck ignoreAdmissionControl=ignore
###TOTO### kubectl run busybox  --image=busybox --namespace busybox
###TOTO### 
###TOTO### kubectl run busybox  --image=busybox   # will fail if "not scanned"
###TOTO### kubectl create namespace mywhitelistednamespace
###TOTO### #whitelist that namespace for C1CS
###TOTO### kubectl label namespace mywhitelistednamespace ignoreAdmissionControl=ignore
###TOTO### #deploying busybox in the "mywhitelistednamespace" will work:
###TOTO### kubectl run busybox  --image=busybox --namespace mywhitelistednamespace
###TOTO### kubectl get namespaces --show-labels
###TOTO### 