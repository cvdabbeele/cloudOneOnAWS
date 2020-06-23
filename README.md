# Overview
This is a collaborated effort with mawinkler and nicgoth   
This sets up an AWS CodePipeline, builds a few containers and applies Trend Micro Cloud One Container Security (C1CS) and Trend Micro Cloud One Application Security (C1AS)to it
Additionally this creates the required EKS cluster, CodeCommit repository, CodePipeline pipeline, ECR registry etc..

# High level overview of steps (detailed steps in next section)
1. open Cloud9
2. clone this repo
3. enter your configuration settings in `00_define_vars.sh.sample` and save it as `.sh`
4. run ./up.sh to deploy the environment (pipeline, scanner,...)
5. build a sample container and see how it get scanned by Cloud One Container Security (C1CS).  If it has vulnerabilities it will not be pushed to the ECR Registry.
6. lower the security thresholds in the C1CS scanner and rebuild the (vulnerable) container.  It will now be pushed to the ECR registry and deployed on EKS. Run a few exploits against it.  Depending on the settings in Cloud One Application Security (C1AS), they will be blocked.
6. run ./down.sh to tear everything down

# Detailed instructions

## Requirements
The AWS region that you work in, on your account, must be able to create a VPC and a Public IP. (there is a soft limit of 5 VPCs per AWS account per AWS region)  
The Cloud Formation Template to build the EKS cluster will crash if those resources cannot be created


## Preparation  
1. Setup a AWS Cloud9 development environment
  - use `t2.micro`
  - use `Ubuntu Server 18.04 LTS`
  - tag it to your liking (tags are good)
  - use default settings for the rest

2. Create an AWS Role to allow the EKS EC2 instances to connect to ECR  
 - AWS Services -> IAM -> Roles -> Create Role (e.g. Cloud9EC2AdminAccess)
 - Select type of trusted entity: AWS Services
 - Choose a use case: EC2 -> Next: Permissions
 - Assign permission policy : "AmazonEC2ContainerRegistryFullAccess" -> Next: Tags
 - -> Next Role name: e.g. project_name_EC2_access_to_ECR    

2. Start the Cloud9 environment

3. In Cloud9, disable the `AWS-managed temporary credentials`  
Click on the AWS Cloud9 tab in the Cloud9 menu bar -> Preferences -> scroll down and expand "AWS Settings" -> Credentials -> uncheck "AWS managed temporary credentials"  
![](images/DisableAWSManagedTemporaryCredentials.png)

4. Create credentials for CodeCommit  
see:
https://docs.aws.amazon.com/codecommit/latest/userguide/setting-up-gc.html?icmpid=docs_acc_console_connect_np

5. Get a trial account for Trend Micro Cloud One Container Security (aka Deep Security Smart Check).  
This will provide pre-runtime scanning of containers.
see: https://github.com/deep-security/smartcheck-helm

6. (optionally) Get a trial account for Trend Micro Cloud One Application Security.  
This will provide runtime protection to the containers.

## 1. Define variables for AWS, Cloud One Container Security and (optionally) for Cloud One Application Security
Open a Cloud9 environment and clone this repo

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

## 3. This script will deploy 3 demo applications

At the same level as the project directory (cloudOneOnAws), an "apps" directory will be created.
Hereunder, 3 apps will be installed (c1appsecmoneyx, troopers and mydvwa)
This will trigger an AWS codeCommit process to build and scan those applications by SmartCheck
By default, the apps will not be deployed because they have too many vulnerabilities.
As a demo you can increase the thresholds in the buildspec.yml files and do a git push
The apps will now be rebuild, scanned again, but because of the high thresholds they will be allowed to be deployed

If you have setup Cloud One Application Security, you can now attach the running (and vulnerable) containers and demonstrate "runtime protection"


## To delete all deployments, run the following command:

```
$ ./down.sh
```
This will tear-down the EKS cluster, the EC2 instances and Cloudformation Stacks.  The Cloud9 EC2 instance will stop, but remain available for later.

## Requirements
- This project needs 1 available VPC. By default an AWS account has a limit of 5 VPCs per region.  
- Every time this project runs, it creates an S3 bucket per pipeline/app (3 pipelines per run), to store its artefacts. By default an AWS account has a limit of 100 buckets.  See the last section of the "down" script to cleanup.
