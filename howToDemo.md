# How to Demo (wip)

## Preparation:

In this demo scenario we will be using the MoneyX demo application

Login to your CloudOne account and go to   set C1AS all policies in REPORT
  MoneyX -> vi buildspec.yaml -> make sure to have a "Failed" pipeline
  Open the following browser tabs:
    Cloud9, codePipeline, DSSC, MoneyX, C1AS, CloudFormation, GIT
demo
  slide on pipeline
  slide on adding 2 sets of Security Controls (pre-runtime checks + runtime security)
  show failed pipeline  -> details -> issue vulns> threshold -
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
