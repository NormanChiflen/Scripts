import hudson.model.*
def thr = Thread.currentThread()
def build = thr?.executable
build.addAction(new ParametersAction(new StringParameterValue('SVN_UPSTREAM', build.getEnvVars()['SVN_REVISION'])))
#http://dmitrijs.artjomenko.com/2011/12/passing-upstream-parameters-to.html