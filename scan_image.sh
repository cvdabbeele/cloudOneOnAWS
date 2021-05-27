echo WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP 
echo WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP 
echo WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP 
echo WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP 
echo WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP WIP 


IMAGE_NAME=wordpress
TAG=latest

SMARTCHECK_HOST=`kubectl get services proxy -n smartcheck -o json | jq -r ".status.loadBalancer.ingress[].hostname"`
IMAGE_NAME=wordpress
TAG="latest"
SMARTCHECK_USER=`grep -i "export DSSC_USERNAME"  00_define_vars.sh | awk -F  "=" '{print $2}' | sed "s/'//g" | sed "s/#.*//g" |sed "s/[ \t]*$//"`
SMARTCHECK_PWD=`grep -i "export DSSC_PASSWORD"  00_define_vars.sh | awk -F  "=" '{print $2}' | sed "s/'//g" | sed "s/#.*//g" |sed "s/[ \t]*$//"`
PRE_SCAN_USER=`grep -i "export DSSC_REGUSER"  00_define_vars.sh   | awk -F  "=" '{print $2}' | sed "s/'//g" | sed "s/#.*//g"|sed "s/[ \t]*$//"`
PRE_SCAN_PWD=`grep -i "export DSSC_REGPASSWORD" 00_define_vars.sh | awk -F  "=" '{print $2}' | sed "s/'//g" | sed "s/#.*//g" |sed "s/[ \t]*$//"`

echo SMARTCHECK_HOST=xxx${SMARTCHECK_HOST}xxx
echo SMARTCHECK_USER=xxx${SMARTCHECK_USER}xxx
echo SMARTCHECK_PWD=xxx${SMARTCHECK_PWD}xxx
echo PRE_SCAN_USER=xxx{$PRE_SCAN_USER}xxx
echo PRE_SCAN_PWD=xxx${PRE_SCAN_PWD}xxx
echo IMAGE_NAME:TAG=${IMAGE_NAME}:${TAG}

sudo openssl s_client -showcerts -connect $SMARTCHECK_HOST:443 < /dev/null | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' | sudo tee   /usr/local/share/ca-certificates/$SMARTCHECK_HOST.crt && sudo update-ca-certificates
sudo systemctl restart docker  

docker pull ${IMAGE_NAME}:${TAG}

docker run -v /var/run/docker.sock:/var/run/docker.sock deepsecurity/smartcheck-scan-action --image-name="$IMAGE_NAME" --findings-threshold="{\"malware\": 0,\"vulnerabilities\":{\"defcon1\": 0,\"critical\": 0,\"high\": 0},\"contents\":{\"defcon1\": 0,\"critical\": 0,\"high\": 0},\"checklists\":{\"defcon1\": 0,\"critical\": 0,\"high\": 0}}" --preregistry-host="$SMARTCHECK_HOST:5000" --smartcheck-host="$SMARTCHECK_HOST" --smartcheck-user="$SMARTCHECK_USER" --smartcheck-password="$SMARTCHECK_PWD" --insecure-skip-tls-verify="true" --preregistry-scan --preregistry-user="$PRE_SCAN_USER" --preregistry-password="$PRE_SCAN_PWD" 


