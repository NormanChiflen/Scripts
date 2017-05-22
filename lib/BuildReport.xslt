<?xml version="1.0"?>

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

	<xsl:template match="/">
		<html>
			<head>
				<title>CCT Release Engineering - Build Install Report</title>
					<style type="text/css">
					td { font-size:small;}
					#information {
						display: block;
					}
					#warn {
						display: block;
					} 
					#error {
						display: block;
					}
				</style>

			<!-- <script type="text/javascript" src="C:\Users\mcraig\Desktop\ps_xslt\javascript.js"></script> -->
			
			
			</head>
			<body>
			<script type="text/javascript">
			<![CDATA[
				function getElementsByClassName(classname, node) {
					if (!node) { node = document.getElementsByTagName("body")[0]; }
					var a = [];
					var re = new RegExp('\\b' + classname + '\\b');
					var els = node.getElementsByTagName("*");
					var i = 0;
					var j = els.length;
					for (i; i < j; i++) {
						if (re.test(els[i].className)) { a.push(els[i]); }
					}
					return a;
				}
					
				function showhide(classname){
					var elements = new Array();
					elements = getElementsByClassName(classname);
					for(i in elements){
						 if (elements[i].style.display == 'block') { 
						 elements[i].style.display = 'none';
						 }else{
						 elements[i].style.display = 'block';
						 }
					}
				}			
			]]> 
			</script>
				<h2>CCT Release Engineering - Build Install Report</h2>
				<h3>Server: <xsl:value-of select="BuildInstall/@ServerName"/></h3>
				<p>
				Installed By <xsl:value-of select="BuildInstall/@InstalledBy"/><br />
				Build Label <xsl:value-of select="BuildInstall/@BuildLabel"/><br />
				Start Time <xsl:value-of select="BuildInstall/@StartTime"/><br />
				End Time <xsl:value-of select="BuildInstall/@StopTime"/><br />
				</p>
				Log Summary
				<ul>
						<li>Total Log Entries: <xsl:value-of select="count(//entry)" /></li>
						<ul>
						<li><a href="#" onclick="javascript:showhide('information')">info:</a>	<xsl:value-of select="count(//entry[@type='info'])" /></li>
						<li><a href="#" onclick="javascript:showhide('warn')">Warn:</a><xsl:value-of select="count(//entry[@type='warn'])" /></li>
						<li><a href="#" onclick="javascript:showhide('error')">Error:</a>	<xsl:value-of select="count(//entry[@type='error'])" /></li>
						</ul>
				</ul>
			
				<table border="1" cellpadding="2" cellspacing="0" width="100%">
					<tr bgcolor="grey" id="header">
						<td  >Time</td>
						<td >Message Type</td>
						<td >Message</td>
					</tr>
						<xsl:for-each select="/BuildInstall/InstallLog/entry">
							<xsl:choose>
								<xsl:when test="@type='info'">
								<tr bgcolor="lightgrey" class="information">
									<td  style="white-space:nowrap;">
												<xsl:apply-templates select="@time"/>
									</td>
									<td  >
											<xsl:apply-templates select="@type"/>
									</td>
									<td width="100%" >
										 <pre><xsl:apply-templates select="@message"/></pre>
									</td>
								</tr>
								</xsl:when>
								<xsl:when test="@type='warn'">
								<tr bgcolor="yellow" class="warn">
									<td  >
												<xsl:apply-templates select="@time"/>
									</td>
									<td  >
										<span style="font-color:#green">
											<xsl:apply-templates select="@type"/>
										</span>
									</td>
									<td  >
											<xsl:apply-templates select="@message"/>
									</td>
								</tr>
								</xsl:when>
								<xsl:otherwise>
								<tr bgcolor="red" class="error">
									<td  >
											<span style="font-size:smaller">
												<xsl:apply-templates select="@time"/>
											</span>								
									</td>
									<td  >
											<xsl:apply-templates select="@type"/>
									</td>
									<td  >
											<xsl:apply-templates select="@message"/>
									</td>
								</tr>
								</xsl:otherwise>
							</xsl:choose>			
						</xsl:for-each>
				</table>
			</body>
		</html>
	</xsl:template>

	<xsl:template match="time">

			<xsl:value-of select="time"></xsl:value-of>

	</xsl:template>
	
	<xsl:template match="type">
			<xsl:value-of select="."></xsl:value-of>
	</xsl:template>
	
	<xsl:template match="message">
				<xsl:value-of select="."></xsl:value-of>
	</xsl:template>
</xsl:stylesheet>