#!/bin/bash
printf '%s\n' "--------------------------"
printf '%s\n' "     Scan Immage(-s)      "
printf '%s\n' "--------------------------"

printf '%s\n' "(re-)Defining variables"
. ./00_define_vars.sh

declare -a IMAGES
declare -A IMAGE_TAGS #ASSOCIATIVE Array (!)

echo $DOCKERHUB_PASSWORD | docker login --username $DOCKERHUB_USERNAME --password-stdin
if [ -z "${1}" ];then
 echo "No image name passed in parameters.  Creating array with sample images"
 IMAGES=("nginx" "redhat/ubi8-minimal" "alpine")
else
 IMAGES=(${1})
fi

for IMAGE in "${IMAGES[@]}"; do
    printf '%s\n' "image = ${IMAGE} "
    docker pull ${IMAGE}:latest
    if [ -n "$AWS_PROJECT" ];then
        echo "'we are in AWS"
        aws ecr create-repository --repository-name ${IMAGE} || true

    elif [ -n "$AZURE_PROJECT" ];then
        echo "'we are in AZURE"
    fi
done

printf '%s\n' "Break script here"
read -s -n 1
