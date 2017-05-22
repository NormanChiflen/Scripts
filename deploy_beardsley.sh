#!/bin/sh


file_version=`echo ${5} | awk -F ',' '{print $1}' | awk -F '=' '{print $2}'`
cookbook_version=`echo ${5} | awk -F ',' '{print $2}' | awk -F '=' '{print $2}'`
app_name=`echo ${5} | awk -F ',' '{print $3}' | awk -F '=' '{print $2}'`
json_file=`echo ${5} | awk -F ',' '{print $4}' | awk -F '=' '{print $2}'`

rm /tmp/${json_file}

if [[ $3 == "MAUI" ]]
then
cp "/mnt/deployment/net/karmalab/e3/gpt/tax/${app_name}/integration/p.main/${json_file}" /tmp/${json_file}
perl -pi -e "s%#FILE_VERSION#%\${file_version}%;" /tmp/${json_file}
sudo /mnt/chef-solo/ruby/bin/chef-solo -j /tmp/${json_file} -r /mnt/depreps/releasecandidate/com.expedia.e3.es.tax.cookbooks/com.expedia.e3.es.tax.cookbooks-${cookbook_version}.tgz
elif [[ $3 == "MILAN" ]]
then
cp "/mnt/deployment/net/karmalab/e3/gpt/tax/${app_name}/stable/p.main/${json_file}" /tmp/${json_file}
perl -pi -e "s%#FILE_VERSION#%${file_version}%;" /tmp/${json_file}
sudo /mnt/chef-solo/ruby/bin/chef-solo -j /tmp/${json_file} -r /mnt/depreps/releasecandidate/com.expedia.e3.es.tax.cookbooks/com.expedia.e3.es.tax.cookbooks-${cookbook_version}.tgz
else
cp "/mnt/deployment/net/karmalab/e3/gpt/tax/${app_name}/prod/p.main/${json_file}" /tmp/${json_file}
perl -pi -e "s%#FILE_VERSION#%\${file_version}%;" /tmp/${json_file}
sudo /mnt/chef-solo/ruby/bin/chef-solo -j /tmp/${json_file} -r /mnt/depreps/release/com.expedia.e3.es.tax.cookbooks/com.expedia.e3.es.tax.cookbooks-${cookbook_version}.tgz
fi
