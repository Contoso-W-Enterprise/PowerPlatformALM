<#
Copyright Microsoft Corporation
This Sample Code is provided for the purpose of illustration only and is not intended to be used in a production environment.
THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR PURPOSE. 
We grant You a nonexclusive, royalty-free right to use and modify the Sample Code and to reproduce and distribute the object code form of the Sample Code, provided that You agree:
(i) to not use Our name, logo, or trademarks to market Your software product in which the Sample Code is embedded;
(ii) to include a valid copyright notice on Your software product in which the Sample Code is embedded; and
(iii) to indemnify, hold harmless, and defend Us and Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or result from the use or distribution of the Sample Code.
Please note: None of the conditions outlined in the disclaimer above will supersede the terms and conditions contained within the Premier Customer Services Description.
#>
<#
.SYNOPSIS
This script contains utility functions for Power Platform.

.DESCRIPTION
The PowerPlatform-Utility.ps1 script provides various utility functions that can be used in Power Platform projects.

.NOTES
Author: William Tsoi
Date: 2024-07-16

.LINK
GitHub Repository: [Link to the GitHub repository]

.EXAMPLE
# Example usage of the utility functions
FunctionName -Parameter1 "Value1" -Parameter2 "Value2"

#> 
# Function definitions and other code

# Import the dataverse-webapi-functions module
Import-Module './PowerShell/dataverse-webapi-functions.psm1' -force
###########################
# PAC CLI functions
# Function to install pac cli
function Install-Pac-Cli{
	param(
        [Parameter()] [String]$nugetPackageVersion		
	)
    $nugetPackage = "Microsoft.PowerApps.CLI"
    $outFolder = "pac"
    if($nugetPackageVersion -ne '') {
        nuget install $nugetPackage -Version $nugetPackageVersion -OutputDirectory $outFolder
    }
    else {
        nuget install $nugetPackage -OutputDirectory $outFolder
    }
    $pacNugetFolder = Get-ChildItem $outFolder | Where-Object {$_.Name -match $nugetPackage + "."}
    $pacPath = $pacNugetFolder.FullName + "\tools"
    Write-Host "##vso[task.setvariable variable=pacPath]$pacPath"	
}
<#
This function copies the generated package deployer file (i.e., pdpkg.zip).
Moves the file to ReleaseAssets folder.
#>
function Copy-Pdpkg-File{
    param (
        [Parameter(Mandatory)] [String]$appSourcePackageProjectPath,
        [Parameter(Mandatory)] [String]$packageFileName,
        [Parameter(Mandatory)] [String]$appSourceAssetsPath,
        [Parameter(Mandatory)] [String]$binPath
    )

    Write-Host "pdpkg file found under $appSourcePackageProjectPath\$binPath"
    Write-Host "Copying pdpkg.zip file to $appSourceAssetsPath\$packageFileName"
            
    Get-ChildItem "$appSourcePackageProjectPath\$binPath" -Filter *pdpkg.zip | Copy-Item -Destination "$appSourceAssetsPath\$packageFileName" -Force -PassThru
    # Copy pdpkg.zip file to ReleaseAssets folder
    if(Test-Path "$releaseAssetsDirectory"){
        Write-Host "Copying pdpkg file to Release Assets Directory"
        Get-ChildItem "$appSourcePackageProjectPath\$binPath" -Filter *pdpkg.zip | Copy-Item -Destination "$releaseAssetsDirectory" -Force -PassThru
    }
    else{
        Write-Host "Release Assets Directory is unavailable to copy pdpkg file; Path - $releaseAssetsDirectory"
    }
}
##############################
# Ddataverse web api functions
# description: This function connects to the Dataverse environment using the provided credentials.
# Usage: Connect-Dataverse -tenantID $tenantID -clientId $clientId -clientSecret $clientSecret -dataverseHost $dataverseHost
# parameters:
# - tenantID: The tenant ID of the Dataverse environment.
# - clientId: The client ID of the Dataverse environment.
# - clientSecret: The client secret of the Dataverse environment.
# - dataverseHost: The Dataverse environment host URL.
# - aadHost: The Azure Active Directory host URL. Default is 'login.microsoftonline.com'.
# returns: The token for the Dataverse environment.

function Connect-Dataverse
{
    param (
        [Parameter(Mandatory)] [String]$tenantID,
        [Parameter(Mandatory)] [String]$clientId,
        [Parameter(Mandatory)] [String]$clientSecret,
        [Parameter(Mandatory)] [String]$dataverseHost,
        [String]$aadHost = "https://login.microsoft.com"
    )
    Write-Verbose "Connecting to Dataverse..."
    Write-verbose "dataverseHost: $dataverseHost"
    Write-verbose "aadHost: $aadHost"
    $token = Get-SpnToken $tenantID $clientId $clientSecret $dataverseHost $aadHost
    return $token
}
<# 
description: This function retrieves the solutions from the Dataverse environment.
#>
function get-DataverseEntities
{
    param (
        [Parameter(Mandatory)] [String]$token,
        [Parameter(Mandatory)] [String]$dataverseHost
    )
    $response = Invoke-DataverseHttpGet -token $token -dataverseHost $dataverseHost -requestUrlRemainder ''
    return $response.value
}
<#
description: This function retrieves the solutions from the Dataverse environment.
#>
function get-DataverseEntityItems {
    param (
        [Parameter(Mandatory)] [String]$token,
        [Parameter(Mandatory)] [String]$dataverseHost,
        [Parameter(Mandatory)] [String]$entityName,
        [String]$select,
        [String]$filter,
        [String]$expand,
        [String]$orderby,
        [String]$top,
        [String]$skip
    )
    $querystring = $entityName + '?'
    if ($select -ne '') {
        $querystring += '$select=' + [uri]::EscapeDataString($select) + '&'
    }
    if ($filter -ne '') {
        $querystring += '$filter=' + [uri]::EscapeDataString($filter) + '&'
    }
    if ($expand -ne '') {
        $querystring += '$expand=' + [uri]::EscapeDataString($expand) + '&'
    }
    if ($orderby -ne '') {
        $querystring += '$orderby=' + [uri]::EscapeDataString($orderby) + '&'
    }
    if ($top -ne '') {
        $querystring += '$top=' + [uri]::EscapeDataString($top) + '&'
    }
    if ($skip -ne '') {
        $querystring += '$skip=' + [uri]::EscapeDataString($skip) + '&'
    }
    $querystring = $querystring.TrimEnd('&')
    $querystring = $querystring.TrimEnd('%26')
    $querystring = $querystring.TrimEnd('?')
    write-Verbose $querystring
    $response = Invoke-DataverseHttpGet -token $token -dataverseHost $dataverseHost -requestUrlRemainder $querystring
    return $response.value
}
<#
description: This function retrieves a specific item from the Dataverse environment.
#>
function get-DataverseEntityItem
{
    param (
        [Parameter(Mandatory)] [String]$token,
        [Parameter(Mandatory)] [String]$dataverseHost,
        [Parameter(Mandatory)] [String]$entityName,
        [Parameter(Mandatory)] [String]$itemId,
        [String]$select,
        [String]$expand
    )
    $querystring = $entityName + "($itemId)?"
    if ('' -ne $select) {
        $querystring += '$select=' + [uri]::EscapeDataString($select) + '&'
    }
    if ('' -ne $expand) {
        $querystring += '$expand=' + [uri]::EscapeDataString($expand) + '&'
    }
    $querystring = $querystring.TrimEnd('&')
    write-verbose $querystring
    $response = Invoke-DataverseHttpGet -token $token -dataverseHost $dataverseHost -requestUrlRemainder $querystring
    return $response
}
<#
description: This function retrieves the metadata for a specific entity from the Dataverse environment.
#>
function get-DataverseEntityMetadata
{
    param (
        [Parameter(Mandatory)] [String]$token,
        [Parameter(Mandatory)] [String]$dataverseHost,
        [Parameter(Mandatory)] [String]$entityName
    )
    $response = Invoke-DataverseHttpGet -token $token -dataverseHost $dataverseHost -requestUrlRemainder "`$metadata#$entityName"
    return $response.value
}
function get-DataverseEntityDefinitions
{
    param (
        [Parameter(Mandatory)] [String]$token,
        [Parameter(Mandatory)] [String]$dataverseHost,
        [String]$entityName,
        [String]$metadataId,
        [String]$select

    )

    if ('' -ne $entityName) {
        $filterString = "LogicalCollectionName eq '$entityName'"
        $response = Get-DataverseEntityItems -token $token -dataverseHost $dataverseHost -entityName 'EntityDefinitions' -filter $filterString -select $select
    }
    if ('' -ne $metadataId) {        
        $querystring = "EntityDefinitions($metadataId)" + '?'
        $response = Get-DataverseEntityItem -token $token -dataverseHost $dataverseHost -entityName 'EntityDefinitions' -itemId $metadataId -select $select
    }
    if ($null -ne $response.value) {
        return $response.value
    }
    return $response
}
<#
description: This function retrieves the attributes definitions for a specific entity from the Dataverse environment.
#>
function get-DataverseEntityAttributesDefinitions
{
    param (
        [Parameter(Mandatory)] [String]$token,
        [Parameter(Mandatory)] [String]$dataverseHost,
        [Parameter(Mandatory)] [String]$entityName
    )
    $querystring = "EntityDefinitions(LogicalName='$entityName')/Attributes"
    $response = Get-DataverseEntityItems -token $token -dataverseHost $dataverseHost -entityName $querystring
    return $response
}
<#
description: This function retrieves the attributes definitions for a specific entity from the Dataverse environment.
#>
function get-DataverseEntityAttributeDefinition
{
    param (
        [Parameter(Mandatory)] [String]$token,
        [Parameter(Mandatory)] [String]$dataverseHost,
        [Parameter(Mandatory)] [String]$entityName,
        [Parameter(Mandatory)] [String]$attributeName
    )
    $response = Get-DataverseEntityItems -token $token -dataverseHost $dataverseHost -entityName "EntityDefinitions(LogicalName='$entityName')/Attributes" -filter "LogicalName='$attributeName" -select $select
    return $response
}

# description: This function retrieves the settings for a specific entity from the Dataverse environment.
# Usage: get-DataverseEntitySettings -token $token -dataverseHost $dataverseHost -entityName $entityName
# parameters:
# - token: The token for the Dataverse environment.
# - dataverseHost: The Dataverse environment host URL.
# - entityName: The name of the entity to retrieve settings for.
# returns: The settings for the specific entity from the Dataverse environment.
function get-DataverseEntitySettings
{
    param (
        [Parameter(Mandatory)] [String]$token,
        [Parameter(Mandatory)] [String]$dataverseHost,
        [Parameter(Mandatory)] [String]$entityName
    )
    $response = Invoke-DataverseHttpGet -token $token -dataverseHost $dataverseHost -requestUrlRemainder "EntityDefinitions(LogicalName='$entityName')"
    return $response

}
# description: This function retrieves the solutions from the Dataverse environment.
# Usage: Get-DataverseSolutions -token $token -dataverseHost $dataverseHost
# parameters:
# - token: The token for the Dataverse environment.
# - dataverseHost: The Dataverse environment host URL.
# returns: The solutions from the Dataverse environment.

function Get-DataverseSolutions
{
    param (
        [Parameter(Mandatory)] [String]$token,
        [Parameter(Mandatory)] [String]$dataverseHost,
        [String]$isManaged,
        [String]$select = 'solutionid,uniquename,friendlyname,description,version,ismanaged,modifiedon,createdon',
        [String]$expand = 'publisherid($select=publisherid,customizationprefix,description,friendlyname),modifiedby($select=systemuserid,fullname,domainname),createdby($select=systemuserid,fullname,domainname)',
        [String]$filter,
        [String]$orderby,
        [String]$top,
        [String]$skip
    )
    if ($isManaged -ne '') {
        if ($filter -ne '') {
            $filter = $filter + " & ismanaged eq $($isManaged.toLower())"
        }
        else {
            $filter = "ismanaged eq $($isManaged.toLower()) "
        }
    }

    $response = Get-DataverseEntityItems -token $token -dataverseHost $dataverseHost -entityName 'solutions' -select $select -filter $filter -orderby $orderby -top $top -skip $skip -expand $expand
    return $response
}
# description: This function retrieves a specific solution from the Dataverse environment.
# Usage: Get-DataverseSolution -token $token -dataverseHost $dataverseHost -solutionUniqueName $solutionUniqueName
# parameters:
# - token: The token for the Dataverse environment.
# - dataverseHost: The Dataverse environment host URL.
# - solutionUniqueName: The unique name of the solution to retrieve.
# returns: The specific solution from the Dataverse environment.

function Get-DataverseSolution
{
    param (
        [Parameter(Mandatory)] [String]$token,
        [Parameter(Mandatory)] [String]$dataverseHost,
        [Parameter(Mandatory)] [String]$solutionUniqueName,
        [String]$select ='solutionid,uniquename,friendlyname,description,version,ismanaged,modifiedon,createdon',
        [String]$expand = 'publisherid($select=publisherid,customizationprefix,description,friendlyname),modifiedby($select=systemuserid,fullname,domainname),createdby($select=systemuserid,fullname,domainname)'
    )
    $response = Get-DataverseEntityItems -token $token -dataverseHost $dataverseHost -entityName 'solutions' -filter ("uniquename eq '$solutionUniqueName'") -select $select -expand $expand
    return $response
}
# description: This function retrieves the solution components from the Dataverse environment.
# Usage: Get-DataverseSolutionComponents -token $token -dataverseHost $dataverseHost -solutionId $solutionId -componentType $componentType
# parameters:
# - token: The token for the Dataverse environment.
# - dataverseHost: The Dataverse environment host URL.
# - solutionId: The ID of the solution to retrieve components for.
# - componentType: The type of component to retrieve. Default is ''.
# returns: The solution components from the Dataverse environment.
# https://learn.microsoft.com/en-us/power-apps/developer/data-platform/webapi/reference/solutioncomponent?view=dataverse-latest

function Get-DataverseSolutionComponents
{
    param (
        [Parameter(Mandatory)] [String]$token,
        [Parameter(Mandatory)] [String]$dataverseHost,
        [Parameter(Mandatory)] [String]$solutionId,
        [String]$componentTypeId
    )
    $results = @()
    if($componentTypeId)
    {
        $response = Get-DataverseEntityItems -token $token -dataverseHost $dataverseHost -entityName 'solutioncomponents' -filter ("_solutionid_value eq '$solutionId' & componenttype eq $componentType")
        #$response = Invoke-DataverseHttpGet -token $token -dataverseHost $dataverseHost -requestUrlRemainder ('solutioncomponents?$filter=_solutionid_value%20eq%20%27' + $solutionId + '%27&componenttype%20eq%20' + $componentType)
    }
    else
    {
        $response = Get-DataverseEntityItems -token $token -dataverseHost $dataverseHost -entityName 'solutioncomponents' -filter ("_solutionid_value eq '$solutionId'")
        #$response = Invoke-DataverseHttpGet -token $token -dataverseHost $dataverseHost -requestUrlRemainder ('solutioncomponents?$filter=_solutionid_value%20eq%20%27' + $solutionId + '%27')
    }

    foreach ($component in $response)
    {
        $componentType = (Get-SolutionComponentType -componenttype $component.componenttype)

        if ($null -ne $componentType.Entity ) {
            if ($componentType.Entity -eq '/')
            {
                $item = get-DataverseEntityDefinitions -token $token -dataverseHost $dataverseHost -metadataId $component.objectid -select 'LogicalName,SchemaName,EntitySetName,PrimaryIdAttribute,PrimaryImageAttribute'
            }
            else {
                $entityColumns = get-DataverseEntityDefinitions -token $token -dataverseHost $dataverseHost -entityName $componentType.Entity -select 'PrimaryIdAttribute,PrimaryNameAttribute'
                $item = get-DataverseEntityItem -token $token -dataverseHost $dataverseHost -entityName ($componentType.Entity) -itemId ($component.objectid) -select ($entityColumns.PrimaryIdAttribute + ',' + $entityColumns.PrimaryNameAttribute)
            }  
        }
        else {
            $item = $null
        }
        $createdBy = get-DataverseUser -token $token -dataverseHost $dataverseHost -userid $component._createdby_value
        $modifiedBy = get-DataverseUser -token $token -dataverseHost $dataverseHost -userid $component._modifiedby_value

         #get-DataverseEntityItem -token $token -dataverseHost $dataverseHost -entityName 'systemusers' -itemId ($component._createdby_value) -select 'systemuserid,fullname,organizationid,domainname'
        #$modifiedBy = get-DataverseEntityItem -token $token -dataverseHost $dataverseHost -entityName 'systemusers' -itemId ($component._modifiedby_value) -select 'systemuserid,fullname,organizationid,domainname'
        $results += [PSCustomObject]@{
            componentTypeName = $componentType.Label
            componentType = $component.componenttype
            id = $component.objectid
            componentId = $component.solutioncomponentid
            component = $item
            createdBy = $createdBy
            modifiedBy = $modifiedBy
        }
    }
    return $results
}
function get-DataverseSolutionJSON
{
    param (
        [Parameter(Mandatory)] [String]$token,
        [Parameter(Mandatory)] [String]$dataverseHost,
        [Parameter(Mandatory)] [String]$solutionName
    )
    $solution = Get-DataverseSolution -token $token -dataverseHost $dataverseHost -solutionUniqueName $solutionName
    $solutionComponents = Get-DataverseSolutionComponents -token $token -dataverseHost $dataverseHost -solutionId $solution.solutionid
    $solutionJSON = [PSCustomObject]@{
        solution = $solution
        components = $solutionComponents
    } | Convertto-json -depth 10
    return $solutionJSON
}
# description: This function retrieves the Dataverse environment profile.
# Usage: get-DataverseWhoAmI -token $token -dataverseHost $dataverseHost
# parameters:
# - token: The token for the Dataverse environment.
# - dataverseHost: The Dataverse environment host URL.
# returns: The Dataverse environment profile.

function get-DataverseWhoAmI
{
    param (
        [Parameter(Mandatory)] [String]$token,
        [Parameter(Mandatory)] [String]$dataverseHost
    )
    $response = Invoke-DataverseHttpGet -token $token -dataverseHost $dataverseHost -requestUrlRemainder 'WhoAmI'
    return $response
}
# description: This function retrieves the audit logs settings from the Dataverse environment.
# Usage: get-DataverseAuditLogsSettings -token $token -dataverseHost $dataverseHost
# parameters:
# - token: The token for the Dataverse environment.
# - dataverseHost: The Dataverse environment host URL.
# returns: The audit logs settings from the Dataverse environment.

function get-DataverseAuditLogsSettings
{
    param (
        [Parameter(Mandatory)] [String]$token,
        [Parameter(Mandatory)] [String]$dataverseHost
    )
    $organizationId = get-DataverseOrganizationId -token $token -dataverseHost $dataverseHost
    $response = Get-DataverseEntityItem -token $token -dataverseHost $dataverseHost -entityName 'organizations' -itemId $organizationId -select 'allowentityonlyaudit,isauditenabled,isuseraccessauditenabled,auditretentionperiod,enableipbasedfirewallruleinauditmode,useraccessauditinginterval,auditretentionperiodv2,isreadauditenabled'
    return $response
}
# description: This function sets the audit logs settings for the Dataverse environment.
# Usage: set-DataverseAuditLogsSettings -token $token -dataverseHost $dataverseHost -isAuditEnabled $isAuditEnabled -isuserAccessAuditEnabled $isuserAccessAuditEnabled -AuditRetentionPeriodV2 $AuditRetentionPeriodV2
# parameters:
# - token: The token for the Dataverse environment.
# - dataverseHost: The Dataverse environment host URL.
# - isAuditEnabled: A boolean value to indicate whether audit logs are enabled.
# - isuserAccessAuditEnabled: A boolean value to indicate whether user access audit is enabled.
# - AuditRetentionPeriodV2: The audit retention period. Default is 30.
# returns: The response from the Dataverse environment.
function set-DataverseAuditLogsSettings
{
    param (
        [Parameter(Mandatory)] [String]$token,
        [Parameter(Mandatory)] [String]$dataverseHost,
        [Parameter(Mandatory)] [boolean]$isAuditEnabled,
        [boolean]$isuserAccessAuditEnabled,
        [int]$AuditRetentionPeriodV2 = 30
    )
    $auditParams = (@{
        "isauditenabled" = $isAuditEnabled;
        "auditretentionperiodv2" = $AuditRetentionPeriodV2;
        "isuseraccessauditenabled" = $isuserAccessAuditEnabled;
    }) | convertto-json -depth 3
    $organizationId = get-DataverseOrganizationId -token $token -dataverseHost $dataverseHost
    $response = Invoke-DataverseHttpPatch -token $token -dataverseHost $dataverseHost -requestUrlRemainder "organizations($organizationId)"  -body $auditParams
    return $response
}
# description: This function retrieves the RPA settings from the Dataverse environment.
# Usage: get-DataverseRPASettings -token $token -dataverseHost $dataverseHost
# parameters:
# - token: The token for the Dataverse environment.
# - dataverseHost: The Dataverse environment host URL.
# returns: The RPA settings from the Dataverse environment.

function get-DataverseRPASettings{
    param (
        [Parameter(Mandatory)] [String]$token,
        [Parameter(Mandatory)] [String]$dataverseHost
    )
    $organizationId = get-DataverseOrganizationId -token $token -dataverseHost $dataverseHost
    $response = get-DataverseEntityItem -token $token -dataverseHost $dataverseHost -entityName 'organizations' -itemId $organizationId -select 'isrpaautoscaleaadjoinenabled,isrpaautoscaleenabled,isrpaunattendedenabled,isrpaboxcrossgeoenabled,isrpaboxenabled'
    return $response
}
# description: This function sets the RPA settings for the Dataverse environment.
# Usage: set-DataverseRPASettings -token $token -dataverseHost $dataverseHost -isrpaautoscaleaadjoinenabled $isrpaautoscaleaadjoinenabled -isrpaautoscaleenabled $isrpaautoscaleenabled -isrpaunattendedenabled $isrpaunattendedenabled -isrpaboxcrossgeoenabled $isrpaboxcrossgeoenabled -isrpaboxenabled $isrpaboxenabled
# parameters:
# - token: The token for the Dataverse environment.
# - dataverseHost: The Dataverse environment host URL.
# - isrpaautoscaleaadjoinenabled: A boolean value to indicate whether RPA autoscale AAD join is enabled.
# - isrpaautoscaleenabled: A boolean value to indicate whether RPA autoscale is enabled.
# - isrpaunattendedenabled: A boolean value to indicate whether RPA unattended is enabled.
# - isrpaboxcrossgeoenabled: A boolean value to indicate whether RPA box cross geo is enabled.
# - isrpaboxenabled: A boolean value to indicate whether RPA box is enabled.
# returns: The response from the Dataverse environment.

function set-DataverseRPASettings {
    param (
        [Parameter(Mandatory)] [String]$token,
        [Parameter(Mandatory)] [String]$dataverseHost,
        [Parameter(Mandatory)] [boolean]$isrpaautoscaleaadjoinenabled,
        [Parameter(Mandatory)] [boolean]$isrpaautoscaleenabled,
        [Parameter(Mandatory)] [boolean]$isrpaunattendedenabled,
        [Parameter(Mandatory)] [boolean]$isrpaboxcrossgeoenabled,
        [Parameter(Mandatory)] [boolean]$isrpaboxenabled
    )
    $organizationId = get-DataverseOrganizationId -token $token -dataverseHost $dataverseHost
    $rpaParams = @{  
        "isrpaautoscaleaadjoinenabled" = $isrpaautoscaleaadjoinenabled 
        "isrpaautoscaleenabled" = $isrpaautoscaleenabled;
        "isrpaunattendedenabled" = $isrpaunattendedenabled;
        "isrpaboxcrossgeoenabled" = $isrpaboxcrossgeoenabled;
        "isrpaboxenabled" = $isrpaboxenabled
    } | convertto-json -depth 3
    $response = Invoke-DataverseHttpPatch -token $token -dataverseHost $dataverseHost -requestUrlRemainder "organizations($organizationId)" -body $rpaParams 
    return $response
}

# description: This function retrieves the audit logs for a specific entity from the Dataverse environment.
# Usage: get-DataverseAuditLogs -token $token -dataverseHost $dataverseHost -entityName $entityName -operation $operation
# parameters:
# - token: The token for the Dataverse environment.
# - dataverseHost: The Dataverse environment host URL.
# - entityName: The name of the entity to retrieve audit logs for.
# - operation: The operation type for the audit logs. Default is ''.
# returns: The audit logs for the specific entity from the Dataverse environment.

function set-DataverseEntityAuditLogSetting
{
    param (
        [Parameter(Mandatory)] [String]$token,
        [Parameter(Mandatory)] [String]$dataverseHost,
        [Parameter(Mandatory)] [String]$entityName,
        [Parameter(Mandatory)] [boolean]$IsRetrieveAuditEnabled,
        [Parameter(Mandatory)] [boolean]$IsRetrieveMultipleAuditEnabled,
        [Parameter(Mandatory)] [boolean]$isAuditEnabled,
        [Parameter(Mandatory)] [boolean]$CanBeChanged,
        [Parameter(Mandatory)] [boolean]$ManagedPropertyLogicalName="canmodifyauditsettings"
    )
    $auditParams = @{}
    $auditParams.Add("IsRetrieveAuditEnabled", $IsRetrieveAuditEnabled)
    $auditParams.Add("IsRetrieveMultipleAuditEnabled", $IsRetrieveMultipleAuditEnabled)
    $auditParams.Add("IsAuditEnabled", @{"Value"=$isAuditEnabled;"CanBeChanged"=$CanBeChanged;"ManagedPropertyLogicalName"=$ManagedPropertyLogicalName})
    $response = Invoke-DataverseHttpPost -token $token -dataverseHost $dataverseHost -requestUrlRemainder "EntityDefinitions(LogicalName='$entityName')" -body $auditParams
    return $response
}

# description: This function retrieves the audit logs for a specific entity from the Dataverse environment.
# Usage: get-DataverseAuditLogs -token $token -dataverseHost $dataverseHost -entityName $entityName -operation $operation
# parameters:
# - token: The token for the Dataverse environment.
# - dataverseHost: The Dataverse environment host URL.
# - entityName: The name of the entity to retrieve audit logs for.
# - operation: The operation type for the audit logs. Default is ''.
# returns: The audit logs for the specific entity from the Dataverse environment.
function get-DataverseAuditLogs
{
    param (
        [Parameter(Mandatory)] [String]$token,
        [Parameter(Mandatory)] [String]$dataverseHost,
        [Parameter(Mandatory)] [String]$entityName,
        [String]$operation,
        [String]$select,
        [String]$top
    )
    # operation types
    # 1 = Create
    # 2 = Update
    # 3 = Delete
    # 4 = Access

    if ($operation -ne ''){
        $filterstring = 'objecttypecode eq ''' + $entityName + ''' and operation eq ' + $operation
    } else {
        $filterstring = 'objecttypecode eq ''' + $entityName + ''''
    }
    $response = Get-DataverseEntityItems -token $token -dataverseHost $dataverseHost -entityName 'audits' -filter $filterstring -select $select -top $top
    return $response 
}<#
description: This function retrieves the organization ID from the Dataverse environment.
#>
function get-DataverseOrganizationId {
    param (
        [Parameter(Mandatory)] [String]$token,
        [Parameter(Mandatory)] [String]$dataverseHost
    )
    $response = get-DataverseEntityItems -token $token -dataverseHost $dataverseHost -entityName 'organizations' -select 'organizationid' -top 1
    return $response.organizationid
}
<# Following scripts are from PowerCAT team (ALM Accelerator)
#>
<#
Sometimes GUID contains underscore (incase of multiple share with teams scenario).
This function trims and validates the GUID.
#>
function Invoke-Validate-And-Clean-Guid {
    param (
        [string]$inputGuid
    )

    try {
        # Use a regular expression to match the GUID pattern
        if ($inputGuid -match '^([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})') {
            return $Matches[1]
        } else {
            Write-Host "Invalid GUID format: $inputGuid"
            return $null
        }
    } catch {
        Write-Host "An error occurred during GUID validation: $_"
        return $null
    }
}
<#
This function grants read access to team to the workflow.
Testable outside of agent
#>
function Grant-DataverseAccessToWorkflow {
    param (
        [Parameter()] [String]$token,
        [Parameter(Mandatory)] [String]$dataverseHost,
        [Parameter(Mandatory)] [String]$teamName,
        [Parameter(Mandatory)] [String]$workflowId
    )

    Write-Host "teamName - $teamName"
    Write-Host "workflowId - $workflowId"
    $validatedId = Invoke-Validate-And-Clean-Guid $workflowId
    if (!$validatedId) {
        Write-Host "Invalid  workflowId GUID. Exiting from Grant-AccessToWorkflow."
        return
    }
    $teamId = Get-DataverseTeamId $token $dataverseHost $teamName
    Write-Host "teamId - $teamId"
    if($teamId -ne '') {
        # $body = "{
        # `n    `"Target`":{
        # `n        `"workflowid`":`"$validatedId`",
        # `n        `"@odata.type`": `"Microsoft.Dynamics.CRM.workflow`"
        # `n    },
        # `n    `"PrincipalAccess`":{
        # `n        `"Principal`":{
        # `n            `"teamid`": `"$teamId`",
        # `n            `"@odata.type`": `"Microsoft.Dynamics.CRM.team`"
        # `n        },
        # `n        `"AccessMask`": `"ReadAccess`"
        # `n    }
        # `n}"
        $body = @{
            Target = @{
                workflowid = $validatedId
                "@odata.type" = "Microsoft.Dynamics.CRM.workflow"
            }
            PrincipalAccess = @{
                Principal = @{
                    teamid = $teamId
                    "@odata.type" = "Microsoft.Dynamics.CRM.team"
                }
                AccessMask = "ReadAccess"
            }
        } | ConvertTo-Json -Depth 3
    
        $requestUrlRemainder = "GrantAccess"
        Invoke-DataverseHttpPost $token $dataverseHost $requestUrlRemainder $body
    }
}

<#
This function grants read access to team to the connector.
#>
function Grant-DataverseAccessToConnector {
    param (
        [Parameter()] [String]$token,
        [Parameter(Mandatory)] [String]$dataverseHost,
        [Parameter(Mandatory)] [String]$teamName,
        [Parameter(Mandatory)] [String]$connectorId
    )
        #Load util function
    . "$env:POWERSHELLPATH/util.ps1"

    Write-Host "TeamName - $teamName"
    Write-Host "ConnectorId - $connectorId"   
    $validatedId = Invoke-Validate-And-Clean-Guid $connectorId
    if (!$validatedId) {
        Write-Host "Invalid  ConnectorId GUID. Exiting from Grant-AccessToConnector."
        return
    }

    $teamId = Get-DataverseTeamId $token $dataverseHost $teamName
    if($teamId -ne '') {
        # $body = "{
        # `n    `"Target`":{
        # `n        `"connectorid`":`"$validatedId`",
        # `n        `"@odata.type`": `"Microsoft.Dynamics.CRM.connector`"
        # `n    },
        # `n    `"PrincipalAccess`":{
        # `n        `"Principal`":{
        # `n            `"teamid`": `"$teamId`",
        # `n            `"@odata.type`": `"Microsoft.Dynamics.CRM.team`"
        # `n        },
        # `n        `"AccessMask`": `"ReadAccess`"
        # `n    }
        # `n}"
        $body = @{ 
            Target = @{
                connectorid = $validatedId
                "@odata.type" = "Microsoft.Dynamics.CRM.connector"
            }
            PrincipalAccess = @{
                Principal = @{
                    teamid = $teamId
                    "@odata.type" = "Microsoft.Dynamics.CRM.team"
                }
                AccessMask = "ReadAccess"
            }
        } | ConvertTo-Json -Depth 3

        $requestUrlRemainder = "GrantAccess"        
        Invoke-DataverseHttpPost $token $dataverseHost $requestUrlRemainder $body
    }
}

<#
This function fetches the team guid from the team name.
#>
function Get-DataverseTeamId {
    param (
        [Parameter(Mandatory)] [String]$token,
        [Parameter(Mandatory)] [String]$dataverseHost,
        [Parameter(Mandatory)] [String]$teamName
    )
    $teamId = ''
    $odataQuery = 'teams?$filter=name eq ' + "'$teamName'" + '&$select=teamid'
    $response = Get-DataverseEntityItems -token $token -dataverseHost $dataverseHost -entityName 'teams' -itemId $teamName -select 'teamid'
    #$response = Invoke-DataverseHttpGet $token $dataverseHost $odataQuery
    if($response.value.length -gt 0) {
        $teamId = $response.value[0].teamid
    }
    return $teamId
}
function Get-DataverseUsers
{
    param (
        [Parameter(Mandatory)] [String]$token,
        [Parameter(Mandatory)] [String]$dataverseHost,
        [String]$select = 'domainname,systemuserid',
        [String]$filter,
        [String]$expand,
        [String]$orderby,
        [String]$top,
        [String]$skip
    )
    $response = Get-DataverseEntityItems -token $token -dataverseHost $dataverseHost -entityName 'systemusers' -select $select -filter $filter -expand $expand -orderby $orderby -top $top -skip $skip
    return $response
} 
function Get-DataverseUser
{
    param (
        [Parameter(Mandatory)] [String]$token,
        [Parameter(Mandatory)] [String]$dataverseHost,
        [string]$userId,
        [String]$select = 'domainname,systemuserid',
        [String]$filter
    )
    if ($userId -ne '') {
        $response = Get-DataverseEntityItem -token $token -dataverseHost $dataverseHost -entityName 'systemusers' -itemId $userId -select $select
    } else {
        $response = Get-DataverseEntityItems -token $token -dataverseHost $dataverseHost -entityName 'systemusers' -filter $filter -select $select
    }
    #$response = Get-DataverseEntityItem -token $token -dataverseHost $dataverseHost -entityName 'systemusers' -select $select -filter $filter
    return $response
}
function get-DataverseWorkflows
{
    param (
        [Parameter(Mandatory)] [String]$token,
        [Parameter(Mandatory)] [String]$dataverseHost,
        [String]$select = 'name,workflowid,modifiedon,solutionid,createdon,ismanaged,versionnumber,description',
        [String]$filter,
        [String]$expand='createdby($select=fullname,systemuserid),modifiedby($select=fullname,systemuserid)',
        [String]$orderby,
        [String]$top,
        [String]$skip
    )
    $response = Get-DataverseEntityItems -token $token -dataverseHost $dataverseHost -entityName 'workflows' -select $select -filter $filter -expand $expand -orderby $orderby -top $top -skip $skip
    return $response.value
}
function get-DataverseWorkflowRuns 
{
    param (
        [Parameter(Mandatory)] [String]$token,
        [Parameter(Mandatory)] [String]$dataverseHost,
        [String]$workflowId,
        [String]$select = 'name,flowrunid,versionnumber,starttime,duration,workflowid,ttlinseconds,isprimary,triggertype,status,endtime,resourceid,errorcode,errormessage,utcconversiontimezonecode',
        [String]$filter,
        [String]$expand,
        [String]$orderby,
        [String]$top,
        [String]$skip
    )
    if ($workflowId -ne '') {
        if($filter -ne '') {
            $filter = $filter + " and workflowid eq $workflowId"
        } else {
            $filter = "workflowid eq $workflowId"
        }
    }

    $response = Get-DataverseEntityItems -token $token -dataverseHost $dataverseHost -entityName 'flowruns' -select $select -filter $filter -expand $expand -orderby $orderby -top $top -skip $skip
    return $response.value
}
##################################
# Git Repository functions 
# description: This function retrieves the version of a solution from the provided folder path.
# Usage: Get-SolutionVersion -solutionName $solutionName -folderPath $folderPath
# parameters:
# - solutionName: The name of the solution.
# - folderPath: The folder path where the solution is located. Default is ''.
# returns: The version of the solution.
function Get-SolutionVersion
{
    param (
        [Parameter(Mandatory)] [String]$solutionName,
        [String]$folderPath = ''
    )
    if ($folderPath -eq '')
    {
        $SolutionFilePath = "src/$solutionName/Other/Solution.xml"
    }
    else {
        $SolutionFilePath = "$folderPath/src/$solutionName/Other/Solution.xml"
    }
    if (Test-Path -LiteralPath $SolutionFilePath ) 
    {
        try{
            [xml]$solutionXml = Get-Content -Path $SolutionFilePath
        }
        catch {
            write-Error $_
            break
        }
        $version = $solutionXml.ImportExportXml.SolutionManifest.Version
        Write-Host "Current solution version: $version"
        return $version
    }
    else {
        write-host "$SolutionFilePath not found"
    }
    return $null
}
# description: This function updates the version of a solution in the provided folder path.
# Usage: Update-SolutionVersion -solutionName $solutionName -folderPath $folderPath -MajorVersionIncrement $MajorVersionIncrement -MinorVersionIncrement $MinorVersionIncrement -ReleaseVersionIncrement $ReleaseVersionIncrement -PatchVersionIncrement $PatchVersionIncrement -updateVersion $updateVersion
# parameters:
# - solutionName: The name of the solution.
# - folderPath: The folder path where the solution is located. Default is ''.
# - MajorVersionIncrement: The increment value for the major version.
# - MinorVersionIncrement: The increment value for the minor version.
# - ReleaseVersionIncrement: The increment value for the release version.
# - PatchVersionIncrement: The increment value for the patch version.
# - updateVersion: A boolean value to indicate whether to update the version in the file. Default is false.
# returns: The new version of the solution.
function Update-SolutionVersion
{
    param (
        [Parameter(Mandatory)] [String]$solutionName,
        [String]$folderPath = '',
        [Int]$MajorVersionIncrement,
        [Int]$MinorVersionIncrement,
        [Int]$ReleaseVersionIncrement,
        [Int]$PatchVersionIncrement,
        [boolean]$updateVersion = $false
    )
    if ($folderPath -eq '')
    {
        $SolutionFilePath = "src/$solutionName/Other/Solution.xml"
    }
    else {
        $SolutionFilePath = "$folderPath/src/$solutionName/Other/Solution.xml"
    }
    if (Test-Path -LiteralPath $SolutionFilePath ) 
    {
        try{
            [xml]$solutionXml = Get-Content -Path $SolutionFilePath
        }
        catch {
            write-Error $_
            break
        }
        $version = $solutionXml.ImportExportXml.SolutionManifest.Version
        Write-Host "Current solution version: $version"
        $setVersion = $version.Split(".")
        $setVersion[0] = [int]$setVersion[0] + $MajorVersionIncrement
        $setVersion[1] = [int]$setVersion[1] + $MinorVersionIncrement
        $setVersion[2] = [int]$setVersion[2] + $ReleaseVersionIncrement
        $setVersion[3] = [int]$setVersion[3] + $PatchVersionIncrement
        $newVersion = $setVersion[0] + "." + $setVersion[1] + "."  + $setVersion[2] + "."  + $setVersion[3]
        write-host "New solution version: $newVersion"
        $solutionXml.ImportExportXml.SolutionManifest.Version = $newVersion
        if ($updateVersion) {
            try {
                $solutionXml.Save($SolutionFilePath)
            }
            catch {
                write-Error $_
                break
            }
            write-host "solution version updated"
        } else {
            write-host "solution version not updated"
        }
        return $newVersion
    }
    else {
        write-host "$SolutionFilePath not found"
    }
    return $null
}
# description: This function clears the current environment variables for a solution.
# Usage: Clear-CurentEnvironmentVariables -solutionName $solutionName -folderPath $folderPath -deleteCurrentValues $deleteCurrentValues
# parameters:
# - solutionName: The name of the solution.
# - folderPath: The folder path where the solution is located. Default is ''.
# - deleteCurrentValues: A boolean value to indicate whether to delete the current values. Default is false.
# returns: A boolean value indicating the success of the operation.
function Clear-CurentEnvironmentVariables
{
    param (
        [Parameter(Mandatory)] [String]$solutionName,
        [String]$folderPath = '',
        [boolean]$deleteCurrentValues = $false
    )
    if ($folderPath -eq '')
    {
        $SolutionFilePath = "src/$solutionName/environmentvariabledefinitions"
    }
    else {
        $SolutionFilePath = "$folderPath/src/$solutionName/environmentvariabledefinitions"
    }
    if (Test-Path -LiteralPath $SolutionFilePath ) 
    {
        try {
            $envars = Get-ChildItem -Path $SolutionFilePath -Directory
        }
        catch {
            write-Error $_
            break
        }
        #loop through all environment variables
        foreach ($envvar in $envars) 
        {
            write-host "#########################"
            write-host "Environment Variable Definition: " $envvar.FullName
            try {
                $envardef = Get-ChildItem -path $envvar.FullName -Filter '*.xml'
            }
            catch {
                write-Error $_
            break
            }
            $envardefvalue = select-xml -path $envardef.FullName -XPath "/environmentvariabledefinition"
            if($envardefvalue.Node -ne $null)
            {
                write-host "Environment Variable Schema Name: " $envardefvalue.Node.schemaname
                write-host "Environment Variable Default Value: " $envardefvalue.Node.defaultvalue
            }
            try {
                $envarvalue = Get-ChildItem -path $envvar.FullName -Filter '*.json'
            }
            catch {
                write-Error $_
            break
            }
            if($envarvalue -eq $null){
                write-host "No environment variable current value"
            } else {
                try {
                    $envarcurrentvalue = (Get-Content -Path $envarvalue.FullName) | ConvertFrom-Json -Depth 3
                }
                catch {
                    write-Error $_
                    break
                }
                write-host "Environment Variable Curret Value: " $envarcurrentvalue.environmentvariablevalues.environmentvariablevalue.value    
                if($deleteCurrentValues)
                {
                    try {
                        Remove-Item -Path $envarvalue.FullName -Confirm:$false -Force
                    }
                    catch {
                        write-Error $_
                        return $false
                        break
                    }
                    write-host "Environment Variable Current Value Deleted"
                    return $true
                }
            }
        }
    }
    else {
        write-host "$SolutionFilePath not found"
    }  
    return $false
}
# description: This function deletes the existing solution source files.
# Usage: Delete-ExistingSolutionSource -solutionName $solutionName -folderPath $folderPath -deleteFiles $deleteFiles
# parameters:
# - solutionName: The name of the solution.
# - folderPath: The folder path where the solution is located. Default is ''.
# - deleteFiles: A boolean value to indicate whether to delete the files. Default is false.
# returns: A boolean value indicating the success of the operation.

function Delete-ExistingSolutionSource
{
    param (
        [Parameter(Mandatory)] [String]$solutionName,
        [String]$folderPath = '',
        [boolean]$deleteFiles = $false
    )
    if ($folderPath -eq '')
    {
        $SolutionFilePath = "src/$solutionName"
    }
    else {
        $SolutionFilePath = "$folderPath/src/$solutionName"
    }
    if (Test-Path -LiteralPath $SolutionFilePath ) 
    {
        if ($deleteFiles) {
            try {
                Remove-Item -Path $SolutionFilePath -Recurse -Confirm:$false -Force -verbose
            }
            catch {
                write-Error $_
                return $false
                break
            }
            write-host "$SolutionFilePath deleted"
            return $true
        }
    }
    else {
        write-host "$SolutionFilePath not found"
    }    
    return $false
}
function Get-SolutionComponentType
{
    param ( 
        [Parameter(Mandatory)] [String]$componenttype
    )   
    $componentTypes = @(
    [PSCustomObject]@{ Values = 1; Label = "Entity"; Entity = "/" }
    [PSCustomObject]@{ Values = 2; Label = "Attribute"; Entity = "attributes" }
    [PSCustomObject]@{ Values = 3; Label = "Relationship"; Entity = "relationships" }
    [PSCustomObject]@{ Values = 4; Label = "Attribute Picklist Value"; Entity = $null }
    [PSCustomObject]@{ Values = 5; Label = "Attribute Lookup Value"; Entity = $null }
    [PSCustomObject]@{ Values = 6; Label = "View Attribute"; Entity = $null }
    [PSCustomObject]@{ Values = 7; Label = "Localized Label"; Entity = $null }
    [PSCustomObject]@{ Values = 8; Label = "Relationship Extra Condition"; Entity = $null }
    [PSCustomObject]@{ Values = 9; Label = "Option Set"; Entity = $null }
    [PSCustomObject]@{ Values = 10; Label = "Entity Relationship"; Entity = $null }
    [PSCustomObject]@{ Values = 11; Label = "Entity Relationship Role"; Entity = $null }
    [PSCustomObject]@{ Values = 12; Label = "Entity Relationship Relationships"; Entity = $null }
    [PSCustomObject]@{ Values = 13; Label = "Managed Property"; Entity = $null }
    [PSCustomObject]@{ Values = 14; Label = "Entity Key"; Entity = $null }
    [PSCustomObject]@{ Values = 16; Label = "Privilege"; Entity = "privileges" }
    [PSCustomObject]@{ Values = 17; Label = "PrivilegeObjectTypeCode"; Entity = $null }
    [PSCustomObject]@{ Values = 20; Label = "Role"; Entity = "roles" }
    [PSCustomObject]@{ Values = 21; Label = "Role Privilege"; Entity = $null }
    [PSCustomObject]@{ Values = 22; Label = "Display String"; Entity = $null }
    [PSCustomObject]@{ Values = 23; Label = "Display String Map"; Entity = $null }
    [PSCustomObject]@{ Values = 24; Label = "Form"; Entity = $null }
    [PSCustomObject]@{ Values = 25; Label = "Organization"; Entity = "organizations" }
    [PSCustomObject]@{ Values = 26; Label = "Saved Query"; Entity = $null }
    [PSCustomObject]@{ Values = 29; Label = "Workflow"; Entity = "workflows" }
    [PSCustomObject]@{ Values = 31; Label = "Report"; Entity = "reports" }
    [PSCustomObject]@{ Values = 32; Label = "Report Entity"; Entity = $null }
    [PSCustomObject]@{ Values = 33; Label = "Report Category"; Entity = $null }
    [PSCustomObject]@{ Values = 34; Label = "Report Visibility"; Entity = $null }
    [PSCustomObject]@{ Values = 35; Label = "Attachment"; Entity = "attachments" }
    [PSCustomObject]@{ Values = 36; Label = "Email Template"; Entity = $null }
    [PSCustomObject]@{ Values = 37; Label = "Contract Template"; Entity = $null }
    [PSCustomObject]@{ Values = 38; Label = "KB Article Template"; Entity = $null }
    [PSCustomObject]@{ Values = 39; Label = "Mail Merge Template"; Entity = $null }
    [PSCustomObject]@{ Values = 44; Label = "Duplicate Rule"; Entity = $null }
    [PSCustomObject]@{ Values = 45; Label = "Duplicate Rule Condition"; Entity = $null }
    [PSCustomObject]@{ Values = 46; Label = "Entity Map"; Entity = $null }
    [PSCustomObject]@{ Values = 47; Label = "Attribute Map"; Entity = $null }
    [PSCustomObject]@{ Values = 48; Label = "Ribbon Command"; Entity = $null }
    [PSCustomObject]@{ Values = 49; Label = "Ribbon Context Group"; Entity = $null }
    [PSCustomObject]@{ Values = 50; Label = "Ribbon Customization"; Entity = $null }
    [PSCustomObject]@{ Values = 52; Label = "Ribbon Rule"; Entity = $null }
    [PSCustomObject]@{ Values = 53; Label = "Ribbon Tab To Command Map"; Entity = $null }
    [PSCustomObject]@{ Values = 55; Label = "Ribbon Diff"; Entity = $null }
    [PSCustomObject]@{ Values = 59; Label = "Saved Query Visualization"; Entity = $null }
    [PSCustomObject]@{ Values = 60; Label = "System Form"; Entity = $null }
    [PSCustomObject]@{ Values = 61; Label = "Web Resource"; Entity = $null }
    [PSCustomObject]@{ Values = 62; Label = "Site Map"; Entity = "sitemaps" }
    [PSCustomObject]@{ Values = 63; Label = "Connection Role"; Entity = $null }
    [PSCustomObject]@{ Values = 64; Label = "Complex Control"; Entity = $null }
    [PSCustomObject]@{ Values = 70; Label = "Field Security Profile"; Entity = $null }
    [PSCustomObject]@{ Values = 71; Label = "Field Permission"; Entity = $null }
    [PSCustomObject]@{ Values = 80; Label = "Model Driven App"; Entity = 'appmodules' }
    [PSCustomObject]@{ Values = 90; Label = "Plugin Type"; Entity = $null }
    [PSCustomObject]@{ Values = 91; Label = "Plugin Assembly"; Entity = $null }
    [PSCustomObject]@{ Values = 92; Label = "SDK Message Processing Step"; Entity = $null }
    [PSCustomObject]@{ Values = 93; Label = "SDK Message Processing Step Image"; Entity = $null }
    [PSCustomObject]@{ Values = 95; Label = "Service Endpoint"; Entity = $null }
    [PSCustomObject]@{ Values = 150; Label = "Routing Rule"; Entity = $null }
    [PSCustomObject]@{ Values = 151; Label = "Routing Rule Item"; Entity = $null }
    [PSCustomObject]@{ Values = 152; Label = "SLA"; Entity = $null }
    [PSCustomObject]@{ Values = 153; Label = "SLA Item"; Entity = $null }
    [PSCustomObject]@{ Values = 154; Label = "Convert Rule"; Entity = $null }
    [PSCustomObject]@{ Values = 155; Label = "Convert Rule Item"; Entity = $null }
    [PSCustomObject]@{ Values = 65; Label = "Hierarchy Rule"; Entity = $null }
    [PSCustomObject]@{ Values = 161; Label = "Mobile Offline Profile"; Entity = $null }
    [PSCustomObject]@{ Values = 162; Label = "Mobile Offline Profile Item"; Entity = $null }
    [PSCustomObject]@{ Values = 165; Label = "Similarity Rule"; Entity = $null }
    [PSCustomObject]@{ Values = 66; Label = "Custom Control"; Entity = $null }
    [PSCustomObject]@{ Values = 68; Label = "Custom Control Default Config"; Entity = $null }
    [PSCustomObject]@{ Values = 166; Label = "Data Source Mapping"; Entity = $null }
    [PSCustomObject]@{ Values = 201; Label = "SDKMessage"; Entity = $null }
    [PSCustomObject]@{ Values = 202; Label = "SDKMessageFilter"; Entity = $null }
    [PSCustomObject]@{ Values = 203; Label = "SdkMessagePair"; Entity = $null }
    [PSCustomObject]@{ Values = 204; Label = "SdkMessageRequest"; Entity = $null }
    [PSCustomObject]@{ Values = 205; Label = "SdkMessageRequestField"; Entity = $null }
    [PSCustomObject]@{ Values = 206; Label = "SdkMessageResponse"; Entity = $null }
    [PSCustomObject]@{ Values = 207; Label = "SdkMessageResponseField"; Entity = $null }
    [PSCustomObject]@{ Values = 210; Label = "WebWizard"; Entity = $null }
    [PSCustomObject]@{ Values = 18; Label = "Index"; Entity = $null }
    [PSCustomObject]@{ Values = 208; Label = "Import Map"; Entity = $null }
    [PSCustomObject]@{ Values = 300; Label = "Canvas App"; Entity = $null }
    [PSCustomObject]@{ Values = 371; Label = "Connector"; Entity = $null }
    [PSCustomObject]@{ Values = 372; Label = "Connector"; Entity = $null }
    [PSCustomObject]@{ Values = 380; Label = "Environment Variable Definition"; Entity = "environmentvariabledefinitions" }
    [PSCustomObject]@{ Values = 381; Label = "Environment Variable Value"; Entity = "environmentvariablevalues" }
    [PSCustomObject]@{ Values = 400; Label = "AI Project Type"; Entity = $null}
    [PSCustomObject]@{ Values = 401; Label = "AI Project"; Entity = $null }
    [PSCustomObject]@{ Values = 402; Label = "AI Configuration"; Entity = $null }
    [PSCustomObject]@{ Values = 430; Label = "Entity Analytics Configuration"; Entity = $null }
    [PSCustomObject]@{ Values = 431; Label = "Attribute Image Configuration"; Entity = $null }
    [PSCustomObject]@{ Values = 432; Label = "Entity Image Configuration"; Entity = $null }
)
    return $componentTypes | where { $_.Values -eq $componenttype }
}
