#!/bin/bash
printf '%s\n' "--------------------------"
printf '%s\n' "     Scan Immage(-s)      "
printf '%s\n' "--------------------------"

printf '%s\n' "(re-)Defining variables"
. ../00_define_vars.sh
printf '%s\n' ""
declare -a IMAGES && IMAGES=()  #declare an empty the array
declare -a IMAGES_FLATENED  && IMAGES_FLATENED=()  
declare -A IMAGE_TAGS && IMAGE_TAGS=()   #ASSOCIATIVE Array (!)
export AWS_REGION=`aws configure get region`
export DSSC_HOST=`kubectl get services proxy -n smartcheck  --output JSON | jq -r '.status.loadBalancer.ingress[].hostname'`
REGISTRY_HOST="`aws sts get-caller-identity | jq -r '.Account'`.dkr.ecr.`aws configure get region`.amazonaws.com"  
echo REGISTRY_HOST=${REGISTRY_HOST}

dummy=`echo ${DOCKERHUB_PASSWORD}| docker login --username ${DOCKERHUB_USERNAME} --password-stdin 2>/dev/null`
if [[ "$dummy" != "Login Succeeded" ]];then
   echo "Failed to login to Docker Hub"
   return "Failed to login to Docker Hub"
fi

if [ -z "${1}" ];then
  printf '%s\n' "No image name passed in parameters.  Creating array with sample images"
  IMAGES=("ubuntu" "redhat/ubi8-minimal" "alpine" "wordpress" "busybox" "redis" "node" "python" "django" "centos" "couchbase"  )
else
  IMAGES=(${1})
fi

#create an ECR repository 
export LENGTH=${#IMAGES[@]}
#LENGTH=2
export IMAGE_TAG="latest"

for((i=0;i<${LENGTH};++i)) do
    IMAGES_FLATENED[${i}]=`echo ${IMAGES[$i]} | sed 's/\///'| sed 's/-//'`
    printf '%s\n' "image ${i} = ${IMAGES[$i]} flatened image name = ${IMAGES_FLATENED[$i]} "
    echo "-----------------------------"
    echo "PULLING ${IMAGES[$i]}:latest from Docker hub"
    docker pull ${IMAGES[$i]}:latest

    # CREATING ECR repository
    echo "CREATING ECR repository ${IMAGES_FLATENED[${i}]}"
    dummy=`aws ecr create-repository --repository-name ${IMAGES_FLATENED[${i}]} --query repository.repositoryArn `

    # login to ECR
    dummy=`aws ecr get-login-password --region ${AWS_REGION} | docker login --username AWS --password-stdin ${REGISTRY_HOST}/${IMAGES_FLATENED[$i]} 2>/dev/null`
    if [[ "$dummy" != "Login Succeeded" ]];then
        echo "Failed to login to ECR"
        break 
    fi


    echo "(re)TAGGING ${IMAGES[$i]}:${IMAGE_TAG}   to   ${REGISTRY_HOST}/${IMAGES_FLATENED[$i]}:${IMAGE_TAG}" 
    docker tag ${IMAGES[$i]}:${IMAGE_TAG} ${REGISTRY_HOST}/${IMAGES_FLATENED[$i]}:${IMAGE_TAG}

    echo "PUSHING to ${REGISTRY_HOST}/${IMAGES_FLATENED[$i]}:${IMAGE_TAG}"
    docker push ${REGISTRY_HOST}/${IMAGES_FLATENED[$i]}:${IMAGE_TAG}

    export IMAGE_TAG2=`openssl rand -hex 4`
    echo "(re)TAGGING ${IMAGES[$i]}:${IMAGE_TAG}   to   ${REGISTRY_HOST}/${IMAGES_FLATENED[$i]}:${IMAGE_TAG2}" 
    docker tag ${IMAGES[$i]}:${IMAGE_TAG} ${REGISTRY_HOST}/${IMAGES_FLATENED[$i]}:${IMAGE_TAG2}

    echo "PUSHING to ${REGISTRY_HOST}/${IMAGES_FLATENED[$i]}:${IMAGE_TAG2}"
    docker push ${REGISTRY_HOST}/${IMAGES_FLATENED[$i]}:${IMAGE_TAG2}

    echo "removing local images ${IMAGES[$i]}:${IMAGE_TAG} and ${REGISTRY_HOST}/${IMAGES_FLATENED[$i]}:${IMAGE_TAG}"
    docker rmi ${IMAGES[$i]}:${IMAGE_TAG}
    docker rmi ${REGISTRY_HOST}/${IMAGES_FLATENED[$i]}:${IMAGE_TAG}
#done
#printf '%s\n' "Break script here"
#read -s -n 1

    #  --image-pull-auth=\''{"aws":{"region":"'$AWS_REGION'","accessKeyID":"'$AWS_ACCESS_KEY_ID'","secretAccessKey":"'$AWS_SECRET_ACCESS_KEY'"}}'\' \

    echo "calling smartcheck-scan-action"
    docker run --rm --read-only --cap-drop ALL -v /var/run/docker.sock:/var/run/docker.sock --network host \
        deepsecurity/smartcheck-scan-action \
            --image-name "${REGISTRY_HOST}/${IMAGES_FLATENED[${i}]}:${IMAGE_TAG}" \
            --smartcheck-host="${DSSC_HOST}" \
            --smartcheck-user="${DSSC_USERNAME}" \
            --smartcheck-password="${DSSC_PASSWORD}" \
            --image-pull-auth="{\"username\":\"AWS\",\"password\":\"`aws ecr get-login-password --region ${AWS_REGION}`\"}" \
            --insecure-skip-tls-verify
echo "-----------------------------"
done





