#!/bin/bash
printf '%s\n' "-------------------------------------"
printf '%s\n' "     Installing / Checking Tools     "
printf '%s\n' "-------------------------------------"

varsok=true

# Validating the shell
if [ -z "$BASH_VERSION" ]; then
   printf '%s\n' "Error: this script requires the BASH shell!"
   read -p "Press CTRL-C to exit script, or Enter to continue anyway (script will fail)"
fi

# Installing packages  
printf '%s\n'  "Updating Package Manager"
if  [ -x "$(command -v apt-get)" ] ; then
  sudo apt-get -qq update 1>/dev/null 2>/dev/null
  sudo apt-get -qq install ca-certificates curl apt-transport-https lsb-release gnupg jq -y
else
   printf '%s' "Cannot install packages... no supported package manager found, must run on Debian/Ubuntu"
   read -p "Press CTRL-C to exit script, or Enter to continue anyway (script will fail)"
fi 

# Installing jq
if ! [ -x "$(command -v jq)" ] ; then
    printf '%s\n'  "installing jq"
    if  [ -x "$(command -v apt-get)" ] ; then
      sudo apt-get install jq -y
    elif  [ -x "$(command -v yum)" ] ; then
      sudo yum install jq -y
    else
      printf '%s' "Cannot install jq... no supported package manager found"
     read -p "Press CTRL-C to exit script, or Enter to continue anyway (script will fail)"
    fi 
else
    printf '%s\n' "Using existing jq.  Version : `jq --version 2>/dev/null`"
fi

# Installing kubectl
printf '%s\n' "Installing/upgrading kubectl...."
sudo curl --silent -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
sudo chmod +x /usr/local/bin/kubectl

# Installing helm
if ! [ -x "$(command -v helm)" ] ; then
    printf '%s\n'  "installing helm...."
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
else
    printf '%s\n'  "Using existing helm.  Version" `helm version  | awk -F',' '{ print $1 }' | awk -F'{' '{ print $2 }' | awk -F':' '{ print $2 }' | sed 's/"//g'`
fi

# setting additional variables 
export PROJECTDIR=`pwd` 
export WORKDIR=${PROJECTDIR}/work
export APPSDIR=${PROJECTDIR}/apps
mkdir -p ${WORKDIR}
mkdir -p ${APPSDIR}
export LC_COLLATE=C  # IMPORTANT setting of LC_LOCATE for the pattern testing the variables
export C1AUTHHEADER="Authorization:	ApiKey ${C1APIKEY}"
export C1CSAPIURL="https://container.${C1REGION}.cloudone.trendmicro.com/api"
export C1CSENDPOINTFORHELM="https://container.${C1REGION}.cloudone.trendmicro.com"
export C1ASAPIURL="https://application.${C1REGION}.cloudone.trendmicro.com"
export DSSC_HOST_FILTER=".status.loadBalancer.ingress[].hostname"

# Generating names for Apps, Stack, Pipelines, ECR, CodeCommit repo,..."
#generate the names of the apps from the git URL
#export APP1=moneyx
export APP1=`echo ${APP1_GIT_URL} | awk -F"/" '{print $NF}' | awk -F"." '{ print $1 }' | tr -cd '[:alnum:]'| awk '{ print tolower($1) }'`
export APP2=`echo ${APP2_GIT_URL} | awk -F"/" '{print $NF}' | awk -F"." '{ print $1 }' | tr -cd '[:alnum:]'| awk '{ print tolower($1) }'`
export APP3=`echo ${APP3_GIT_URL} | awk -F"/" '{print $NF}' | awk -F"." '{ print $1 }' | tr -cd '[:alnum:]'| awk '{ print tolower($1) }'`

# checking dockerlogin
printf "%s" "Validating Docker login..."
DOCKERLOGIN=`docker login -u $DOCKERHUB_USERNAME -p $DOCKERHUB_PASSWORD 2>/dev/null`
[ ${VERBOSE} -eq 1 ] && printf "\n%s\n" "DOCKERLOGIN= $DOCKERLOGIN"
if [[ ${DOCKERLOGIN} == "Login Succeeded" ]];then 
  printf "%s\n" "OK"; 
else 
  printf "%s\n" "Docker Login Failed.  Please check the Docker Variables in 00_define.var.sh";    
fi

# pulling/cloning common parts
printf "\n%s\n" "Cloning/pulling deploySmartcheck"
mkdir -p deploySmartcheck
git clone https://github.com/cvdabbeele/deploySmartcheck.git deploySmartcheck
cp deploySmartcheck/*.sh ./
rm -rf deploySmartcheck

printf "\n%s\n" "Cloning/pulling deployC1ASandC1CS"
mkdir -p deployC1ASandC1CS
git clone https://github.com/cvdabbeele/deployC1ASandC1CS.git deployC1ASandC1CS
cp deployC1ASandC1CS/*.sh ./
rm -rf deployC1ASandC1CS


#can I create and C1AS opbject? (validating C1APIkeyb)
export C1ASRND=-$(openssl rand -hex 4)
export PAYLOAD="{ \"name\": \"${C1PROJECT^^}-${C1ASRND}\"}"
printf "%s" "Validating C1API key by creating C1AS Group object ${C1PROJECT^^}-${C1ASRND}\"} in C1AS..."
export C1ASGROUPCREATERESULT=`\
curl --silent --location --request POST "${C1ASAPIURL}/accounts/groups/" --header 'Content-Type: application/json' --header "${C1AUTHHEADER}" --header 'api-version: v1'  --data-raw "${PAYLOAD}" \
`
[ ${VERBOSE} -eq 1 ] &&  printf "%s" "$C1ASGROUPCREATERESULT"
APPKEY=`printf "%s" "C1ASGROUPCREATERESULT" | jq   -r ".credentials.key"`
[ ${VERBOSE} -eq 1 ] &&  printf "%s" APPKEY=$APPKEY
APPSECRET=`printf "%s" "$C1ASGROUPCREATERESULT" | jq   -r ".credentials.secret"`
[ ${VERBOSE} -eq 1 ] &&  printf "%s" APPSECRET= $APPSECRET
if [[ "$APPKEY" == "null"  ]];then
   printf "\n%s\n" "Failed to create group object in C1AS for ${1}"; 
   read -p "Press CTRL-C to exit script, or Enter to continue anyway (script will fail)"
else
  printf "%s\n" "OK"
  #deleting C1AS test object

     printf "%s\n" "Deleting test Group object ${C1PROJECT^^}-${C1ASRND} in C1AS"
    curl --silent --location --request DELETE "${C1ASAPIURL}/accounts/groups/${C1PROJECT^^}-${C1ASRND}"   --header 'Content-Type: application/json' --header "${C1AUTHHEADER}" --header 'api-version: v1' 
  
   ${C1PROJECT^^}-${C1ASRND}\"} 
fi
} 



# ---------------
#  AWS specific 
# ---------------
export PLATFORM="AWS"
export DSSC_SUBJECTALTNAME="*.${AWS_REGION}.elb.amazonaws.com"

# Installing eksctl
if ! [ -x "$(command -v eksctl)" ] ; then
    printf '%s\n'  "installing eksctl...."
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    sudo mv -v /tmp/eksctl /usr/local/bin
else
    printf '%s\n'  "Using existing eksctl. Version: `eksctl version`"
fi

# Installing aws authenticator
if ! [ -x "$(command -v aws-iam-authenticator)" ] ; then
    printf '%s\n'  "installing AWS authenticator...."
    curl -s -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.16.8/2020-04-16/bin/linux/amd64/aws-iam-authenticator
    chmod +x ./aws-iam-authenticator
    mkdir -p $HOME/bin && cp ./aws-iam-authenticator $HOME/bin/aws-iam-authenticator && export PATH=$PATH:$HOME/bin
else
    printf '%s\n'  "Using existing AWS authenticator. Version `aws-iam-authenticator version | jq -r '.Version'  2>/dev/null`"
fi

# Validate aws keys 
DUMMY=`aws s3 ls`
if [ "$?" != "0" ]; then
  echo "Check AWS keys and, re-run aws configure" && varsok=false; 
  aws configure
fi
DUMMY=`aws s3 ls`
if [ "$?" != "0" ]; then
  echo "AWS credentials still not OK, exit the script and re-run aws configure"
  varsok=false; 
  read -p "Press CTRL-C to exit script, or Enter to continue anyway (script will fail)"
fi


export ACCOUNT_ID=`aws sts get-caller-identity | jq -r '.Account'`
export AWS_REGION=`aws configure get region`
export AWS_ACCESS_KEY_ID=`aws configure get aws_access_key_id`
export AWS_SECRET_ACCESS_KEY=`aws configure get aws_secret_access_key`


# Declaring associative arrays (mind the capital 'A')
declare -A VAROK
declare -A VARFORMAT

# set list of VARS_TO_VALIDATE_BY_FORMAT
VARS_TO_VALIDATE_BY_FORMAT=(C1REGION C1CS_RUNTIME C1PROJECT DSSC_AC C1APIKEY AWS_EKS_NODES)
# set the expected FORMAT for each variable
#  ^ is the beginning of the line anchor
#  [...] is a character class definition
#  * is "zero-or-more" repetition
#  $ is the end of the line anchor
# in the IF comparison, the "=~" means the right hand side is a regex expression
VARFORMAT[C1REGION]="^(us-1|in-1|gb-1|jp-1|de-1|au-1|ca-1|sg-1|trend-us-1)$"
VARFORMAT[C1CS_RUNTIME]="^(true|false)$"
VARFORMAT[C1PROJECT]="^[a-z0-9]*$"
VARFORMAT[DSSC_AC]='^[A-Z]{2}-[[:alnum:]]{4}-[[:alnum:]]{5}-[[:alnum:]]{5}-[[:alnum:]]{5}-[[:alnum:]]{5}-[[:alnum:]]{5}$'
VARFORMAT[C1APIKEY]='^[[:alnum:]]{27}:[[:alnum:]]{66}$'
VARFORMAT[AWS_EKS_NODES]='^[1-5]'

# Check all variables from the VARS_TO_VALIDATE_BY_FORMAT list
INPUTISVALID="true"
for i in "${VARS_TO_VALIDATE_BY_FORMAT[@]}"; do
  [ ${VERBOSE} -eq 1 ] && printf "%s"  "checking variable ${i} with contents =  ${!i}    "
  if [[ ${!i} =~ ${VARFORMAT[$i]} ]];then
    VAROK[$i]="true"
   [ ${VERBOSE} -eq 1 ] && printf "%s\n"  "OK"
  else
    VAROK[$i]="false"
    INPUTISVALID="false"
    printf "%s\n" "Variable ${i} has a wrong format. "
    printf "%s\n" "     Contents =  ${!i} " 
    printf "%s\n" "     Expected format must be ${VARFORMAT[$i]} "
  fi
done

if [[ ${INPUTISVALID} == "true" ]]; then
  echo "All variables checked out ok"
else
  echo "Please correct the above-mentioned variables"
  read -p "Press CTRL-C to exit script, or Enter to continue anyway (script will fail)"
fi

# quick-check other variables 
if  [ -z "$DOCKERHUB_USERNAME" ]; then echo DOCKERHUB_USERNAME must be set && varsok=false; fi
if  [ -z "$DOCKERHUB_PASSWORD" ]; then echo DOCKERHUB_PASSWORD must be set && varsok=false; fi
if  [ -z "$DSSC_PASSWORD" ]; then echo DSSC_PASSWORD must be set && varsok=false; fi
if  [ -z "$DSSC_REGPASSWORD" ]; then echo DSSC_REGPASSWORD must be set && varsok=false; fi
if  [ -z "$DSSC_NAMESPACE" ]; then echo DSSC_NAMESPACE must be set && varsok=false; fi
if  [ -z "$DSSC_USERNAME" ]; then echo DSSC_USERNAME must be set && varsok=false; fi
if  [ -z "$DSSC_TEMPPW" ]; then echo DSSC_TEMPPW must be set && varsok=false; fi
if  [ -z "$DSSC_HOST" ]; then echo DSSC_HOST must be set && varsok=false; fi
if  [ -z "$DSSC_REGUSER" ]; then echo DSSC_REGUSER must be set && varsok=false; fi
if  [ -z "$TAGKEY0" ]; then echo TAGKEY0 must be set && varsok=false; fi
if  [ -z "$TAGVALUE0" ]; then echo TAGVALUE0 must be set && varsok=false; fi
if  [ -z "$TAGKEY1" ]; then echo TAGKEY1 must be set && varsok=false; fi
if  [ -z "$TAGVALUE1" ]; then echo TAGVALUE1 must be set && varsok=false; fi
if  [ -z "$TAGKEY2" ]; then echo TAGKEY2 must be set && varsok=false; fi
if  [ -z "$TAGVALUE2" ]; then echo TAGVALUE2 must be set && varsok=false; fi

if  [ -z "$APP1_GIT_URL" ]; then printf '%s\n' "APP1_GIT_URL must be set && varsok=false"; fi
if  [ -z "$APP2_GIT_URL" ]; then printf '%s\n' "APP2_GIT_URL must be set && varsok=false"; fi
if  [ -z "$APP3_GIT_URL" ]; then printf '%s\n' "APP3_GIT_URL must be set && varsok=false"; fi

if  [ "$varsok" = false ]; then
  printf '%s\n' "Please check your 00_define_vars.sh file"
  read -p "Press CTRL-C to exit script, or Enter to continue anyway (script will fail)"
fi
#printf '%s\n' "OK"

rolefound="false"
AWS_ROLES=(`aws iam list-roles | jq -r '.Roles[].RoleName ' | grep ${C1PROJECT} `)
for i in "${!AWS_ROLES[@]}"; do
  if [[ "${AWS_ROLES[$i]}" = "${C1PROJECT}EksClusterCodeBuildKubectlRole" ]]; then
     printf "%s\n" "Reusing existing EksClusterCodeBuildKubectlRole: ${AWS_ROLES[$i]} "
     rolefound="true"
  fi
done
if [[ "${rolefound}" = "false" ]]; then
  printf "%s\n" "Creating Role ${C1PROJECT}EksClusterCodeBuildKubectlRole"
  export ACCOUNT_ID=`aws sts get-caller-identity | jq -r '.Account'`
  TRUST="{ \"Version\": \"2012-10-17\", \"Statement\": [ { \"Effect\": \"Allow\", \"Principal\": { \"AWS\": \"arn:aws:iam::${ACCOUNT_ID}:root\" }, \"Action\": \"sts:AssumeRole\" } ] }"
  #TRUST="{ \"Version\": \"2012-10-17\", \"Statement\": [ { \"Effect\": \"Allow\", \"Resource\": { \"AWS\": \"arn:aws:iam::${ACCOUNT_ID}:role/*\" }, \"Action\": \"sts:AssumeRole\" } ] }"
  echo '{ "Version": "2012-10-17", "Statement": [ { "Effect": "Allow", "Action": "eks:Describe*", "Resource": "*" } ] }' > /tmp/iam-role-policy

  aws iam create-role --role-name ${C1PROJECT}EksClusterCodeBuildKubectlRole   --tags Key=${TAGKEY0},Value=${TAGVALUE0} Key=${TAGKEY1},Value=${TAGVALUE1} Key=${TAGKEY2},Value=${TAGVALUE2} --assume-role-policy-document "$TRUST" --output text --query 'Role.Arn'
  aws iam put-role-policy --role-name ${C1PROJECT}EksClusterCodeBuildKubectlRole --policy-name eks-describe --policy-document file:///tmp/iam-role-policy
fi

# checking AWS Service Limits
## checking VPC Service Limit (Can I create a VPC?)
printf "%s" "testing VPC Service Limit (Can I create a VPC?)..."
[ ${VERBOSE} -eq 1 ] && printf "\n%s" "Trying to create a VPC..."
TESTVPCID=`aws ec2 create-vpc --cidr-block 10.0.0.0/16 | jq -r ".Vpc.VpcId"`
if [[ "${?}" -ne 0 ]]; then
  [ ${VERBOSE} -eq 1 ] && printf "\n%s\n" "TESTVPCID= ${TESTVPCID}"
  printf "\n%s\n" "ERROR: Unable to create a test VPC, check your \"AWS SERVICE LIMITS\"  (see also README.md"
  read -p "Press CTRL-C to exit script, or Enter to continue anyway (script will fail)"
else
  [ ${VERBOSE} -eq 1 ] && printf "%s\n" "Deleting test VPC with id= ${TESTVPCID}"
  aws ec2 delete-vpc --vpc-id ${TESTVPCID}
  printf "%s\n" "OK"
fi

## checing available Elastic IP Service Limit
printf "%s" "Testing Elastic IP Service Limit (Can I create an Elastic IP ?)..."
[ ${VERBOSE} -eq 1 ] && printf "%s\n" "Trying to create an Elastic IP"
TESTEIPALLOCATIONID=`aws ec2 allocate-address --domain vpc |jq -r ".AllocationId"`
if [[ "${?}" -ne 0 ]]; then
  [ ${VERBOSE} -eq 1 ] && printf "\n%s\n" "TestIpAcllocation id= ${TESTEIPALLOCATIONID}"
  printf "\n%s\n" "ERROR: unable to create a test elastic IP, check your \"AWS SERVICE LIMITS\"  (see also README.md"
  read -p "Press CTRL-C to exit script, or Enter to continue anyway (script will fail)"
else
  [ ${VERBOSE} -eq 1 ] && printf "%s\n" "Deleting test Elastic IP with id= ${TESTEIPALLOCATIONID}"
  aws ec2 release-address --allocation-id ${TESTEIPALLOCATIONID}
  printf "%s\n" "OK"
fi

## checking available Internet Gateway Service Limit
printf "%s" "Testing Internet Gateway Service Limit (Can I create an IGW ?)..."
[ ${VERBOSE} -eq 1 ] && printf "\n%s\n" "Trying to create an Internet Gateway"
TESTINTERNETGWID=`aws ec2 create-internet-gateway | jq -r ".InternetGateway.InternetGatewayId"`
if [[ "${?}" -ne 0 ]]; then
  [ ${VERBOSE} -eq 1 ] && printf "\n%s\n" "Internet Gateway Allocation id= ${TESTINTERNETGWID}"
  printf "\n%s\n" "ERROR: Unable to create a test Internet Gateway, check your \"AWS SERVICE LIMITS\"  (see also README.md"
  read -p "Press CTRL-C to exit script, or Enter to continue anyway (script will fail)"
else
  [ ${VERBOSE} -eq 1 ] && printf "%s\n" "Deleting test Internet Gateway with id= ${TESTINTERNETGWID}"
  aws ec2 delete-internet-gateway --internet-gateway-id  ${TESTINTERNETGWID}
  printf "%s\n" "OK"
fi

