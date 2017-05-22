 #!/bin/bash
 #http://blog.diabol.se/?cat=15
set -e  # Exit on error

function usage {
echo "Usage: $0 -r  (-s|-p|-c|-d)
example:
$0 -pc -r 123
$0 -d -r 156
-r The svn revision to use
-s Add a sleep of 60 secs after svn up to be sure we have rsync:ed the puppet code to external puppet
-p parse the manifests changed in
-c compile all hosts in \$TARGET_ENV
-d Do a puppet dry-run (noop) on \$TARGET_HOSTS

Updates puppet modules from svn in \$TARGET_ENV on puppet master at the
beginning of run, and reverts if any failures.

The puppet master is used for parsing and compiling.

This scrips relies on environment variables:
* \$TARGET_ENV for svn
* \$TARGET_HOSTS for dry-run
";
}

if [ $# -lt 1 ]; then
usage; exit 1;
fi

# Set options
sleep=false; parse=false; compile=false; dryrun=false;
while getopts "r:spcd" option; do
case $option in
r) REVISION="$OPTARG";;
s) sleep=true;;
p) parse=true;;
c) compile=true;;
d) dryrun=true;;
*) echo "Unknown parameter: $opt $OPTARG"; usage; exit 1;;
esac
done
shift $((OPTIND - 1))

if [ "x$REVISION" = "x" ]; then
usage; exit 1;
fi

# This directory is updated by a Jenkins job
cd /opt/tools/ci-jenkins/jenkins-home/common-tools/scripts/ansible/

# SVN UPDATE ##################################################################
declare -i OLD_SVN_REV
declare -i NEXT_SVN_REV
## Store old svn rev before updating so we can roll back if not OK
OLD_SVN_REV=`ssh -T admin@puppetmaster svn info /etc/puppet/environments/${TARGET_ENV}/modules/| grep -E '^Revision:' | cut -d ' ' -f 2`
echo $'\n######### ######### ######### ######### ######### ######### ######### #########'
echo "Current svn revision in ${TARGET_ENV}: $OLD_SVN_REV"
if [ "$OLD_SVN_REV" != "$REVISION" ]; then
# We could have more than on commit since last run (even if we use post-commit hooks)
NEXT_SVN_REV=${OLD_SVN_REV}+1
# Update Puppet master
ansible-playbook puppet-master-update.yml -i hosts --extra-vars="target_env=${TARGET_ENV} revision=${REVISION}"
# SLEEP #############################
$sleep {
echo 'Sleep for a minute to be sure we have rsync:ed the puppet code to external puppet...'
sleep 60
}
else
echo 'Svn was already at required revision. Continuing...'
NEXT_SVN_REV=$REVISION
fi

# Final result ################################################################
declare -i RESULT
RESULT=0
set +e  # Don't exit on error. Collect the errors instead.

# PARSE #######################################################################
$parse {
# Parse manifests ###################
## Get only the paths to the manifests that was changed (to limit the number of parses).
MANIFEST_PATH_LIST=`svn -q -v --no-auth-cache --username $JENKINS_USR --password $JENKINS_PWD -r $NEXT_SVN_REV:$REVISION log http://scm.company.com/svn/puppet/trunk | grep -F '/puppet/trunk/modules' | grep -F '.pp' |  grep -Fv '   D' | cut -c 28- | sed 's/ .*//g'`
echo $'\n######### ######### ######### ######### ######### ######### ######### #########'
echo $'Manifests to parse:'; echo "$MANIFEST_PATH_LIST"; echo "";
for MANIFEST_PATH in $MANIFEST_PATH_LIST; do
# Parse this manifest on puppet master
ansible-playbook puppet-parser-validate.yml -i hosts --extra-vars="manifest_path=/etc/puppet/environments/${TARGET_ENV}/modules/${MANIFEST_PATH}"
RESULT+=$?
done

# Check template syntax #############
TEMPLATE_PATH_LIST=`svn -q -v --no-auth-cache --username $JENKINS_USR --password $JENKINS_PWD -r $NEXT_SVN_REV:$REVISION log http://scm.company.com/svn/platform/puppet/trunk | grep -F '/puppet/trunk/modules' | grep -F '.erb' |  grep -Fv '   D' | cut -c 28-`
echo $'\n######### ######### ######### ######### ######### ######### ######### #########'
echo $'Templates to check syntax:'; echo "$TEMPLATE_PATH_LIST"; echo "";
for TEMPLATE_PATH in $TEMPLATE_PATH_LIST; do
erb -P -x -T '-' modules/${TEMPLATE_PATH} | ruby -c
RESULT+=$?
done
}

# COMPILE #####################################################################
$compile {
echo $'\n######### ######### ######### ######### ######### ######### ######### #########'
echo "Compile all manifests in $TARGET_ENV"
ansible-playbook puppet-master-compile-all.yml -i hosts --extra-vars="target_env=${TARGET_ENV} puppet_args=--color=false"
RESULT+=$?
}

# DRY-RUN #####################################################################
$dryrun {
echo $'\n######### ######### ######### ######### ######### ######### ######### #########'
echo "Run puppet in dry-run (noop) mode on $TARGET_HOSTS"
ansible-playbook puppet-run.yml -i hosts --extra-vars="hosts=${TARGET_HOSTS} puppet_args='--noop --color=false'"
RESULT+=$?
}

set -e  # Back to default: Exit on error

# Revert svn on puppet master if there was a problem ##########################
if [ $RESULT -ne 0 ]; then
echo $'\n######### ######### ######### ######### ######### ######### ######### #########'
echo $'Revert svn on puppet master due to errors above\n'
ansible-playbook puppet-master-revert-modules.yml -i hosts --extra-vars="target_env=${TARGET_ENV} revision=${OLD_SVN_REV}"
fi

exit $RESULT