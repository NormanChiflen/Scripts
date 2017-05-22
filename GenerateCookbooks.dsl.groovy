import javax.net.ssl.*
import javax.security.cert.X509Certificate
import groovy.json.*

/**
  get a page of the project list from the gitlab server.
  this only required to hack around the expedia certs
*/
def gitlabProjects(page) {
  def fakeTrustManager = [ 
    checkClientTrusted:{chain, authType -> },
    checkServerTrusted:{chain, authType -> },
    getAcceptedIssuers:{ null }
  ] as X509TrustManager
  def reallyTrustingVerifier = [
    verify:{hostname, session -> true}
  ] as HostnameVerifier

  // Install the all-trusting trust manager
  SSLContext sslContext = SSLContext.getInstance( "SSL" );
  sslContext.init( null, [fakeTrustManager] as TrustManager[] , new java.security.SecureRandom() )
  // Create an ssl socket factory with our all-trusting manager
  SSLSocketFactory sslSocketFactory = sslContext.getSocketFactory()

  // All set up, we can get a resource through https now:
  URLConnection urlCon = new URL("https://git.ean/api/v3/projects?private_token=${GITLAB_TOKEN}&page=${page}&per_page=10").openConnection()

  // Tell the url connection object to use our socket factory which bypasses security checks
  urlCon.setSSLSocketFactory( sslSocketFactory )
  urlCon.setHostnameVerifier( reallyTrustingVerifier )
  
  def input = urlCon.inputStream
  new JsonSlurper().parseText(input.text)
}

allprojects = []

def projects 
def page = 1
while( !(projects = gitlabProjects(page)).empty) {
  allprojects.addAll( projects )
  page ++
}

// start of generation loop
allprojects.findAll{ it.namespace.name == 'cookbooks' }.each { gitlabProject -> 
  job {
    name "${gitlabProject.name - '-cookbook'} cookbook"
    description "${gitlabProject.description}"
    customWorkspace "${gitlabProject.name.tr(" ", "_")}"
    scm {
      git("${gitlabProject.ssh_url_to_repo}") {
      }
    }
    triggers {
      scm "H/5 * * * *"
    }
    steps {
      shell '''rm -rf .kitchen'''      
      shell '''rm -f Berksfile.lock Gemfile.lock
/opt/rbenv/shims/bundle install
/opt/rbenv/shims/bundle exec berks
'''
      shell '/opt/rbenv/shims/bundle exec foodcritic -f any -f ~style -f ~ETSY001 -f ~ETSY004 -f ~FC033 -t ~FC035 -f ~FC005 -f ~FC011 -f ~FC012 -f ~FC019 -f ~FC017 -t ~FC001 -t ~solo -t ~FC015 -t ~FC023 -f ~FC021 -f ~FC022 -f ~FC023 -t ~FC034 -f ~FC034 -t ~FC024 -f ~FC039 -t ~FC042 -f ~FC042 -t ~FC043 -f ~FC043 -t ~FC045 -f ~FC045 .'
      // tailor is disabled for the short term as the upstream dependances are broken
      // see https://github.com/turboladen/tailor/pull/161 for fix
      // it also would be possible to fix this in all the Gemfile's but that would 
      // be a little tendious
/*      shell '/opt/rbenv/shims/bundle exec tailor'*/
      shell '/opt/rbenv/shims/bundle exec kitchen test -d always'
      shell '''if [ "$GIT_BRANCH" = "origin/master" -o  "$GIT_BRANCH" = "origin/HEAD" ]; then
  /opt/rbenv/shims/bundle exec thor version:bump patch
  /opt/rbenv/shims/bundle exec berks update
  /opt/rbenv/shims/bundle exec berks upload --except integration
else
  echo "Skipping version bump upload as current git branch [$GIT_BRANCH] is not master"
fi
'''
      shell '/opt/rbenv/shims/bundle exec kitchen destroy all'
    }
    publishers {
      archiveJunit("results/report/*.xml", false)
      mailer("", false, true) // dontNotifyEveryUnstableBuild, sendToIndividuals
    }
    wrappers {}

    // nasty hacky bit to configure stuff that job dsl doesn't have
    configure { project ->
      def publishers = project / 'publishers'
      publishers << {
        'jenkins.plugins.hipchat.HipChatNotifier'(plugin:"hipchat@0.1.8") {
          jenkinsUrl "https://jenkins.ean/"
          authToken "5e04054ea1ec7ae1db8f265172fc35"
          room 237641
        }
      }

      def wrappers = project / 'buildWrappers'
      wrappers << {
        'org.jenkinsci.plugins.buildnamesetter.BuildNameSetter'(plugin:"build-name-setter@1.3") {
          template '#${BUILD_NUMBER}-${GIT_BRANCH}'
        }
      }

      def properties = project / 'properties'
      properties << {
        'jenkins.plugins.hipchat.HipChatNotifier_-HipChatJobProperty'(plugin:"hipchat@0.1.8") {
          room 237641
          startNotification false
          notifySuccess true
          notifyAborted false
          notifyNotBuilt false
          notifyUnstable false
          notifyFailure true
          notifyBackToNormal false
        }
      }
      def scm = project / 'scm'
      
      scm << {
        extensions {} // forces an empty tag, which hopefully will prevent the 
                      // default tag everybuild plugin from begining configured
      }

    }

  }
}
