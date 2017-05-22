import jenkins.model.*

def instance = jenkins.model.Jenkins.instance

def jobNames = [
  ["xwiki-commons", "${newCommonsBranch}"],
  ["xwiki-rendering", "${newRenderingBranch}"],
  ["xwiki-platform", "${newPlatformBranch}"],
  ["xwiki-enterprise", "${newEnterpriseBranch}"],
  ["xwiki-manager", "${newManagerBranch}"],
  // The order below is important since those builds are dependent on one another and need to be created in the right order
  ["xwiki-enterprise-test-cluster", "${newEnterpriseBranch}"],
  ["xwiki-enterprise-test-rest", "${newEnterpriseBranch}"],
  ["xwiki-enterprise-test-escaping", "${newEnterpriseBranch}"],
  ["xwiki-enterprise-test-extension", "${newEnterpriseBranch}"],
  ["xwiki-enterprise-test-ldap", "${newEnterpriseBranch}"],
  ["xwiki-enterprise-test-misc", "${newEnterpriseBranch}"],
  ["xwiki-enterprise-test-storage", "${newEnterpriseBranch}"],
  ["xwiki-enterprise-test-ui", "${newEnterpriseBranch}"],
  ["xwiki-enterprise-test-webdav", "${newEnterpriseBranch}"],
  ["xwiki-enterprise-test-webstandards", "${newEnterpriseBranch}"],
  ["xwiki-enterprise-test-wysiwyg", "${newEnterpriseBranch}"],
  ["xwiki-enterprise-test-xmlrpc", "${newEnterpriseBranch}"],
  ["xwiki-manager-test-selenium", "${newManagerBranch}"],
  ["xwiki-manager-test-webstandards", "${newManagerBranch}"],
  ["xwiki-enterprise-test-selenium", "${newEnterpriseBranch}"],
  ["xwiki-enterprise-test-pageobjects", "${newEnterpriseBranch}"],
  ["xwiki-enterprise-test-pom", "${newEnterpriseBranch}"],
  ["xwiki-manager-test-pom", "${newManagerBranch}"]
]
  
jobNames.each() { jobData ->

  def jobName = jobData.get(0)
  def branchName = jobData.get(1)
  
  def newJobName = "${jobName}-${newShortVersion}"
  print "Copying job \"${jobName}\" to \"${newJobName}\"... "
  
  def item = instance.getItem(jobName)

  // Perform the job copy
  if (instance.getItem(newJobName) == null) {
    def newitem = instance.copy(item, newJobName)

    // Change the branch to build
    def branchSpec = newitem.scm.branches.get(0)
    def oldBranchName = branchSpec.name
    branchSpec.name = branchName
    println ""
    println "  - Changed branch from [${oldBranchName}] to [${branchName}]"
      
    // Change the build triggers
    // Note tha BuildTriggers are immutable which is why we need to remove and add it again
    def pl = newitem.publishersList
    def bt = pl.get(hudson.tasks.BuildTrigger.class)
    if (bt != null) {
      def triggers = bt.childProjectsValue
      def newTriggers = triggers.split(",").findAll {
        instance.getItem("${it.trim()}-${newShortVersion}") != null
      }.collect { "${it.trim()}-${newShortVersion}" }.join(",")
      pl.remove(bt)
      pl.add(new hudson.tasks.BuildTrigger(newTriggers, false)) 
      println "  - Changed build triggers from [${triggers}] to [${newTriggers}]"
    } else {
      println "  - No build triggers defined"
    }
        
    newitem.save()
  } else {
    println "Job already exists!"
  }
}

// Since we've potentially changed the dependencies, update the in-memory dependency graph
instance.rebuildDependencyGraph()