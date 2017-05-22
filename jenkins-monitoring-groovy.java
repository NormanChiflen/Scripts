servers = ['ex1.server.com','ex2.server.com','ex3.server.com']

wdsls=[]
simpleurls=[]
servers.each() {host ->
   wdsls.add("http://${host}/ws/MyWebService?wsdl")
   simpleurls.add("http://${host}/ui/MyConsole.html")
}

def koCount=0;
def slowCount=0;
def checkUrl = { url, check ->
 def status ='KO'
 def host =''
   start= System.currentTimeMillis()
    try {
     myurl = new URL(url)
       host =myurl.getHost()
       def text = myurl.getText(connectTimeout: 10000, readTimeout: 10000)
       def ok = check(url,text)
      status = ok?'OK':'KO';
      if (!ok) {koCount++}
    } catch (Throwable t) {
       koCount++
       }
    end= System.currentTimeMillis()
    if ((end-start)>100)
       slowCount++
    println "$host\t"+status+'\t'+(end-start)+'\t'+' '+url
}
def checkAllUrl =  {urls, check -> urls.each() {url ->checkUrl(url,check)}}
def wsdlCheck = {url,content -> content.contains("wsdl:definitions")}
def pingCheck = {url,content -> content.contains("status=NORMAL")}
def contentCheck = {url,content -> content.contains("login")}

checkAllUrl (wdsls,wsdlCheck )
checkAllUrl (simpleurls,contentCheck)

println "ko.count="+koCount
println "slow.count="+slowCount

if (koCount>0 || slowCount >0) {
    System.exit(-1)
}


Add a Groovy Postbuild : Groovy script:

def addShortTextSlow = { comp,shortcomp->
matcher = manager.getMatcher(manager.build.logFile, comp+".count=(.*)\$")
if(matcher?.matches()) {
    manager.addShortText(shortcomp+' '+matcher.group(1), "grey", "white", "0px", "white")
}
}
addShortTextSlow('slow','slow')
addShortTextSlow('ko','ko')


