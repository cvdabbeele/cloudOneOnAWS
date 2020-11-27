#!/bin/bash
# import variables
# check for variabels
#----------------------
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
printf '%s\n' "Pausing Project ${AWS_PROJECT} "
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
#TODO needs to be enhanced: jq errors when there are no nodegroups
aws_nodegroup=`eksctl get nodegroup  --cluster=${AWS_PROJECT} -o json| jq -r '.[].Name'`
if [[ "${aws_nodegroup}" == "nodegroup"  ]]; then
  printf "%s\n" "Deleting nodegroup \"nodegroup\""
  eksctl delete nodegroup nodegroup --cluster=${AWS_PROJECT}
  printf "%s\n" "Waiting for nodegroup \"nodegroup\" to be fully deleted"
  #TODO comparion in while needs to be enhanced
  while [[ `eksctl get nodegroup nodegroup --cluster=${AWS_PROJECT}` != "" ]];do
    aws_nodegroup=`eksctl get nodegroup  --cluster=${AWS_PROJECT} -o json| jq -r '.[].Name'`
    sleep 2
    printf "%s" "."
  done
  printf "%s\n" ""
fi
if [[ "`eksctl get nodegroup nodegroup --cluster=${AWS_PROJECT}`"  == ""  ]]; then
  printf "%s\n" "Nodegroup has been deleted"
fi
