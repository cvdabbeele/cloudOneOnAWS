printf '%s\n' "--------------------------"
printf '%s\n' "     (re-)Adding C1CS     "
printf '%s\n' "--------------------------"

#delete old namespaces  
printf '%s\n' "Deleting any potential old C1CS artefacts on the EKS cluster"
#kubectl delete namespace c1cs  &>/dev/null
kubectl delete namespace trendmicro-system   2>/dev/null
kubectl delete clusterrole oversight-manager-role 2>/dev/null 
kubectl delete ClusterRoleBinding "oversight-manager-rolebinding"  2>/dev/null 

kubectl delete clusterrole oversight-proxy-role 2>/dev/null 
kubectl delete ClusterRoleBinding "oversight-proxy-rolebinding"  2>/dev/null 

kubectl delete namespace nginx  2>/dev/null
kubectl delete clusterrole usage-manager-role 2>/dev/null
kubectl delete clusterroleBinding "usage-manager-rolebinding" 2>/dev/null

kubectl delete namespace mywhitelistednamespace 2>/dev/null
kubectl delete clusterrole usage-proxy-role 2>/dev/null
kubectl delete ClusterRoleBinding "usage-proxy-rolebinding"  2>/dev/null


# if a cluster object for this project already exists in c1cs, then delete it 
C1CSCLUSTERS=(`\
curl --silent --location --request GET "${C1CSAPIURL}/clusters" \
--header 'Content-Type: application/json' \
--header "${C1AUTHHEADER}"  \
--header 'api-version: v1' \
 | jq -r ".clusters[]? | select(.name == \"${C1PROJECT}\").id"`)

for i in "${!C1CSCLUSTERS[@]}"
do
  #printf "%s\n" "C1CS: found cluster ${C1CSCLUSTERS[$i]}"
  if [[ "${C1CSCLUSTERS[$i]}" =~ "${C1PROJECT}" ]]; 
  then
    printf "%s\n" "Deleting old Cluster object (${C1CSCLUSTERS[$i]}) in C1CS"
    curl --silent --location --request DELETE "${C1CSAPIURL}/clusters/${C1CSCLUSTERS[$i]}" \
       --header 'Content-Type: application/json' \
       --header "${C1AUTHHEADER}"  \
       --header 'api-version: v1' 
  fi
done 

# if a Scanner object for this project already exists in c1cs, then delete it 
C1CSSCANNERS=(`\
curl --silent --location --request GET "${C1CSAPIURL}/scanners" \
--header 'Content-Type: application/json' \
--header "${C1AUTHHEADER}"  \
--header 'api-version: v1' \
 | jq -r ".scanners[]? | select(.name == \"${C1PROJECT}\").id"`)

for i in "${!C1CSSCANNERS[@]}"
do
  printf "%s\n" "Deleting old scanner object ${C1CSSCANNERS[$i]} from C1CS"
  curl --silent --location --request DELETE "${C1CSAPIURL}/scanners/${C1CSSCANNERS[$i]}" \
--header 'Content-Type: application/json' \
--header "${C1AUTHHEADER}"  \
--header 'api-version: v1' 
done 

# if a Policy object for this project already exists in c1cs, then delete it 
C1CSPOLICIES=(`\
curl --silent --location --request GET "${C1CSAPIURL}/policies" \
--header 'Content-Type: application/json' \
--header "${C1AUTHHEADER}"  \
--header 'api-version: v1' \
 | jq -r ".policies[]? | select(.name == \"${C1PROJECT}\").id"`)  2>/dev/null

for i in "${!C1CSPOLICIES[@]}"
do
  printf "%s\n" "Deleting old policy objecy ${C1CSPOLICIES[$i]} from C1CS"
  curl --silent --location --request DELETE "${C1CSAPIURL}/policies/${C1CSPOLICIES[$i]}" \
--header 'Content-Type: application/json' \
--header "${C1AUTHHEADER}"  \
--header 'api-version: v1' 
done 


printf '%s\n' "Creating a cluster object in C1Cs and get an API key to deploy C1CS to the K8S cluster"
export TEMPJSON=` \
curl --silent --location --request POST "${C1CSAPIURL}/clusters" \
--header 'Content-Type: application/json' \
--header "${C1AUTHHEADER}"  \
--header 'api-version: v1' \
--data-raw "{   \
    \"name\": \"${C1PROJECT}\", \
    \"description\": \"EKS cluster added by the CloudOneOnAWS project ${C1PROJECT}\"}"`
#echo $TEMPJSON | jq

export C1APIKEYforCLUSTERS=`echo ${TEMPJSON}| jq -r ".apiKey"`
#echo  C1APIKEYforCLUSTERS = $C1APIKEYforCLUSTERS
export C1CSCLUSTERID=`echo ${TEMPJSON}| jq -r ".id"`
#echo C1CSCLUSTERID = $C1CSCLUSTERID
if [[ "${C1CS_RUNTIME}" == "true" ]]; then
    export C1RUNTIMEKEY=`echo ${TEMPJSON}| jq -r ".runtimeKey"`
    #echo C1RUNTIMEKEY = $C1RUNTIMEKEY
    export C1RUNTIMESECRET=`echo ${TEMPJSON}| jq -r ".runtimeSecret"`
    #echo C1RUNTIMESECRET = $C1RUNTIMESECRET
else
    export C1RUNTIMEKEY=""
    export C1RUNTIMESECRET=""
fi

## deploy C1CS to the K8S cluster of the CloudOneOnAWS project
printf '%s\n' "Deploying C1CS to the K8S cluster of the CloudOneOnAWS project"

if [[ "${C1CS_RUNTIME}" == "true" ]]; then
    cat << EOF >work/overrides.addC1csToK8s.yml
    cloudOne:
        apiKey: ${C1APIKEYforCLUSTERS}
        endpoint: ${C1CSENDPOINTFORHELM}
        runtimeSecurity:
          enabled: true
EOF
else
    cat << EOF >work/overrides.addC1csToK8s.yml
    cloudOne:
        apiKey: ${C1APIKEYforCLUSTERS}
        endpoint: ${C1CSENDPOINTFORHELM}
EOF
fi
printf '%s\n' "Running Helm to deploy/upgrade C1CS"
DUMMY=`helm upgrade \
     trendmicro \
     --namespace trendmicro-system --create-namespace \
     --values work/overrides.addC1csToK8s.yml \
     --install \
     https://github.com/trendmicro/cloudone-container-security-helm/archive/master.tar.gz`

printf '%s' "Waiting for C1CS pod to become running"
while [[ `kubectl get pods -n trendmicro-system | grep trendmicro-admission-controller | grep "1/1" | grep -c Running` -ne 1 ]];do
  sleep 3
  printf '%s' "."
  #kubectl get pods -n trendmicro-system
done

# Creating a Scanner
## Creating a Scanner object in C1Cs and getting an API key for the Scanner

printf '\n%s\n' "Creating a Scanner object in C1Cs and getting an API key for the Scanner"
export TEMPJSON=`\
curl --silent --location --request POST "${C1CSAPIURL}/scanners" \
--header 'Content-Type: application/json' \
--header "${C1AUTHHEADER}"  \
--header 'api-version: v1' \
--data-raw "{
    \"name\": \"${C1PROJECT}\",
    \"description\": \"The SmartCheck scanner added by the CloudOneDevOps project ${C1PROJECT} \"
}" `
#echo $TEMPJSON | jq
export C1APIKEYforSCANNERS=`echo ${TEMPJSON}| jq -r ".apiKey"`
#echo  $C1APIKEYforSCANNERS
export C1CSSCANNERID=`echo ${TEMPJSON}| jq -r ".id"`
#echo $C1CSSCANNERID
cat << EOF > work/overrides.smartcheck.yml
cloudOne:
     apiKey: ${C1APIKEYforSCANNERS}
     endpoint: ${C1CSENDPOINTFORHELM}
EOF
printf '%s\n' "Running Helm upgrade for SmartCheck"
DUMMY=`helm upgrade \
     deepsecurity-smartcheck -n ${DSSC_NAMESPACE} \
     --values work/overrides.smartcheck.yml \
     --reuse-values \
     https://github.com/deep-security/smartcheck-helm/archive/master.tar.gz`
     
#watch kubectl get pods -n ${DSSC_NAMESPACE} 
        
# Creating an Admission Policy
printf '%s\n' "Creating Admission Policy in C1Cs"
export POLICYID=`curl --silent --location --request POST "${C1CSAPIURL}/policies" \
--header 'Content-Type: application/json' \
--header "${C1AUTHHEADER}"  \
--header 'api-version: v1' \
--data-raw "{
    \"name\": \"${C1PROJECT}\",
    \"description\": \"Policy created by the CloudOneDevOps project ${C1PROJECT}\",
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
#echo $POLICYID


# AssignAdmission Policy to Cluster
ADMISSION_POLICY_ID=`curl --silent --request POST \
  --url ${C1CSAPIURL}/clusters/${C1CSCLUSTERID} \
  --header "${C1AUTHHEADER}" \
  --header 'Content-Type: application/json' \
  --data "{\"description\":\"EKS cluster added and Policy Assigned by the CloudOneOnAWS project ${C1PROJECT}\",\"policyID\":\"${POLICYID}\"}" | jq -r ".policyID"`

# testing C1CS (admission control)
# --------------------------------
printf '%s\n' "Whitelisting namespace smartcheck for Admission Control"
kubectl label namespace smartcheck ignoreAdmissionControl=ignore &>/dev/null
# testing admission control
kubectl create namespace nginx 
kubectl create namespace mywhitelistednamespace
#whitelist that namespace for C1CS
kubectl label namespace mywhitelistednamespace ignoreAdmissionControl=ignore --overwrite=true 
printf '%s\n' "Testing C1CS Admission Control:"
printf '%s\n' "   THE DEPLOYMENT BELOW SHOULD FAIL: Deploying nginx pod in its own namespace "
kubectl run nginx --image=nginx --namespace nginx nginx 
printf '%s\n' "   THE DEPLOYMENT BELOW SHOULD WORK: Deploying nginx pod in whitelisted namespace "
#deploying nginx in the "mywhitelistednamespace" will work:
kubectl run nginx --image=nginx --namespace mywhitelistednamespace 
#kubectl get namespaces --show-labels
#kubectl get pods -A | grep nginx