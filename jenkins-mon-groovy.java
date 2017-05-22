You can easily embed this graph or the green/red ball in jira our your wiki :


<a href="http://myjenkins.com/job/monitoring/lastBuild/consoleText">
    <img src="http://myjenkins.com/job/monitoring/buildTimeGraph/png" alt="200" title="200" border="0"/>
</a>

<a href="http://myjenkins.com/job/monitoring/lastBuild/consoleText">
    <img src="http://myjenkins.com/job/monitoring/lastBuild/buildStatus" border="0">
</a>

The sky is the limit !

Ok now you got the idea… let’s add some checks to gather

– check some open ports :

try {
    s = new Socket(host, port);
    s.withStreams { input, output ->	}
    println "management port ok $host $port"
} catch (Exception e){
    koCount++
    println "management port KO for  $host $port : "+e.getMessage()
}	

– access jmx beans

import javax.management.remote.*
def serverUrl = new JMXServiceURL('service:jmx:rmi:///jndi/rmi://ex1.server.com:9999/jmxrmi')
def server = JMXConnectorFactory.connect(serverUrl).MBeanServerConnection;
def memory = new GroovyMBean(server, 'java.lang:type=Memory')
println memory.listAttributeNames() 
println memory.listOperationNames() 

– some jamon statistics :

jamonurls=[]
jamonurlsuffix='/jamonadmin.jsp?sortCol=2&sortOrder=desc&displayTypeValue=RangeColumns&RangeName=ms.&outputTypeValue=xml&formatterValue=%23%2C%23%23%23&TextSize=0&highlight=&ArraySQL=^WS-|^Fault&'

servers.each() {host ->	jamonurls.add("http://${host}"+jamonurlsuffix)}

def fixJamonXml= {
	xml ->
	if (xml.indexOf("No data was returned") != -1) {
		return '<JAMonXML></JAMonXML>';
	}
	String content = xml.substring(xml.indexOf('<JAMonXML>'));
	rangeLabels = [ "0_10ms", "10_20ms","20_40ms","40_80ms","80_160ms","160_320ms","320_640ms","640_1280ms","1280_2560ms","2560_5120ms","5120_10240ms","10240_20480ms"];
	content = content.replaceAll( '<Label>','<Label><![CDATA[');
	content = content.replaceAll( '</Label>',']]></Label>');
	rangeLabels.each() {
		rangeLabel -> content = content.replaceAll(rangeLabel, "range_" + rangeLabel);
	}
	content = content.replaceAll(  "LessThan_0ms", "range_LessThan_0ms");
	content = content.replaceAll( "GreaterThan", "range_GreaterThan");
	return content
}

def jamonCheck= {
	url,content ->
	monitors = []
	def JAMonXML = new XmlSlurper().parseText(fixJamonXml(content))
    def parseLong =  { t ->  if (t.text().equals("")) return null; Long.valueOf(t.text().replaceAll(',', ''))}
    def parseLongString =  { t ->  if (t.equals("")) return null; Long.valueOf(t.replaceAll(',', ''))}
    def parseRange = {
		rangeText ->	// 15/10.2 (0/0/0)
		// http://docs.codehaus.org/display/GROOVY/Tutorial+5+-+Capturing+regex+groups
		rangeFormat = /(.*)\/(.*) \((.*)\/(.*)\/(.*)\)/
		matched = ( rangeText.text() =~ rangeFormat )
		if (matched.matches()) {
			return [	'label':rangeText.name() , hits : parseLongString(matched[0][1]),average:matched[0][2]]
		}
		return [	'label':rangeText.name() , hits : 0,average:0.0]
	}
	println "************************"+ url
	JAMonXML.children().each() { row ->
		monitors.add( [
			'label' : row.Label,
			'units' : row.Units,
			'hits' : parseLong(row.Hits),
			'avg'  : parseLong(row.Avg),
			'total' : parseLong(row.Total),
			'stddev' : parseLong(row.StdDev),
			'lastvalue': parseLong(row.LastValue),
			'min' : parseLong(row.Min),
			'max' : parseLong(row.Max),
			'active' : parseLong(row.Active),
			'avgActice':parseLong(row.AvgActive),
			'maxActice':parseLong(row.MaxActive),
			'firstAccess':row.FirstAccess,
			'lastAccess' : row.LastAccess,
			'ranges' : [
				'range_LessThan_0ms' :parseRange(row.range_LessThan_0ms),
				'range_0_10ms' : parseRange(row.range_0_10ms),
				'range_10_20ms' : parseRange(row.range_10_20ms) ,
				'range_20_40ms' : parseRange(row.range_20_40ms),
				'range_40_80ms':parseRange(row.range_40_80ms),
				'range_80_160ms' : parseRange(row.range_80_160ms) ,
				'range_160_320ms' : parseRange(row.range_160_320ms),
				'range_320_640ms' : parseRange(row.range_320_640ms),
				'range_640_1280ms' : parseRange(row.range_640_1280ms),
				'range_1280_2560ms' : parseRange(row.range_1280_2560ms) ,
				'range_2560_5120ms' : parseRange(row.range_2560_5120ms),
				'range_5120_10240ms' : parseRange(row.range_5120_10240ms),
				'range_10240_20480ms' : parseRange(row.range_10240_20480ms),
				'range_GreaterThan_20480ms': parseRange(row.range_GreaterThan_20480ms)]
		] )
	}
	/**
	 *  1      0      10ms
		2     10      20ms
		3     20      40ms
		4     40      80ms 
		5     80     160ms
		6    160     320ms
		7    320     640ms
		8    640    1280ms
		9   1280    2560ms
		10  2560    5120ms
		10  5120   10240ms
		12 10240   20480ms
		13 >>      20480ms
	 */
	def getPercentiles = {monitor ->
	    def ps = [0.5,0.8,0.9,0.95,0.98,0.99]
		def ranges = [];
		monitor.ranges.eachWithIndex() {it, i -> ranges.add(it.value.hits) }	
		def rangesCumulative  = [];	 
		(0..13).each() {i -> rangesCumulative.add (monitor.hits>0?ranges[i]/monitor.hits:0)}
		def percentages= (0..13).collect() {i -> rangesCumulative[1..i].sum()}
		def percentiles = ps.collect{ percentile->percentages.findIndexOf{it>=percentile}}
	   return percentiles
    }
	percentileserrors = [];
	monitors.each {
		percentiles = getPercentiles(it)
		println percentiles.join('\t') + "\t"+it.label
		if (percentiles[2]>8) {
			percentileserrors.add(it.label)
		}		
	}	

	return percentileserrors>0;
}
checkAllUrl (jamonurls,jamonCheck)
