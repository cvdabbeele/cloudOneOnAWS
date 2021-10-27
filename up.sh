#!/bin/bash

MAINSTARTTIME=`date +%s`

# import variables
. ./00_define_vars.sh

# install tools
. ./environmentSetup.sh

mkdir -p work

# create cluster
. ./eksCluster.sh

# deploy SmartCheck
. ./smartcheck.sh

# add internal smartcheck repo
. ./smartcheckInternalRepo.sh

# create groups in C1AS
. ./C1AS.sh

# add C1CS
. ./C1CS.sh

# setup AWS CodePipeline
. ./pipelines.sh

# add the demo apps
. ./demoApps.sh

# add ECR registry to SmartCheck
. ./smartCheckAddEcr.sh

printf '%s\n'  "You can now kick off sample pipeline-builds of MoneyX"
printf '%s\n'  " e.g. by running ./pushWithHighSecurityThresholds.sh"
printf '%s\n'  " e.g. by running ./pushWithMalware.sh"
printf '%s\n'  " After each script, verify that the pipeline has started and give it time to complete"
printf '%s\n'  " If you kick off another pipeline too early, it will overrule (and stop) the previous one"

MAINENDTIME=`date +%s`
printf '%s\n' "Script run time = $((($MAINENDTIME-$MAINSTARTTIME)/60)) minutes"
 

# create report
#still need to ensure that either "latest" gets scanned or that $TAG gets exported from the pipeline
# plus: data on Snyk findings is not visible in the report
# docker run --network host mawinkler/scan-report:dev -O    --name "${TARGET_IMAGE}"    --image_tag latest    --service "${DSSC_HOST}"    --username "${DSSC_USERNAME}"    --password "\"${DSSC_PASSWORD}"\"
#end