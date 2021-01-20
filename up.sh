#!/bin/bash
# import variables
# check for variabels
#-----------------------
#TODO: check if we have enough limits to create a VPC (or if one for our project already exists fro a previous run of this script)
#TODO: check if we have enough limits to create a IGW (or if one for our project already exists fro a previous run of this script
#TODO: check if we have enough limits to create an Elastic IP  (or if one for our project already exists fro a previous run of this script)

printf '%s' "Importing variables... "
. ./00_define_vars.sh

printf '%s\n'  "installing jq"
sudo apt-get install jq -y

export ACCOUNT_ID=`aws sts get-caller-identity | jq -r '.Account'`


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

if  [ "$varsok" = false ]; then
  printf '%s\n' "Please check your 00_define_vars.sh file"
  read -t 15 -p "exiting script in 15 seconds"
  exit
fi
printf '%s\n' "OK"

printf '%s\n' "--------------------------"
printf '%s\n' "Setting up Project ${AWS_PROJECT} "
printf '%s\n' "--------------------------"

#get AWS variables
export AWS_ACCESS_KEY_ID=`aws configure get aws_access_key_id`
export AWS_SECRET_ACCESS_KEY=`aws configure get aws_secret_access_key`
export AWS_REGION=`aws configure get region`

#TMP=`cat ~/.aws/config | grep key`
#if [[ ! ${TMP} =~ "key" ]]
#then
#  cat ~/.aws/credentials | grep key >> ~/.aws/config
#fi
#sed -n 's/aws_session_token = //g' ~/.aws/config
#sed -n 's/aws_session_token = //g' ~/.aws/credentials

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
  aws iam create-role --role-name ${AWS_PROJECT}EksClusterCodeBuildKubectlRole --assume-role-policy-document "$TRUST" --output text --query 'Role.Arn'
  aws iam put-role-policy --role-name ${AWS_PROJECT}EksClusterCodeBuildKubectlRole --policy-name eks-describe --policy-document file:///tmp/iam-role-policy
fi

# install tools
. ./install_tools.sh

#create cluster
. ./create_cluster.sh

# deploy SmartCheck
. ./deploy_smartcheck.sh

#adding registries
. ./add_internal_repo.sh
. ./add_demo_repo.sh

# setup AWS CodePipeline
. ./setup_pipelines.sh
  
# add ECR registry to SmartCheck
. ./add_ECR_registry.sh

# add the demo apps
. ./add_demoApps.sh

# add C1CS
. ./add_C1CS.sh
#end