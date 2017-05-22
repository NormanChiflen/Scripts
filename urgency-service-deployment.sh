working_folder=$(pwd)

cd product/target/
warfile=$(ls urgency-service-product*.war)
appconfig_zipfile=$(ls urgency-service-product*appconfig.zip)

s3cmd --verbose put $warfile s3://ewe-softwares/builds/git@ewegithub.sb.karmalab.net:EWE/exp-urgency-service.git/exp-urgency-service/$GIT_COMMIT/

s3cmd --verbose put $appconfig_zipfile s3://ewe-softwares/builds/git@ewegithub.sb.karmalab.net:EWE/exp-urgency-service.git/exp-urgency-service/$GIT_COMMIT/


if [ "$GIT_BRANCH" == "origin/HEAD" ]; then
  curl --insecure "https://ewe.deploy.sb.karmalab.net:8443/job/ewe-exp-urgency-service-chef-deploy/buildWithParameters?token=eweurgencydeploy&REMARKS=$BUILD_URL&CHANGE_NUMBER=$GIT_COMMIT&WAR_FILE=$warfile&APPCONFIG_ZIPFILE=$appconfig_zipfile"
fi