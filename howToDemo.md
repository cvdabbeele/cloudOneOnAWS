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
- show the AWS pipelines -> click on the failed c1appsecmoneyx pipeline and scroll all the way down.  Show why this pipeline failed (see screenshot below) ![](images/VulnerabilitiesExceededThreshold.png)
 <br />
- in Cloud9 type `eksctl get clusters` and show the cluster
- type `kubectl get pods --namespace smartcheck` and show the pods used by smartcheck.  Also show the deployments `kubectl get deployments -n smartcheck`
- type `kubectl get services -n smartcheck` and copy the URL of the proxy service as indicated in the screenshot below ![](images/GetDSSCURL.png)
.  Then open a browser to that url
(e.g. https://afa8c13bf2497469ba8411dfa1cfebec-1286344911.eu-central-1.elb.amazonaws.com )
show scanfindings in DSSC
    try to fix, but the issues are in "external" libraries -> we depend on the community to fix them
    Business manager wants the App online for a big Marketing Campaign
    -> deploy app with vulns and rely on runtime protection
  vi buildspec.yaml
    bump up thresholds for vulnerabilities
  git add, commit, push
  while the pipeline is building
      -> explore the buildspec.yaml and the Dockerfile
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
