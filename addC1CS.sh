
# Create a Cluster
## Create a cluster object in C1Cs and get an API key to deploy C1CS to the K8S cluster
export C1CSAPIKEYforCLUSTERS=`\
curl --location --request POST 'https://cloudone.trendmicro.com/api/container/clusters' \
--header 'Content-Type: application/json' \
--header "api-secret-key: ${C1APIKEY}"  \
--header 'api-version: v1' \
--data-raw "{
    \"name\": \"${AWS_PROJECT}\",
    \"description\": \"EKS cluster added by the CloudOneOnAWS project ${AWS_PROJECT}\",
    \"policyID\": \"TO DO\",
    \"runtimeEnabled\": \"true\"
}" | jq -r ".apiKey"\
`
echo ${C1CSAPIKEYforCLUSTERS}

## deploy C1CS to the K8S cluster of the CloudOneOnAWS project
cat << EOF >overrides.addC1csToK8s.yml
cloudOne:
   admissionController:
     apiKey: ${C1CSAPIKEYforCLUSTERS}
EOF
cat overrides.addC1csToK8s.yml
kubectl create namespace c1cs

helm upgrade \
     trendmicro-c1cs \
     --values overrides.addC1csToK8s.yml \
     --namespace c1cs \
     --install \
     --create-namespace \
     https://github.com/trendmicro/cloudone-container-security-helm/archive/master.tar.gz

cat <<EOF >>overrides.smartcheck.yml
cloudOne:
     apiKey: ${C1CSAPIKEY}
EOF
cat overrides.smartcheck.yml


# Create a Scanner
## Create a Scanner object in C1Cs and get an API key to grant C1CS to push scanresults to C1CS
export C1CSAPIKEYforSCANNERS=`\
curl --location --request POST 'https://cloudone.trendmicro.com/api/container/scanners' \
--header 'Content-Type: application/json' \
--header "api-secret-key: ${C1APIKEY}"  \
--header 'api-version: v1' \
--data-raw "{
    \"name\": \"${AWS_PROJECT}\",
    \"description\": \"The SmartCheck scanner added by the CloudOneOnAWS project ${AWS_PROJECT}\"
}" | jq -r ".apiKey"\
`
echo ${C1CSAPIKEYforSCANNERS}

## add C1CS to smartcheck
helm upgrade \
          deepsecurity-smartcheck \
          --reuse-values \
          --values overrides.smartcheck.yml \
          -n ${DSSC_NAMESPACE} \
          https://github.com/deep-security/smartcheck-helm/archive/master.tar.gz

# create Admission Policy
# TODO

# Assign Cluster to Admission Policy
# Todo

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
