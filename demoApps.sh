#!/bin/bash
printf '%s\n' "-------------------------------"
printf '%s\n' "     (re-)Adding Demo-apps     "
printf '%s\n' "-------------------------------"

#checking required variables
varsok=true
if  [ -z "$AWS_REGION" ]; then echo AWS_REGION must be set && varsok=false; fi
if  [ -z "$APP_GIT_URL1" ]; then echo APP_GIT_URL1 must be set && varsok=false; fi
if  [ -z "$APP_GIT_URL2" ]; then echo APP_GIT_URL2 must be set && varsok=false; fi
if  [ -z "$APP_GIT_URL3" ]; then echo APP_GIT_URL3 must be set && varsok=false; fi
if  [ "$varsok" = false ]; then exit 1 ; fi

function setupApp {
  #$1=appname
  #$2=downloadURL for application on public git
  currentDir=`pwd`
  #printf '%s\n' "Creating required vars for ${1}"
  #finding AWS_CODECOMMITURL
  aws_cc_repos=(`aws codecommit list-repositories --region $AWS_REGION | jq -r '.repositories[].repositoryName'`)
  export AWS_CC_REPO=''
  for i in "${!aws_cc_repos[@]}"; do
    # printf '%s\n' "Repo $i =  ${aws_ecr_repos[$i]} .........."
    if [[ "${aws_cc_repos[$i]}" =~ "${C1PROJECT}${1}" ]]; then
         #printf "%s\n" "Found CodeCommit Repo "${aws_cc_repos[$i]}
         AWS_CC_REPO=${aws_cc_repos[$i]}
         export AWS_CC_REPO_URL=`aws codecommit get-repository --region $AWS_REGION --repository-name ${AWS_CC_REPO} | jq -r '.repositoryMetadata.cloneUrlHttp' | sed 's/https\:\/\///'`
         printf "%s\n" "Found CodeCommit Repo URL ${AWS_CC_REPO_URL}"
         break
    else
      AWS_CC_REPO=''
    fi
  done

  if [[ "${AWS_CC_REPO}" = '' ]]; then
    printf '%s \n' "PANIC:  Could not find the CodeCommit repository: ${AWS_CC_REPO}. Run \"up.sh\" again."
    read -p "Press CTRL-C to exit script, or Enter to continue anyway"
  fi


  #finding AWS_ECRREPOSITORYURL
  aws_ecr_repos=(`aws ecr describe-repositories --region ${AWS_REGION} | jq -r '.repositories[].repositoryName'`)
  export AWS_ECR_REPO=''
  aws_searchrepo=`echo ${C1PROJECT}${1} | awk '{ print tolower($0) }'`
  for i in "${!aws_ecr_repos[@]}"; do
    #printf '%s\n' "Repo $i =  ${aws_ecr_repos[$i]} .........."
    if [[ "${aws_ecr_repos[$i]}" =~ "${aws_searchrepo}" ]]; then
         #printf "%s\n" "Found ECR repo ${aws_ecr_repos[$i]}"
         export AWS_ECR_REPO=${aws_ecr_repos[$i]}
         export AWS_ECR_REPO_URL=`aws ecr describe-repositories --region ${AWS_REGION} | jq -r ".repositories[$i].repositoryUri"`
         #printf "%s\n" "Found ECR repo URL ${AWS_ECR_REPO_URL}"
         break
    else
     AWS_ECR_REPO=''
    fi
  done
  if [[ "${AWS_ECR_REPO}" = '' ]]; then
      printf '%s \n' "PANIC:  Could not find the ECR repository: ${AWS_ECR_REPO}. Run \"up.sh\" again."
      read -p "Press CTRL-C to exit script, or Enter to continue anyway"
  fi

  mkdir -p  ../apps
  cd ../apps
  #cannot use ${1} for dirname because ${1} =  dirname | tr -cd '[:alnum:]'| awk '{ print tolower($1) }'
  dirname=`echo ${2} | awk -F"/" '{print $NF}' | awk -F"." '{ print $1 }' `
  #echo ${2}
  #echo dirname= $dirname
  #clone from public git if not already done so
  ###if [ -d "${dirname}" ]; then
  ###   printf '%s\n' "Directory ../apps/${dirname} exists.  Not downloading app again"
  ###else
     printf '%s\n' "Cloning ${dirname} from public git"
     git clone ${2} 2>/dev/null
     #printf '%s\n' "Deleting ${dirname}/.git directory (.git from github)"
     rm -rf ${dirname}/.git
  ###fi
  cd ../apps/$dirname
  # removing the link to github as this will be linked to the AWS CodeCommit
  ###if [ -d ".git" ]; then
  ###  printf '%s\n'  ".git directory found, skipping git init"
  ###else
    printf '%s\n'  "Initializing git for CodeCommit"
    git init  1>/dev/null 2>/dev/null
    git config --global user.name ${C1PROJECT}
    git config --global user.email ${C1PROJECT}@example.com
    #git remote add origin https://${AWS_CC_REPO_URL}.git
    git remote add origin https://${AWS_CC_REPO_URL}
  ###fi

  #adding AWS codecommit credential-helper to ~/.gitconfig"
  printf '%s\n' "Adding AWS codecommit credential-helper to ~/.gitconfig"
  git config --global credential.helper '!aws codecommit credential-helper $@'

  printf '%s\n'  "Generating a dummy change to trigger an intial build through the pipeline"
  echo " " >> Dockerfile
  #. push to the git repo in AWS
  git add .  2>/dev/null
  printf '%s\n'  "Committing with tag \"add demoApps\""
  git commit -m "commit by \"add demoApps\""    1>/dev/null 2>/dev/null 
  printf '%s\n'  "   Pushing ${dirname} to CodeCommit"    
  git push --set-upstream origin master         1>/dev/null 2>/dev/null
  #4. pipeline will pick it up, build an Image, send it to SmartCheck..
  cd $currentDir
}

function getUrl {
  #todo.. wait for service to become online
  fqdn=`kubectl get service ${1}  | grep ${1} | awk '{ print $4 }'`
  port=`kubectl get service ${1}  | grep ${1} | awk '{ print $5 }' |  awk -F ":" '{ print $1 }'`
  if [ ! -z "$fqdn" ]; then
    printf '%s\n' "App \"${1}\" has been deployed to EKS and can be reached at http(s)://${fqdn}:${port}"
  fi
#  return 0
}

# If exists, delete old Apps directory
[ -d "/home/ubuntu/environment/appsxx"/ ] && printf '%s\n' "Cleaning up old Apps directory" && rm -rf ../apps 

# setupApp
#  for backward compatibility; set the TREND_AP variables
TREND_AP_KEY=${APP1KEY}
TREND_AP_SECRET=${APP1SECRET}
setupApp ${APP1} ${APP_GIT_URL1}

TREND_AP_KEY=${APP2KEY}
TREND_AP_SECRET=${APP2SECRET}
setupApp ${APP2} ${APP_GIT_URL2}

TREND_AP_KEY=${APP3KEY}
TREND_AP_SECRET=${APP3SECRET}
setupApp ${APP3} ${APP_GIT_URL3}

#exit
#optionally (if the app makes it through the scanning)
#it takes a while for the apps to get processed through the pipeline
#running the getUrl below will typically result in errors because the apps have not been deployed yet
#getUrl $APP1
#getUrl $APP2
#getUrl $APP3

