#!/bin/bash
# import variables
# check for variabels
#-----------------------
printf '%s' "Importing variables... "
. ./00_define_vars.sh
export ACCOUNT_ID=`aws sts get-caller-identity | jq -r '.Account'`
varsok=true
# Check AWS settings
#if  [ -z "$AWS_REGION" ]; then echo AWSC_REGION must be set && varsok=false; fi
if  [ -z "$AWS_PROJECT" ]; then echo AWSC_PROJECT must be set && varsok=false; fi
if  [ "$varsok" = false ]; then exit ; fi
printf '%s\n' "OK"

printf '%s\n' "--------------------------"
printf '%s\n' "Resuming Project ${AWS_PROJECT} "
printf '%s\n' "--------------------------"

#get AWS variables
export AWS_ACCESS_KEY_ID=`aws configure get aws_access_key_id`
export AWS_SECRET_ACCESS_KEY=`aws configure get aws_secret_access_key`
export AWS_REGION=`aws configure get region`

TMP=`cat ~/.aws/config | grep key`
if [[ ! ${TMP} =~ "key" ]]
then
  cat ~/.aws/credentials | grep key >> ~/.aws/config
fi
sed -n 's/aws_session_token = //g' ~/.aws/config
sed -n 's/aws_session_token = //g' ~/.aws/credentials

aws_cluster_exists="false"
aws_clusters=( `eksctl get clusters -o json| jq '.[].metadata.name'` )
for i in "${!aws_clusters[@]}"; do
  #printf "%s" "cluster $i =  ${aws_clusters[$i]}.........."
  if [[ "${aws_clusters[$i]}" =~ "${AWS_PROJECT}" ]]; then
      aws_cluster_exists="true"
      break
  fi
done

if [[ "${aws_cluster_exists}" = "true" ]]; then
    printf "%s\n" "Found EKS cluster ${AWS_PROJECT}"
else
    printf '%s\n' "Cannot find EKS cluster"
    #exit
fi

aws_nodegroup=`eksctl get nodegroup  --cluster=${AWS_PROJECT} -o json| jq -r '.[].Name'`

 if [[ "${aws_nodegroup}" == ""  ]]
 then
  printf "%s\n" "Creating nodegroup nodegroup"
  eksctl create nodegroup nodegroup --cluster=${AWS_PROJECT}
else
  printf "%s\n" "Already found a nodegroup for this cluster"
  printf "%s\n" "This is unexpected, please resolve manually or terminate and recreate the environment"
  printf "%s\n" "e.g. eksctl delete nodegroup  --cluster=${AWS_PROJECT}  --name=XYZ"
fi
