#!/usr/bin/env python
import urllib2
import re
import sys
 
check_url = 'http://blog.dataloop.io/2013/10/26/notes-from-monitorama-eu/'
html_content = urllib2.urlopen(check_url).read()
 
matches = re.findall('Monitorama', html_content)
if len(matches) == 0:
 print 'Down'
 sys.exit(2)
else:
 print 'Up'
 sys.exit(0)
 
 top 4 lines imported some standard libraries which give you enough to talk to a web page, search the response and set a return code.

Line 7 reads the web page content into the variable html_content so you can imagine that variable containing exactly the same text as what you’d see if you right clicked on the page in a browser and clicked ‘view page source’.

Line 9 searches for the word Monitorama within the page. If it can’t find that word then it’s going to contain ‘0’ which is a number we can check for later on. In our case we know that the word Monitorama appears on the page 10 times so the matches variable is going to contain the number 10.

The final comparison lines (10 downwards) do a quick check against the length of matches and returns the Nagios format output depending on the result. Which in this case is simply some text printed to the screen and a return code.

Here’s the equivalent in Ruby which does exactly the same thing as the Python example:

