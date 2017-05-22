Something like this? (http://www.sc-orchestrator.eu/index.php/scoblog/64-using-64bit-powershell-cmdlets-in-the-run-net-script-activity-from-orchestrator)

function GetPowershellMode
{
Switch ([System.Runtime.InterOpServices.Marshal]::SizeOf([System.IntPtr]))
{
        4 {$powershellmode="32-bit"}
        8 {$powershellmode="64-bit"}
        default {$powershellmode="unknown"}
}
return $powershellmode
}
$powershellmode=Invoke-Command -ScriptBlock ${function:GetPowershellMode} -computerName localhost