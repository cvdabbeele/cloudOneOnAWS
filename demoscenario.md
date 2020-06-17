# Demo scenario

## awsEc2

prep  
 - AWS: delete EC2s
 - DSM: sync AWS connector

demo  
 -   ./up.sh  
 -   aws: show instances and tags  
DSM: show connector  
- show instances that come online
- show different tags resulting in different policies  
- show EBTs  
- open Finance system  
- show tags, show attached policies
-  show 19 IPS rules
- ./recoscan

## awscicd
prep:  
-   kubectl delete -f /app.yaml  

demo  
- EKS cluster with a pipeline
- running SmartCheck -> WebUI  
- kubectl get pods -n smartcheck  
- ./build_moneyx.sh  
- show codecommit, show buildspec  
- walk through pipeline  
