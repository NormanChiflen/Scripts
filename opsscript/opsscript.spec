Name:		opsscript	
Version:	0.10
Release:	1%{?dist}
Summary:	CCT Operations Scripts

Group:		Applications/Internet
BuildArch:      noarch
License:	DK
URL:		http://basecamp/en-us/departments/teams/CCT/
Source0:	opsscript-0.10.tar.gz
BuildRoot:	%(mktemp -ud %{_tmppath}/%{name}-%{version}-%{release}-XXXXXX)

Requires:	bash

%description
A collection of CCT Shell Scripts

%prep
%setup -q


%build


%install
rm -rf ${RPM_BUILD_ROOT}
mkdir -p ${RPM_BUILD_ROOT}/ops/bin
install -m 755 memhog ${RPM_BUILD_ROOT}/ops/bin
install -m 755 deploy-lab ${RPM_BUILD_ROOT}/ops/bin
install -m 755 hww_bulksender ${RPM_BUILD_ROOT}/ops/bin
install -m 755 deploy-prod ${RPM_BUILD_ROOT}/ops/bin
install -m 755 restart_tomcat ${RPM_BUILD_ROOT}/ops/bin
install -m 755 tomcat_stopall ${RPM_BUILD_ROOT}/ops/bin
install -m 755 tomcat_startall ${RPM_BUILD_ROOT}/ops/bin

%clean
rm -rf $RPM_BUILD_ROOT


%files
%defattr(-,root,root)
%attr(755,root,root) /ops/bin/memhog
%attr(755,root,root) /ops/bin/deploy-lab
%attr(755,root,root) /ops/bin/deploy-prod
%attr(755,root,root) /ops/bin/hww_bulksender
%attr(755,root,root) /ops/bin/restart_tomcat
%attr(755,root,root) /ops/bin/tomcat_stopall
%attr(755,root,root) /ops/bin/tomcat_startall

%changelog
* Mon Sep 24 2012 Updates and Amendments
- added chmod to deploy-lab script for unlocking files in appconfig so they can be rm 
* Tue Sep 18 2012 Updates and Amendments
- added tomcat_Restart script
* Thu Aug 09 2012 Updates and Amendments
- fixed code for curl validation at the end
* Wed Aug 08 2012 Updates and Amemdments
- deploy-lab updated to include configjar switching based on environment
* Mon Jul 30 2012 Updates and Amendments
- deploy-prod script added
- deploy-lab updated to include environment
- hww_bulksender added
* Thu May 24 2012 A Collection of CCT Shell Scripts
- memhog script added
