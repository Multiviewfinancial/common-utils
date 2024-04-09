<#
    This script find deployment oracle DB services and retrieve the version information,
    and write to AWS inventory.
    The following information will be collected:
    1. Client ID
    2. Client Name
    3. MV Application version
    4. DB instance name, usually it is MV and MVT
    5. Oracle binary version
    This script requires AWS.Tools module.
#>
<# Get MV values#>
function Get-MvValue {
    <#
    .Synopsis
        Get all MV application informations, including client id, name, app version and oracle version.
    .DESCRIPTION
        This function returns the dict data which contains the application info.
    .EXAMPLE
        Get-MvValue -DbName $db
    #>
    param (
        # Database service name.
        [Parameter(Mandatory)]
        [string]$DbName
    )
    $env:oracle_sid = "$db"
    $QueryApp = "set markup csv on`nselect DB_VERSION,CLIENT_ID,CLIENT_NAME from application_version;`nExit"
    $v = $QueryApp | sqlplus -silent sys/$oraclerootpass as sysdba | Select-Object -Index 2
    $AppVer,$ClientId,$ClientName = $v.split(",")
    #Write-Output "$DbName[app-ver: $AppVer, client-id: $ClientId,client-name: $ClientName]"
    $OraV = "set markup csv on`nselect banner_full from v`$version;`nExit"
    $OracleVersion = $OraV | sqlplus -silent sys/$oraclerootpass as sysdba | Select-Object -Index 2,3
    #Write-Output "$DbName[oracle version: $OracleVersion]"
    
    # Write inventory items
    $data = New-Object "System.Collections.Generic.Dictionary[System.String,System.String]"
    $data.Add("DbName", $DbName.Replace("`"",""))
    $data.Add("ApplicationVersion", $AppVer.Replace("`"",""))
    $data.Add("ClientID", [string]$ClientId)
    $data.Add("ClientName", $ClientName.Replace("`"",""))
    $data.Add("OracleVersion", $OracleVersion.Replace("`"",""))
    return $data
}
    
$databases = (Get-Service Oracleservice*) -replace ("Oracleservice", "")
try {
    $oraclerootpass = (Get-SSMParameter -Name /prod/multiview/core/oracle_root_password -WithDecryption $true).Value
}
catch {
    Write-Output "Could not get Oracle root password from SSM Parameter Store." 
    Write-Output "$_.Exception.Message"
    exit 1
}


$mid = Get-EC2InstanceMetadata -Category InstanceId
$mnow = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
$env:oracle_sid = "MV"
$GetClientName = "select CLIENT_NAME from application_version;" | sqlplus -silent sys/$oraclerootpass as sysdba
$ClientName = $GetClientName | ConvertFrom-Csv
Write-Output "Client: " $ClientName.CLIENT_NAME
$items = New-Object "System.Collections.Generic.List[System.Collections.Generic.Dictionary[System.String, System.String]]"
foreach ($db in $databases) {
    $d = Get-MvValue -DbName $db
    $items.Add($d)
}

if ($items.count -gt 0) {
    # Write to AWS inventory
    $customInventoryItem = New-Object Amazon.SimpleSystemsManagement.Model.InventoryItem
    $customInventoryItem.CaptureTime = $mnow
    $customInventoryItem.Content = $items
    $customInventoryItem.TypeName = "Custom:Multiview"
    $customInventoryItem.SchemaVersion = "1.0"
    $inventoryItems = @($customInventoryItem)

    Write-SSMInventory -InstanceId $mid -Item $inventoryItems
    Write-Output "Update inventory for $mid, done."
} else {
    Write-Output "No Multiview application deployment found!"
}
exit 0