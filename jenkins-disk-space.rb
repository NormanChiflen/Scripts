http://mestachs.wordpress.com/2012/05/05/jenkins-diskspace-requirement-tips/
As lazy programmer, you may be know that jenkins offer a jenkins script console.
https://wiki.jenkins-ci.org/display/JENKINS/Jenkins+Script+Console
So you can fix artefact archiving in a single batch with the following script :

String format ='%-45s | %-20s | %-10s | %-10s | %-30s'
def readonly = false
activeJobs = hudson.model.Hudson.instance.items.findAll
    {job -> job.isBuildable() && job instanceof hudson.maven.MavenModuleSet}
def oneline= { str ->   if (str==null)     return "";  str.replaceAll("[\n\r]", " - ")}
println String.format(format , "job", "scm trigger","last status"," logrot","archiving")
println "-------------------------------------------------------------------------------------------------------------------------------"
activeJobs.each{run ->
    println String.format(format ,run.name,oneline(run.getTrigger(hudson.triggers.Trigger.class)?.spec), run?.lastBuild?.result, run.logRotator.getDaysToKeep()+" "+run.logRotator.getNumToKeepStr(), ""+run.isArchivingDisabled()) ; 
    if (!run.isArchivingDisabled() && !readonly ) {        
        run.setIsArchivingDisabled(true);
        run.save()
    }
}