#Start the service instances
Start-SPEnterpriseSearchServiceInstance $env:computername
Start-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance $env:computername

#Provide a unique name for the service application
$serviceAppName = "Search Service Application"

#Get the application pools to use (make sure you change the value for your environment)
$svcPool = Get-SPServiceApplicationPool "SharePoint Services App Pool"
$adminPool = Get-SPServiceApplicationPool "SharePoint Services App Pool"

#Get the service from the service instance so we can call a method on it
$searchServiceInstance = Get-SPEnterpriseSearchServiceInstance –Local
$searchService = $searchServiceInstance.Service

#Use reflection to provision the default topology just as the wizard would
$bindings = @("InvokeMethod", "NonPublic", "Instance")
$types = @([string], [Type], [Microsoft.SharePoint.Administration.SPIisWebServiceApplicationPool], [Microsoft.SharePoint.Administration.SPIisWebServiceApplicationPool])
$values = @($serviceAppName, [Microsoft.Office.Server.Search.Administration.SearchServiceApplication], [Microsoft.SharePoint.Administration.SPIisWebServiceApplicationPool]$svcPool, [Microsoft.SharePoint.Administration.SPIisWebServiceApplicationPool]$adminPool)
$methodInfo = $searchService.GetType().GetMethod("CreateApplicationWithDefaultTopology", $bindings, $null, $types, $null)
$searchServiceApp = $methodInfo.Invoke($searchService, $values)

#Create the search service application proxy (we get to use the cmdlet for this!)
$searchProxy = New-SPEnterpriseSearchServiceApplicationProxy -Name "$serviceAppName Proxy" -SearchApplication $searchServiceApp

#Provision the search service application
$searchServiceApp.Provision()