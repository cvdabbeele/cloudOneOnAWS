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
# install tools
. ./tools.sh

# import variables
. ./00_define_vars.sh

# set additional variables based on aws configure
PROJECTDIR=`pwd` 
export ACCOUNT_ID=`aws sts get-caller-identity | jq -r '.Account'`
export AWS_REGION=`aws configure get region`
export AWS_ACCESS_KEY_ID=`aws configure get aws_access_key_id`
export AWS_SECRET_ACCESS_KEY=`aws configure get aws_secret_access_key`

# set additional variables based on the selected C1authentication mechanism
if [[ "${C1AUTH}" = "accountbased" ]] ; then
    export C1AUTHHEADER="api-secret-key: ${C1APIKEY}"
    export C1CSAPIURL="https://cloudone.trendmicro.com/api/container"
    export C1ASAPIURL="https://cloudone.trendmicro.com/api/application"
fi

if [[ "${C1AUTH}" = "emailbased" ]] ; then
    export C1AUTHHEADER="Authorization:	ApiKey ${C1APIKEY}"
    export C1CSAPIURL="https://container.${C1REGION}.cloudone.trendmicro.com/api"
    export C1ASAPIURL="https://application.${C1REGION}.cloudone.trendmicro.com"
fi

if [ "${C1AUTH}" != "accountbased" ] && [ "${C1AUTH}" != "emailbased" ]  ; then
    printf "%s\n" 'ERROR: illegal value for ${C1AUTH}'
    export C1AUTHHEADER=""
fi

varsok=true
# Check AWS settings
#if  [ -z "$AWS_REGION" ]; then echo AWSC_REGION must be set && varsok=false; fi
if  [ -z "$AWS_PROJECT" ]; then echo AWSC_PROJECT must be set && varsok=false; fi
#if  [ -z "$AWS_ACCESS_KEY_ID" ]; then echo AWS_ACCESS_KEY_ID must be set && varsok=false; fi
#if  [ -z "$AWS_SECRET_ACCESS_KEY" ]; then echo AWS_SECRET_ACCESS_KEY must be set && varsok=false; fi
if  [ -z "$AWS_EKS_NODES" ]; then echo AWS_EKS_NODES must be set && varsok=false; fi

# Check Cloud One Container Security (aka Deep Security Smart Check) settings (for pre-runtime scanning)
if  [ -z "$DSSC_NAMESPACE" ]; then echo DSSC_NAMESPACE must be set && varsok=false; fi
if  [ -z "$DSSC_AC" ]; then echo DSSC_AC must be set && varsok=false; fi
if  [ -z "$DSSC_USERNAME" ]; then echo DSSC_USERNAME must be set && varsok=false; fi
if  [ -z "$DSSC_TEMPPW" ]; then echo DSSC_TEMPPW must be set && varsok=false; fi
if  [ -z "$DSSC_PASSWORD" ]; then echo DSSC_PASSWORD must be set && varsok=false; fi
if  [ -z "$DSSC_HOST" ]; then echo DSSC_HOST must be set && varsok=false; fi
if  [ -z "$DSSC_REGUSER" ]; then echo DSSC_REGUSER must be set && varsok=false; fi
if  [ -z "$DSSC_REGPASSWORD" ]; then echo DSSC_REGPASSWORD must be set && varsok=false; fi

if  [ -z "$APP_GIT_URL1" ]; then echo APP_GIT_URL1 must be set && varsok=false; fi
if  [ -z "$APP_GIT_URL2" ]; then echo APP_GIT_URL2 must be set && varsok=false; fi
if  [ -z "$APP_GIT_URL3" ]; then echo APP_GIT_URL3 must be set && varsok=false; fi

#check Application Security settings (for runtime protection)
if  [ -z "$TREND_AP_KEY" ]; then echo TREND_AP_KEY must be set && varsok=false; fi
if  [ -z "$TREND_AP_SECRET" ]; then echo TREND_AP_SECRET must be set && varsok=false; fi

# if C1CS_RUNTIME does not exist, assume that C1CS_RUNTIME is enabled (for compatibility reasons)
if  [ -z "$C1CS_RUNTIME" ]; then export C1CS_RUNTIME="true";  fi  

if  [ "$varsok" = false ]; then
  printf '%s\n' "Please check your 00_define_vars.sh file"
  read -t 60 -p "exiting script in 60 seconds"
  exit
fi
printf '%s\n' "OK"

rolefound="false"
AWS_ROLES=(`aws iam list-roles | jq -r '.Roles[].RoleName ' | grep ${AWS_PROJECT} `)
for i in "${!AWS_ROLES[@]}"; do
  if [[ "${AWS_ROLES[$i]}" = "${AWS_PROJECT}EksClusterCodeBuildKubectlRole" ]]; then
     printf "%s\n" "Reusing existing EksClusterCodeBuildKubectlRole: ${AWS_ROLES[$i]} "
     rolefound="true"
  fi
done
if [[ "${rolefound}" = "false" ]]; then
  printf "%s\n" "Creating Role ${AWS_PROJECT}EksClusterCodeBuildKubectlRole"
  export ACCOUNT_ID=`aws sts get-caller-identity | jq -r '.Account'`
  TRUST="{ \"Version\": \"2012-10-17\", \"Statement\": [ { \"Effect\": \"Allow\", \"Principal\": { \"AWS\": \"arn:aws:iam::${ACCOUNT_ID}:root\" }, \"Action\": \"sts:AssumeRole\" } ] }"
  #TRUST="{ \"Version\": \"2012-10-17\", \"Statement\": [ { \"Effect\": \"Allow\", \"Resource\": { \"AWS\": \"arn:aws:iam::${ACCOUNT_ID}:role/*\" }, \"Action\": \"sts:AssumeRole\" } ] }"
  echo '{ "Version": "2012-10-17", "Statement": [ { "Effect": "Allow", "Action": "eks:Describe*", "Resource": "*" } ] }' > /tmp/iam-role-policy
  aws iam create-role --role-name ${AWS_PROJECT}EksClusterCodeBuildKubectlRole   --tags Key=${TAGKEY0},Value=${TAGVALUE0} Key=${TAGKEY1},Value=${TAGVALUE1} Key=${TAGKEY2},Value=${TAGVALUE2} --assume-role-policy-document "$TRUST" --output text --query 'Role.Arn'
  aws iam put-role-policy --role-name ${AWS_PROJECT}EksClusterCodeBuildKubectlRole --policy-name eks-describe --policy-document file:///tmp/iam-role-policy
fi


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
printf '%s\n' "Script run time = $((($MAINSTARTTIME-$MAINENDTIME)/60)) minutes"
 
#. ./strickt_security_settings.sh  

# create report
#still need to ensure that either "latest" gets scanned or that $TAG gets exported from the pipeline
# plus: data on Snyk findings is not visible in the report
# docker run --network host mawinkler/scan-report:dev -O    --name "${TARGET_IMAGE}"    --image_tag latest    --service "${DSSC_HOST}"    --username "${DSSC_USERNAME}"    --password "\"${DSSC_PASSWORD}"\"
#end