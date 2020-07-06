# Overview
This is a collaborated effort with mawinkler and nicgoth   
This sets up:
- an AWS codeCommit registry
- codePipeline
- deploys Trend Micro Cloud One Container Security (C1CS)
- and integrates it in the pipeline.  

Then it will:
- deploy 3 containers and
- scan them for vulnerabilities, malware, sensitive content etc..
- and then push them to the ECR registry

This README.md describes how to deploy the demo environment

Checkout the **howToDemo.md** for demo scenarios

# High level overview of steps (detailed steps in next section)
1. open Cloud9
2. clone this repo
3. enter your configuration settings in `00_define_vars.sh.sample` and save it as `.sh` (make sure it is executable)
4. run ./up.sh to deploy the environment (pipeline, scanner,...)
5. build a sample container and see how it get scanned by Cloud One Container Security (C1CS).  If it has more  vulnerabilities, malware or sensitive content than defined in the threshold, then it will not be pushed to the ECR Registry.
6. increase the security thresholds in buildspec.yaml file (=allow more risk) and rebuild the (vulnerable) container.  It will now be pushed to the ECR registry and deployed on EKS.
7. Run a few exploits against it.  Depending on the settings in Cloud One Application Security (C1AS), they will be blocked.  (for a detailed demo scenario, see **howToDemo.md** )
6. run ./down.sh to tear everything down

# Detailed setup instructions

## Requirements
The AWS region that you work in, on your account, must be able to create a VPC and a Public IP. (there is a soft limit of 5 VPCs per AWS account per AWS region)  <br />
The Cloud Formation Template to build the EKS cluster will crash if those resources cannot be created, <br />
If you don't have a license key for Deep Security Smartcheck yet, you can get one here: https://www.trendmicro.com/product_trials/download/index/us/168 <br />
If you want to demo the Runtime Protection as well, then you need to setup a CloudOne Application Security Account ( https://cloudone.trendmicro.com/_workload_iframe//SignUp.screen ) and create a new "group" for the MoneyX application.  This will give you a key and a secret that you can use for TREND_AP_KEY and TREND_AP_SECRET<br />

## Preparation  
1. Setup a AWS Cloud9 development environment
  - use `t2.micro`
  - use `Ubuntu Server 18.04 LTS`
  - tag it to your liking (tags are good)
  - use default settings for the rest

2. Create an AWS Role to allow the EKS worker nodes (EC2 instances) to connect to ECR  
 - AWS Services -> IAM -> Roles -> Create Role
 - Select type of trusted entity: AWS Services
 - Choose a use case: EC2 -> Next: Permissions
 - Assign permission policy : "AmazonEC2ContainerRegistryFullAccess" -> Next: Tags
 - -> Next Role name: e.g. project_name_EC2_access_to_ECR    

3. Start the Cloud9 environment

4. In Cloud9, disable the `AWS-managed temporary credentials`  
Click on the AWS Cloud9 tab in the Cloud9 menu bar (if you don't see the menu bar as indicated in the screenshot below, hover the mouse over the top of the window. The menu bar should roll down and become visible) -> Preferences -> scroll down and expand "AWS Settings" -> Credentials -> uncheck "AWS managed temporary credentials"    
![](images/DisableAWSManagedTemporaryCredentials.png)

5. Create credentials for CodeCommit  
CodeCommit requires AWS Key Management Service. If you are using an existing IAM user, make sure there are no policies attached to the user that expressly deny the AWS KMS actions required by CodeCommit. For more information, see AWS KMS and encryption. <br />
- In the AWS console, go to Services and choose IAM, then go to Users, and then click on the IAM user you want to configure for CodeCommit access.<br />
- On the Permissions tab, choose Add Permissions.
- In Grant permissions, choose Attach existing policies directly.<br />
- From the list of policies, select AWSCodeCommitPowerUser or another managed policy for CodeCommit access.<br />
- Click "Next: Review" to review the list of policies to attach to the IAM user.<br />
- If the list is correct, choose Add permissions.

see also:
https://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-gc.html?icmpid=docs_acc_console_connect_np

6. Get a trial account for Trend Micro Cloud One Container Security (aka Deep Security Smart Check).  
This will provide pre-runtime scanning of containers.
see: https://github.com/deep-security/smartcheck-helm

7. (optionally) Get a trial account for Trend Micro Cloud One Application Security.  
This will provide runtime protection to the containers.

## 1. Define variables for AWS, Cloud One Container Security and (optionally) for Cloud One Application Security
Open a Cloud9 environment and clone this repo:

git clone https://github.com/cvdabbeele/cloudOneOnAWS.git
Copy `00_define_vars.sh.sample` to 00_define_vars.sh

Enter your own configuration variables in the config file


## 2. Deploy the environment

```
$ ./up.sh
```
This will do the following:

1. Create an EKS cluster

2. Install Smart Check with internal registry

3. Add a demo Repo to Smart Check

4. Setup demo pipelines

5. Deploy 3 demo applications

If you encounter any errors, please check the "common issues" section at the bottom

## 3. This script will deploy 3 demo applications

At the same level as the project directory (cloudOneOnAWS), an "apps" directory will be created.
Hereunder, 3 apps will be installed (c1appsecmoneyx, troopers and mydvwa) <br />
This will trigger an AWS codeCommit process to build and scan those applications by SmartCheck

By default:
- the troopers app will be deployed because it is clean
- the c1-app-sec-moneyx and the mydvwa apps will not be deployed because they have too many vulnerabilities

As a demo you can increase the thresholds in the buildspec.yml file of the cloudone01c1appsecmoneyx app, and do a git push
The app will now be rebuild, scanned again and will be deployed (with vulnerabilities)

If you have setup Cloud One Application Security, you can now attach the running (and vulnerable) containers and demonstrate "runtime protection"


## Suspend / Tear down
```
$ ./down.sh
```
Unfortunately it is (currently) not possible to set the number of EKS nodes to 0.  So we cannot *suspend* the environment.

To avoid exessive costs when not using the demo environment, tear-down the environment.  This ./down.sh script will delete the EKS cluster, the EC2 instances and Cloudformation Stacks.  The Cloud9 EC2 instance will stop, but remain available for later.

To re-use the demo environment later, just start Cloud9 and run **./up.sh**

## Common issues (WIP)
### Error: Kubernetes cluster unreachable
`The connection to the server localhost:8080 was refused - did you specify the right host or port?`

Verify your AWS_PROJECT variable. It may only contain **lowercase and trailing numbers**, but :
- no uppercase
- no " - "
- no " _ "
- nor any special characters

This variable is used for several purposes and each of them have their own restrictions,..which add up to "only a-z lowercase and numbers"  It may also not begin with a number.
