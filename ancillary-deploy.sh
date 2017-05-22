#!/bin/bash -l

echo TODO: DEPRECATED BUILD STEP, DELETE ME?

echo
echo
echo Preparing lab ssh keys for use...
echo $WORKSPACE

chmod 600 $WORKSPACE/git-repository/dev-ops/ssh/lab/id_rsa
ls -al $WORKSPACE/git-repository/dev-ops/ssh/lab/

echo
echo ...done preparing lab ssh keys.
echo
echo





#PART 2

echo
echo
echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~    Setting Up Shell Environment ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo

# TODO the following hosts are not ready for installation yet: 10.0.17.193

echo setting environment variables...
export LAB_HOSTS=$DeploymentServer
export WORKSPACE_TEMP_DIR=$WORKSPACE/temp
export ancillaryServicePort=8080

export expectedBuildNumber=$UPSTREAM_BUILD_NUMBER
export WORKSPACE_MAVEN_REPOSITORY=$WORKSPACE/repository

# make a maven repository inside the workspace in case it has been manually cleaned
mkdir -p $WORKSPACE_MAVEN_REPOSITORY

echo

# TODO improve this step: use http://wiki.hudson-ci.org/display/HUDSON/Parameterized+Trigger+Plugin instead of fetching the value manually :)
echo setting expected build number:
echo UPSTREAM_JOB_NAME=$UPSTREAM_JOB_NAME
echo UPSTREAM_BUILD_NUMBER=$UPSTREAM_BUILD_NUMBER
echo expectedBuildNumber=$expectedBuildNumber

echo cleaning workspace temp directory...
rm -rf  $WORKSPACE_TEMP_DIR
mkdir $WORKSPACE_TEMP_DIR
echo

echo changing to workspace temp directory...
cd $WORKSPACE_TEMP_DIR
echo

echo
echo
echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
echo
echo

echo
echo
echo ~~~~~~~~~~~~~~~~~~~~~~~~    Running Chef Client On Lab Hosts: $LAB_HOSTS ~~~~~~~~~~~~~~~~~~~~~~~~~
echo

for labHost in $LAB_HOSTS
do
    echo
    echo
    echo ~~~~~~~~~~~~~~~~~~~~~   Host:  $labHost  ~~~~~~~~~~~~~~~~~~~~~
    echo

    echo
    echo
    echo pinging labhost: $labHost
    ping -c 5 $labHost

    echo
    echo
    echo running chef-client...
    #knife ssh -m cheiassint001.karmalab.net 'sudo chef-client' -a 10.187.66.14 -x jenkins -i ~/.ssh/lab/id_rsa
    echo "jenkins" | ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i $WORKSPACE/git-repository/dev-ops/ssh/lab/id_rsa jenkins@$labHost -t -t "sudo -S chef-client"


    echo
    echo
    echo ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    echo
    echo

done
