#!/bin/bash
# import variables
# check for variabels
#-----------------------
printf '%s' "Importing variables... "
#TBD: verify ALL variables
. ./00_define_vars.sh

printf '%s\n'  "installing jq"
sudo apt-get install jq -y

export ACCOUNT_ID=`aws sts get-caller-identity | jq -r '.Account'`

  #tr -d "-" | tr -d "_"| awk '{ print tolower($1) }'

#declare -a APP_GITTT_URL
#export APP_GITTT_URL=(https://github.com/cvdabbeele/c1-app-sec-moneyx.git https://github.com/cvdabbeele/troopers.git https://github.com/cvdabbeele/mydvwa.git)


varsok=true
# Check AWS settings
#if  [ -z "$AWS_REGION" ]; then echo AWS_REGION must be set && varsok=false; fi
if  [ -z "$AWS_PROJECT" ]; then echo AWS_PROJECT must be set && varsok=false; fi
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

if  [ "$varsok" = false ]; then exit ; fi
printf '%s\n' "OK"

printf '%s\n' "--------------------------"
printf '%s\n' "Setting up Project ${AWS_PROJECT} "
printf '%s\n' "--------------------------"

#env | grep -i AWS
# configure AWS cli
printf '%s\n' "Getting region from AWS configure"
export AWS_REGION=`aws configure get region`
echo AWS_REGION= $AWS_REGION

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
./install_tools.sh

#create cluster
./create_cluster.sh

# deploy SmartCheck
./deploy_smartcheck.sh

#adding registries
./add_internal_repo.sh
./add_demo_repo.sh

# setup AWS CodePipeline
./setup_pipelines.sh

# add the demo apps
./add_demoApps.sh
