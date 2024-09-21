param(
    [Parameter(
        Mandatory=$True)]
    [ValidateSet(
    'Development',
    'SysDev',
    'Test',
    'Staging',
    'Production'
    )]
    [string]$env,
    [switch]$deviceAuth,
    [switch]$clearCurrentEnvVarValue,
    [switch]$incrementVersion,
    [string]$solutionName,
    [string]$commitMessage,
    [string]$branch
)
switch($env)
{
    'SysDev'
    {
        $orgURL = 'https://org439c3f54.crm.dynamics.com/'
    }
    'Development'
    {
        $orgURL = 'https://org1b29da34.crm.dynamics.com'
    }
    'Test'
    {
        $orgURL = 'https://org3e1752d5.crm.dynamics.com/'
    }
    'Staging'
    {
        $orgURL = 'https://org12a26e6e.crm.dynamics.com/'
        
    }
    'Production'
    {
        $orgURL = ''
    }
}
$outputPath = 'solutions'
$srcPath = 'src'
if($deviceAuth)
{
    pac auth create --url $orgURL --deviceCode
} else {
    pac auth create --url $orgURL

}
pac solution export --name ($solutionName) --path  ($outputPath + '\' + $solutionName +'.zip') -ow
pac solution export --name ($solutionName) --path  ($outputPath  + '\' + $solutionName +'_managed.zip') -m -ow
pac solution unpack -z ($outputPath+'\' +$solutionName + '.zip') -f ($srcPath +'\' + $solutionName )-p both -pca
if($clearCurrentEnvVarValue)
{
    $envars = Get-ChildItem -Path "$srcPath\$solutionname\environmentvariabledefinitions" -Directory
    #loop through all environment variables
    foreach ($envvar in $envars) {
        write-host "#########################"
        write-host "Environment Variable Definition: " $envvar.FullName
        $envardef = Get-ChildItem -path $envvar.FullName -Filter '*.xml'
        $envardefvalue = select-xml -path $envardef.FullName -XPath "/environmentvariabledefinition"
        if($envardefvalue.Node -ne $null)
        {
            write-host "Environment Variable Schema Name: " $envardefvalue.Node.schemaname
            write-host "Environment Variable Default Value: " $envardefvalue.Node.defaultvalue
        }
        $envarvalue = Get-ChildItem -path $envvar.FullName -Filter '*.json'
        if($envarvalue -eq $null){
            write-host "No environment variable current value"
        } else {
            $envarcurrentvalue = (Get-Content -Path $envarvalue.FullName) | ConvertFrom-Json -Depth 3
            write-host "Environment Variable Curret Value: " $envarcurrentvalue.environmentvariablevalues.environmentvariablevalue.value    
            Remove-Item -Path $envarvalue.FullName
            write-host "Environment Variable Current Value Deleted"
        }
    }
}
pac auth clear

