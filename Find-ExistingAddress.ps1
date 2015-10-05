$domain_owners = [System.DirectoryServices.ActiveDirectory.Domain]::GetCurrentDomain();
$forest_owners = [System.DirectoryServices.ActiveDirectory.Forest]::GetCurrentForest();

$DC = $domain_owners.PDCRoleOwner.Name;

$strFilter = "(&(objectCategory=User))"

$objDomain = New-Object System.DirectoryServices.DirectoryEntry

$objSearcher = New-Object System.DirectoryServices.DirectorySearcher
$objSearcher.SearchRoot = $objDomain
$objSearcher.PageSize = 1000
$objSearcher.Filter = $strFilter
$objSearcher.SearchScope = "Subtree"

$colProplist = "TargetAddress,Name"
foreach ($i in $colPropList){$objSearcher.PropertiesToLoad.Add($i)}

$colResults = $objSearcher.FindAll()

foreach ($objResult in $colResults)
    {$objItem = $objResult.Properties; $objItem.name}