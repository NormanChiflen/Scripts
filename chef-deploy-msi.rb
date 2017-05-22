#

# Cookbook Name:: myapp

# Recipe:: deploymsi

#

# Copyright 2011, @devopscloud

#

# All rights reserved – Do Not Redistribute

#

msifile = File.basename(“myapp.msi”)

dir = “buildoutput”

drive=”c:”

msifiledst = “#{drive}\\#{dir}\\#{msifile}”

execute “install #{msifiledst}” do

command “msiexec /qn /i #{msifiledst} TARGETENV=DEV”

only_if { File.exists?(msifiledst) }

end




-------------
This example does what you think it does it installs an MSI on the target node.

How does it work:

Firstly we define a number of variables to allow us to identify the msi.

All the grunt work is defined in the execute resource:

execute “install #{msifiledst}” do

command “msiexec /qn /i #{msifiledst} TARGETENV=DEV”

only_if { File.exists?(msifiledst) }

end

The resource  type is: execute.

The resource name is : install #{msifiledst} = Install c:\buildoutput\myapp.msi

It calls the command prompt and then runs msiexec but only if the msi actually exists which is what the only_if (File.exists?..  bit of the recipe does.

Tip  the ‘\\’ to allow you to  use ‘\’  not an issue with Linux nodes but useful when working with windows nodes.