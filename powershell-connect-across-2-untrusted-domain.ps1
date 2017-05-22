# getting it to function across 2 domains which include a 1 way non transitive trust relationship.
# Domain A) Domain functional level - Server 2003
# Domain B) Domain fucntiona level - Server 2008 
# In this setup Domain A has a 1 way non transitive trust w/ Domain B.



$VMHost = "hypervhost"
$Session = New-PSSession $VMHost -credential ( Get-Credential )

Invoke-Command -Session $Session -ScriptBlock `
    {
    $Env = "environment"
    CD D:\PSt\Scripts\
    . .\hyperv.ps1
    Get-VM $Env*
    }

Remove-PSSession $Session

#http://social.technet.microsoft.com/Forums/en-US/winserverpowershell/thread/5078f77d-4bd2-4ad5-ae43-e8350c6da84c