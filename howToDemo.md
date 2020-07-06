# How to Demo (wip)

## Preparation:

In this demo scenario we will be using the MoneyX demo application

Login to your CloudOne account and go to Cloud One Application Security.  Find the group that you created for the MoneyX application (c1-app-sec-moneyx).  Open Polcies" and set all policies to REPORT <br />

In AWS, under CodePipeline -> Pipelines -> make sure you have a failed pipeline for the <projectname>c1appsecmoneyxPipeline  <br />

Open the following browser tabs:
- Cloud9,
- codePipeline,
- DSSC,
- MoneyX,
- C1AS,
- CloudFormation,
- GIT

## Demo Scenario
- show the 3 AWS CodeCommit repositories
- show the AWS pipelines -> click on the failed c1appsecmoneyx pipeline and scroll all the way down. <br />
  Show why this pipeline failed (see "Vulnerabilities exceeded threshold" in screenshot below) ![](images/VulnerabilitiesExceededThreshold.png)  <br />
- in Cloud9 type `eksctl get clusters` and show that you have an EKS cluster
- type `kubectl get pods --namespace smartcheck` and show the pods used by smartcheck.  Also show the deployments `kubectl get deployments -n smartcheck`
- type `kubectl get services -n smartcheck` and copy the URL of the proxy service as indicated in the screenshot below ![](images/GetDSSCURL.png) <br />
- Then open a browser to that url
(e.g. https://afa8c13bf2497469ba8411dfa1cfebec-1286344911.eu-central-1.elb.amazonaws.com )
- show scanfindings in DSSC
- **Story:** <br />
For an urgent Marketing event, the "business" wants us to put this application online ASAP.  Our code is fine, the vulnerabilities are in the external libraries that we have used and we don't know how to quickly fix them.  As a work-around, we will deploy the app with vulnerabilities and rely on runtime protection (CloudOne Application Control)
- vi buildspec.yaml
    bump up thresholds for vulnerabilities as indicated in the screenshot below ![](images/IncreaseThresholds.png)  <br />

-  git add, commit, push
- while the pipeline is building: <br />
explore the buildspec.yaml and the Dockerfile
      kubectl get pods -n smartcheck / get deployments / get services
      kubectl get pods -> current deployed apps
  pipeline success
      kubctl get pods -> MoneyX pod is new
      kubectl get services -> go to URL
      show scanresults: still vulnr pod
      login to app: -> go to Received Payments -> add to url:  " or 1=1" -> see ALL payments
      go to https://cloudone.trendmicro.com/application#/events -> set SQL injection to MITIGATE
      Try exploit again  -> blocked
  show Dockerfile
      ADD library added (java in this case)
      CMD -> library inserted
      (registration keys for AppSec are in: CFT->)
          Tab: Template ->search appSec
          registration keys for AppSec


exploit running app:
-> received payments
http://a091a4276fe2d48009ecee19c6c64981-609291530.eu-central-1.elb.amazonaws.com:8080/payment/list-received/ or 1=1
- check security events in CloudOne Application Security
- set the Policies to MITIGATE
- run the SQL injection again and show that it now gets blocked as indicated in the screenshot below
![](images/Blocked.png)  <br />
