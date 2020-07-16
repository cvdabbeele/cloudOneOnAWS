#!/bin/bash
printf '%s\n' "--------------------------"
printf '%s\n' "        Tools             "
printf '%s\n' "--------------------------"

printf '%s\n'  "installing jq"
sudo apt-get install jq -y

#Install kubectl
if ! command -v kubectl &>/dev/null; then
    printf '%s' "installing kubectl...."
    sudo curl --silent --location -o /usr/local/bin/kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.15.10/2020-02-22/bin/linux/amd64/kubectl
    sudo chmod +x /usr/local/bin/kubectl
else
    printf '%s\n' "kubectl already installed: "
    kubectl version 2>/dev/null
fi

#Install eksctl
if ! command -v eksctl &>/dev/null; then
    printf '%s\n'  "installing eksctl...."
    curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
    sudo mv -v /tmp/eksctl /usr/local/bin
else
    printf '%s\n'  "eksctl already installed: "
    eksctl version 2>/dev/null
fi

#Install helm
if ! command -v helm &>/dev/null; then
    printf '%s\n'  "installing helm...."
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    command helm version
else
    printf '%s\n'  "helm already installed, version: "
    helm version 2>/dev/null
fi

#Install aws authenticator
if ! command -v aws-iam-authenticator &>/dev/null; then
    printf '%s\n'  "installing AWS authenticator...."
curl -o aws-iam-authenticator https://amazon-eks.s3.us-west-2.amazonaws.com/1.16.8/2020-04-16/bin/linux/amd64/aws-iam-authenticator
chmod +x ./aws-iam-authenticator
mkdir -p $HOME/bin && cp ./aws-iam-authenticator $HOME/bin/aws-iam-authenticator && export PATH=$PATH:$HOME/bin
else
  printf '%s\n'  "AWS authenticator already installed "
fi
