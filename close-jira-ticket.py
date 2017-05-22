#!/usr/bin/python
https://confluence.atlassian.com/display/FISHKB/Close+JIRA+Issues+when+Fixing+Jobs+in+Perforce
 
import SOAPpy, getpass, datetime, sys
 
soap = SOAPpy.WSDL.Proxy('http://erdinger.sydney.atlassian.com:8080/rpc/soap/jirasoapservice-v2?wsdl')
 
jirauser='admin'
passwd='password'
 
 
auth = soap.login(jirauser, passwd)
 
for arg in sys.argv[1:len(sys.argv)]:
 
        issue = soap.getIssue(auth, arg)
 
        print 'Closing issue..', issue['key']
 
        # the default "fixed" resolution has an id of 1
        # the default close workflow action has an id of 2
        soap.progressWorkflowAction(auth, issue['key'], '2' , [
                {"id": "resolution", "values": "1" }
        ])
 
print "Done!"


closeJira fix-add fix "/Users/amyers/closeIssue.py %jobs%"