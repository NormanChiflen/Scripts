The DSL allows the definition of a job, and then offers a useful set of functions to configure common Jenkins items. A configure is available to give direct access to the config.xml before generating the job. The script is groovy code, which can be very powerful. Here's an example to create a job for each branch in a git repo:

def project = 'quidryan/aws-sdk-test'
def branchApi = new URL("https://api.github.com/repos/${project}/branches")
def branches = new groovy.json.JsonSlurper().parse(branchApi.newReader())
branches.each {
    def branchName = it.name
    job {
        name "${project}-${branchName}".replaceAll('/','-')
        scm {
            git("git://github.com/${project}.git", branchName)
        }
        steps {
            maven("test -Dproject.name=${project}/${branchName}")
        }
    }
}

