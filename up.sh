#!/bin/bash

#TODO: check if we have enough limits to create a VPC (or if one for our project already exists fro a previous run of this script)
#TODO: check if we have enough limits to create a IGW (or if one for our project already exists fro a previous run of this script
#TODO: check if we have enough limits to create an Elastic IP  (or if one for our project already exists fro a previous run of this script)
# aws service-quotas list-service-quotas     --service-code vpc  
#      "ServiceCode": "vpc",
#            "ServiceName": "Amazon Virtual Private Cloud (Amazon VPC)",
#            "QuotaArn": "arn:aws:servicequotas:eu-central-1:517003314933:vpc/L-F678F1CE",
#            "QuotaCode": "L-F678F1CE",
#            "QuotaName": "VPCs per Region",
#            "Value": 10.0,
#            "Unit": "None",
#            "Adjustable": true,
#            "GlobalQuota": false

# removing "aws_session_token = <blanco> " from credentials file (which throws an error if not removed)
#sed -i "/aws_session_token/d" ~/.aws/credentials 
MAINSTARTTIME=`date +%s`

# import variables
. ./00_define_vars.sh

# install tools
. ./environmentSetup.sh


mkdir -p work

# create cluster
. ./eks_cluster.sh

# deploy SmartCheck
. ./smartcheck.sh

# add registries
. ./internal_repo.sh
#. ./add_demo_repo.sh   #this repository does no longer exist

# create groups in C1AS
. ./C1AS.sh

# setup AWS CodePipeline
. ./pipelines.sh
  
# add ECR registry to SmartCheck
. ./ECR_registry.sh

# add the demo apps
. ./demoApps.sh

# add C1CS
. ./C1CS.sh

printf '%s\n'  "You can now kick off sample pipeline-builds of MoneyX"
printf '%s\n'  " e.g. by running ./pushWithHighSecurityThresholds.sh"
printf '%s\n'  " e.g. by running ./pushWithMalware.sh"
printf '%s\n'  " After each script, verify that the pipeline has started and give it time to complete"
printf '%s\n'  " If you kick off another pipeline too early, it will overrule (and stop) the previous one"
MAINENDTIME=`date +%s`
printf '%s\n' "Script run time = $((($MAINENDTIME-$MAINSTARTTIME)/60)) minutes"
 
#. ./strickt_security_settings.sh  

# create report
#still need to ensure that either "latest" gets scanned or that $TAG gets exported from the pipeline
# plus: data on Snyk findings is not visible in the report
# docker run --network host mawinkler/scan-report:dev -O    --name "${TARGET_IMAGE}"    --image_tag latest    --service "${DSSC_HOST}"    --username "${DSSC_USERNAME}"    --password "\"${DSSC_PASSWORD}"\"
#end