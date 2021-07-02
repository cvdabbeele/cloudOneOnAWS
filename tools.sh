#!/bin/bash
printf '%s\n' "--------------------------"
printf '%s\n' "        Tools             "
printf '%s\n' "--------------------------"

printf '%s\n'  "installing jq"
sudo apt-get install jq -y


#!/bin/bash
printf '%s\n' "-------------------------------------"
printf '%s\n' "        Installing Tools             "
printf '%s\n' "-------------------------------------"

# Install jq
if ! [ -x "$(command -v jq)" ] ; then
    printf '%s\n'  "installing jq"
    if  [ -x "$(command -v apt-get)" ] ; then
      sudo apt-get install jq -y
    elif  [ -x "$(command -v yum)" ] ; then
      sudo yum install jq -y
    else
      printf '%s' "Cannot install jq... no supported package manager found"
      exit
    fi 
else
    printf '%s\n' "Using existing jq version : `jq --version 2>/dev/null`"
fi


# Install kubectl
if ! [ -x "$(command -v kubectl)" ] ; then
    printf '%s' "installing kubectl...."
    sudo curl --silent --location -o /usr/local/bin/kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.15.10/2020-02-22/bin/linux/amd64/kubectl
    sudo chmod +x /usr/local/bin/kubectl
else
    printf '%s\n' "Using existing kubectl version: `kubectl version  --output json  2>/dev/null | jq -r '.clientVersion|"Major: \(.major), Minor: \(.minor)"'`" 
fi

#Install eksctl
if ! [ -x "$(command -v eksctl)" ] ; then
    printf '%s\n'  "installing eksctl...."
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    sudo mv -v /tmp/eksctl /usr/local/bin
else
    printf '%s\n'  "Using existing eksctl version: `eksctl version`"
fi

#Install helm
if ! [ -x "$(command -v helm)" ] ; then
    printf '%s\n'  "installing helm...."
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
else
    printf '%s\n'  "Using existing helm version `helm version  | awk -F',' '{ print $1 }' | awk -F'{' '{ print $2 }' | awk -F':' '{ print $2 }' | sed 's/"//g'`"
fi



#Install aws authenticator
if ! [ -x "$(command -v aws-iam-authenticator)" ] ; then
    printf '%s\n'  "installing AWS authenticator...."
    curl -s -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.16.8/2020-04-16/bin/linux/amd64/aws-iam-authenticator
    chmod +x ./aws-iam-authenticator
    mkdir -p $HOME/bin && cp ./aws-iam-authenticator $HOME/bin/aws-iam-authenticator && export PATH=$PATH:$HOME/bin
else
    printf '%s\n'  "Using existing AWS authenticator version `aws-iam-authenticator version | jq -r '.Version'  2>/dev/null`"
fi
