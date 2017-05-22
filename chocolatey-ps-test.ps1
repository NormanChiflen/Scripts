# Chocolatey
iex ((new-object net.webclient).DownloadString('http://bit.ly/psChocInstall'))

# install applications
cinst virtualclonedrive
cinst sysinternals
cinst msysgit
cinst fiddler
cinst tortoisesvn

# getting the latest build for webpi support: git clone git://github.com/chocolatey/chocolatey.git | cd chocolatey | build | cd _{tab}| cinst chocolatey -source %cd%
# I’ve already done this and the resulting nugetpkg is also saved in the same network directory: 
cinst chocolatey –source "Z:\Installation\SetupDevPC\"

# Now I’ve got choc I may as well use it to install a bunch of other stuff from WebPI;
# things that didn’t always work when I put them in the looong list of comma delimited installs
# IIS
cinst IIS7 -source webpi
cinst ASPNET -source webpi
cinst BasicAuthentication -source webpi
cinst DefaultDocument -source webpi
cinst DigestAuthentication -source webpi
cinst DirectoryBrowse -source webpi
cinst HTTPErrors -source webpi
cinst HTTPLogging -source webpi
cinst HTTPRedirection -source webpi
cinst IIS7_ExtensionLessURLs -source webpi
cinst IISManagementConsole -source webpi
cinst IPSecurity -source webpi
cinst ISAPIExtensions -source webpi
cinst ISAPIFilters -source webpi
cinst LoggingTools -source webpi
cinst MetabaseAndIIS6Compatibility -source webpi
cinst NETExtensibility -source webpi
cinst RequestFiltering -source webpi
cinst RequestMonitor -source webpi
cinst StaticContent -source webpi
cinst StaticContentCompression -source webpi
cinst Tracing -source webpi
cinst WindowsAuthentication -source w