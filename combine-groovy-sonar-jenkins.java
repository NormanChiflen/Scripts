groovy script to analyze the latest war file and post the manual measure to sonar and send you a mail ;) :


import java.util.zip.ZipFile;

//authenticated post
def postSonarMeasure = { resource,metric,val, sonarhost,token ->
	def script = "resource=${resource}&metric=${metric}&val=${val}&text=fromgroovy&description=fromgroovy";
	println script
	URL url = new URL("${sonarhost}/api/manual_measures?"+script);
	URLConnection conn = url.openConnection();
	conn.setRequestMethod("POST");
	conn.setRequestProperty("Content-Type","application/x-www-form-urlencoded");
	conn.setRequestProperty ("Authorization", "Basic ${token}")
	conn.setDoOutput(true);
	OutputStreamWriter wr = new OutputStreamWriter(conn.getOutputStream());
	wr.write(script);
	wr.flush();
	result=  conn.getInputStream().getText()
	println 'metrics created '+result;
	return result
}

def sonar = 'https://continuousbuild.com/sonar'
def mavencoordinate='com.company:mywebapp'
def token = 'myuser:mypassword'.bytes.encodeBase64().toString()

//http://docs.codehaus.org/display/SONAR/Web+Service+API
//curl http://continuousbuild.com/sonar/api/manual_measures?resource=com.company:mywebapp&metric=unverifiedwebinfjars
//http://jira.codehaus.org/browse/SONAR-2966 <not_supported/>  
// 1. define the metrics
// 2. add a measure manually
// 3. launch an analysis
// 4. check the data through api/manual_measures
def postSonarUnverifiedWebInfJars = { value ->
	postSonarMeasure(mavencoordinate,'unverifiedwebinfjars',value,sonar,token)
}

def getActualContentOfWebInfLibFromLastestWar ={
	// find latest war file in target directory
	fileWar = new File("./target").listFiles().findAll(){ it.getName().endsWith('.war')}.sort() { a,b ->
		a.lastModified().compareTo b.lastModified()
	}.getAt(0);
	println "Checking WEB-INF/lib from "+fileWar.canonicalPath;
	//and create actuals with content
	ZipFile file = new ZipFile(fileWar)
	actuals = file.entries().collect { entry -> if (entry.getName().startsWith('WEB-INF/lib/')) return entry.getName().substring('WEB-INF/lib/'.length()) }
	actuals = actuals.findAll {it!=null && !it.equals('')}
	return actuals
}

def getBaseLine = {
	allowed=[]
	new File("./baseline.txt").eachLine { if (!it.trim().isEmpty())allowed.add(it) }
	return 	allowed
}
	actuals =getActualContentOfWebInfLibFromLastestWar();
	allowed =getBaseLine();

	println "************************************ "
	println "actuals "+actuals.size()
	println "allowed "+allowed.size()
	println "************************************ "

	unallowed = [];
	unmatched = [];

	allowedNonMatching = [];
	allowedNonMatching.addAll(allowed);

	actuals.each { actual ->
		ok = allowed.find() { allow ->
			boolean match= (actual =~ '^'+allow)
			if (match) {
				allowedNonMatching.remove(allow)
				println "matching " +actual +" "+ allow
			}
			return match;
		}
		if (ok==null) {
			unallowed.add("unmatched dependencies ! '${actual}' ")
			println "unmatched dependencies ! '${actual}' "
			unmatched.add(actual)
		}
	}
	if (!unallowed.isEmpty() || !allowedNonMatching.isEmpty) {
		def msg =  "The ${project} problem dependencies : \n"+unallowed.join('\n')+" \n add exclusions or adapt baseline.txt check if websphere deployment is ok.\nplease.\n"+actuals.join('\n');
		 ant = new AntBuilder()
		 ant.mail(mailhost:'mysmtp.server.com', subject:"${project} : undesired dependencies detected !" ,tolist:'myaddress@mestachs.com'){
		         from(address:'jenkins@mestachs.com')
		         replyto(address:'myaddress@mestachs.com')
		         message(msg.toString())
		 }

		println msg.toString()
	}
	println "************************************ unused constraint from baseline.txt"
	allowedNonMatching.each {println it}
	println "*************************"
	println "************************************ append content to baseline.txt"
	unmatched.each {println it}
	println "*************************"
	postSonarUnverifiedWebInfJars(unallowed.size())
 

Enable the run of this scripts via maven plugin in a dedicated profile

	
   	            <plugin>
				<groupId>org.codehaus.groovy.maven</groupId>
				<artifactId>gmaven-plugin</artifactId>
				<version>1.0</version>
				<executions>
					<execution>
						<phase>verify</phase>
						<goals>
							<goal>execute</goal>
						</goals>
						<configuration>
							<source>./comparewebinf.groovy</source>
						</configuration>
					</execution>
				</executions>
			</plugin> 	
 
 
 http://mestachs.wordpress.com/2012/10/01/webs-fear-and-maven/
 