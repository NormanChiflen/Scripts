#!/usr/bin/env bash
if [ ! -f /usr/bin/chef-client ]; then
    curl https://opscode-omnibus-packages.s3.amazonaws.com/el/6/x86_64/chef-11.4.0-1.el6.x86_64.rpm > /tmp/chef-11.4.0-1.el6.x86_64.rpm
    rpm -Uvh /tmp/chef-11.4.0-1.el6.x86_64.rpm
fi
sed -i -e's/^Defaults\s*requiretty$/#Defaults requiretty/' /etc/sudoers
(
cat <<'EOF'
[s3tools]
name=Tools for managing Amazon S3 - Simple Storage Service (RHEL_6)
type=rpm-md
baseurl=http://s3tools.org/repo/RHEL_6/
gpgcheck=1
gpgkey=http://s3tools.org/repo/RHEL_6/repodata/repomd.xml.key
enabled=1
EOF
) > /etc/yum.repos.d/s3tools.repo
yum localinstall -y --nogpgcheck http://mirror.umd.edu/fedora/epel/6/i386/epel-release-6-7.noarch.rpm
yum clean all
yum install -y s3cmd
(
cat <<'EOF'
[default]
access_key = {{ access_key }}
secret_key = {{ secret_key }}
use_https = True
EOF
) > /root/.s3cfg
s3cmd -c /root/.s3cfg get s3://eaap-artefacts/validation.pem /etc/chef/validation.pem
mkdir -p /etc/chef
(
cat <<'EOP'
log_level        :info
log_location     STDOUT
chef_server_url  "https://api.opscode.com/organizations/eaap"
validation_client_name "eaap-validator"
EOP
) > /etc/chef/client.rb
(
cat <<'EOP'
{
{{{ defaults }}},
"run_list": "role[{{ role }}]"
}
EOP
) > /etc/chef/first-boot.json
/opt/chef/bin/chef-client -K /etc/chef/validation.pem -j /etc/chef/first-boot.json -L /var/log/first-chef.log

 #   access_key - this needs to be the access key for the AWS user account
  #  secret_key - this needs to be the secret key for the AWS user account. Rather than add these values here, check an existing server to see if it has those values or ask someone in the know
   # defaults - this needs to be a valid JSON snippet supplying default values for revisions of applications to install
    #role - this needs to be the Chef role that this node will fulfil. Current nodes are users_service, service_registry and demonstrator. Others will be created in the future

