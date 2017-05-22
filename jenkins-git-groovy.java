def matcher = manager.getLogMatcher(".*Commencing build of Revision (.*) (.*)\$")
if(matcher?.matches()) {
    branch = matcher.group(2).substring(8,matcher.group(2).length()-1)
    commit = matcher.group(1).substring(0,6)
    githuburl = manager.build.getParent().getProperty("com.coravy.hudson.plugins.github.GithubProjectProperty").getProjectUrl().commitId(matcher.group(1))
    description = "<a href='${githuburl}'>${commit}</a>"+" - "+branch 
    manager.build.setDescription(description)
}

 ------postbuild groovy script that will show the deployed sha and the github difference between the previously deployed version :

def matcher = manager.getLogMatcher(".*commit (.*)\$")
if(matcher?.matches()) {
    branch = 'develop'
    commit = matcher.group(1).substring(0,6)
    projectUrl = manager.build.getParent().getProperty("com.coravy.hudson.plugins.github.GithubProjectProperty").getProjectUrl()
    githuburl = projectUrl.commitId(matcher.group(1))
    def matcher_currently_depoyed = manager.getLogMatcher(".*CURRENTLY_DEPLOYED_SHA (.*)\$")
    commit_from = matcher_currently_depoyed.group(1).substring(0,6)
    description = "<a href='${githuburl}'>${commit}</a> - ${branch} - <a href='${projectUrl.baseUrl}compare/${commit_from}...${commit}'>diff</a>"
    manager.build.setDescription(description)
}
