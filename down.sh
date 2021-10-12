#! /bin/bash

#still WIP state... needs work
printf '%s\n' "----------------------"
printf '%s\n' "Terminating environment"
printf '%s\n' "----------------------"
# check for variabels
#-----------------------
. 00_define_vars.sh

varsok=true
#if  [ -z "${AWS_REGION}" ]; then echo AWS_REGION must be set && varsok=false; fi
if  [ -z "${C1PROJECT}" ]; then printf '%s\n' "C1PROJECT must be set" && varsok=false; fi
if  [ "$varsok" = false ]; then exit ; fi

printf '%s\n' "Getting region from AWS configure"
export AWS_REGION=`aws configure get region`
printf '%s\n' "AWS_REGION= $AWS_REGION"


#remove this project's cluster from c1cs
C1CSCLUSTERS=(`\
curl --silent --location --request GET "${C1CSAPIURL}/clusters" \
--header 'Content-Type: application/json' \
--header "${C1AUTHHEADER}"  \
--header 'api-version: v1' \
 | jq -r ".clusters[] | select(.name == \"${C1PROJECT}\").id"`)

for i in "${!C1CSCLUSTERS[@]}"
do
  printf "%s\n" "C1CS: Removing cluster ${C1CSCLUSTERS[$i]}"
  curl --silent --location --request DELETE "${C1CSAPIURL}/clusters/${C1CSCLUSTERS[$i]}" \
--header 'Content-Type: application/json' \
--header "${C1AUTHHEADER}"  \
--header 'api-version: v1' 
done 


# remove this project's Policy from c1cs
C1CSPOLICIES=(`\
curl --silent --location --request GET "${C1CSAPIURL}/policies" \
--header 'Content-Type: application/json' \
--header "${C1AUTHHEADER}"  \
--header 'api-version: v1' \
 | jq -r ".policies[] | select(.name == \"${C1PROJECT}\").id"`)

for i in "${!C1CSPOLICIES[@]}"
do
  printf "%s\n" "C1CS: Removing policy ${C1CSPOLICIES[$i]}"
  curl --silent --location --request DELETE "${C1CSAPIURL}/policies/${C1CSPOLICIES[$i]}" \
--header 'Content-Type: application/json' \
--header "${C1AUTHHEADER}"  \
--header 'api-version: v1' 
done 


# remove this project's Scanner from c1cs
C1CSSCANNERS=(`\
curl --silent --location --request GET "${C1CSAPIURL}/scanners" \
--header 'Content-Type: application/json' \
--header "${C1AUTHHEADER}"  \
--header 'api-version: v1' \
 | jq -r ".scanners[] | select(.name == \"${C1PROJECT}\").id"`)

for i in "${!C1CSSCANNERS[@]}"
do
  printf "%s\n" "C1CS: Removing scanner ${C1CSSCANNERS[$i]}"
  curl --silent --location --request DELETE "${C1CSAPIURL}/scanners/${C1CSSCANNERS[$i]}" \
--header 'Content-Type: application/json' \
--header "${C1AUTHHEADER}"  \
--header 'api-version: v1' 
done 


#delete c1cs 
printf '%s\n' "C1CS: Removing from EKS cluster"
helm_c1cs=`helm list -n c1cs -o json | jq -r '.[].name'`
if [[ "${helm_c1cs}" == "trendmicro-c1cs" ]]; then
  printf "%s" "Uninstalling C1CS... "
  helm delete trendmicro-c1cs -n c1cs
fi

# remove these project groups from c1as
readarray -t C1ASGROUPS <<< `curl --silent --location --request GET "${C1ASAPIURL}/accounts/groups" --header 'Content-Type: application/json' --header "${C1AUTHHEADER}" --header 'api-version: v1' | jq -r ".[].name"`
readarray -t DUMMYARRAYTOFIXSYNTAXCOLORINGINVSCODE <<< `pwd `
echo C1ASGROUPS[@] =  ${C1ASGROUPS[@]}
readarray -t C1ASGROUPIDS <<< `curl --silent --location --request GET "${C1ASAPIURL}/accounts/groups" --header 'Content-Type: application/json' --header "${C1AUTHHEADER}" --header 'api-version: v1' | jq -r ".[].group_id"`
readarray -t DUMMYARRAYTOFIXSYNTAXCOLORINGINVSCODE <<< `pwd `

for i in "${!C1ASGROUPS[@]}"
do
  #printf "%s\n" "C1AS: found group ${C1ASGROUPS[$i]} with ID ${C1ASGROUPIDS[$i]}"
  if [[ "${C1ASGROUPS[$i]}" == "${C1PROJECT^^}-${APP1^^}" ]]; 
  then
    printf "%s\n" "Deleting old Group object ${C1PROJECT^^}-${APP1^^} in C1AS"
    curl --silent --location --request DELETE "${C1ASAPIURL}/accounts/groups/${C1ASGROUPIDS[$i]}"   --header 'Content-Type: application/json' --header "${C1AUTHHEADER}" --header 'api-version: v1' 
  fi
  if [[ "${C1ASGROUPS[$i]}" == "${C1PROJECT^^}-${APP2^^}" ]]; 
  then
    printf "%s\n" "Deleting old Group object ${C1PROJECT^^}-${APP2^^} in C1AS"
    curl --silent --location --request DELETE "${C1ASAPIURL}/accounts/groups/${C1ASGROUPIDS[$i]}"   --header 'Content-Type: application/json' --header "${C1AUTHHEADER}" --header 'api-version: v1' 
  fi
  if [[ "${C1ASGROUPS[$i]}" == "${C1PROJECT^^}-${APP3^^}" ]]; 
  then
    printf "%s\n" "Deleting old Group object ${C1PROJECT^^}-${APP3^^} in C1AS"
    curl --silent --location --request DELETE "${C1ASAPIURL}/accounts/groups/${C1ASGROUPIDS[$i]}"   --header 'Content-Type: application/json' --header "${C1AUTHHEADER}" --header 'api-version: v1' 
  fi

done 


#remove smartcheck 
helm_smartcheck=`helm list -n ${DSSC_NAMESPACE}  -o json | jq -r '.[].name'`
if [[ "${helm_smartcheck}" =~ "deepsecurity-smartcheck" ]]; then
  printf "%s" "Uninstalling smartcheck... "
  helm delete deepsecurity-smartcheck -n ${DSSC_NAMESPACE}
fi

#delete services
printf "%s\n" "Removing Services from EKS cluster"
for i in `kubectl get services -o json | jq -r '.items[].metadata.name'`
do
  printf "%s" "... "
  kubectl delete service $i
done

#delete deployed apps
printf "\n%s" "Removing Deployments from EKS cluster... "
for i in `kubectl get deployments  -o json | jq -r '.items[].metadata.name'`
do
  kubectl delete deployment $i
done

# Delete ECR repos
aws_ecr_repos=(`aws ecr describe-repositories --region ${AWS_REGION} | jq -r '.repositories[].repositoryName'`)
aws_ecr_repo=''
for i in "${!aws_ecr_repos[@]}"; do
  #printf "%s" "Repo $i =  ${aws_ecr_repos[$i]}"
  aws_ecr_repo=`echo ${1} | awk '{ print tolower($0) }'`
  if [[ "${aws_ecr_repos[$i]}" =~ "${C1PROJECT}" ]]; then
      printf "%s\n" "Deleting ECR repository: ${aws_ecr_repos[$i]}"
      aws_ecr_repo_exists="true"
      DUMMY=`aws ecr delete-repository --repository-name ${aws_ecr_repos[$i]} --region ${AWS_REGION} --force`
  fi
done

# Delete CodeCommit repos
aws_cc_repos=(`aws codecommit list-repositories --region $AWS_REGION | jq -r '.repositories[].repositoryName'`)
aws_cc_repo=''
for i in "${!aws_cc_repos[@]}"; do
  #printf '%s\n' "Checking CC Repo $i =  ${aws_cc_repos[$i]} ..........Comparing with ${1}"
  if [[ "${aws_cc_repos[$i]}" =~ "${C1PROJECT}" ]]; then
      printf "%s\n" "Deleting CodeCommit Repo "${aws_cc_repos[$i]}
      DUMMY=`aws codecommit delete-repository --repository-name ${aws_cc_repos[$i]} --region ${AWS_REGION}`
    fi
done

# Delete Cloudformation Stacks
aws_stack=""
aws_stacks=(`aws cloudformation describe-stacks --output json --region $AWS_REGION| jq -r '.Stacks[].StackName'` )
for i in "${!aws_stacks[@]}"; do
  #printf "%s\n" "stack $i =  ${aws_stacks[$i]}"
  if [[ "${aws_stacks[$i]}" =~ "${C1PROJECT}"  && "${aws_stacks[$i]}" =~ "Pipeline" ]]; then
    printf "%s \n" "Deleting CloudFormation Pipeline Stack ${aws_stacks[$i]}"
    aws cloudformation delete-stack --stack-name ${aws_stacks[$i]} --region ${AWS_REGION}
  fi
done
printf "\n"

# Waiting for Cloudformation Stacks to be deleted
aws_stack=""
aws_stacks=(`aws cloudformation describe-stacks --output json --region $AWS_REGION| jq -r '.Stacks[].StackName'` )
for i in "${!aws_stacks[@]}"; do
  #printf "%s\n" "stack $i =  ${aws_stacks[$i]}"
  if [[ "${aws_stacks[$i]}" =~ "${C1PROJECT}"  && "${aws_stacks[$i]}" =~ "Pipeline" ]]; then
    printf "%s \n" "Waiting for CloudFormation Pipeline Stack ${aws_stacks[$i]} to be deleted"
    aws cloudformation wait stack-delete-complete --stack-name ${aws_stacks[$i]}  --region ${AWS_REGION}
  fi
done
printf "\n"


#TBD: delete log groups

# delete cluster
aws_eks_clusters=(`eksctl get clusters -o json | jq -r '.[].metadata.name'`)
for i in "${!aws_eks_clusters[@]}"; do
  #printf "%s" "cluster $i =  ${aws_eks_clusters[$i]}.........."
  if [[ "${aws_eks_clusters[$i]}" =~ "${C1PROJECT}" ]]; then
       printf "%s\n" "Deleting EKS cluster: ${C1PROJECT}"
       printf "%s\n" "Waiting for EKS cluster to be deleted. "
       printf "%s\n" "   Please be patient, this can take up to 30 minutes... (started at:`date`)"
       starttime=`date +%s`
       eksctl delete cluster ${C1PROJECT} --wait
       sleep 30  #giving the delete cluster process a bit more time
       endtime=`date +%s`
       printf '%s\n' "  Elapsed time: $((($endtime-$starttime)/60)) minutes"
  fi
done

# deleting apps directory
printf "%s\n" "Deleting: ~/environment/apps"
rm -rf ~/environment/apps

# Cleaning up project VPC, starting with its dependencies
# Note: idealy the VPC should have been deleted with the EKS cluster, in reality this sometimes fails
# the below is a failsave attempt to cleanup any remains
aws_vpc_ids=(`aws ec2 describe-vpcs | jq -r ".Vpcs[].VpcId"`)
#find Project VPCs
for i in "${!aws_vpc_ids[@]}"; do
  #printf "%s\n" "vpc $i = ${aws_vpc_ids[$i]}.........."
  aws_vpc_tags=`aws ec2 describe-vpcs --vpc-ids ${aws_vpc_ids[$i]} | jq -r '.Vpcs[].Tags'`  #no array needed here; just get thm all in one string
  #printf "%s\n" "${aws_vpc_tags}"
  if [[ ${aws_vpc_tags} =~ "c1onaws" ]];then
    printf "%s\n" "Found VPC belonging to project: ${aws_vpc_ids[$i]}"
    aws_attachment_ids=(`aws ec2 describe-network-interfaces --filters Name=vpc-id,Values=${aws_vpc_ids[$i]} | jq -r '.NetworkInterfaces[].Attachment.AttachmentId'`)
      printf "%s\n" "Found Network attachment_ids: ${aws_attachment_ids[@]}"
    for j in "${!aws_attachment_ids[@]}"; do
        printf "%s\n" "Found attachment ID ${aws_attachment_ids[$j]}"
      if [[ "${aws_attachment_ids[$j]}" != "null" &&  "${aws_attachment_ids[$j]}" != "" ]];then
        printf "%s\n" "Detaching ENI with attachment_id ${aws_attachment_ids[$j]}"
        aws ec2 detach-network-interface --attachment-id  ${aws_attachment_ids[$j]}
        #get ENI ID
      else
        printf "%s\n" "No Elastic Network Interface attached"
      fi
    done
    aws_ENI_ids=(`aws ec2 describe-network-interfaces --filters Name=vpc-id,Values=${aws_vpc_ids[$i]} | jq -r '.NetworkInterfaces[].NetworkInterfaceId'`)
    for j in "${!aws_ENI_ids[@]}"; do
        printf "%s\n" "Deleting ENI: ${aws_ENI_ids[$j]}"
        aws ec2 delete-network-interface --network-interface-id ${aws_ENI_ids[$j]}
    done
    #delete Load Balancer
    aws_lb=(`aws elb describe-load-balancers | jq -r ".LoadBalancerDescriptions[]|select(.VPCId|test(\"${aws_vpc_ids[$i]}\"))|.LoadBalancerName"`)

    for j in "${!aws_lb[@]}"; do
      if [[ "${aws_lb[$j]}" != "null" &&  "${aws_lb[$j]}" != "" ]];then
        printf "%s\n" "Deleting Load Balancer: xxxxx${aws_lb[$j]}xxxxxxxxx"
        aws elb delete-load-balancer --load-balancer-name ${aws_lb[$j]}
      else
        printf "%s\n" "No Load Balancer attached"
      fi
    done

    #delete nat gateway
    natgw_id=`aws ec2 describe-nat-gateways --filter "Name=vpc-id,Values=${aws_vpc_ids[$i]}"  | jq -r ".NatGateways[].NatGatewayId"`
    if [[ "${natgw_id}" != "null" &&  "${natgw_id}" != "" ]];then
      printf "%s\n" "Deleting NAT Gateway: ${natgw_id}"
      aws ec2 delete-nat-gateway --nat-gateway-id ${natgw_id}
    else
      printf "%s\n" "No NAT Gateway attached"
    fi

    #delete internet gateway
    igw_id=`aws ec2 describe-internet-gateways | jq -r ".InternetGateways[]|
    select(.Attachments[].VpcId|test(\"${aws_vpc_ids[$i]}\"))|.InternetGatewayId"`
    if [[ "${igw_id}" != "null" &&  "${igw_id}" != "" ]];then
      printf "%s\n" "Detaching Internet Gateway: ${igw_id}"
      aws ec2 detach-internet-gateway --internet-gateway-id ${igw_id}  --vpc-id=${aws_vpc_ids[$i]}
      printf "%s\n" "Deleting Internet Gateway: ${igw_id}"
      aws ec2 delete-internet-gateway --internet-gateway-id ${igw_id}
    else
      printf "%s\n" "No Internet Gateway attached"
    fi

    #delete security groups
    printf "%s\n" "Checking Security Groups"
    aws_sg_ids=(`aws ec2 describe-security-groups --filters Name=vpc-id,Values=${aws_vpc_ids[$i]} | jq -r '.SecurityGroups[].GroupId'`)
    for j in "${!aws_sg_ids[@]}"; do
        if [[ "`aws ec2 describe-security-groups --filters Name=group-id,Values=${aws_sg_ids[$j]} | jq -r '.SecurityGroups[].GroupName'`" != "default" ]];then
          printf "%s\n" "Deleting Security Group: ${aws_sg_ids[$j]}"
          aws ec2 delete-security-group --group-id ${aws_sg_ids[$j]}
        fi
    done


    #delete Subnets
    printf "%s\n" "Checking Subnets"
    aws_sn_ids=(`aws ec2 describe-subnets --filters Name=vpc-id,Values=${aws_vpc_ids[$i]} | jq -r '.Subnets[].SubnetId'`)
    for j in "${!aws_sn_ids[@]}"; do
        if [[ "`aws ec2 describe-subnets --filters Name=subnet-id,Values=${aws_sn_ids[j]} | jq -r '.Subnets[].DefaultForAz'`" != "true" ]];then
          printf "%s\n" "Deleting Subnet: ${aws_sn_ids[$j]}"
          aws ec2 delete-subnet --subnet-id ${aws_sn_ids[$j]}
        fi
    done

    printf "%s\n" "Checking dependencies of VPC: ${aws_vpc_ids[$i]}"
    vpc=${aws_vpc_ids[$i]}
    printf "%s\n" "Checking dependencies of VPC: $vpc"
    #TO DO delete ENIs first
      aws ec2 describe-network-interfaces --filters 'Name=vpc-id,Values='$vpc | grep NetworkInterfaceId | jq

    aws ec2 describe-internet-gateways --filters 'Name=attachment.vpc-id,Values='$vpc | grep InternetGatewayId
    aws ec2 describe-subnets --filters 'Name=vpc-id,Values='$vpc | grep SubnetId
    RTASSOCIATIONID=$(aws ec2 describe-route-tables --filters 'Name=vpc-id,Values='$vpc | jq -r ".RouteTables[].RouteTableAssociationId")
    aws ec2 describe-network-acls --filters 'Name=vpc-id,Values='$vpc | grep NetworkAclId
    aws ec2 describe-vpc-peering-connections --filters 'Name=requester-vpc-info.vpc-id,Values='$vpc | grep VpcPeeringConnectionId
    aws ec2 describe-vpc-endpoints --filters 'Name=vpc-id,Values='$vpc | grep VpcEndpointId
    aws ec2 describe-nat-gateways --filter 'Name=vpc-id,Values='$vpc | grep NatGatewayId
    aws ec2 describe-security-groups --filters 'Name=vpc-id,Values='$vpc | grep GroupId
    aws ec2 describe-instances --filters 'Name=vpc-id,Values='$vpc | grep InstanceId
    aws ec2 describe-vpn-connections --filters 'Name=vpc-id,Values='$vpc | grep VpnConnectionId
    aws ec2 describe-vpn-gateways --filters 'Name=attachment.vpc-id,Values='$vpc | grep VpnGatewayId
  

    printf "%s\n" "Deleting VPC: ${aws_vpc_ids[$i]}  (hopefully)"
    aws ec2 delete-vpc --vpc-id ${aws_vpc_ids[$i]}
    printf "%s\n" "---"
  fi
done

#the EKS cluster should already have been deleted  (in reality it is sometimes not)
aws_eks_clusters=(`eksctl get clusters -o json | jq -r '.[].metadata.name'`)
for i in "${!aws_eks_clusters[@]}"; do
  printf "%s" "cluster $i =  ${aws_eks_clusters[$i]}.........."
  if [[ "${aws_eks_clusters[$i]}" =~ "${C1PROJECT}"  && "${aws_eks_clusters[$i]}" =~ "Pipeline" ]]; then
      printf "%s\n" "Deleting EKS cluster: ${C1PROJECT}"
      if [ -s  "${C1PROJECT}EksCluster.yml" ]; then
        #eksctl delete cluster -f ${C1PROJECT}EksCluster.yml
        echo "Second attempt to delete the EKS cluster"
        eksctl delete cluster ${C1PROJECT}
        sleep 30  #giving the delete cluster process a bit more time
      else
        printf '%s \n' "PANIC: eks cluster with name ${C1PROJECT} exists, but file \"${C1PROJECT}EksCluster.yml\" does not"
        printf '%s \n' "This situation should not exist.  Manual cleanup is required"
      fi
  else
      printf "%s\n" ""
  fi
done


printf "%s\n" "Checking CloudFormation EKS nodegroup Stack"
aws_stack=""
aws_stacks=(`aws cloudformation describe-stacks --output json --region $AWS_REGION| jq -r '.Stacks[].StackName'` )
for i in "${!aws_stacks[@]}"; do
  # printf "%s\n" "stack $i =  ${aws_stacks[$i]}"
  if [[ "${aws_stacks[$i]}" =~ "eksctl-${C1PROJECT}-nodegroup" ]]; then
    printf "%s\n" "Deleting CloudFormation Stack:  ${aws_stacks[$i]}"
    starttime=`date +%s`
    printf "%s\n" "Please be patient, this can take up to 30 minutes... (started at:`date`)"
    aws cloudformation delete-stack --stack-name ${aws_stacks[$i]} --region ${AWS_REGION}
    #aws cloudformation wait stack-delete-complete --stack-name ${aws_stacks[$i]}  --region ${AWS_REGION}
    endtime=`date +%s`
    printf '%s\n' "Elapsed time: $((($endtime-$starttime)/60)) minutes"
  fi
done

printf "%s\n" "Checking CloudFormation EKS Stack"
aws_stack=""
aws_stacks=(`aws cloudformation describe-stacks --output json --region $AWS_REGION| jq -r '.Stacks[].StackName'` )
for i in "${!aws_stacks[@]}"; do
  # printf "%s\n" "stack $i =  ${aws_stacks[$i]}"
  if [[ "${aws_stacks[$i]}" =~ "eksctl-${C1PROJECT}-cluster" ]]; then
    printf "%s\n" "Waiting for CloudFormation Stack deletion to complete:  ${aws_stacks[$i]}"
    starttime=`date +%s`
    printf "%s\n" "Please be patient, this can take up to 30 minutes... (started at:`date`)"
    #aws cloudformation delete-stack --stack-name ${aws_stacks[$i]} --region ${AWS_REGION}
    aws cloudformation wait stack-delete-complete --stack-name ${aws_stacks[$i]}  --region ${AWS_REGION}
    endtime=`date +%s`
    printf '%s\n' "Elapsed time: $((($endtime-$starttime)/60)) minutes"
  fi
done

##UPDATE THE DELETE BUCKETS AFTER THE MEGA S3 BUCKET HAS BEEN DELETED !!!!!!!!!!!!!!!

#cleanup codepipelineartifactbuckets
readarray -t BUCKETS  <<< `aws s3api list-buckets --region ${AWS_REGION}| jq -r '.Buckets[].Name' `
readarray -t DUMMYARRAYTOFIXSYNTAXCOLORINGINVSCODE <<< `pwd `
for i in "${!BUCKETS[@]}"; do
  #printf '%s\n' "Bucket ${i} = ${BUCKETS[${i}]}"
  BUCKETNAME=`aws s3 ls ${BUCKETS[${i}]}` 
  echo "${i}  ${BUCKETS[${i}]}" ${BUCKETNAME}
  if [[ "${BUCKETS[${i}]}" =~ "codepipelineartifact" ]] &&  [[ "${BUCKETNAME}" =~ "${C1PROJECT}" ]]; then
      printf "%s\n"  "Deleting codepipelineartifactbucket: ${BUCKETNAME}"
      aws s3 rb s3://${BUCKETS[${i}]} --force  2>/dev/null
      #aws s3api  delete-bucket  --bucket ${BUCKETS[$i]}  --region ${AWS_REGION}
  else
      printf "%s"  "."
  fi
done

#cleaning up local files
[ -e ${C1PROJECT}EksCluster.yml ] && rm ${C1PROJECT}EksCluster.yml
[ -e ${C1PROJECT}${APP1}Pipeline.yml ] && rm ${C1PROJECT}${APP1}Pipeline.yml
[ -e ${C1PROJECT}${APP2}Pipeline.yml ] && rm ${C1PROJECT}${APP2}Pipeline.yml
[ -e ${C1PROJECT}${APP3}Pipeline.yml ] && rm ${C1PROJECT}${APP3}Pipeline.yml
[ -e req.conf ] && rm req.conf
[ -e k8s.key ] && rm k8s.key
[ -e k8s.crt ] && rm k8s.crt
[ -e overrides.yml ] && rm overrides.yml

#printf "%s\n" "Deleting Roles and Instance-Profiles"
#AWS_ROLES=(`aws iam list-roles | jq -r '.Roles[].RoleName ' | grep ${C1PROJECT} `)
#for i in "${!AWS_ROLES[@]}"; do
#  if [[ "${AWS_ROLES[$i]}" =~ "${C1PROJECT}" ]]; then
#     printf "%s\n" "Role $i =  ${AWS_ROLES[$i]}.........."
#     #printf "%s\n" "Getting AWS_POLICIES"
#     AWS_POLICIES=(`aws iam list-role-policies --role-name ${AWS_ROLES[$i]} | jq -r '.PolicyNames[]'`)
#      #              aws iam list-role-policies --role-name ${AWS_ROLES[$i]}
#     printf "%s\n" "AWS_POLICIES= $AWS_POLICIES"
#     for j in "${!AWS_POLICIES[@]}"; do
#       printf "%s\n" "  Policy $j =  ${AWS_POLICIES[$j]}"
#       printf "%s\n" "     Detaching Policy ${AWS_POLICIES[$j]} from Role ${AWS_ROLES[$i]} "
#       aws iam detach-role-policy --role-name ${AWS_ROLES[$i]} --policy-name ${AWS_POLICIES[$j]}
#       printf "%s\n" "     Deleting Role-policy Policy ${AWS_POLICIES[$j]}"
#       aws iam delete-role-policy --role-name ${AWS_ROLES[$i]} --policy-name ${AWS_POLICIES[$j]}
#     done
#     #printf "%s\n" "Getting instance Profiles"
#     #printf "%s\n" "Analyzing Instance Profiles for Role: ${AWS_ROLES[$i]}"
#     AWS_PROFILES=(`aws iam list-instance-profiles-for-role --role-name ${AWS_ROLES[$i]} | jq -r '.InstanceProfiles[].InstanceProfileName'`)
#     printf "%s\n" "AWS_PROFILES = $AWS_PROFILES"
#     for k in "${!AWS_PROFILES[@]}"; do
#       printf "%s\n" "  Profile $k =  ${AWS_PROFILES[$k]}"
#       aws iam remove-role-from-instance-profile --role-name ${AWS_ROLES[$i]} --instance-profile-name ${AWS_PROFILES[$j]}
#       aws iam delete-instance-profile --instance-profile-name ${AWS_PROFILES[$j]}
#     done
#     aws iam delete-role  --role-name ${AWS_ROLES[$i]}
#  fi
#done
#aws iam list-roles | jq -r '.Roles[].RoleName ' | grep cloudone

#TODO: delete Policy
