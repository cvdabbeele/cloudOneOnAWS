# Overview

This is a collaborative effort with mawinkler and nicgoth.

1. UPDATES: [20201126](#20201126)  [20210129](#20210129)  
2. [High level overview](#high-level-overview-of-steps-see-detailed-steps-in-next-section)  
3. [Detailed Steps](#detailed-setup-instructions)


## UPDATES  
### 20210129
Cloud One Container Security is now included.  
The Admission Controller part is fully functional
The Runtime protection is still in preview (as this Product Feature is still preview as well)
### 20201126  
1. You now need to enter your DOCKERHUB_USERNAME and DOCKERHUB_PASSWORD in the 00_define_vars.sh file (may be a free account).  To deal with docker image pull rate-limits, the buildscipts of the Apps will now do authenticated pulls (to https://hub.docker.com) from the AWS pipeline.  This script passes along those variables to the buildspec.yml files
  For more info on the Dockerhub pull rate limits, see: https://www.docker.com/increase-rate-limits  Image Pulls for unauthenticated connections are now capped to 100 and for connections authenticated with a free account, they are capped to 200.  Both pull rates are for the last 6 hours (sliding window).  Paid dockerhub subscriptions have no pull rate limit.
2. The json structure that is returned by the command "eksctl get cluster" has apparently changed (the Name attribute is now part of a Metadata sub-structure).  This threw errors in the down.sh, pause.sh and resume.sh scripts.  These scripts have been adapted for this.  
3. The down.sh script has been enhanced to provide a better cleanup.


## In short, the script in this repo sets up:

- an AWS Elastic Kubernetes Service Cluster (EKS)
- an AWS codeCommit registry
- three AWS codePipelines
- Trend Micro Cloud One Container Registry Security (C1CS or "SmartCheck") and integrates it in the pipelines

Then it will:

- build 3 containers and
- scan them for vulnerabilities, malware, sensitive content etc..
- and, if the risk is below the defined threshold:
  - push them to the ECR registry
  - deploy them on AKS

This README.md describes how to deploy the demo environment

Checkout the **howToDemo.md** for demo scenarios

- [Overview](#overview)
  - [UPDATES](#updates)
    - [20210129](#20210129)
    - [20201126](#20201126)
  - [In short, the script in this repo sets up:](#in-short-the-script-in-this-repo-sets-up)
  - [High level overview of steps (see detailed steps in next section)](#high-level-overview-of-steps-see-detailed-steps-in-next-section)
  - [Detailed setup instructions](#detailed-setup-instructions)
    - [Prerequisiteds     IMPORTANT  IMPORTANT  IMPORTANT](#prerequisiteds-----important--important--important)
      - [Shared AWS Accounts](#shared-aws-accounts)
    - [Prepare the environment](#prepare-the-environment)
    - [Deploy the environment](#deploy-the-environment)
    - [Next Step: How to Demo](#next-step-how-to-demo)
    - [Suspend](#suspend)
    - [Resume](#resume)
    - [Tear down](#tear-down)
  - [Common issues (WIP)](#common-issues-wip)
    - [Error: Kubernetes cluster unreachable](#error-kubernetes-cluster-unreachable)
    - [Error Code: AddressLimitExceeded](#error-code-addresslimitexceeded)
    - [Error: `fatal: unable to access 'https://git-codecommit.eu-central-1.amazonaws.com/v1/repos/<somerepo>.git/': The requested URL returned error: 403`](#error-fatal-unable-to-access-httpsgit-codecommiteu-central-1amazonawscomv1repossomerepogit-the-requested-url-returned-error-403)


## High level overview of steps (see detailed steps in next section)

1. open Cloud9, configure AWS CLI with your keys and region
2. clone this repo  
3. enter your settings in `00_define_vars.sh`  
4. run  `. ./up.sh` to deploy the environment (mind the extra dot which is needed to "source" the vars from the script)
5. see [howToDemo.md](howToDemo.md) for demo scenarios
6. run ./down.sh to tear everything down

## Detailed setup instructions

### Prerequisiteds     IMPORTANT  IMPORTANT  IMPORTANT

#### Shared AWS Accounts

If you share an AWS account with a co-worker, make sure that:

- you both use **different regions**
- you both use different project names and that project name is not a subset of the other one: eg cloudone and cloudone01 would be bad, but cloudone01 and cloudone02 would be fine  (I know... there is room for improvement here)

The AWS Region that you will use must have:

- **one "free" VPC "slot"**
   By default, there is a soft limit of 5 VPCs per region.  This script must be able to create 1 VPC
- **one "free" Elastic IP "slot"**
   By default, there is a soft limit of 5 Elastic IPs per region.  This script must be able to create 1 Elastic IP
- **one "free" Internet Gateway "slot"**
   By default, there is a soft limit of 5 Internet Gateways per region.  This script must be able to create 1 Internet Gateway

The Cloud Formation Template to build the EKS cluster will crash if those resources cannot be created

The IAM User account that you will use:

- must have **Programmatic Access** as well as **AWS Management Console Access**
- must have **AdministratorAccess** permissions (AWS console -> Services -> IAM -> Users -> click on the user -> Permissions tab -> If AdministratorAccess is not there, then click on Add permissions and add it; or request the rights from you Admin)  The reason is that the script will not only create an EKS cluster, but also a lot of other things, like create  VPC, subnets, routetables, roles, IPs, S3 buckets, ...

(trial) Licenses:

- **A license for Deep Security SmartCheck** If you don't have a license key yet, you can get one here: <https://www.trendmicro.com/product_trials/download/index/us/168>
- **CloudOne Application Security Account**  You can register for a trial here: <https://cloudone.trendmicro.com/_workload_iframe//SignUp.screen>  You will need to create a "group" for the MoneyX application.  This will give you a **key** and a **secret** that you can use for the TREND_AP_KEY and TREND_AP_SECRET variables in this script.

### Prepare the environment

1. Setup an AWS Cloud9 development environment
  - Login to your AWS account 
  - go to "Services" -> "Cloud9"
  - select `Create environment`
  - Name environment: e.g.: `c1setrain`
  - `Next`
  - Environment type: `Create a new EC2 instance for environment (direct access)`
  - Instance type: `t3.small`
  - Platform: `**Ubuntu Server 18.04 LTS**`
  - tag it to your liking 
  - use default settings for the rest
  - `Next`
  - `Create Environment`  This may take 1-3 minutes

<!--0. <not needed?>
Create an AWS Role to allow the EKS worker nodes (EC2 instances) to connect to ECR  
 - AWS Services -> IAM -> Roles -> Create Role
 - Select type of trusted entity: AWS Services
 - Choose a use case: EC2 -> Next: Permissions
 - Assign permission policy : "AmazonEC2ContainerRegistryFullAccess" -> Next: Tags
 - -> Next Role name: e.g. project_name_EC2_access_to_ECR  
  -->

<!-- 0. Grant the Cloud9 environment Administrator Access
- Click the following deep to create the Role for Cloud9:
https://console.aws.amazon.com/iam/home#/roles$new?step=review&commonUseCase=EC2%2BEC2&selectedUseCase=EC2&policies=arn:aws:iam::aws:policy%2FAdministratorAccess
- Name it Cloud9EC2AdminAccess
- Attach the IAM role Cloud9EC2AdminAccess to the ec2 instance of your Cloud9:
  * In the AWS Console, go to Services -> EC2 -> select the EC2 instance used for this Cloud9 -> Actions -> Instance Settings -> Attach/Replace IAM Role
* Within Cloud9 Preferences -> AWS Settings -> Credentials -> AWS managed temporary credentials -> Disable
-->

2. In Cloud9, disable the `AWS-managed temporary credentials` :
To do thi, cClick on the AWS Cloud9 tab in the Cloud9 menu bar.  The tab shows as a cloud icon with a number 9 in it.  If you don't see the menu bar as indicated in the screenshot below, hover the mouse over the top of the window. The menu bar should roll down and become visible.  Go to -> `Preferences` (see "1" in screenshot below) -> scroll down and expand `"AWS Settings"` (see "2")-> `Credentials` -> uncheck `"AWS managed temporary credentials"`  (see "3") It should be RED.
![AWS Settings](images/DisableAWSManagedTemporaryCredentials.png)

3. configure AWS cli  
Find your terminal at the bottom of the window
At the prompt, type:  

```shell
aws configure
```

Enter your `AWS Access Key ID`  
Enter your `AWS Secret Access Key`  
Set the `Default region name` e.g. eu-central-1  
Set the `Default output format` to `json`  

```shell
AWS Access Key ID [****************GT7G]:   type your AWS Access Key here
AWS Secret Access Key [****************0LQy]:  type your AWS Secret Access key here
Default region name [eu-central-1]:    Configure your region here
Default output format [json]:          Set default output to json
```

<!--4. Create credentials for CodeCommit  
CodeCommit requires AWS Key Management Service. If you are using an existing IAM user, make sure there are no policies attached to the user that expressly deny the AWS KMS actions required by CodeCommit. For more information, see AWS KMS and encryption.
- In the AWS console, go to Services and choose IAM, then go to Users, and then click on the IAM user you want to configure for CodeCommit access.
- On the Permissions tab, choose Add Permissions.
- In Grant permissions, choose Attach existing policies directly.
- From the list of policies, select AWSCodeCommitPowerUser or another managed policy for CodeCommit access.
- Click "Next: Review" to review the list of policies to attach to the IAM user.
- If the list is correct, choose Add permissions.

see also:
https://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-gc.html?icmpid=docs_acc_console_connect_np
-->
4. In your Cloud9 environment, run the following command to clone this repository:

```shell
git clone https://github.com/cvdabbeele/cloudOneOnAWS.git
cd cloudOneOnAWS
```  

5. Define variables for AWS, Cloud One Container Security and for Cloud One Application Security

```shell
cp 00_define_vars.sh.sample 00_define_vars.sh
```

Edit the `00_define_vars.sh` file with the built in editor of Cloud9 or by your prefered editor (e.g. by using vi).  
To use the built-in editor:  
- in the left margin, expand the tree until you see the files of the repo.  
- double cllick: `00_define_vars.sh`  
  

Enter your own configuration variables in the config file.   
At the minimum, configure the following variables:

- `DSSC_AC` (your SmartCheck Activation Code/Key)
- `TREND_AP_KEY` (your Cloud One Application Security Key)  see `prerequisites` above if you don't know how to create one) 
- `TREND_AP_SECRET` (your Cloud One Application Security Secret Key)

The rest are preconfigured default variables which you can use as they are.

### Deploy the environment

Deploy the demo environment by running: `. ./up.sh`   
Important: don't forget the leading dot and the space.  This is required to source the environment.

```shell
. ./up.sh
```

The script will do the following:
(the text below is meant to provide some guidance of what you will see on the screen.  Newer versions of this script may have a sllightly different output)  
This deployment may take about `30 minutes`  
Once the environment is deployed, continue with [howToDemo.md](howToDemo.md) for a few typical demo scenarios  

1. Install the essential tools like `eksctl`, `jq`, etc.

```shell
--------------------------
        Tools
--------------------------
installing jq
Reading package lists... Done
Building dependency tree
Reading state information... Done
jq is already the newest version (1.5+dfsg-2).
0 upgraded, 0 newly installed, 0 to remove and 4 not upgraded.
installing kubectl....installing eksctl....
renamed '/tmp/eksctl' -> '/usr/local/bin/eksctl'
installing helm....
Downloading https://get.helm.sh/helm-v3.2.4-linux-amd64.tar.gz
Preparing to install helm into /usr/local/bin
helm installed into /usr/local/bin/helm
version.BuildInfo{Version:"v3.2.4", GitCommit:"0ad800ef43d3b826f31a5ad8dfbb4fe05d143688", GitTreeState:"clean", GoVersion:"go1.13.12"}
installing AWS authenticator....
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100 33.6M  100 33.6M    0     0  6633k      0  0:00:05  0:00:05 --:--:-- 7094k
```

2. Create an EKS cluster

```shell
-----------------------
 Creating EKS cluster
-----------------------
Creating file: cloudone01EksCluster.yml...
Creating a 2-node eks cluster named: cloudone01 in region eu-central-1
This may take up to 20 minutes... (started at:Mon Jul 20 07:44:39 UTC 2020)
[ℹ]  eksctl version 0.24.0
[ℹ]  using region eu-central-1
[ℹ]  setting availability zones to [eu-central-1c eu-central-1a eu-central-1b]
[ℹ]  subnets for eu-central-1c - public:192.168.0.0/19 private:192.168.96.0/19
[ℹ]  subnets for eu-central-1a - public:192.168.32.0/19 private:192.168.128.0/19
[ℹ]  subnets for eu-central-1b - public:192.168.64.0/19 private:192.168.160.0/19
[ℹ]  using Kubernetes version 1.16
[ℹ]  creating EKS cluster "cloudone01" in "eu-central-1" region with managed nodes
[ℹ]  1 nodegroup (nodegroup) was included (based on the include/exclude rules)
[ℹ]  will create a CloudFormation stack for cluster itself and 0 nodegroup stack(s)
[ℹ]  will create a CloudFormation stack for cluster itself and 1 managed nodegroup stack(s)
[ℹ]  if you encounter any issues, check CloudFormation console or try 'eksctl utils describe-stacks --region=eu-central-1 --cluster=cloudone01'
[ℹ]  CloudWatch logging will not be enabled for cluster "cloudone01" in "eu-central-1"
[ℹ]  you can enable it with 'eksctl utils update-cluster-logging --region=eu-central-1 --cluster=cloudone01'
[ℹ]  Kubernetes API endpoint access will use default of {publicAccess=true, privateAccess=false} for cluster "cloudone01" in "eu-central-1"
[ℹ]  2 sequential tasks: { create cluster control plane "cloudone01", 2 sequential sub-tasks: { no tasks, create managed nodegroup "nodegroup" } }
[ℹ]  building cluster stack "eksctl-cloudone01-cluster"
[ℹ]  deploying stack "eksctl-cloudone01-cluster"
[ℹ]  building managed nodegroup stack "eksctl-cloudone01-nodegroup-nodegroup"
[ℹ]  deploying stack "eksctl-cloudone01-nodegroup-nodegroup"

[ℹ]  waiting for the control plane availability...
[✔]  saved kubeconfig as "/home/ubuntu/.kube/config"
[ℹ]  no tasks
[✔]  all EKS cluster resources for "cloudone01" have been created
[ℹ]  nodegroup "nodegroup" has 2 node(s)
[ℹ]  node "ip-192-168-7-126.eu-central-1.compute.internal" is ready
[ℹ]  node "ip-192-168-84-105.eu-central-1.compute.internal" is ready
[ℹ]  waiting for at least 2 node(s) to become ready in "nodegroup"
[ℹ]  nodegroup "nodegroup" has 2 node(s)
[ℹ]  node "ip-192-168-7-126.eu-central-1.compute.internal" is ready
[ℹ]  node "ip-192-168-84-105.eu-central-1.compute.internal" is ready
[ℹ]  kubectl command should work with "/home/ubuntu/.kube/config", try 'kubectl get nodes'
[✔]  EKS cluster "cloudone01" in "eu-central-1" region is ready
Cloudformation Stacks deployed.  Elapsed time: 15 minutes
Checking EKS cluster.  You should see your EKS cluster in the list below
NAME            REGION
cloudone01      eu-central-1
```

3. Install Smart Check with internal registry

```shell
------------------------------
 Cloud One Container Security
------------------------------
Creating namespace smartcheck...namespace/smartcheck created
Creating certificate for loadballancer...Generating a RSA private key
....................................................................................................++++
.....................++++
writing new private key to 'k8s.key'
-----
Creating secret with keys in Kubernetes...secret/k8s-certificate created
Creating overrides.yml file
Deploying Helm chart...

Waiting for Cloud One Container Security to come online: ........  
Doing initial (required) password change
You can login:  
--------------
     URL: https://a1837449ce2db4dcf8a56d955208c8dc-263324481.eu-central-1.elb.amazonaws.com
     user: administrator
     passw: trendmicro
--------------
```

4. Add the internal Repository plus a demo Repository to Smart Check

```shell
-------------------------------------------------------------
 Adding internal repository to Cloud One Container Security  
-------------------------------------------------------------
--------------------------------------------------------
 Adding Demo repository to Cloud One Container Security
--------------------------------------------------------
    Adding demo repository with filter: {*photo*}
```

5. Setup demo pipelines

```shell
-------------------------------
Creating CodeBuild pipelines
-------------------------------
Patching aws-auth configmap for cloudone01
configmap/aws-auth patched
No environment found:
--------------------------
   CodeCommit repo:  exists = false
   CloudFormation stack:  status =
   CodePipeline:  exists = false
   ECR repo:  exists = false
creating: CodeCommit repository , ECR repository , Pipeline cloudone01c1appsecmoneyx and Cloudformation stack
Creating file: cloudone01c1appsecmoneyxPipeline.yml
Creating Cloudformation Stack and Pipeline cloudone01c1appsecmoneyx...
^[cWaiting for Cloudformation stack cloudone01c1appsecmoneyxPipeline to be created.
No environment found:
--------------------------
   CodeCommit repo:  exists = false
   CloudFormation stack:  status =
   CodePipeline:  exists = false
   ECR repo:  exists = false
creating: CodeCommit repository , ECR repository , Pipeline cloudone01troopers and Cloudformation stack
Creating file: cloudone01troopersPipeline.yml
Creating Cloudformation Stack and Pipeline cloudone01troopers...
Waiting for Cloudformation stack cloudone01troopersPipeline to be created.
No environment found:
--------------------------
   CodeCommit repo:  exists = false
   CloudFormation stack:  status =
   CodePipeline:  exists = false
   ECR repo:  exists = false
creating: CodeCommit repository , ECR repository , Pipeline cloudone01mydvwa and Cloudformation stack
Creating file: cloudone01mydvwaPipeline.yml
Creating Cloudformation Stack and Pipeline cloudone01mydvwa...
Waiting for Cloudformation stack cloudone01mydvwaPipeline to be created.
```

6. Git-clone 3 demo applications
At the same level as the project directory (cloudOneOnAWS), an "apps" directory will be created.

```shell
---------------------
 Adding Demo-apps
---------------------
Deploying c1appsecmoneyx (from https://github.com/cvdabbeele/c1-app-sec-moneyx.git)
---------------------------------------------
Importing c1-app-sec-moneyx from public git
Cloning into 'c1-app-sec-moneyx'...
remote: Enumerating objects: 113, done.
remote: Counting objects: 100% (113/113), done.
remote: Compressing objects: 100% (79/79), done.
remote: Total 113 (delta 62), reused 82 (delta 32), pack-reused 0
Receiving objects: 100% (113/113), 15.87 KiB | 1.22 MiB/s, done.
Resolving deltas: 100% (62/62), done.
Deleting c1-app-sec-moneyx/.git directory (.git from github)
initializing git for CodeCommit
Initialized empty Git repository in /home/ubuntu/environment/apps/c1-app-sec-moneyx/.git/
generating a dummy change to trigger a pipeline
updating CodeCommit repository
[master (root-commit) e070204] commit by "add_demoApps"
 7 files changed, 324 insertions(+)
 create mode 100644 Dockerfile
 create mode 100644 Jenkinsfile
 create mode 100644 README.md
 create mode 100644 app-eks.yml
 create mode 100644 app.yml
 create mode 100644 buildspec.yml
 create mode 100644 exploits.md
Counting objects: 9, done.
Compressing objects: 100% (9/9), done.
Writing objects: 100% (9/9), 4.57 KiB | 1.52 MiB/s, done.
Total 9 (delta 1), reused 0 (delta 0)
To https://git-codecommit.eu-central-1.amazonaws.com/v1/repos/cloudone01c1appsecmoneyx.git
 * [new branch]      master -> master
Branch 'master' set up to track remote branch 'master' from 'origin'.
Everything up-to-date
Deploying troopers (from https://github.com/cvdabbeele/troopers.git)
---------------------------------------------
Importing troopers from public git
Cloning into 'troopers'...
remote: Enumerating objects: 24, done.
remote: Counting objects: 100% (24/24), done.
remote: Compressing objects: 100% (17/17), done.
remote: Total 215 (delta 12), reused 18 (delta 7), pack-reused 191
Receiving objects: 100% (215/215), 1.07 MiB | 2.30 MiB/s, done.
Resolving deltas: 100% (121/121), done.
Deleting troopers/.git directory (.git from github)
initializing git for CodeCommit
Initialized empty Git repository in /home/ubuntu/environment/apps/troopers/.git/
generating a dummy change to trigger a pipeline
updating CodeCommit repository
[master (root-commit) d5c2be9] commit by "add_demoApps"
 22 files changed, 1005 insertions(+)
 create mode 100644 .dockerignore
 create mode 100644 Dockerfile
 create mode 100644 Jenkinsfile
 create mode 100644 LICENSE
 create mode 100644 README.md
 create mode 100644 app-eks.yml
 create mode 100644 app.py
 create mode 100644 app.yml
 create mode 100644 buildspec.yml
 create mode 100644 requirements.txt
 create mode 100644 smartcheck.snippet
 create mode 100644 static/photo-1472457847783-3d10540b03d7.jpeg
 create mode 100644 static/photo-1472457897821-70d3819a0e24.jpeg
 create mode 100644 static/photo-1472457974886-0ebcd59440cc.jpeg
 create mode 100644 static/photo-1484656551321-a1161420a2a0.jpeg
 create mode 100644 static/photo-1484824823018-c36f00489002.jpeg
 create mode 100644 static/photo-1518331368925-fd8d678778e0.jpeg
 create mode 100644 static/photo-1518331483807-f6adb0e1ad23.jpeg
 create mode 100644 static/photo-1544816565-aa8c1166648f.jpeg
 create mode 100644 static/photo-1547700055-b61cacebece9.jpeg
 create mode 100644 static/photo-1558492426-df14e290aefa.jpeg
 create mode 100644 templates/index.html
Counting objects: 26, done.
Compressing objects: 100% (22/22), done.
Writing objects: 100% (26/26), 1.05 MiB | 17.84 MiB/s, done.
Total 26 (delta 1), reused 0 (delta 0)
To https://git-codecommit.eu-central-1.amazonaws.com/v1/repos/cloudone01troopers.git
 * [new branch]      master -> master
Branch 'master' set up to track remote branch 'master' from 'origin'.
Everything up-to-date
Deploying mydvwa (from https://github.com/cvdabbeele/mydvwa.git)
---------------------------------------------
Importing mydvwa from public git
Cloning into 'mydvwa'...
remote: Enumerating objects: 152, done.
remote: Counting objects: 100% (152/152), done.
remote: Compressing objects: 100% (106/106), done.
remote: Total 152 (delta 79), reused 114 (delta 43), pack-reused 0
Receiving objects: 100% (152/152), 18.50 KiB | 1.32 MiB/s, done.
Resolving deltas: 100% (79/79), done.
Deleting mydvwa/.git directory (.git from github)
initializing git for CodeCommit
Initialized empty Git repository in /home/ubuntu/environment/apps/mydvwa/.git/
generating a dummy change to trigger a pipeline
updating CodeCommit repository
[master (root-commit) 19bce80] commit by "add_demoApps"
 6 files changed, 251 insertions(+)
 create mode 100644 Dockerfile
 create mode 100644 Jenkinsfile
 create mode 100644 README.md
 create mode 100644 app-eks.yml
 create mode 100644 app.yml
 create mode 100644 buildspec.yml
Counting objects: 8, done.
Compressing objects: 100% (7/7), done.
Writing objects: 100% (8/8), 3.38 KiB | 1.69 MiB/s, done.
Total 8 (delta 1), reused 0 (delta 0)
To https://git-codecommit.eu-central-1.amazonaws.com/v1/repos/cloudone01mydvwa.git
 * [new branch]      master -> master
Branch 'master' set up to track remote branch 'master' from 'origin'.
Everything up-to-date
...
```

Hereunder, 3 app-repos will be git-cloned from the public github (`c1appsecmoneyx`, `troopers` and `mydvwa`).

```shell
markus:~/environment/cloudOneOnAWS (master) $ ls -l ../apps/
total 12
drwxrwxr-x 3 ubuntu ubuntu 4096 Jul 20 08:06 c1-app-sec-moneyx
drwxrwxr-x 3 ubuntu ubuntu 4096 Jul 20 08:07 mydvwa
drwxrwxr-x 5 ubuntu ubuntu 4096 Jul 20 08:06 troopers
```

Those apps will be pushed to the AWS CodeCommit repository of the project
 and an AWS CodeBuild process to build the applications is triggered.

By default:

- the **troopers** app will be deployed to the EKS cluster because it is clean
- the **c1-app-sec-moneyx** and the **mydvwa** apps will not be deployed because they have too many vulnerabilities

If you encounter any **errors**, please check the "common issues" section at the bottom

### Next Step: How to Demo

Checkout [howToDemo.md](howToDemo.md) for a few typical demo scenarios

### Suspend

```shell
./pause.sh
```
The pause.sh script removes the Nodegroup.  This drains the 2 worker nodes and then terminates them  

### Resume

```shell  
./resume.sh  
```
The resume script re-creates the Nodegroup.  Make sure to leave enough time between a pause and a resume.  Sometimes AWS needs a lot of time to cleanup things  

### Tear down  

```shell
./down.sh
```


To avoid excessive costs when not using the demo environment, tear-down the environment.  The ./down.sh script will delete the EKS cluster, the EC2 instances, Cloudformation Stacks, Roles, VPCs, Subnets, S3buckets,....  
The Cloud9 EC2 instance will stop, but remain available for later.  

To start the enviroment again, simply reconnect to the Cloud9 environment and run **./up.sh**  This will redeploy everything from scratch


## Common issues (WIP)

### Error: Kubernetes cluster unreachable

`The connection to the server localhost:8080 was refused - did you specify the right host or port?`

Verify your AWS_PROJECT variable. It may only contain **lowercase and trailing numbers**, but :

- no uppercase
- no " - "
- no " _ "
- nor any special characters

This variable is used for several purposes and each of them have their own restrictions,..which add up to "only a-z lowercase and numbers"  It may also not begin with a number.

### Error Code: AddressLimitExceeded

![Address Limit Exceeded](images/AddressLimitExceeded.png)

Ensure that you can create Elastic IPs in this region.
By default, there is a (soft) limit of 5 Elastic IPs per AWS region.

### Error: `fatal: unable to access 'https://git-codecommit.eu-central-1.amazonaws.com/v1/repos/<somerepo>.git/': The requested URL returned error: 403`

This has to do wich the credential helper and the environment which is created by the `up.sh`. Very likely you forgot the first `.`when running `up.sh`.  
So please rerun

```shell
. ./up.sh
```

Afterwards you will be able to commit changes to your CodeCommit repositories.
