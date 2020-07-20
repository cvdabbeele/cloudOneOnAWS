# How to Demo (wip)

- [How to Demo (wip)](#how-to-demo-wip)
  - [Preparation for the Demo](#preparation-for-the-demo)
  - [Demo Scenario](#demo-scenario)
    - [Story: We have to deploy with vulnerabilities](#story-we-have-to-deploy-with-vulnerabilities)
    - [Attack and Protect the running app](#attack-and-protect-the-running-app)
    - [Walk through how Cloud 1 Application Control setup](#walk-through-how-cloud-1-application-control-setup)
  
## Preparation for the Demo

In this demo scenario we will be using the MoneyX demo application. This is the only app that has the runtime protection enabled.

Login to your CloudOne account and go to Cloud One Application Security. Find the group that you created for the MoneyX application (`c1-app-sec-moneyx`).

Open Policies" and set all policies to REPORT.

In AWS, under `CodePipeline -> Pipelines` -> make sure you have a failed pipeline for the `cloudone01c1appsecmoneyxPipeline`

Ensure to have the following browser tabs opened and authenticated.

- Cloud9 shell
- AWS Service CodePipeline.
- CloudOne Application Security
- MoneyX

## Demo Scenario

Open the following browser tabs for your Cloud9 shell and the AWS Service CodePipeline.

- Show the 3 AWS CodeCommit repositories
- Show the AWS pipelines -> click on the failed c1appsecmoneyx pipeline and scroll all the way down.  
  Show why this pipeline failed (see "Vulnerabilities exceeded threshold" in screenshot below) ![Exceeded Threshold](images/VulnerabilitiesExceededThreshold.png)  
- In Cloud9 type `eksctl get clusters` and show that you have an EKS cluster
- Type `kubectl get pods --namespace smartcheck` and show the pods used by smartcheck.  Also show the deployments `kubectl get deployments -n smartcheck`
- Type `kubectl get svc -n smartcheck proxy  -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'` and open a browser to that url
(e.g. <https://afa8c13bf2497469ba8411dfa1cfebec-1286344911.eu-central-1.elb.amazonaws.com>)
- Show and discuss the scanfindings in Smart Check

### Story: We have to deploy with vulnerabilities

For an urgent Marketing event, the "business" wants us to put this application online ASAP.  Our code is fine, the vulnerabilities are in the external libraries that we have used and we don't know how to quickly fix them.  

As a work-around, we will deploy the app with vulnerabilities and rely on runtime protection (CloudOne Application Control)

```shell
cd ~/environment/apps/c1-app-sec-moneyx/
```

And edit the buildspec.yml. Bump up thresholds for vulnerabilities as indicated below

```yaml
        ...
        --findings-threshold="{\"malware\":0,\"vulnerabilities\":{\"defcon1\":0,\"critical\":100,\"high\":100},\"contents\":{\"defcon1\":0,\"critical\":0,\"high\":1},\"checklists\":{\"defcon1\":0,\"critical\":0,\"high\":0}}"
        ...
```

Now, commit and push the changes.

```shell
git commit buildspec.yml -m "removed safety thresholds" && git push
```

While the pipeline is building;
explore the buildspec.yaml and the Dockerfile

```shell
kubectl get pods -n smartcheck
kubectl get deployments -n smartcheck
kubectl get services -n smartcheck
kubectl get pods
```

The last command will tell you if any of the new apps got deployed

```shell
markus:~/environment/apps/c1-app-sec-moneyx (master) $ kubectl get pods
NAME                              READY   STATUS    RESTARTS   AGE
c1appsecmoneyx-7d7c6944f5-vjjsb   1/1     Running   0          2m33s
troopers-6c6b4cc9cd-bv5qv         1/1     Running   0          4m56s
```

Maybe you need to repeat `kubectl get pods`, since building and deploying takes a couple of minutes.  
Walk through the scanresults in SmartCheck and notice that we still have a vulnerable image.

Notice the URL and port (8080) of the MoneyX app.

```shell
echo $(kubectl get svc c1appsecmoneyx -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'):$(kubectl get svc c1appsecmoneyx -o jsonpath='{.spec.ports[0].port}')
```

### Attack and Protect the running app

login to the MoneyX app:  

- username = "user"
- password = "user123"

Go to Received Payments.  You see no received payments.  

Go to the URL window at the top of the browser and add to the end of the url:  " or 1=1" (without the quotes)
e.g.

```url
http://a2baec90930634639a260c64b1be4b91-1290966830.eu-central-1.elb.amazonaws.com:8080/payment/list-received/3 or 1=1
```

You should now see ALL payments... which is bad

Go to <https://cloudone.trendmicro.com/application#/events> show that there is a security event for SQL injection

Check security events in CloudOne Application Security

Set the SQL Injection policy to MITIGATE

**important:**  
Open the SQL Injection Policy and ensure to have all subsections enabled.

Run the SQL injection again  (just refresh the browser page) You should get our super fancy blocking page.

### Walk through how Cloud 1 Application Control setup

In AWS codecommit: show the Dockerfile
point out:

- ADD command: library is imported (in this case it is a java app, so we added the java library)
- CMD -> library inserted.  Here we invoke the imported library

The Registration keys for Cloud One Application Security must be called at runtime.  You can show those in the Cloud Formation Template -> Tab:Template ->search appSec registration keys for AppSec
