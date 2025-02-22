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
        [String]$aadHost = 'login.microsoftonline.com'
    )
    $token = Get-SpnToken -tenantID $tenantID -clientId $clientId -clientSecret $clientSecret -dataverseHost $dataverseHost -aadHost $aadHost
    return $token
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
        [Parameter(Mandatory)] [String]$dataverseHost

    )
    $response = Invoke-DataverseHttpGet -token $token -dataverseHost $dataverseHost -requestUrlRemainder 'solutions'
    return $response.value
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
        [Parameter(Mandatory)] [String]$solutionUniqueName
    )
    $response = Invoke-DataverseHttpGet -token $token -dataverseHost $dataverseHost -requestUrlRemainder ('solutions?$filter=uniquename%20eq%20%27' + $solutionUniqueName + '%27')
    return $response.value
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
        [String]$componentType
    )
    if($componentType)
    {
        $response = Invoke-DataverseHttpGet -token $token -dataverseHost $dataverseHost -requestUrlRemainder ('solutioncomponents?$filter=_solutionid_value%20eq%20%27' + $solutionId + '%27&componenttype%20eq%20' + $componentType)
    }
    else
    {
        $response = Invoke-DataverseHttpGet -token $token -dataverseHost $dataverseHost -requestUrlRemainder ('solutioncomponents?$filter=_solutionid_value%20eq%20%27' + $solutionId + '%27')
    }
    $results = @()
    foreach ($component in $response.value)
    {
        $componentType = Get-SolutionComponentTypes -componenttype $component.componenttype
        $results += [PSCustomObject]@{
            componentTypeName = $componentType.Label
            componentType = $component.componenttype
            id = $component.objectid
            componentId = $component.solutioncomponentid
        }
    }
    return $results
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
    $querystring = "organizations($organizationId)?`$select=" + [uri]::EscapeDataString("allowentityonlyaudit,isauditenabled,isuseraccessauditenabled,auditretentionperiod,enableipbasedfirewallruleinauditmode,useraccessauditinginterval,auditretentionperiodv2,isreadauditenabled")
    $response = Invoke-DataverseHttpGet -token $token -dataverseHost $dataverseHost -requestUrlRemainder $querystring
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
    write-host $auditParams
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
    $querystring = "organizations($organizationId)?`$select=" + [uri]::EscapeDataString("isrpaautoscaleaadjoinenabled,isrpaautoscaleenabled,isrpaunattendedenabled,isrpaboxcrossgeoenabled,isrpaboxenabled")
    $response = Invoke-DataverseHttpGet -token $token -dataverseHost $dataverseHost -requestUrlRemainder $querystring
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
        [String]$operation
    )
    # operation types
    # 1 = Create
    # 2 = Update
    # 3 = Delete
    # 4 = Access
    if ($operation -ne ''){
        $querystring = 'objecttypecode eq ''' + $entityName + ''' and operation eq ' + $operation
    } else {
        $querystring = 'objecttypecode eq ''' + $entityName + ''''
    }
    $querystring = 'audits?$filter=' + [uri]::EscapeDataString($querystring)
    write-host $querystring
    $response = Invoke-DataverseHttpGet -token $token -dataverseHost $dataverseHost -requestUrlRemainder $querystring
    return $response.value 
}

function get-DataverseOrganizationId {
    param (
        [Parameter(Mandatory)] [String]$token,
        [Parameter(Mandatory)] [String]$dataverseHost
    )
    $response = Invoke-DataverseHttpGet -token $token -dataverseHost $dataverseHost -requestUrlRemainder 'organizations'
    return $response.value[0].organizationid
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
        $body = "{
        `n    `"Target`":{
        `n        `"workflowid`":`"$validatedId`",
        `n        `"@odata.type`": `"Microsoft.Dynamics.CRM.workflow`"
        `n    },
        `n    `"PrincipalAccess`":{
        `n        `"Principal`":{
        `n            `"teamid`": `"$teamId`",
        `n            `"@odata.type`": `"Microsoft.Dynamics.CRM.team`"
        `n        },
        `n        `"AccessMask`": `"ReadAccess`"
        `n    }
        `n}"
    
        $requestUrlRemainder = "GrantAccess"
        Invoke-DataverseHttpPost $token $dataverseHost $requestUrlRemainder $body
        Invoke-
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
        $body = "{
        `n    `"Target`":{
        `n        `"connectorid`":`"$validatedId`",
        `n        `"@odata.type`": `"Microsoft.Dynamics.CRM.connector`"
        `n    },
        `n    `"PrincipalAccess`":{
        `n        `"Principal`":{
        `n            `"teamid`": `"$teamId`",
        `n            `"@odata.type`": `"Microsoft.Dynamics.CRM.team`"
        `n        },
        `n        `"AccessMask`": `"ReadAccess`"
        `n    }
        `n}"

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
    $response = Invoke-DataverseHttpGet $token $dataverseHost $odataQuery
    if($response.value.length -gt 0) {
        $teamId = $response.value[0].teamid
    }
    return $teamId
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
function Get-SolutionComponentTypes 
{
    param ( 
        [Parameter(Mandatory)] [String]$componenttype
    )   
    $componentTypes = @(
    [PSCustomObject]@{ Values = 1; Label = "Entity" }
    [PSCustomObject]@{ Values = 2; Label = "Attribute" }
    [PSCustomObject]@{ Values = 3; Label = "Relationship" }
    [PSCustomObject]@{ Values = 4; Label = "Attribute Picklist Value" }
    [PSCustomObject]@{ Values = 5; Label = "Attribute Lookup Value" }
    [PSCustomObject]@{ Values = 6; Label = "View Attribute" }
    [PSCustomObject]@{ Values = 7; Label = "Localized Label" }
    [PSCustomObject]@{ Values = 8; Label = "Relationship Extra Condition" }
    [PSCustomObject]@{ Values = 9; Label = "Option Set" }
    [PSCustomObject]@{ Values = 10; Label = "Entity Relationship" }
    [PSCustomObject]@{ Values = 11; Label = "Entity Relationship Role" }
    [PSCustomObject]@{ Values = 12; Label = "Entity Relationship Relationships" }
    [PSCustomObject]@{ Values = 13; Label = "Managed Property" }
    [PSCustomObject]@{ Values = 14; Label = "Entity Key" }
    [PSCustomObject]@{ Values = 16; Label = "Privilege" }
    [PSCustomObject]@{ Values = 17; Label = "PrivilegeObjectTypeCode" }
    [PSCustomObject]@{ Values = 20; Label = "Role" }
    [PSCustomObject]@{ Values = 21; Label = "Role Privilege" }
    [PSCustomObject]@{ Values = 22; Label = "Display String" }
    [PSCustomObject]@{ Values = 23; Label = "Display String Map" }
    [PSCustomObject]@{ Values = 24; Label = "Form" }
    [PSCustomObject]@{ Values = 25; Label = "Organization" }
    [PSCustomObject]@{ Values = 26; Label = "Saved Query" }
    [PSCustomObject]@{ Values = 29; Label = "Workflow" }
    [PSCustomObject]@{ Values = 31; Label = "Report" }
    [PSCustomObject]@{ Values = 32; Label = "Report Entity" }
    [PSCustomObject]@{ Values = 33; Label = "Report Category" }
    [PSCustomObject]@{ Values = 34; Label = "Report Visibility" }
    [PSCustomObject]@{ Values = 35; Label = "Attachment" }
    [PSCustomObject]@{ Values = 36; Label = "Email Template" }
    [PSCustomObject]@{ Values = 37; Label = "Contract Template" }
    [PSCustomObject]@{ Values = 38; Label = "KB Article Template" }
    [PSCustomObject]@{ Values = 39; Label = "Mail Merge Template" }
    [PSCustomObject]@{ Values = 44; Label = "Duplicate Rule" }
    [PSCustomObject]@{ Values = 45; Label = "Duplicate Rule Condition" }
    [PSCustomObject]@{ Values = 46; Label = "Entity Map" }
    [PSCustomObject]@{ Values = 47; Label = "Attribute Map" }
    [PSCustomObject]@{ Values = 48; Label = "Ribbon Command" }
    [PSCustomObject]@{ Values = 49; Label = "Ribbon Context Group" }
    [PSCustomObject]@{ Values = 50; Label = "Ribbon Customization" }
    [PSCustomObject]@{ Values = 52; Label = "Ribbon Rule" }
    [PSCustomObject]@{ Values = 53; Label = "Ribbon Tab To Command Map" }
    [PSCustomObject]@{ Values = 55; Label = "Ribbon Diff" }
    [PSCustomObject]@{ Values = 59; Label = "Saved Query Visualization" }
    [PSCustomObject]@{ Values = 60; Label = "System Form" }
    [PSCustomObject]@{ Values = 61; Label = "Web Resource" }
    [PSCustomObject]@{ Values = 62; Label = "Site Map" }
    [PSCustomObject]@{ Values = 63; Label = "Connection Role" }
    [PSCustomObject]@{ Values = 64; Label = "Complex Control" }
    [PSCustomObject]@{ Values = 70; Label = "Field Security Profile" }
    [PSCustomObject]@{ Values = 71; Label = "Field Permission" }
    [PSCustomObject]@{ Values = 90; Label = "Plugin Type" }
    [PSCustomObject]@{ Values = 91; Label = "Plugin Assembly" }
    [PSCustomObject]@{ Values = 92; Label = "SDK Message Processing Step" }
    [PSCustomObject]@{ Values = 93; Label = "SDK Message Processing Step Image" }
    [PSCustomObject]@{ Values = 95; Label = "Service Endpoint" }
    [PSCustomObject]@{ Values = 150; Label = "Routing Rule" }
    [PSCustomObject]@{ Values = 151; Label = "Routing Rule Item" }
    [PSCustomObject]@{ Values = 152; Label = "SLA" }
    [PSCustomObject]@{ Values = 153; Label = "SLA Item" }
    [PSCustomObject]@{ Values = 154; Label = "Convert Rule" }
    [PSCustomObject]@{ Values = 155; Label = "Convert Rule Item" }
    [PSCustomObject]@{ Values = 65; Label = "Hierarchy Rule" }
    [PSCustomObject]@{ Values = 161; Label = "Mobile Offline Profile" }
    [PSCustomObject]@{ Values = 162; Label = "Mobile Offline Profile Item" }
    [PSCustomObject]@{ Values = 165; Label = "Similarity Rule" }
    [PSCustomObject]@{ Values = 66; Label = "Custom Control" }
    [PSCustomObject]@{ Values = 68; Label = "Custom Control Default Config" }
    [PSCustomObject]@{ Values = 166; Label = "Data Source Mapping" }
    [PSCustomObject]@{ Values = 201; Label = "SDKMessage" }
    [PSCustomObject]@{ Values = 202; Label = "SDKMessageFilter" }
    [PSCustomObject]@{ Values = 203; Label = "SdkMessagePair" }
    [PSCustomObject]@{ Values = 204; Label = "SdkMessageRequest" }
    [PSCustomObject]@{ Values = 205; Label = "SdkMessageRequestField" }
    [PSCustomObject]@{ Values = 206; Label = "SdkMessageResponse" }
    [PSCustomObject]@{ Values = 207; Label = "SdkMessageResponseField" }
    [PSCustomObject]@{ Values = 210; Label = "WebWizard" }
    [PSCustomObject]@{ Values = 18; Label = "Index" }
    [PSCustomObject]@{ Values = 208; Label = "Import Map" }
    [PSCustomObject]@{ Values = 300; Label = "Canvas App" }
    [PSCustomObject]@{ Values = 371; Label = "Connector" }
    [PSCustomObject]@{ Values = 372; Label = "Connector" }
    [PSCustomObject]@{ Values = 380; Label = "Environment Variable Definition" }
    [PSCustomObject]@{ Values = 381; Label = "Environment Variable Value" }
    [PSCustomObject]@{ Values = 400; Label = "AI Project Type" }
    [PSCustomObject]@{ Values = 401; Label = "AI Project" }
    [PSCustomObject]@{ Values = 402; Label = "AI Configuration" }
    [PSCustomObject]@{ Values = 430; Label = "Entity Analytics Configuration" }
    [PSCustomObject]@{ Values = 431; Label = "Attribute Image Configuration" }
    [PSCustomObject]@{ Values = 432; Label = "Entity Image Configuration" }
)
    if($componenttype)
    {
        return $componentTypes | where { $_.Values -eq $componenttype }
    }
    return $componentTypes
}
