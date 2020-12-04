
#Add a Cluster
#--------------
cat <<EOF>overrides.cloudone.yml
cloudOne:
     apiKey: ${C1CSAPIKEY}
EOF
cat overrides.cloudone.yml
kubectl create namespace c1cs
helm install \
     trendmicro -n c1cs\
     --values overrides.cloudone.yml \
     https://github.com/trendmicro/cloudone-admission-controller-helm/archive/master.tar.gz


#Add a Scanner
#------------
cp overrides.yml overrides.smartcheck.yml
cat <<EOF>>overrides.smartcheck.yml
cloudOne:
     apiKey: ${C1CSAPIKEY}
EOF
cat overrides.smartcheck.yml

helm upgrade \
          deepsecurity-smartcheck \
          --values overrides.smartcheck.yml \
          -n ${DSSC_NAMESPACE} \
          https://github.com/deep-security/smartcheck-helm/archive/master.tar.gz

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
