from starcluster.clustersetup import ClusterSetup
from starcluster.logger import log

global repo_to_install
global pkg_to_install

class WgetPackages(ClusterSetup):
	def __init__(self,pkg_to_wget):
		self.pkg_to_wget = pkg_to_wget
		log.debug('pkg_to_wget = %s' % pkg_to_wget)
	def run(self, nodes, master, user, user_shell, volumes):
		for node in nodes:
			log.info("Wgetting %s on %s" % (self.pkg_to_wget, node.alias))
			node.ssh.execute('wget %s' % self.pkg_to_wget)

class RpmInstaller(ClusterSetup):
	def __init__(self,rpm_to_install):
		self.rpm_to_install = rpm_to_install
		log.debug('rpm_to_install = %s' % rpm_to_install)
	def run(self, nodes, master, user, user_shell, volumes):
		for node in nodes:
			log.info("Installing %s on %s" % (self.rpm_to_install, node.alias))
			node.ssh.execute('yum -y --nogpgcheck localinstall %s' %self.rpm_to_install)

class RepoConfigurator(ClusterSetup):
	def __init__(self,repo_to_install):
		self.repo_to_install  = repo_to_install
		log.debug('repo_to_install = %s' % repo_to_install)
	def run(self, nodes, master, user, user_shell, volumes):
		for node in nodes:
			log.info("Installing %s on %s" % (self.repo_to_install, node.alias))
			node.ssh.execute('rpm --import %s' % self.repo_to_install)

class PackageInstaller(ClusterSetup):
	def __init__(self,pkg_to_install):
		self.pkg_to_install  = pkg_to_install
		log.debug('pkg_to_install = %s' % pkg_to_install)
	def run(self, nodes, master, user, user_shell, volumes):
		for node in nodes:
			log.info("Installing %s on %s" % (self.pkg_to_install, node.alias))
			node.ssh.execute('yum -y install %s' % self.pkg_to_install)