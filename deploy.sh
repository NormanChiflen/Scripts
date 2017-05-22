#!/bin/sh


file_version=`echo ${5} | awk -F ',' '{print $1}' | awk -F '=' '{print $2}'`
cookbook_version=`echo ${5} | awk -F ',' '{print $2}' | awk -F '=' '{print $2}'`

rm /tmp/ui.json

if [[ $3 == "MAUI" ]]
then
cp "/mnt/deployment/net/karmalab/e3/gpt/tax/ui/integration/p.main/ui.json" /tmp/ui.json
perl -pi -e "s%#FILE_VERSION#%\${file_version}%;" /tmp/ui.json
sudo /mnt/chef-solo/ruby/bin/chef-solo -j /tmp/ui.json -r /mnt/depreps/releasecandidate/com.expedia.e3.es.tax.cookbooks/com.expedia.e3.es.tax.cookbooks-${cookbook_version}.tgz
elif [[ $3 == "MILAN" ]]
then
cp "/mnt/deployment/net/karmalab/e3/gpt/tax/ui/stable/p.main/ui.json" /tmp/ui.json
perl -pi -e "s%#FILE_VERSION#%${file_version}%;" /tmp/ui.json
sudo /mnt/chef-solo/ruby/bin/chef-solo -j /tmp/ui.json -r /mnt/depreps/releasecandidate/com.expedia.e3.es.tax.cookbooks/com.expedia.e3.es.tax.cookbooks-${cookbook_version}.tgz
else
cp "/mnt/deployment/net/karmalab/e3/gpt/tax/ui/prod/p.main/ui.json" /tmp/ui.json
perl -pi -e "s%#FILE_VERSION#%\${file_version}%;" /tmp/ui.json
sudo /mnt/chef-solo/ruby/bin/chef-solo -j /tmp/ui.json -r /mnt/depreps/release/com.expedia.e3.es.tax.cookbooks/com.expedia.e3.es.tax.cookbooks-${cookbook_version}.tgz
fi
