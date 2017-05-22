#

# Cookbook Name:: myapp

# Recipe:: deploywebapp

#

# Copyright 2011,  @devopscloud

#

# All rights reserved – Do Not Redistribute

#

msi = File.basename(“myWebapp.msi”)

dir = “buildoutput”

drive=”c:”

dst = “#{drive}\\#{dir}\\#{msi}”

template “C:/chef/tmp/appool.ps1? do

source “appool.ps1.erb”

end

execute “install #{dst}” do

command “msiexec /qn /i #{dst} TARGETENV=DEV”

only_if { File.exists?(dst) }

end

execute “updateappool” do

command “c:\\Windows\\System32\\WindowsPowerShell\\V1.0\\powershell.exe c:\\chef\\tmp\\appool.ps1\”"

action :run

cwd “c:/chef/tmp”

end


This recipe installs an MSI as in example 1 but it then runs a powershell script that makes modifications to the appool. This recipe introduces the concept of templates. Templates are stored in the templates folder of your cookbook and stored as .erb files. In this example the erb file contains powershell script. So what does these two line mean?

template “C:/chef/tmp/appool.ps1? do

source “appool.ps1.erb”

This essentially equates to the following:  copy the   file appool.ps1.erb  to target node to the folder c:/chef/tmp  and name accordingly.

Later on in the recipe we actually run the powershell script. Easy huh   Smile

The key thing here really is that all the Powershell you inevitably use as a windows administrator is still reusable and I haven’t even started talking about providers as yet.

The examples above are simple and not exactly robust but they do stuff which is all we want chef recipes to do really.

Recipes are quite a huge topic and I have barely  scraped the surface with these two  simple examples.