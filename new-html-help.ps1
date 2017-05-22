#Import System.Web in order to use HtmlEncode functionality
[System.Reflection.Assembly]::LoadWithPartialName("System.Web") | out-null

function encode($str) {
   [System.web.httputility]::HtmlEncode($str).Trim()
}

function New-HtmlHelp {
   param($commands = $null, $outputDir = "./help", $title = "")

   $commandsHelp = $commands | sort-object name | get-help -full

   #create an output directory
   md $outputDir | Out-Null
   cp doc-style.css $outputDir

   #Generate frame page
   $frameFileName = $outputDir + "/index.html"

   "<html><head><title>$title</title></head><frameset cols=`"20%,80%`"><frame name=`"navigation`" src=`"left-frame.html`"><frame name=`"content`" src=`"right-frame.html`"></frameset></html>" | out-file -encoding ascii $frameFileName

   #Generate index
   $indexFileName = $outputDir + "/left-frame.html"
   $indexData = "<html><head><title></title><link href=`"doc-style.css`" type=`"text/css`" rel=`"StyleSheet`"></head><body>"

   foreach ($c in $commandsHelp) {
      $name = encode($c.Name)
      $indexData += "<a href=`"$name.html`" target=`"content`">$name</a><br>"
   }

   $indexData += "</body></html>"
   $indexData | out-file -encoding ascii $indexFileName

   #Generate all single help files
   $outputText = $null
   foreach ($c in $commandsHelp) {
      $fileName = ( $outputDir + "/" + $c.Name + ".html" )

      $data = "<html><head><title>$(encode($c.Name))</title><link href=`"doc-style.css`" type=`"text/css`" rel=`"StyleSheet`"></head><body>"
   
      # Name
      $data += "<h1>$(encode($c.Name))</h1>"
   
      # Synopsis
      $data += "<h2>Synopsis</h2>$(encode($c.synopsis))"
      
      # Syntax
      $data += "<p class=`"table-title`">Syntax</p>$(encode(&{$c.syntax | out-string -width 2000}))"
   
      # Related Commands
      $data += "<p class=`"table-title`">Related Commands</p>"
      foreach ($relatedLink in $c.relatedLinks.navigationLink) {
         if($relatedLink.linkText -ne $null -and 
            $relatedLink.linkText.StartsWith("about") -eq $false){
            $uri = ""
            if( $relatedLink.uri -ne "" ) {
               $uri = $relatedLink.uri
            } else{
               $uri = $relatedLink.linkText
            }
         
            $data += "<a href='$(encode($uri)).html'>$(encode($relatedLink.linkText))</a><br>"
         }
      }
   
      # Detailed Description
      $data += "<p class=`"table-title`">Detailed Description</p>$(encode(&{$c.Description | out-string -width 2000}))"
   
      # Parameters
      $data += "<p class=`"table-title`">Parameters</p>" +
         "<table cellspacing=`"0`">" +
         "<tr><th>Name</th><th>Description</th><th>Required?</td><th>Pipeline Input</th><th>Default Value</th></tr>"
      $paramNum = 0
      $c.parameters.parameter | %{
         $param = $_
         $data += "<tr class=`"r$(++$paramNum % 2)`"><td><strong>$(encode($param.Name))</strong></td>"
         $data += "<td>$(encode(&{$param.Description | out-string -width 2000}))</td>"
         $data += "<td>$(encode($param.Required))</td><td>$(encode($param.PipelineInput))</td>"
         $data += "<td>$(encode($param.DefaultValue))</td></tr>"
      }
      $data += "</table>"
   
      # Input Type
      $data += "<p class=`"table-title`">Input Type</p>$(encode(&{$c.inputTypes | out-string -width 2000}))"
   
      # Return Type
      $data += "<p class=`"table-title`">Return Type</p>$(encode(&{$c.returnValues | out-string -width 2000}))"
   
      # Notes
      $data += "<p class=`"table-title`">Notes</p><pre>$(encode(&{$c.alertSet | out-string}))</pre>"
   
      # Examples
      $data += "<p class=`"table-title`">Examples</p><pre>$(encode(&{$c.Examples | out-string -width 80}))</pre>"
   
      $data += "</body></html>"
      $data | out-file -encoding ascii $fileName
   }
}
